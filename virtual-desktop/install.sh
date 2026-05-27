#!/bin/bash

set -e

echo "🚀 Starting Ubuntu Remote Dev Environment Setup..."

# -------------------------------

# 1. Update system

# -------------------------------

echo "📦 Updating packages..."
sudo apt update && sudo apt upgrade -y

# -------------------------------

# 2. Install XFCE (Lightweight GUI)

# -------------------------------

echo "🖥️ Installing XFCE Desktop..."
sudo apt install -y xfce4 xfce4-goodies


# -------------------------------

# 3. Install xRDP

# -------------------------------

echo "🔌 Installing xRDP..."
sudo apt install -y xrdp
sudo systemctl enable xrdp
sudo systemctl start xrdp

# Set XFCE as default session

echo "startxfce4" > ~/.xsession

# Fix permissions

sudo adduser xrdp ssl-cert

sudo systemctl restart xrdp

# -------------------------------

# 4. Open firewall port

# -------------------------------

echo "🔥 Configuring firewall..."
sudo ufw allow 3389 || true
sudo ufw allow 22 
sudo ufw reload
sudo ufw --force enable || true

# -------------------------------

# 5. Install basic dev tools

# -------------------------------

echo "💻 Installing development tools..."

# Git

sudo apt install -y git

# Node.js (v20)

curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

# -------------------------------

# 6. Create intern user

# -------------------------------

read -p "👤 Enter username for intern: " USERNAME

sudo adduser --gecos "" $USERNAME
sudo usermod -aG sudo $USERNAME
echo "✅ User '$USERNAME' created and added to sudo group."

# Set XFCE for new user

sudo -u $USERNAME bash -c 'echo "startxfce4" > ~/.xsession'


# -------------------------------

# 8. Install Firefox

# -------------------------------

echo "🌐 Installing Firefox..."
sudo apt install -y firefox
# echo "Set default browser properly"
# xdg-settings set default-web-browser firefox.desktop


# -------------------------------

# 9. Install VS Code

# -------------------------------

echo "🖥️ Installing Visual Studio Code..."
sudo apt install -y wget gpg
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
sudo install -D -o root -g root -m 644 packages.microsoft.gpg /usr/share/keyrings/packages.microsoft.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list
sudo apt update
sudo apt install -y code

# -------------------------------

# 10. Generate SSH key for CodeCommit access

# -------------------------------

ssh-keygen -t rsa -b 2048 -C "codecommit-access"
echo "✅ SSH key generated for CodeCommit access. Remember to add the public key to AWS IAM."

# ------------------------------- 

# Setup config manually for codecommit access
# nano ~/.ssh/config
# Host git-codecommit.*.amazonaws.com
#   User <SSH_KEY_ID_FROM_AWS>
#   IdentityFile ~/.ssh/id_rsa


# To test
# ssh git-codecommit.ap-south-1.amazonaws.com
# -------------------------------

# 11. Show final info

# -------------------------------

IP=$(curl -s ifconfig.me || hostname -I | awk '{print $1}')

echo ""
echo "✅ Setup Complete!"
echo "--------------------------------------"
echo "🌐 Server IP: $IP"
echo "👤 Username: $USERNAME"
echo "🔑 Password: (the one you just set)"
echo "🖥️ Use RDP (Remote Desktop) to connect"
echo "📌 Port: 3389"
echo "--------------------------------------"

echo "🎯 Recommended:"
echo "Use SSH + VS Code Remote for development"
echo "Use RDP only for UI tasks"

echo "🚀 Done!"

######
# To give access to terminal
######
sudo apt install -y openssh-server

# Enable & start SSH service
sudo systemctl enable ssh
sudo systemctl start ssh

echo "⚙️ Configuring SSH..."

# Create config override directory
sudo mkdir -p /etc/ssh/sshd_config.d

# Remove conflicting PasswordAuthentication entries from cloud configs
sudo sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config.d/*.conf || true
sudo sed -i 's/^KbdInteractiveAuthentication no/KbdInteractiveAuthentication yes/' /etc/ssh/sshd_config || true

# Update main sshd config safely
sudo sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
sudo sed -i 's/^#\?PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config
sudo sed -i 's/^#\?KbdInteractiveAuthentication.*/KbdInteractiveAuthentication yes/' /etc/ssh/sshd_config
sudo sed -i 's/^#\?UsePAM.*/UsePAM yes/' /etc/ssh/sshd_config
sudo sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config

# Create high-priority override config (99 loads last)
cat <<EOF | sudo tee /etc/ssh/sshd_config.d/99-password-auth.conf > /dev/null
PasswordAuthentication yes
PubkeyAuthentication yes
KbdInteractiveAuthentication yes
UsePAM yes
PermitRootLogin no
EOF

# Force final settings at end of main config (last value wins)
sudo bash -c 'cat >> /etc/ssh/sshd_config <<EOF

# --- Intern SSH Password Login ---
PasswordAuthentication yes
PubkeyAuthentication yes
KbdInteractiveAuthentication yes
UsePAM yes
PermitRootLogin no
EOF'

# Validate SSH config
echo "🧪 Validating SSH config..."
sudo sshd -t

# Restart SSH
echo "🔄 Restarting SSH..."
sudo systemctl restart ssh

# Open firewall port
echo "🔥 Opening SSH port..."
sudo ufw allow 22/tcp || true

# Verify effective config
echo "✅ Effective SSH Config:"
sudo sshd -T | grep -E 'passwordauthentication|pubkeyauthentication|kbdinteractiveauthentication|usepam'

echo "✅ SSH configured successfully!"

# -------------------------------
# Intern user setup
# -------------------------------

if [ -n "$USERNAME" ]; then
    echo "👤 Configuring user: $USERNAME"

    # Prevent password expiry
    sudo chage -M 99999 "$USERNAME"

    # Ensure ownership
    sudo chown -R "$USERNAME:$USERNAME" "/home/$USERNAME"

    # Ensure bash shell
    sudo chsh -s /bin/bash "$USERNAME"

    echo "✅ User '$USERNAME' configured."
fi