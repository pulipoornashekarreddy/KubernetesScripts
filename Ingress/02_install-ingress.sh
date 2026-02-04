#!/bin/bash

echo "=============================="
echo " STEP 1 — Install Ingress-Nginx"
echo "=============================="

kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml

echo "Waiting for ingress-nginx-controller to be ready..."
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=180s

kubectl patch svc ingress-nginx-controller -n ingress-nginx -p '{"spec": {"type": "NodePort"}}'

echo "Ingress Controller Installed."


echo "=============================="
echo " STEP 2 — Get NodePort Values"
echo "=============================="

kubectl get svc -n ingress-nginx ingress-nginx-controller

NODEPORT_HTTP=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o=jsonpath='{.spec.ports[?(@.port==80)].nodePort}')
NODEPORT_HTTPS=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o=jsonpath='{.spec.ports[?(@.port==443)].nodePort}')

echo "HTTP will be available on NodePort:  $NODEPORT_HTTP"
echo "HTTPS will be available on NodePort: $NODEPORT_HTTPS"


# HTTP will be available on NodePort:  30545
# HTTPS will be available on NodePort: 32370