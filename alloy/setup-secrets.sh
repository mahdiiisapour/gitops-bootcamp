#!/bin/bash

# setup-secrets.sh - Create the alloy-remote-credentials secret for Alloy to authenticate with Loki and Mimir
# Usage: ./setup-secrets.sh [namespace]

NAMESPACE="${1:-observability}"

echo "Creating alloy-remote-credentials secret in namespace: $NAMESPACE"

# Create the secret with bearer tokens for Loki and Mimir authentication
# Replace these token values with your actual tokens or leave empty if not using authentication
kubectl create secret generic alloy-remote-credentials \
  --from-literal=LOKI_TOKEN="" \
  --from-literal=MIMIR_TOKEN="" \
  -n "$NAMESPACE" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "✓ Secret 'alloy-remote-credentials' created/updated in namespace '$NAMESPACE'"

# If you need to update tokens later, use:
# kubectl patch secret alloy-remote-credentials -n $NAMESPACE -p '{"data":{"LOKI_TOKEN":"'$(echo -n "your-loki-token" | base64 -w0)'"}}'
# kubectl patch secret alloy-remote-credentials -n $NAMESPACE -p '{"data":{"MIMIR_TOKEN":"'$(echo -n "your-mimir-token" | base64 -w0)'"}}'

echo ""
echo "Next steps:"
echo "1. If Loki requires authentication, update the secret with your token:"
echo "   kubectl set env secret/alloy-remote-credentials LOKI_TOKEN='your-token' -n $NAMESPACE"
echo ""
echo "2. If Mimir requires authentication, update the secret with your token:"
echo "   kubectl set env secret/alloy-remote-credentials MIMIR_TOKEN='your-token' -n $NAMESPACE"
echo ""
echo "3. Deploy Alloy, Loki, and Grafana with:"
echo "   helm repo add grafana https://grafana.github.io/helm-charts"
echo "   helm repo update"
echo ""
echo "4. Install/upgrade Loki:"
echo "   helm upgrade --install loki grafana/loki -n $NAMESPACE -f loki/custom-values.yaml"
echo ""
echo "5. Install/upgrade Alloy:"
echo "   helm upgrade --install alloy grafana/alloy -n $NAMESPACE -f alloy/custom-values.yaml"
echo ""
echo "6. Install/upgrade Grafana:"
echo "   helm upgrade --install grafana grafana/grafana -n $NAMESPACE -f grafana/grafana-custom-values.yaml"
echo ""
echo "7. Access Grafana:"
echo "   kubectl port-forward -n $NAMESPACE svc/grafana 3000:80"
echo "   Open http://localhost:3000 and login with admin/helldiverslab123!"
echo ""
echo "8. In Grafana, verify the Loki datasource is configured (should be auto-added from values.yaml)"
echo ""
