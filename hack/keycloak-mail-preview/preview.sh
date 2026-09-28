#!/usr/bin/env bash
# preview.sh
# Rendert die Keycloak-E-Mail-Templates des cvo-Themes gegen Testdaten und
# öffnet eine Vorschau-Galerie im Browser - ohne laufenden Keycloak.
#
# Abhängigkeiten: java 11+ (nur zum Rendern; FreeMarker wird einmalig geladen)
#
# Verwendung:
#   ./hack/keycloak-mail-preview/preview.sh              # DE + EN, öffnet Browser
#   ./hack/keycloak-mail-preview/preview.sh --no-open    # nur rendern (CI / Check)
#   ./hack/keycloak-mail-preview/preview.sh de           # nur eine Sprache

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd -P)"
THEME_DIR="$REPO_ROOT/base/security/keycloak/keycloak-theme/cvo/email"
OUT_DIR="${PREVIEW_OUT:-$SCRIPT_DIR/.preview}"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/keycloak-mail-preview"
FREEMARKER_VERSION="2.3.34"
FREEMARKER_JAR="$CACHE_DIR/freemarker-$FREEMARKER_VERSION.jar"

OPEN=1
LOCALES=()
for arg in "$@"; do
  case "$arg" in
    --no-open) OPEN=0 ;;
    -*) echo "Unbekannte Option: $arg" >&2; exit 1 ;;
    *) LOCALES+=("$arg") ;;
  esac
done
[ ${#LOCALES[@]} -eq 0 ] && LOCALES=(de en)

command -v java >/dev/null || { echo "ERROR: 'java' nicht gefunden (java 11+ nötig)." >&2; exit 1; }
[ -d "$THEME_DIR" ] || { echo "ERROR: Theme nicht gefunden: $THEME_DIR" >&2; exit 1; }

# ─── FreeMarker besorgen (einmalig, danach aus dem Cache) ────────────────────
if [ ! -f "$FREEMARKER_JAR" ]; then
  mkdir -p "$CACHE_DIR"
  echo "# Lade FreeMarker $FREEMARKER_VERSION nach $CACHE_DIR ..." >&2
  curl -sSfL -o "$FREEMARKER_JAR" \
    "https://repo1.maven.org/maven2/org/freemarker/freemarker/$FREEMARKER_VERSION/freemarker-$FREEMARKER_VERSION.jar" \
    || { rm -f "$FREEMARKER_JAR"; echo "ERROR: Download fehlgeschlagen." >&2; exit 1; }
fi

# ─── Rendern ────────────────────────────────────────────────────────────────
rm -rf "$OUT_DIR"
mkdir -p "$OUT_DIR"
echo "# Rendere $THEME_DIR (${LOCALES[*]}) ..." >&2
java -cp "$FREEMARKER_JAR" "$SCRIPT_DIR/Render.java" "$THEME_DIR" "$OUT_DIR" "${LOCALES[@]}"

echo "" >&2
echo "# Vorschau: $OUT_DIR/index.html" >&2

if [ "$OPEN" -eq 1 ]; then
  case "$(uname -s)" in
    Darwin) open "$OUT_DIR/index.html" ;;
    Linux)  command -v xdg-open >/dev/null && xdg-open "$OUT_DIR/index.html" ;;
  esac
fi
