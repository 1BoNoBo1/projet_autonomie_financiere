#!/bin/bash
# Script de configuration du firewall UFW pour le VPS
# À exécuter avec les privilèges root sur le VPS

set -e

echo "Configuration du firewall UFW..."

# Réinitialiser UFW (optionnel, à utiliser avec précaution)
# ufw --force reset

# Définir les règles par défaut
ufw default deny incoming
ufw default allow outgoing

# Autoriser SSH (remplacez PORT par votre port SSH personnalisé si différent de 22)
SSH_PORT=${SSH_PORT:-22}
ufw allow $SSH_PORT/tcp comment 'SSH'

# Autoriser HTTP et HTTPS (pour Cloudflare Tunnel)
ufw allow 80/tcp comment 'HTTP'
ufw allow 443/tcp comment 'HTTPS'

# Autoriser les ports Docker internes (optionnel, pour debugging)
# ufw allow 8000/tcp comment 'CrewAI (via Cloudflare Tunnel)'
# ufw allow 5678/tcp comment 'n8n (via Cloudflare Tunnel)'

# Autoriser Cloudflare IPs (recommandé pour sécurité supplémentaire)
# Téléchargez la liste des IPs Cloudflare et autorisez-les
# wget -q https://www.cloudflare.com/ips-v4 -O /tmp/cloudflare-ips-v4.txt
# while read ip; do
#     ufw allow from $ip to any port 443 proto tcp comment 'Cloudflare HTTPS'
#     ufw allow from $ip to any port 80 proto tcp comment 'Cloudflare HTTP'
# done < /tmp/cloudflare-ips-v4.txt

# Activer le firewall
ufw --force enable

# Afficher le statut
ufw status verbose

echo "Firewall configuré avec succès!"
echo "IMPORTANT: Assurez-vous que votre connexion SSH reste active avant de continuer."
