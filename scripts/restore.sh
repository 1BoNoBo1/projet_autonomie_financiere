#!/bin/bash
# Script de restauration complète
# À exécuter sur le nouveau serveur après transfert de la sauvegarde

set -e

echo "=========================================="
echo "Restauration de l'infrastructure"
echo "=========================================="

# Vérifier que le script est exécuté avec sudo
if [ "$EUID" -ne 0 ]; then 
    echo "ERREUR: Ce script doit être exécuté avec sudo"
    echo "Usage: sudo ./restore.sh <fichier_sauvegarde.tar.gz>"
    exit 1
fi

# Détecter l'utilisateur (ubuntu pour OVH)
if [ -n "$SUDO_USER" ]; then
    ACTUAL_USER="$SUDO_USER"
else
    ACTUAL_USER="ubuntu"
fi

# Demander le chemin de la sauvegarde
if [ -z "$1" ]; then
    echo "Usage: $0 <chemin_vers_sauvegarde.tar.gz>"
    echo "Exemple: $0 ~/backup_complete_20240112.tar.gz"
    exit 1
fi

BACKUP_FILE="$1"
RESTORE_DIR="/tmp/restore_$(date +%Y%m%d_%H%M%S)"
PROJECT_DIR="/opt/projet_autonomie_financiere"

echo "Fichier de sauvegarde: $BACKUP_FILE"
echo "Répertoire de restauration: $RESTORE_DIR"
echo "Répertoire du projet: $PROJECT_DIR"

# Vérifier que le fichier existe
if [ ! -f "$BACKUP_FILE" ]; then
    echo "ERREUR: Le fichier de sauvegarde n'existe pas: $BACKUP_FILE"
    exit 1
fi

# Créer le répertoire de restauration
mkdir -p "$RESTORE_DIR"
cd "$RESTORE_DIR"

echo ""
echo "Étape 1: Extraction de la sauvegarde..."
tar xzf "$BACKUP_FILE" || {
    echo "ERREUR: Impossible d'extraire la sauvegarde"
    exit 1
}

# Trouver le dossier de sauvegarde
BACKUP_SOURCE=$(find . -type d -name "backup_replication_*" | head -1)
if [ -z "$BACKUP_SOURCE" ]; then
    echo "ERREUR: Structure de sauvegarde non trouvée"
    exit 1
fi

echo "Source de restauration trouvée: $BACKUP_SOURCE"

echo ""
echo "Étape 2: Vérification de la structure..."
if [ ! -d "$BACKUP_SOURCE/projet_autonomie_financiere" ]; then
    echo "ERREUR: Structure du projet non trouvée dans la sauvegarde"
    exit 1
fi

echo ""
echo "Étape 3: Arrêt des services existants (si présents)..."
if [ -d "$PROJECT_DIR" ] && [ -f "$PROJECT_DIR/docker-compose.yml" ]; then
    cd "$PROJECT_DIR"
    if command -v docker &>/dev/null; then
        # Détecter la commande docker compose
        if docker compose version &>/dev/null; then
            DOCKER_COMPOSE_CMD="docker compose"
        elif command -v docker-compose &>/dev/null; then
            DOCKER_COMPOSE_CMD="docker-compose"
        else
            DOCKER_COMPOSE_CMD=""
        fi
        
        if [ -n "$DOCKER_COMPOSE_CMD" ]; then
            echo "Arrêt des services..."
            $DOCKER_COMPOSE_CMD down 2>/dev/null || true
        fi
    fi
fi

echo ""
echo "Étape 4: Restauration des fichiers du projet..."
# Créer le répertoire du projet s'il n'existe pas
mkdir -p "$PROJECT_DIR"

# Restaurer les fichiers (sauf .env qui sera restauré séparément)
rsync -av --exclude='.env' \
    "$RESTORE_DIR/$BACKUP_SOURCE/projet_autonomie_financiere/" \
    "$PROJECT_DIR/"

echo ""
echo "Étape 5: Restauration du fichier .env..."
if [ -f "$RESTORE_DIR/$BACKUP_SOURCE/.env" ]; then
    cp "$RESTORE_DIR/$BACKUP_SOURCE/.env" "$PROJECT_DIR/.env"
    echo "Fichier .env restauré"
    echo "IMPORTANT: Vérifiez et mettez à jour le fichier .env si nécessaire"
    echo "  vim $PROJECT_DIR/.env"
else
    echo "ATTENTION: Fichier .env non trouvé dans la sauvegarde"
    echo "Créez-le à partir de .env.example"
fi

echo ""
echo "Étape 6: Restauration de la configuration Cloudflare..."
if [ -d "$RESTORE_DIR/$BACKUP_SOURCE/cloudflared_config" ]; then
    mkdir -p ~/.cloudflared
    cp -r "$RESTORE_DIR/$BACKUP_SOURCE/cloudflared_config/"* ~/.cloudflared/ 2>/dev/null || true
    echo "Configuration Cloudflare restaurée"
else
    echo "ATTENTION: Configuration Cloudflare non trouvée"
    echo "Vous devrez la reconfigurer manuellement"
fi

echo ""
echo "Étape 7: Restauration des volumes Docker..."
if [ -f "$RESTORE_DIR/$BACKUP_SOURCE/n8n_data_backup.tar.gz" ]; then
    echo "Restauration des données n8n..."
    docker volume create n8n_data 2>/dev/null || true
    
    docker run --rm \
        -v n8n_data:/data \
        -v "$RESTORE_DIR/$BACKUP_SOURCE":/backup \
        alpine sh -c "cd /data && tar xzf /backup/n8n_data_backup.tar.gz" 2>/dev/null || {
        echo "ATTENTION: Erreur lors de la restauration des données n8n"
        echo "Les données seront recréées au premier démarrage"
    }
    echo "Données n8n restaurées"
else
    echo "ATTENTION: Sauvegarde des données n8n non trouvée"
fi

echo ""
echo "Étape 8: Configuration des permissions..."
chown -R $ACTUAL_USER:$ACTUAL_USER "$PROJECT_DIR" 2>/dev/null || true
chmod +x "$PROJECT_DIR/scripts/"*.sh 2>/dev/null || true
echo "Permissions configurées pour l'utilisateur: $ACTUAL_USER"

echo ""
echo "=========================================="
echo "Restauration terminée!"
echo "=========================================="
echo ""
echo "Prochaines étapes:"
echo "1. Vérifier et mettre à jour le fichier .env:"
echo "   vim $PROJECT_DIR/.env"
echo ""
echo "2. Configurer Cloudflare Tunnel si nécessaire:"
echo "   cloudflared tunnel create autonomie-tunnel"
echo ""
echo "3. Tester l'installation:"
echo "   cd $PROJECT_DIR"
echo "   ./scripts/test_installation.sh"
echo ""
echo "4. Déployer les services:"
echo "   ./scripts/deploy.sh"
echo ""
echo "5. Tester l'API:"
echo "   ./scripts/test_api.sh"
echo ""

# Nettoyer
echo "Nettoyage des fichiers temporaires..."
rm -rf "$RESTORE_DIR"

echo "Restauration complète terminée!"
