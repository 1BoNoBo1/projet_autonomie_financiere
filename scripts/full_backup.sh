#!/bin/bash
# Script de sauvegarde complète pour réplication
# Crée une sauvegarde complète incluant tous les éléments nécessaires

set -e

echo "=========================================="
echo "Sauvegarde complète pour réplication"
echo "=========================================="

# Configuration
BACKUP_BASE_DIR="${BACKUP_DIR:-/opt/backups/autonomie-financiere}"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="backup_complete_$DATE"
BACKUP_DIR="$BACKUP_BASE_DIR/$BACKUP_NAME"
PROJECT_DIR="/opt/projet_autonomie_financiere"

# Vérifier que le répertoire du projet existe
if [ ! -d "$PROJECT_DIR" ]; then
    echo "ERREUR: Le répertoire du projet n'existe pas: $PROJECT_DIR"
    exit 1
fi

# Créer le répertoire de sauvegarde
mkdir -p "$BACKUP_DIR"
cd "$BACKUP_DIR"

echo "Répertoire de sauvegarde: $BACKUP_DIR"

echo ""
echo "Étape 1: Sauvegarde des fichiers du projet..."
mkdir -p projet_autonomie_financiere
rsync -av --exclude='.git' \
    --exclude='__pycache__' \
    --exclude='*.pyc' \
    --exclude='node_modules' \
    --exclude='.env' \
    "$PROJECT_DIR/" \
    "projet_autonomie_financiere/"

echo ""
echo "Étape 2: Sauvegarde du fichier .env (sans les secrets réels)..."
if [ -f "$PROJECT_DIR/.env" ]; then
    # Créer une copie avec masquage partiel des secrets
    cp "$PROJECT_DIR/.env" projet_autonomie_financiere/.env.backup
    echo "Fichier .env sauvegardé (vérifiez manuellement les secrets)"
else
    echo "ATTENTION: Fichier .env non trouvé"
fi

echo ""
echo "Étape 3: Sauvegarde de la configuration Cloudflare..."
if [ -d ~/.cloudflared ]; then
    cp -r ~/.cloudflared cloudflared_config 2>/dev/null || true
    echo "Configuration Cloudflare sauvegardée"
else
    echo "ATTENTION: Configuration Cloudflare non trouvée"
fi

echo ""
echo "Étape 4: Sauvegarde des volumes Docker..."
if command -v docker &>/dev/null; then
    # Sauvegarder n8n data
    if docker volume ls | grep -q n8n_data; then
        echo "Sauvegarde des données n8n..."
        docker run --rm \
            -v n8n_data:/data \
            -v $(pwd):/backup \
            alpine tar czf /backup/n8n_data_backup.tar.gz -C /data . 2>/dev/null || {
            echo "ATTENTION: Erreur lors de la sauvegarde des données n8n"
        }
    else
        echo "Volume n8n_data non trouvé (normal si pas encore créé)"
    fi
    
    # Sauvegarder crewai data si existe
    if docker volume ls | grep -q crewai_data; then
        echo "Sauvegarde des données CrewAI..."
        docker run --rm \
            -v crewai_data:/data \
            -v $(pwd):/backup \
            alpine tar czf /backup/crewai_data_backup.tar.gz -C /data . 2>/dev/null || {
            echo "ATTENTION: Erreur lors de la sauvegarde des données CrewAI"
        }
    fi
else
    echo "Docker n'est pas disponible, saut de la sauvegarde des volumes"
fi

echo ""
echo "Étape 5: Sauvegarde de la configuration système..."
# Sauvegarder la configuration SSH (authorized_keys)
if [ -f ~/.ssh/authorized_keys ]; then
    mkdir -p system_config
    cp ~/.ssh/authorized_keys system_config/authorized_keys 2>/dev/null || true
    echo "Configuration SSH sauvegardée"
fi

# Sauvegarder la configuration UFW si existe
if [ -f /etc/ufw/user.rules ]; then
    sudo cp /etc/ufw/user.rules system_config/ufw_rules 2>/dev/null || true
    echo "Configuration firewall sauvegardée"
fi

echo ""
echo "Étape 6: Création d'un fichier d'informations..."
cat > "$BACKUP_DIR/info.txt" << EOF
Sauvegarde créée le: $(date)
Serveur source: $(hostname)
IP serveur: $(hostname -I | awk '{print $1}')
Utilisateur: $(whoami)
Répertoire projet: $PROJECT_DIR

Éléments sauvegardés:
- Fichiers du projet (sans .git, __pycache__, etc.)
- Fichier .env (vérifiez les secrets)
- Configuration Cloudflare
- Volumes Docker (n8n_data, crewai_data)
- Configuration système (SSH, firewall)

IMPORTANT:
1. Vérifiez le fichier .env.backup et mettez à jour les secrets si nécessaire
2. Notez le Tunnel ID et Token Cloudflare avant migration
3. Vérifiez que tous les secrets sont documentés ailleurs
4. Testez la restauration sur un serveur de test avant migration production

Pour restaurer:
1. Transférer cette archive sur le nouveau serveur
2. Extraire: tar xzf backup_complete_*.tar.gz
3. Exécuter: ./scripts/restore.sh backup_complete_*.tar.gz
EOF

echo "Fichier d'informations créé"

echo ""
echo "Étape 7: Création de l'archive..."
cd "$BACKUP_BASE_DIR"
tar czf "${BACKUP_NAME}.tar.gz" "$BACKUP_NAME"

# Calculer la taille
SIZE=$(du -h "${BACKUP_NAME}.tar.gz" | cut -f1)
echo "Archive créée: ${BACKUP_NAME}.tar.gz ($SIZE)"

echo ""
echo "Étape 8: Vérification de l'archive..."
if tar tzf "${BACKUP_NAME}.tar.gz" > /dev/null 2>&1; then
    echo "✓ Archive valide"
else
    echo "✗ ERREUR: Archive invalide"
    exit 1
fi

echo ""
echo "=========================================="
echo "Sauvegarde complète terminée!"
echo "=========================================="
echo ""
echo "Fichier de sauvegarde: $BACKUP_BASE_DIR/${BACKUP_NAME}.tar.gz"
echo "Taille: $SIZE"
echo ""
echo "Pour transférer sur un nouveau serveur:"
echo "  scp $BACKUP_BASE_DIR/${BACKUP_NAME}.tar.gz user@new-server-ip:~/"
echo ""
echo "Pour restaurer:"
echo "  ./scripts/restore.sh ~/${BACKUP_NAME}.tar.gz"
echo ""
