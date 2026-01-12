#!/bin/bash
# Script d'installation initiale de l'infrastructure
# À exécuter sur le VPS OVH

set -e

echo "=========================================="
echo "Installation de l'infrastructure"
echo "Projet: Autonomie Financière"
echo "=========================================="

# Vérifier que le script est exécuté en root
if [ "$EUID" -ne 0 ]; then 
    echo "Veuillez exécuter ce script en tant que root (sudo ./setup.sh)"
    exit 1
fi

# Variables
PROJECT_DIR="/opt/autonomie-financiere"
USER_NAME="autonomie"

echo "Étape 1: Mise à jour du système..."
apt-get update
apt-get upgrade -y

echo "Étape 2: Installation des dépendances de base..."
apt-get install -y \
    curl \
    wget \
    git \
    vim \
    ufw \
    fail2ban \
    python3 \
    python3-pip \
    python3-venv \
    openssh-server \
    ca-certificates \
    gnupg \
    lsb-release

echo "Étape 3: Installation de Docker..."
# Vérifier si Docker est déjà installé
if ! command -v docker &>/dev/null; then
    # Installer les prérequis
    apt-get install -y \
        ca-certificates \
        curl \
        gnupg \
        lsb-release
    
    # Ajouter la clé GPG officielle de Docker
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    chmod a+r /etc/apt/keyrings/docker.asc
    
    # Ajouter le dépôt Docker
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | \
      tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Installer Docker
    apt-get update
    apt-get install -y \
        docker-ce \
        docker-ce-cli \
        containerd.io \
        docker-buildx-plugin \
        docker-compose-plugin
else
    echo "Docker est déjà installé, vérification de Docker Compose..."
    # Vérifier si Docker Compose V2 est installé
    if ! docker compose version &>/dev/null; then
        echo "Installation du plugin Docker Compose..."
        apt-get update
        apt-get install -y docker-compose-plugin
    fi
fi

# Configuration de Docker
systemctl enable docker
systemctl start docker

# Ajouter l'utilisateur au groupe docker
if [ -n "$SUDO_USER" ]; then
    usermod -aG docker "$SUDO_USER"
    echo "Utilisateur $SUDO_USER ajouté au groupe docker"
elif [ -n "$USER" ] && [ "$USER" != "root" ]; then
    usermod -aG docker "$USER"
    echo "Utilisateur $USER ajouté au groupe docker"
fi

echo "Étape 4: Installation de Cloudflared..."
# Télécharger et installer cloudflared
wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb -O /tmp/cloudflared.deb
dpkg -i /tmp/cloudflared.deb || apt-get install -f -y
rm /tmp/cloudflared.deb

echo "Étape 5: Création de l'utilisateur pour le projet..."
if ! id "$USER_NAME" &>/dev/null; then
    useradd -m -s /bin/bash $USER_NAME
    usermod -aG docker $USER_NAME
    echo "Utilisateur $USER_NAME créé"
else
    echo "Utilisateur $USER_NAME existe déjà"
fi

echo "Étape 6: Configuration du répertoire du projet..."
mkdir -p $PROJECT_DIR
chown $USER_NAME:$USER_NAME $PROJECT_DIR

echo "Étape 7: Configuration SSH..."
# Hardening SSH
sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config
systemctl restart sshd

echo "Étape 8: Configuration du firewall..."
chmod +x infrastructure/firewall/ufw-rules.sh
./infrastructure/firewall/ufw-rules.sh

echo "Étape 9: Configuration de fail2ban..."
systemctl enable fail2ban
systemctl start fail2ban

echo "=========================================="
echo "Installation terminée!"
echo "=========================================="
echo ""
echo "Prochaines étapes:"
echo "1. Copiez votre projet dans $PROJECT_DIR"
echo "2. Configurez le fichier .env avec vos secrets"
echo "3. Configurez Cloudflare Tunnel avec votre token"
echo "4. Démarrez les services avec: docker compose up -d"
echo "   (ou utilisez: ./scripts/deploy.sh)"
echo ""
echo "Documentation: voir docs/deployment.md"
