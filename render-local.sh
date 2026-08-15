#!/usr/bin/env bash
# render-local.sh
# Rendert alle Manifeste eines Cluster-Verzeichnisses so wie Flux es tun würde,
# ohne einen laufenden K8s-Cluster zu benötigen.
#
# Abhängigkeiten: kustomize, yq (mikefarah/yq v4), envsubst (gettext)
#
# Verwendung:
#   ./render-local.sh [cluster-verzeichnis]   (default: hetzner-k8s-vs-01)
#   ./render-local.sh hetzner-k8s-vs-01 > rendered.yaml
#   ./render-local.sh hetzner-k8s-vs-01 | grep -A20 "kind: Cluster"

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
TARGET_DIR="${1:-hetzner-k8s-dt-01}"
TARGET_PATH="$REPO_ROOT/$TARGET_DIR"
TMPDIR_BASE=$(mktemp -d)
# Symlinks auflösen (z.B. /var -> /private/var auf macOS), damit die per
# os.path.relpath berechneten relativen Pfade mit dem Pfad übereinstimmen,
# den kustomize's evalsymlink beim Einlesen tatsächlich verwendet.
TMPDIR_BASE=$(cd "$TMPDIR_BASE" && pwd -P)

cleanup() { rm -rf "$TMPDIR_BASE"; }
trap cleanup EXIT

# ─── Abhängigkeiten prüfen ────────────────────────────────────────────────────
for cmd in kustomize yq envsubst python3; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "ERROR: '$cmd' nicht gefunden. Bitte installieren." >&2
    exit 1
  fi
done

if [ ! -d "$TARGET_PATH" ]; then
  echo "ERROR: Verzeichnis nicht gefunden: $TARGET_PATH" >&2
  exit 1
fi

# ─── Hilfsfunktion: Flux Kustomization → kustomization.yaml ──────────────────
# Baut aus einem extrahierten Flux Kustomization-Objekt ein temporäres
# Kustomize-Overlay und rendert es inkl. postBuild.substitute.
render_flux_ks() {
  local ks_file="$1"   # Pfad zur Flux Kustomization (Single-Doc YAML)
  local ks_name ks_path local_path temp_dir relative_path

  ks_name=$(yq '.metadata.name' "$ks_file")
  ks_path=$(yq '.spec.path' "$ks_file")
  local_path="$REPO_ROOT/$ks_path"

  if [ ! -d "$local_path" ]; then
    echo "  SKIP: $ks_name — Pfad nicht lokal vorhanden: $ks_path" >&2
    return 0
  fi

  echo "  -> $ks_name ($ks_path)" >&2

  # Temp-Overlay-Verzeichnis anlegen
  temp_dir="$TMPDIR_BASE/overlay-${ks_name}"
  mkdir -p "$temp_dir"

  # Relativen Pfad vom Overlay-Dir zur Base berechnen
  relative_path=$(python3 -c "import os; print(os.path.relpath('$local_path', '$temp_dir'))")

  # kustomization.yaml zusammenbauen
  {
    echo "apiVersion: kustomize.config.k8s.io/v1beta1"
    echo "kind: Kustomization"
    echo "resources:"
    echo "  - $relative_path"

    # namePrefix
    val=$(yq '.spec.namePrefix // ""' "$ks_file")
    [ -n "$val" ] && echo "namePrefix: $val"

    # nameSuffix
    val=$(yq '.spec.nameSuffix // ""' "$ks_file")
    [ -n "$val" ] && echo "nameSuffix: $val"

    # targetNamespace → namespace
    val=$(yq '.spec.targetNamespace // ""' "$ks_file")
    [ -n "$val" ] && echo "namespace: $val"

    # patches
    patches_count=$(yq '.spec.patches // [] | length' "$ks_file")
    if [ "$patches_count" -gt 0 ]; then
      echo "patches:"
      yq '.spec.patches' "$ks_file"
    fi
  } > "$temp_dir/kustomization.yaml"

  # Header ausgeben
  echo "---"
  echo "# =================================================================="
  echo "# Flux Kustomization: $ks_name"
  echo "# Pfad: $ks_path"
  echo "# =================================================================="

  # postBuild.substitute Variablen sammeln
  subst_count=$(yq '.spec.postBuild.substitute // {} | length' "$ks_file")

  if [ "$subst_count" -gt 0 ]; then
    # Alle Vars exportieren
    while IFS= read -r var_name; do
      [ -z "$var_name" ] && continue
      var_val=$(yq ".spec.postBuild.substitute.\"$var_name\"" "$ks_file")
      export "$var_name=$var_val"
    done < <(yq '.spec.postBuild.substitute // {} | keys | .[]' "$ks_file")

    # Nur die deklarierten Vars substituieren (kein versehentliches Ersetzen anderer $-Zeichen)
    var_list=$(yq '.spec.postBuild.substitute // {} | keys | .[]' "$ks_file" \
      | awk '{print "${" $1 "}"}' | tr '\n' ' ')

    kustomize build "$temp_dir" | envsubst "$var_list"
  else
    kustomize build "$temp_dir"
  fi
}

# ─── Part 1: Statische Ressourcen via kustomize build ────────────────────────
echo "# Rendering: $TARGET_DIR" >&2
echo "# [1/2] kustomize build $TARGET_DIR ..." >&2
echo "---"
echo "# =================================================================="
echo "# Statische Ressourcen: kustomize build $TARGET_DIR"
echo "# =================================================================="
kustomize build "$TARGET_PATH"

# ─── Part 2: Alle Flux Kustomizations rendern ────────────────────────────────
echo "" >&2
echo "# [2/2] Flux Kustomizations suchen und rendern ..." >&2

find "$TARGET_PATH" -name "*.yaml" | sort | while read -r file; do
  names=$(yq 'select(.apiVersion == "kustomize.toolkit.fluxcd.io/v1" and .kind == "Kustomization") | .metadata.name' \
    "$file" 2>/dev/null || true)
  [ -z "$names" ] && continue

  while IFS= read -r ks_name; do
    [ -z "$ks_name" ] && continue

    # Nur das Kustomization-Objekt in eine eigene Datei extrahieren
    temp_ks="$TMPDIR_BASE/${ks_name}.yaml"
    yq "select(.apiVersion == \"kustomize.toolkit.fluxcd.io/v1\" and .kind == \"Kustomization\" and .metadata.name == \"$ks_name\")" \
      "$file" > "$temp_ks"

    render_flux_ks "$temp_ks"

  done <<< "$names"
done

echo "" >&2
echo "# Fertig." >&2
