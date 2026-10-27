#!/bin/bash
# dated : 02-10-2026
set -e

echo "🔧 Installing HELM if not present..."

if ! command -v helm >/dev/null 2>&1; then
  curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

echo "Helm version:"
helm version --short

echo "🚀 Installing Kubernetes Monitoring Stack..."

# Add Helm repositories
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts --force-update
helm repo add grafana https://grafana.github.io/helm-charts --force-update
helm repo update

# Create namespace
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -

echo "📦 Installing kube-prometheus-stack..."

helm upgrade --install kube-prom-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false \
  --timeout 15m \
  --wait

echo "✅ Prometheus + Alertmanager + Grafana installed successfully"

echo "⏳ Waiting for Grafana service..."

for i in {1..60}; do
  if kubectl get svc kube-prom-stack-grafana -n monitoring >/dev/null 2>&1; then
    echo "✅ Grafana service found"
    break
  fi

  echo "Waiting for Grafana service... ($i/60)"
  sleep 5
done

if ! kubectl get svc kube-prom-stack-grafana -n monitoring >/dev/null 2>&1; then
  echo "❌ Grafana service was not created"
  kubectl get all -n monitoring
  exit 1
fi

echo "🌐 Exposing Grafana on NodePort 32000..."

kubectl patch svc kube-prom-stack-grafana -n monitoring --type=merge -p '{
  "spec": {
    "type": "NodePort",
    "ports": [
      {
        "name": "http-web",
        "port": 80,
        "targetPort": 3000,
        "nodePort": 32000
      }
    ]
  }
}'

kubectl patch deployment kube-prom-stack-grafana -n monitoring --type=strategic -p '{
  "spec": {
    "template": {
      "spec": {
        "nodeSelector": {
          "node-role.kubernetes.io/control-plane": ""
        }
      }
    }
  }
}'

echo "⏳ Waiting for Grafana deployment..."

kubectl rollout status deployment/kube-prom-stack-grafana \
  -n monitoring \
  --timeout=5m

echo ""
echo "========================================="
echo "✅ Kubernetes Monitoring Stack Ready"
echo "========================================="
echo ""
echo "Grafana NodePort: 32000"
echo ""
echo "Check services:"
kubectl get svc -n monitoring

echo ""
echo "Check pods:"
kubectl get pods -n monitoring