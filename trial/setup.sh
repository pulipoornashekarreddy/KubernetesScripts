#!/bin/bash
# Kubernetes Setup Script (Master Node)
# Run as: sudo bash setup.sh

# 1️⃣ Disable swap
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab

# 2️⃣ Update packages
sudo apt-get update -y

# 3️⃣ Install dependencies
sudo apt-get install -y apt-transport-https ca-certificates curl gpg

# 4️⃣ Add Kubernetes signing key and repository
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key \
  | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] \
https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /" \
  | sudo tee /etc/apt/sources.list.d/kubernetes.list

# 5️⃣ Update repo and install Kubernetes components
sudo apt-get update -y
sudo apt-get install -y kubelet kubeadm kubectl containerd

# 6️⃣ Prevent auto-updates
sudo apt-mark hold kubelet kubeadm kubectl containerd

# 7️⃣ Enable containerd and kubelet
sudo systemctl enable containerd
sudo systemctl start containerd
sudo systemctl enable kubelet
sudo systemctl start kubelet

# 8️⃣ Verify installation
echo "✅ Kubernetes components installed:"
kubeadm version
kubectl version --client
kubelet --version

# 9️⃣ Initialize the Kubernetes master node (only on master)
echo "🚀 Initializing Kubernetes master node..."
sudo kubeadm init --pod-network-cidr=10.244.0.0/16

# 10️⃣ Setup kubectl access for the ubuntu user
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

echo "✅ Master node initialized successfully!"
echo "Next step: Apply Flannel network plugin using:"
echo "kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml"
