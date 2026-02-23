sudo apt update && sudo apt upgrade -y

# 1️⃣ Disable swap
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab

sudo modprobe overlay
sudo modprobe br_netfilter

cat <<EOF | sudo tee /etc/sysctl.d/kubernetes.conf >/dev/null
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

sudo sysctl --system

sudo apt install -y docker.io
# reboot if required
sudo systemctl enable docker
sudo systemctl start docker

sudo apt install -y containerd
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
sudo systemctl restart containerd
sudo systemctl enable containerd

sudo apt install -y apt-transport-https ca-certificates curl gpg
sudo mkdir -p /etc/apt/keyrings

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.34/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/k8s.gpg
echo "deb [signed-by=/etc/apt/keyrings/k8s.gpg] https://pkgs.k8s.io/core:/stable:/v1.34/deb/ /" | sudo tee /etc/apt/sources.list.d/k8s.list

sudo apt update

sudo apt install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
sudo kubeadm init --pod-network-cidr=10.0.0.0/16

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

kubectl get nodes

curl -L --remote-name https://github.com/cilium/cilium-cli/releases/latest/download/cilium-linux-amd64.tar.gz
sudo tar xzvf cilium-linux-amd64.tar.gz -C /usr/local/bin
cilium install

cilium status
cilium version

# If on AWS please enable following ports on security group
# 6443 - TCP - Kubernetes API Server (REQUIRED for join)
# 2379-2380 TCP etcd (if stacked etcd)
# 10250 - TCP - kubelet
# 10257 - TCP - controller-manager
# 10259 - TCP - Scheduler
# 30000-32767 - TCP - NodePort Services
# 4240 - TCP - Cilium health checking
# 8472 - UDP - VXLAN (if using VXLAN mode)
# 6081 - UDP - Geneve (if using Geneve mode)

# Which Encapsulation Are You Using
# kubectl -n kube-system get cm cilium-config -o yaml | grep tunnel
# tunnel: vxlan
# or
# tunnel: geneve

# Taint: Remove Control Plain Taint instead of 172-31-30-212 use internal ip of master node, so that you can schedule on the master node also
# kubectl taint nodes ip-172-31-30-212 node-role.kubernetes.io/control-plane:NoSchedule-

# Add control-plane taint
# kubectl taint nodes <node-name> node-role.kubernetes.io/control-plane=:NoSchedule

# Remove control-plane taint
# kubectl taint nodes <node-name> node-role.kubernetes.io/control-plane:NoSchedule-

# Add custom taint
# kubectl taint nodes <node-name> key=value:NoSchedule

# Remove custom taint
# kubectl taint nodes <node-name> key=value:NoSchedule-
