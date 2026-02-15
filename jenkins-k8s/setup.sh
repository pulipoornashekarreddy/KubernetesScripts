#!/bin/bash

set -e

echo "========================================="
echo " Jenkins on Kubernetes - Automated Setup "
echo "========================================="

# 1. Basic checks
echo "[1/8] Checking kubectl access..."
kubectl version --client >/dev/null 2>&1 || {
  echo "❌ kubectl not found"
  exit 1
}

kubectl cluster-info >/dev/null 2>&1 || {
  echo "❌ Cannot access Kubernetes cluster"
  exit 1
}

echo "✅ Kubernetes access OK"

# 2. Prepare hostPath directory
echo "[2/8] Preparing Jenkins data directory..."

sudo mkdir -p /data/jenkins
sudo chown -R 1000:1000 /data/jenkins
sudo chmod -R 775 /data/jenkins

echo "✅ /data/jenkins ready"

# 3. Create namespace
echo "[3/8] Creating namespace..."
kubectl apply -f 01-namespace.yaml

# 4. Apply Persistent Volume
echo "[4/8] Applying Persistent Volume..."
kubectl apply -f 02-pv.yaml

# 5. Apply Persistent Volume Claim
echo "[5/8] Applying Persistent Volume Claim..."
kubectl apply -f 03-pvc.yaml

# 6. Deploy Jenkins (Java 21)
echo "[6/8] Deploying Jenkins (Java 21)..."
kubectl apply -f 04-deployment.yaml

# 7. Expose Jenkins
echo "[7/8] Creating Service..."
kubectl apply -f 05-service.yaml

# 8. Wait for Jenkins pod
echo "[8/8] Waiting for Jenkins pod to be READY..."

kubectl wait --namespace jenkins \
  --for=condition=ready pod \
  --selector=app=jenkins \
  --timeout=300s

echo ""
echo "========================================="
echo " ✅ Jenkins is UP and RUNNING "
echo "========================================="


NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
NODE_PORT=$(kubectl get svc jenkins -n jenkins -o jsonpath='{.spec.ports[0].nodePort}')

echo ""
echo "🌐 Access Jenkins:"
echo "👉 http://${NODE_IP}:${NODE_PORT}"

echo ""
echo "🔐 Initial Admin Password:"
kubectl exec -n jenkins deploy/jenkins -- \
  cat /var/jenkins_home/secrets/initialAdminPassword

echo ""
echo "========================================="
echo " Done. Happy CI/CD 🚀 "
echo "========================================="