#!/bin/bash

echo "🔧 Installing HELM if not present..."
if ! command -v helm &> /dev/null; then
  curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

echo "🚀 Installing Kubernetes Monitoring Stack..."

# Add Helm repos
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Create namespace
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -

# Install Prometheus + Alertmanager + Node Exporter
helm install kube-prom-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false

echo "✅ Prometheus + Alertmanager Installed"

sleep 20

# Expose Grafana
kubectl patch svc kube-prom-stack-grafana -n monitoring -p '{
  "spec": {
    "type": "NodePort",
    "ports": [{
      "port": 80,
      "targetPort": 3000,
      "nodePort": 32000
    }]
  }
}'

echo "✅ Grafana is ready on NodePort 32000"

# if on AWS open the following ports
# 9100 -  for prometheus


# if adding disk space later, run below commands to attach volumes
# sudo growpart /dev/nvme0n1 1
# sudo resize2fs /dev/nvme0n1p1

# df -h // to verify the disk space
