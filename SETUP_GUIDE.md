# Loki + Alloy + Grafana Setup Guide

## Overview

This setup enables:
- **Loki**: Centralized log storage and querying
- **Alloy**: Log collection and forwarding from applications and Kubernetes pods
- **Grafana**: Visualization of logs with Loki as a datasource

## Architecture

```
Applications/Pods (via OTLP)
        ↓
    Alloy (OTLP receiver)
        ↓ (processes & batches)
    Loki (log storage)
        ↓ (read queries)
    Grafana (visualization)
```

## File Changes Made

### 1. **Loki** (`loki/custom-values.yaml`)
- ✓ Enabled `allow_structured_metadata: true` to accept OTLP logs
- ✓ Configured retention period: 720 hours (30 days)
- ✓ Set server port to 3100 (standard Loki port)
- ✓ Optimized limits_config for better ingestion performance

### 2. **Grafana** (`grafana/grafana-custom-values.yaml`)
- ✓ Added Loki datasource configuration (auto-provisioned)
- ✓ Configured endpoint: `http://loki.observability.svc.cluster.local:3100`
- ✓ Added Prometheus datasource (optional, for metrics)
- ✓ Configured ingress with TLS

### 3. **Alloy** (`alloy/custom-values.yaml`)
- ✓ Updated to use Alloy's native syntax (not legacy receiver/exporter style)
- ✓ Configured OTLP receiver on ports 4317 (gRPC) and 4318 (HTTP)
- ✓ Added Kubernetes pod discovery for pod-level logs
- ✓ Configured log export to Loki via OTLP/HTTP
- ✓ Configured metrics export to Mimir
- ✓ Configured traces export to logging exporter
- ✓ Added batch processing for efficiency

## Deployment Steps

### Step 1: Create the secrets namespace and secret

```bash
# Create the namespace
kubectl create namespace observability --dry-run=client -o yaml | kubectl apply -f -

# Create the alloy-remote-credentials secret (currently with empty tokens)
kubectl create secret generic alloy-remote-credentials \
  --from-literal=LOKI_TOKEN="" \
  --from-literal=MIMIR_TOKEN="" \
  -n observability \
  --dry-run=client -o yaml | kubectl apply -f -
```

Alternatively, use the provided script:
```bash
chmod +x ./alloy/setup-secrets.sh
./alloy/setup-secrets.sh observability
```

### Step 2: Add Grafana Helm repository

```bash
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
```

### Step 3: Deploy Loki

```bash
helm upgrade --install loki grafana/loki \
  -n observability \
  -f gitops-bootcamp/loki/custom-values.yaml
```

### Step 4: Deploy Alloy

```bash
helm upgrade --install alloy grafana/alloy \
  -n observability \
  -f gitops-bootcamp/alloy/custom-values.yaml
```

### Step 5: Deploy Grafana

```bash
helm upgrade --install grafana grafana/grafana \
  -n observability \
  -f gitops-bootcamp/grafana/grafana-custom-values.yaml
```

### Step 6: Verify the setup

```bash
# Check pod status
kubectl get pods -n observability

# Check Loki is running
kubectl logs -n observability -l app.kubernetes.io/name=loki

# Check Alloy is running
kubectl logs -n observability -l app.kubernetes.io/name=alloy

# Port-forward to Grafana
kubectl port-forward -n observability svc/grafana 3000:80

# Access Grafana at http://localhost:3000
# Login: admin / helldiverslab123!
```

## Sending Logs from Applications

Your applications can send logs to Alloy in two ways:

### Option 1: Direct OTLP (Recommended)

Configure your application to send logs via OTLP:

```
OTEL_EXPORTER_OTLP_ENDPOINT: http://alloy.observability.svc.cluster.local:4318
OTEL_EXPORTER_OTLP_PROTOCOL: http/protobuf
```

Python example:
```python
from opentelemetry import trace, logs
from opentelemetry.exporter.otlp.proto.http.log_exporter import OTLPLogExporter
from opentelemetry.sdk.logs import LoggerProvider
from opentelemetry.sdk.logs.export import BatchLogRecordProcessor

exporter = OTLPLogExporter(endpoint="http://alloy.observability.svc.cluster.local:4318")
logger_provider = LoggerProvider()
logger_provider.add_log_record_processor(BatchLogRecordProcessor(exporter))
```

### Option 2: Kubernetes stdout (Automatic via Alloy pod discovery)

Logs written to stdout by pods are discovered automatically by Alloy's Kubernetes discovery.

## Verifying the Setup

1. **Access Grafana**:
   ```bash
   kubectl port-forward -n observability svc/grafana 3000:80
   ```
   - Open http://localhost:3000
   - Login: `admin` / `helldiverslab123!`

2. **Check Loki Datasource**:
   - Click on the gear icon (Configuration)
   - Select "Data Sources"
   - You should see "Loki" listed with status "OK"

3. **Query Logs**:
   - Go to "Explore" (left sidebar)
   - Select "Loki" from the dropdown
   - Write a query like `{job="alloy-self"}` or `{namespace="observability"}`
   - Click "Run Query" to see logs

4. **Create a Log Panel**:
   - Create a new dashboard
   - Add a new panel
   - Set datasource to "Loki"
   - Write a log query: `{container="my-app"}`
   - Save the dashboard

## Troubleshooting

### Loki Pod not starting
```bash
kubectl logs -n observability -l app.kubernetes.io/name=loki
# Check storage class and PVC
kubectl get pvc -n observability
```

### Alloy not connecting to Loki
```bash
# Check Alloy logs
kubectl logs -n observability -l app.kubernetes.io/name=alloy

# Verify connectivity
kubectl exec -n observability alloy-pod-name -- curl -v http://loki.observability.svc.cluster.local:3100/ready
```

### No logs appearing in Loki
- Ensure applications are sending OTLP logs to Alloy
- Check Alloy OTLP receiver is listening: `kubectl port-forward -n observability svc/alloy 4318:4318`
- Verify logs are reaching Loki: `kubectl logs -n observability -l app.kubernetes.io/name=loki`

### Grafana can't connect to Loki datasource
- Check Grafana datasource configuration in the UI
- Verify Loki is accessible: `kubectl port-forward -n observability svc/loki 3100:3100`
- Test endpoint: `curl http://localhost:3100/ready`

## References

- [Loki Documentation](https://grafana.com/docs/loki/latest/)
- [Alloy Documentation](https://grafana.com/docs/alloy/latest/)
- [Grafana OTLP Integration](https://grafana.com/docs/grafana/latest/datasources/otel-metrics/)
- [Kubernetes Discovery in Alloy](https://grafana.com/docs/alloy/latest/reference/components/discovery/discovery_kubernetes/)
