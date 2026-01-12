#!/bin/bash
# Script de déploiement des services
# À exécuter depuis le répertoire du projet

set -e

echo "=========================================="
echo "Déploiement des services"
echo "=========================================="

# Fonction pour détecter la commande docker compose
detect_docker_compose() {
    if docker compose version &>/dev/null; then
        echo "docker compose"
    elif command -v docker-compose &>/dev/null && docker-compose version &>/dev/null; then
        echo "docker-compose"
    else
        echo ""
    fi
}

# Fonction pour installer Docker
install_docker() {
    echo "Installation de Docker..."
    
    # Vérifier les privilèges
    if [ "$EUID" -ne 0 ]; then
        echo "ERREUR: L'installation de Docker nécessite les privilèges root."
        echo "Exécutez: sudo $0"
        exit 1
    fi
    
    # Mettre à jour la liste des paquets
    apt-get update
    
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
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    # Démarrer Docker
    systemctl enable docker
    systemctl start docker
    
    # Ajouter l'utilisateur au groupe docker (si pas root)
    if [ -n "$SUDO_USER" ]; then
        usermod -aG docker "$SUDO_USER"
        echo "L'utilisateur $SUDO_USER a été ajouté au groupe docker."
        echo "Vous devrez peut-être vous déconnecter/reconnecter pour que cela prenne effet."
    fi
    
    echo "Docker installé avec succès!"
}

# Fonction pour installer Docker Compose
install_docker_compose() {
    echo "Installation de Docker Compose..."
    
    # Vérifier les privilèges
    if [ "$EUID" -ne 0 ]; then
        echo "ERREUR: L'installation de Docker Compose nécessite les privilèges root."
        echo "Exécutez: sudo $0"
        exit 1
    fi
    
    apt-get update
    apt-get install -y docker-compose-plugin
    
    echo "Docker Compose installé avec succès!"
}

# Vérifier que .env existe
if [ ! -f .env ]; then
    echo "ERREUR: Le fichier .env n'existe pas!"
    echo "Copiez .env.example vers .env et configurez-le."
    exit 1
fi

# Charger les variables d'environnement
set -a
source .env
set +a

echo "Étape 1: Vérification des prérequis..."

# Vérifier Docker
if ! command -v docker &>/dev/null; then
    echo "Docker n'est pas installé."
    if [ "$EUID" -eq 0 ]; then
        install_docker
    else
        echo "ERREUR: Docker n'est pas installé et ce script n'est pas exécuté en root."
        echo "Exécutez d'abord: sudo ./scripts/setup.sh"
        echo "Ou installez Docker manuellement, puis relancez ce script."
        exit 1
    fi
else
    echo "✓ Docker est installé ($(docker --version))"
fi

# Détecter la commande docker compose
DOCKER_COMPOSE_CMD=$(detect_docker_compose)

if [ -z "$DOCKER_COMPOSE_CMD" ]; then
    echo "Docker Compose n'est pas disponible."
    if [ "$EUID" -eq 0 ]; then
        install_docker_compose
        DOCKER_COMPOSE_CMD=$(detect_docker_compose)
    else
        echo "ERREUR: Docker Compose n'est pas installé et ce script n'est pas exécuté en root."
        echo "Exécutez d'abord: sudo ./scripts/setup.sh"
        echo "Ou installez Docker Compose manuellement, puis relancez ce script."
        exit 1
    fi
fi

if [ -z "$DOCKER_COMPOSE_CMD" ]; then
    echo "ERREUR: Impossible d'installer ou de détecter Docker Compose."
    exit 1
fi

echo "✓ Docker Compose est disponible (commande: $DOCKER_COMPOSE_CMD)"

# Vérifier que Docker fonctionne
if ! docker info &>/dev/null; then
    echo "ERREUR: Docker n'est pas démarré ou vous n'avez pas les permissions."
    if [ "$EUID" -ne 0 ]; then
        echo "Essayez: sudo $0"
        echo "Ou ajoutez votre utilisateur au groupe docker: sudo usermod -aG docker $USER"
    fi
    exit 1
fi

echo "Étape 2: Construction des images Docker..."
$DOCKER_COMPOSE_CMD build

echo "Étape 3: Arrêt des services existants..."
$DOCKER_COMPOSE_CMD down

echo "Étape 4: Démarrage des services..."
$DOCKER_COMPOSE_CMD up -d

echo "Étape 5: Vérification de l'état des services..."
sleep 5
$DOCKER_COMPOSE_CMD ps

echo "Étape 6: Affichage des logs..."
echo "Logs CrewAI:"
$DOCKER_COMPOSE_CMD logs --tail=20 crewai
echo ""
echo "Logs n8n:"
$DOCKER_COMPOSE_CMD logs --tail=20 n8n
echo ""
echo "Logs Cloudflared:"
$DOCKER_COMPOSE_CMD logs --tail=20 cloudflared

echo "=========================================="
echo "Déploiement terminé!"
echo "=========================================="
echo ""
echo "Services disponibles:"
echo "- CrewAI: https://crewai.1bonobo1.com"
echo "- n8n: https://n8n.1bonobo1.com"
echo ""
echo "Pour voir les logs en temps réel: $DOCKER_COMPOSE_CMD logs -f"
