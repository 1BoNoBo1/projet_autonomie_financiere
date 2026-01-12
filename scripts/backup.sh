#!/bin/bash
# Script de sauvegarde des configurations et données
# À exécuter régulièrement (via cron par exemple)

set -e

# Configuration
BACKUP_DIR="/opt/backups/autonomie-financiere"
DATE=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS=30

echo "=========================================="
echo "Sauvegarde du projet"
echo "Date: $(date)"
echo "=========================================="

# Créer le répertoire de backup
mkdir -p $BACKUP_DIR

# Sauvegarder les configurations
echo "Sauvegarde des configurations..."
tar -czf $BACKUP_DIR/config_$DATE.tar.gz \
    infrastructure/ \
    docker-compose.yml \
    .env.example \
    2>/dev/null || echo "Avertissement: certains fichiers de config n'existent pas"

# Sauvegarder les workflows n8n
if [ -d "n8n/workflows" ]; then
    echo "Sauvegarde des workflows n8n..."
    tar -czf $BACKUP_DIR/n8n_workflows_$DATE.tar.gz n8n/workflows/
fi

# Sauvegarder les configurations CrewAI
if [ -d "crewai/config" ]; then
    echo "Sauvegarde des configurations CrewAI..."
    tar -czf $BACKUP_DIR/crewai_config_$DATE.tar.gz crewai/config/
fi

# Sauvegarder les volumes Docker (si nécessaire)
echo "Sauvegarde des volumes Docker..."
docker run --rm \
    -v n8n_data:/data \
    -v $(pwd):/backup \
    alpine tar czf /backup/$BACKUP_DIR/n8n_data_$DATE.tar.gz -C /data . 2>/dev/null || \
    echo "Avertissement: volume n8n_data non trouvé"

# Nettoyer les anciennes sauvegardes
echo "Nettoyage des anciennes sauvegardes (plus de $RETENTION_DAYS jours)..."
find $BACKUP_DIR -type f -name "*.tar.gz" -mtime +$RETENTION_DAYS -delete

echo "=========================================="
echo "Sauvegarde terminée!"
echo "Répertoire: $BACKUP_DIR"
echo "=========================================="

# Afficher l'espace utilisé
du -sh $BACKUP_DIR
