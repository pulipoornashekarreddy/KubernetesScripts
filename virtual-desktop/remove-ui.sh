#!/bin/bash

set -e

echo "🚀 Removing GUI & Optimizing Server..."

# -------------------------------
# 1. Stop GUI Services
# -------------------------------

echo "🛑 Stopping xRDP..."

sudo systemctl stop xrdp || true
sudo systemctl disable xrdp || true

sudo systemctl stop lightdm || true
sudo systemctl disable lightdm || true

sudo systemctl stop gdm || true
sudo systemctl disable gdm || true

# -------------------------------
# 2. Remove xRDP + XFCE
# -------------------------------

echo "🗑 Removing XFCE and xRDP..."

sudo apt purge -y \
xrdp \
xfce4 \
xfce4-goodies \
lightdm \
gdm3 \
ubuntu-desktop \
xubuntu-desktop \
tasksel \
tasksel-data

# Remove orphan packages
sudo apt autoremove -y
sudo apt autoclean

# -------------------------------
# 3. Remove leftover configs
# -------------------------------

echo "🧹 Cleaning old configs..."

rm -f ~/.xsession

sudo find /home -name ".xsession" -delete || true
sudo rm -rf /usr/share/xsessions/* || true
sudo rm -rf /etc/xrdp || true

# -------------------------------
# 4. Ensure SSH stays enabled
# -------------------------------

echo "🔐 Verifying SSH..."

sudo apt install -y openssh-server

sudo systemctl enable ssh
sudo systemctl restart ssh

sudo ufw allow 22/tcp || true

# -------------------------------
# 5. Add 4GB Swap (if missing)
# -------------------------------

echo "💾 Checking swap..."

if [ "$(swapon --show | wc -l)" -eq 0 ]; then
    echo "Creating 4GB swap..."

    sudo fallocate -l 4G /swapfile || sudo dd if=/dev/zero of=/swapfile bs=1M count=4096
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile

    grep -q "/swapfile" /etc/fstab || \
    echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

    echo "✅ Swap created."
else
    echo "✅ Swap already exists."
fi

# -------------------------------
# 6. Install Monitoring Tools
# -------------------------------

echo "📊 Installing monitoring tools..."

sudo apt install -y \
htop \
iotop \
sysstat \
ncdu \
net-tools

# -------------------------------
# 7. Reduce Swappiness
# -------------------------------

echo "⚙️ Optimizing memory..."

echo "vm.swappiness=10" | sudo tee /etc/sysctl.d/99-swappiness.conf
sudo sysctl --system

# -------------------------------
# 8. Show Status
# -------------------------------

echo ""
echo "✅ Cleanup Complete!"
echo "--------------------------------"

echo "RAM Usage:"
free -h

echo ""
echo "CPU:"
nproc

echo ""
echo "Disk:"
df -h /

echo ""
echo "Top Memory Consumers:"
ps aux --sort=-%mem | head -10

echo "--------------------------------"

echo "⚠️ Reboot Recommended"
echo "Run:"
echo "sudo reboot"