#!/usr/bin/env bash
# Vergleicht die vendorten PrometheusRules unter
# base/monitoring/prometheus-stack/rules/ mit dem, was kube-prometheus-stack
# in der angegebenen Version generieren wuerde.
#
# Verwendung:
#   ./hack/diff-default-rules.sh [chart-version]
# Ohne Argument wird die Version aus prometheus-helm.yaml gelesen.
#
# Abhaengigkeiten: helm, yq (mikefarah v4)

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
STACK_DIR="$REPO_ROOT/base/monitoring/prometheus-stack"
VERSION="${1:-$(yq 'select(.kind == "HelmRelease") | .spec.chart.spec.version' "$STACK_DIR/prometheus-helm.yaml")}"

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

echo "# Rendere kube-prometheus-stack $VERSION ..." >&2
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts >/dev/null 2>&1 || true
helm repo update prometheus-community >/dev/null

helm template kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --version "$VERSION" -n monitoring \
  -f "$STACK_DIR/values.yaml" \
  --set defaultRules.create=true \
  | yq 'select(.kind == "PrometheusRule")' \
  | yq '.metadata.name |= (sub("^kube-prometheus-stack-"; "") | sub("\."; "-")
          | sub("-seconds-tot$"; "-seconds-total")
          | sub("-working-set-by$"; "-working-set-bytes"))
        | .metadata.labels = {"release": "kube-prometheus-stack"}
        | ... comments=""' \
  > "$TMP/upstream.yaml"

mkdir -p "$TMP/upstream" && (cd "$TMP/upstream" && yq -s '.metadata.name' "$TMP/upstream.yaml")
# Fuehrenden Doc-Separator entfernen, damit nur echte Inhaltsunterschiede auftauchen
for f in "$TMP/upstream"/*.yml; do
  if [ "$(head -1 "$f")" = "---" ]; then
    tail -n +2 "$f" > "$f.tmp" && mv "$f.tmp" "$f"
  fi
done

# Vendorte Dateien normalisieren (Kommentar-Header und Kustomization raus)
mkdir -p "$TMP/vendored"
for f in "$STACK_DIR"/rules/*.yaml; do
  [ "$(basename "$f")" = "kustomization.yaml" ] && continue
  yq '... comments=""' "$f" > "$TMP/vendored/$(basename "$f" .yaml).yml"
done

diff -ru "$TMP/upstream" "$TMP/vendored" && echo "# Keine Abweichungen." >&2
