# Guide de Déploiement

Ce document décrit le processus de déploiement de l'infrastructure sur le VPS OVH.

## Prérequis

- VPS OVH avec accès root
- Clé SSH configurée et testée
- Compte Cloudflare avec domaine 1bonobo1.com configuré
- Compte OpenRouter avec clé API
- Compte GitHub (1BoNoBo1)

## Étape 1: Préparation du VPS

### Connexion au VPS
```bash
# Pour OVH, l'utilisateur par défaut est "ubuntu"
ssh ubuntu@51.77.147.143
# ou avec la configuration SSH
ssh vps-ovh
```

### Mise à jour du système
```bash
apt-get update && apt-get upgrade -y
```

## Étape 2: Installation Initiale

### Cloner le projet
```bash
cd /opt
git clone https://github.com/1BoNoBo1/projet_autonomie_financiere.git
cd projet_autonomie_financiere
```

### Exécuter le script d'installation
```bash
# IMPORTANT: Pour OVH, utilisez l'utilisateur ubuntu avec sudo
chmod +x scripts/setup.sh
sudo ./scripts/setup.sh
```

Ce script installe:
- Docker et Docker Compose
- Cloudflared
- UFW (firewall)
- fail2ban
- Toutes les dépendances nécessaires

## Étape 3: Configuration des Secrets

### Créer le fichier .env
```bash
cp .env.example .env
vim .env  # ou votre éditeur préféré
```

### Remplir les variables d'environnement

#### VPS Configuration
```bash
VPS_HOST=your-vps-ip-or-hostname
VPS_USER=root
VPS_SSH_PORT=22
```

#### Cloudflare Configuration
1. Obtenez votre Account ID depuis le dashboard Cloudflare
2. Créez un tunnel Cloudflare:
   ```bash
   cloudflared tunnel create autonomie-tunnel
   ```
3. Récupérez le Tunnel ID et Token
4. Configurez dans `.env`:
   ```bash
   CLOUDFLARE_TUNNEL_ID=your-tunnel-id
   CLOUDFLARE_TUNNEL_SECRET=your-tunnel-token
   CLOUDFLARE_ACCOUNT_ID=your-account-id
   CLOUDFLARE_API_TOKEN=your-api-token
   ```

#### OpenRouter Configuration
```bash
OPENROUTER_API_KEY=your-openrouter-api-key
OPENROUTER_DEFAULT_MODEL=openai/gpt-4-turbo
```

#### n8n Configuration
```bash
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=your-secure-password
N8N_ENCRYPTION_KEY=your-32-char-encryption-key
```

## Étape 4: Configuration Cloudflare

### Créer le tunnel
```bash
cloudflared tunnel create autonomie-tunnel
```

### Configurer les routes DNS
```bash
cloudflared tunnel route dns autonomie-tunnel crewai.1bonobo1.com
cloudflared tunnel route dns autonomie-tunnel n8n.1bonobo1.com
```

### Configurer Zero Trust Access

1. Accédez à https://one.dash.cloudflare.com/
2. Créez une application pour CrewAI:
   - Application name: CrewAI
   - Application domain: `crewai.1bonobo1.com`
   - Session duration: 24 hours
3. Créez une politique d'accès:
   - Policy name: Allow Team
   - Action: Allow
   - Include: Email domain `@1bonobo1.com` (ou votre email)
4. Répétez pour n8n avec `n8n.1bonobo1.com`

## Étape 5: Configuration SSH

### Sur votre laptop
```bash
# Copiez la configuration SSH
cp infrastructure/ssh/config ~/.ssh/config

# Éditez et remplacez les variables
vim ~/.ssh/config
```

### Sur votre smartphone
- Installez Termux (Android) ou iTerminal (iOS)
- Copiez votre clé SSH
- Configurez la connexion SSH

## Étape 6: Déploiement des Services

### Construire et démarrer les services
```bash
chmod +x scripts/deploy.sh
./scripts/deploy.sh
```

Le script `deploy.sh` détecte automatiquement si Docker est installé et l'installe si nécessaire.
Il utilise également la commande appropriée (`docker compose` pour Ubuntu 25 ou `docker-compose` pour compatibilité).

Ou manuellement:
```bash
# Sur Ubuntu 25 (Docker Compose V2)
docker compose build
docker compose up -d

# Sur systèmes plus anciens (Docker Compose V1)
docker-compose build
docker-compose up -d
```

### Vérifier l'état
```bash
# Ubuntu 25
docker compose ps
docker compose logs -f

# Systèmes plus anciens
docker-compose ps
docker-compose logs -f
```

## Étape 7: Vérification

### Vérifier les services
- CrewAI: https://crewai.1bonobo1.com
- n8n: https://n8n.1bonobo1.com

### Vérifier les logs
```bash
# Ubuntu 25
docker compose logs crewai
docker compose logs n8n
docker compose logs cloudflared

# Systèmes plus anciens
docker-compose logs crewai
docker-compose logs n8n
docker-compose logs cloudflared
```

### Tester l'accès SSH
```bash
# Depuis votre laptop
ssh vps-ovh

# Depuis votre smartphone
ssh vps-ovh
```

## Étape 8: Configuration des Sauvegardes

### Configurer un cron job pour les sauvegardes
```bash
crontab -e
```

Ajoutez:
```bash
# Sauvegarde quotidienne à 2h du matin
0 2 * * * /opt/projet_autonomie_financiere/scripts/backup.sh >> /var/log/backup.log 2>&1
```

## Maintenance

### Mise à jour des services
```bash
# Ubuntu 25
docker compose pull
docker compose up -d

# Systèmes plus anciens
docker-compose pull
docker-compose up -d
```

### Mise à jour du système
```bash
apt-get update && apt-get upgrade -y
```

### Voir les logs
```bash
# Ubuntu 25
docker compose logs -f [service-name]

# Systèmes plus anciens
docker-compose logs -f [service-name]
```

### Redémarrer un service
```bash
# Ubuntu 25
docker compose restart [service-name]

# Systèmes plus anciens
docker-compose restart [service-name]
```

## Dépannage

### Service ne démarre pas
1. Vérifiez les logs: `docker compose logs [service-name]` (ou `docker-compose logs [service-name]`)
2. Vérifiez le fichier .env
3. Vérifiez les ports disponibles: `netstat -tulpn`

### Problème de connexion Cloudflare
1. Vérifiez le tunnel: `cloudflared tunnel list`
2. Vérifiez les logs: `docker compose logs cloudflared` (ou `docker-compose logs cloudflared`)
3. Vérifiez la configuration DNS dans Cloudflare

### Problème SSH
1. Vérifiez les permissions: `ls -la ~/.ssh/`
2. Vérifiez les logs: `tail -f /var/log/auth.log`
3. Vérifiez fail2ban: `fail2ban-client status sshd`

## Support

Pour toute question ou problème:
- Consultez la documentation dans `docs/`
- Vérifiez les logs des services
- Consultez la documentation officielle de chaque service
