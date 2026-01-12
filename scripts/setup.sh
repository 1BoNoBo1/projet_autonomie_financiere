#!/bin/bash
# Script d'installation initiale de l'infrastructure
# À exécuter sur le VPS OVH avec l'utilisateur ubuntu
# Usage: sudo ./setup.sh

set -e

echo "=========================================="
echo "Installation de l'infrastructure"
echo "Projet: Autonomie Financière"
echo "Serveur OVH - Utilisateur: ubuntu"
echo "=========================================="

# Vérifier que le script est exécuté avec sudo
if [ "$EUID" -ne 0 ]; then 
    echo "ERREUR: Ce script doit être exécuté avec sudo"
    echo "Usage: sudo ./setup.sh"
    exit 1
fi

# Variables
PROJECT_DIR="/opt/projet_autonomie_financiere"
# Créer un utilisateur dédié pour le projet (meilleure sécurité)
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

# Ajouter l'utilisateur ubuntu au groupe docker
usermod -aG docker "$USER_NAME"
echo "Utilisateur $USER_NAME ajouté au groupe docker"
echo "NOTE: Vous devrez peut-être vous déconnecter/reconnecter pour que les changements prennent effet"

echo "Étape 4: Installation de Cloudflared..."
# Télécharger et installer cloudflared
wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb -O /tmp/cloudflared.deb
dpkg -i /tmp/cloudflared.deb || apt-get install -f -y
rm /tmp/cloudflared.deb

echo "Étape 5: Création de l'utilisateur dédié pour le projet..."
# Créer un utilisateur dédié (meilleure pratique de sécurité)
if ! id "$USER_NAME" &>/dev/null; then
    echo "Création de l'utilisateur $USER_NAME..."
    useradd -m -s /bin/bash $USER_NAME
    
    # Créer un répertoire .ssh pour l'utilisateur
    mkdir -p /home/$USER_NAME/.ssh
    chmod 700 /home/$USER_NAME/.ssh
    chown $USER_NAME:$USER_NAME /home/$USER_NAME/.ssh
    
    echo "Utilisateur $USER_NAME créé avec succès"
    echo "IMPORTANT: Configurez les clés SSH pour cet utilisateur:"
    echo "  - Copiez vos clés publiques dans /home/$USER_NAME/.ssh/authorized_keys"
    echo "  - chmod 600 /home/$USER_NAME/.ssh/authorized_keys"
    echo "  - chown $USER_NAME:$USER_NAME /home/$USER_NAME/.ssh/authorized_keys"
else
    echo "Utilisateur $USER_NAME existe déjà"
fi

# Ajouter l'utilisateur au groupe docker (sera fait après installation Docker)
echo "L'utilisateur $USER_NAME sera ajouté au groupe docker après l'installation"

echo "Étape 6: Configuration du répertoire du projet..."
mkdir -p $PROJECT_DIR
chown $USER_NAME:$USER_NAME $PROJECT_DIR
chmod 755 $PROJECT_DIR

echo "Étape 7: Configuration SSH..."
# Hardening SSH (sans désactiver root si déjà désactivé)
# Vérifier et configurer seulement si nécessaire

# Désactiver l'accès root direct (sécurisé)
if grep -q "^PermitRootLogin yes" /etc/ssh/sshd_config; then
    sed -i 's/^PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
    echo "Accès root SSH désactivé"
elif grep -q "^#PermitRootLogin yes" /etc/ssh/sshd_config; then
    sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
    echo "Accès root SSH désactivé"
else
    echo "Accès root SSH déjà configuré"
fi

# Désactiver l'authentification par mot de passe (utiliser uniquement les clés)
if grep -q "^PasswordAuthentication yes" /etc/ssh/sshd_config; then
    sed -i 's/^PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
    echo "Authentification par mot de passe désactivée"
elif grep -q "^#PasswordAuthentication yes" /etc/ssh/sshd_config; then
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
    echo "Authentification par mot de passe désactivée"
else
    echo "Authentification par mot de passe déjà configurée"
fi

# S'assurer que l'authentification par clé est activée
if ! grep -q "^PubkeyAuthentication yes" /etc/ssh/sshd_config && ! grep -q "^#PubkeyAuthentication yes" /etc/ssh/sshd_config; then
    echo "PubkeyAuthentication yes" >> /etc/ssh/sshd_config
    echo "Authentification par clé activée"
fi

# Redémarrer SSH seulement si des changements ont été faits
if systemctl is-active --quiet sshd; then
    systemctl reload sshd || systemctl restart sshd
    echo "Configuration SSH appliquée"
else
    echo "ATTENTION: Service SSH n'est pas actif"
fi

echo "Étape 8: Configuration du firewall..."
# Configuration UFW de base pour OVH
ufw --force reset 2>/dev/null || true

# Règles par défaut
ufw default deny incoming
ufw default allow outgoing

# Autoriser SSH (port 22) - CRITIQUE: faire avant d'activer
SSH_PORT=${SSH_PORT:-22}
ufw allow $SSH_PORT/tcp comment 'SSH'

# Autoriser HTTP et HTTPS pour Cloudflare Tunnel
ufw allow 80/tcp comment 'HTTP'
ufw allow 443/tcp comment 'HTTPS'

# Activer le firewall
ufw --force enable

echo "Firewall UFW configuré et activé"
echo "IMPORTANT: Assurez-vous que votre connexion SSH reste active!"

echo "Étape 9: Configuration de fail2ban..."
systemctl enable fail2ban
systemctl start fail2ban

echo "=========================================="
echo "Installation terminée!"
echo "=========================================="
echo ""
echo "Utilisateur créé: $USER_NAME"
echo "Répertoire du projet: $PROJECT_DIR"
echo ""
echo "IMPORTANT - Configuration SSH pour l'utilisateur $USER_NAME:"
echo "1. Copiez vos clés SSH publiques vers le serveur:"
echo "   ssh-copy-id -i ~/.ssh/id_rsa.pub $USER_NAME@$(hostname -I | awk '{print $1}')"
echo "   OU manuellement:"
echo "   sudo mkdir -p /home/$USER_NAME/.ssh"
echo "   sudo nano /home/$USER_NAME/.ssh/authorized_keys"
echo "   sudo chmod 600 /home/$USER_NAME/.ssh/authorized_keys"
echo "   sudo chown $USER_NAME:$USER_NAME /home/$USER_NAME/.ssh/authorized_keys"
echo ""
echo "2. Testez la connexion avec le nouvel utilisateur:"
echo "   ssh $USER_NAME@$(hostname -I | awk '{print $1}')"
echo ""
echo "3. Une fois connecté en tant que $USER_NAME:"
echo "   cd $PROJECT_DIR"
echo "   git clone https://github.com/1BoNoBo1/projet_autonomie_financiere.git ."
echo ""
echo "4. Configurer le fichier .env avec vos secrets"
echo "   cp .env.example .env"
echo "   vim .env"
echo ""
echo "5. Configurer Cloudflare Tunnel avec votre token"
echo "   cloudflared tunnel create autonomie-tunnel"
echo ""
echo "6. Tester l'installation"
echo "   ./scripts/test_installation.sh"
echo ""
echo "7. Déployer les services"
echo "   ./scripts/deploy.sh"
echo ""
echo "Documentation: voir docs/deployment.md et docs/ovh_setup.md"
