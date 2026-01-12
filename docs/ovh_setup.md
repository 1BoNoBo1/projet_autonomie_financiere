# Guide de Configuration OVH

Ce guide spécifique décrit la configuration correcte pour un serveur OVH avec Ubuntu.

## Caractéristiques OVH

### Utilisateur par défaut
- **Utilisateur**: `ubuntu` (pas `root`)
- **Accès**: Via SSH avec clés
- **Permissions**: Utilise `sudo` pour les commandes administratives

### Serveur
- **IP**: 51.77.147.143
- **Provider**: OVH
- **OS**: Ubuntu 25
- **Spécifications**: 6 vCPU, 12 GB RAM, 100 GB disk

## Première Connexion

### 1. Connexion SSH initiale (avec utilisateur ubuntu par défaut)

```bash
# Depuis votre laptop - première connexion avec l'utilisateur par défaut OVH
ssh ubuntu@51.77.147.143

# Ou avec votre configuration SSH
ssh vps-ovh
```

### 2. Vérification

```bash
# Vérifier l'utilisateur
whoami
# Devrait afficher: ubuntu

# Vérifier les permissions sudo
sudo whoami
# Devrait afficher: root
```

### 3. Installation et création de l'utilisateur dédié

Après l'installation, un utilisateur dédié `autonomie` sera créé pour des raisons de sécurité.

## Installation Initiale

### Étape 1: Cloner le projet (avec utilisateur ubuntu)

```bash
# Se connecter au serveur avec l'utilisateur ubuntu par défaut
ssh ubuntu@51.77.147.143

# Créer le répertoire et cloner
sudo mkdir -p /opt/projet_autonomie_financiere
cd /opt
sudo git clone https://github.com/1BoNoBo1/projet_autonomie_financiere.git projet_autonomie_financiere
cd /opt/projet_autonomie_financiere
```

### Étape 2: Exécuter le script d'installation

```bash
# IMPORTANT: Utiliser sudo avec l'utilisateur ubuntu
chmod +x scripts/setup.sh
sudo ./scripts/setup.sh
```

Le script va:
- Installer Docker et Docker Compose
- Installer Cloudflared
- **Créer un utilisateur dédié `autonomie`** (meilleure sécurité)
- Configurer le firewall (UFW)
- Configurer SSH (hardening)
- Configurer fail2ban
- Ajouter l'utilisateur `autonomie` au groupe docker

### Étape 3: Configurer l'accès SSH pour l'utilisateur autonomie

```bash
# Depuis votre laptop, copier votre clé SSH publique
ssh-copy-id -i ~/.ssh/id_rsa.pub autonomie@51.77.147.143

# OU manuellement depuis le serveur (en tant qu'ubuntu avec sudo):
sudo mkdir -p /home/autonomie/.ssh
sudo nano /home/autonomie/.ssh/authorized_keys
# Coller votre clé publique ici

sudo chmod 700 /home/autonomie/.ssh
sudo chmod 600 /home/autonomie/.ssh/authorized_keys
sudo chown -R autonomie:autonomie /home/autonomie/.ssh
```

### Étape 4: Se connecter avec l'utilisateur autonomie

```bash
# Se déconnecter
exit

# Se reconnecter avec l'utilisateur autonomie
ssh autonomie@51.77.147.143

# Vérifier que docker fonctionne (sans sudo)
docker ps
```

Si docker ne fonctionne pas sans sudo:
```bash
# Vérifier le groupe
groups
# Devrait inclure "docker"

# Si pas présent, ajouter manuellement (en tant qu'ubuntu avec sudo)
sudo usermod -aG docker autonomie
# Puis se déconnecter/reconnecter avec autonomie
```

## Configuration

### Étape 1: Finaliser les permissions du projet

```bash
# En tant qu'utilisateur ubuntu avec sudo
sudo chown -R autonomie:autonomie /opt/projet_autonomie_financiere
```

### Étape 2: Se connecter avec l'utilisateur autonomie

```bash
ssh autonomie@51.77.147.143
cd /opt/projet_autonomie_financiere
```

### Étape 3: Configurer les secrets

```bash
cp .env.example .env
vim .env  # ou nano .env
```

Remplir les variables importantes:
- `OPENROUTER_API_KEY`
- `CLOUDFLARE_TUNNEL_ID` et `CLOUDFLARE_TUNNEL_SECRET`
- `CLOUDFLARE_ACCOUNT_ID`
- `N8N_BASIC_AUTH_PASSWORD`
- `N8N_ENCRYPTION_KEY`

### Étape 2: Configurer Cloudflare Tunnel

```bash
# Créer le tunnel
cloudflared tunnel create autonomie-tunnel

# Récupérer le Tunnel ID et Token
# Les mettre dans le fichier .env

# Configurer les routes DNS
cloudflared tunnel route dns autonomie-tunnel crewai.1bonobo1.com
cloudflared tunnel route dns autonomie-tunnel n8n.1bonobo1.com
```

## Déploiement

### Étape 1: Tester l'installation

```bash
cd /opt/projet_autonomie_financiere
./scripts/test_installation.sh
```

### Étape 2: Déployer

```bash
./scripts/deploy.sh
```

### Étape 3: Vérifier

```bash
# Vérifier les services
docker compose ps

# Voir les logs
docker compose logs -f
```

## Commandes Utiles

### Avec sudo (si nécessaire)

```bash
# Pour les commandes système
sudo systemctl status docker
sudo ufw status
sudo fail2ban-client status
```

### Sans sudo (après configuration)

```bash
# Commandes Docker (sans sudo après ajout au groupe)
docker ps
docker compose ps
docker compose logs
```

## Dépannage OVH Spécifique

### Problème: Permission denied avec Docker

```bash
# Vérifier le groupe (en tant qu'utilisateur autonomie)
groups | grep docker

# Si absent, ajouter (en tant qu'ubuntu avec sudo)
sudo usermod -aG docker autonomie

# Se déconnecter/reconnecter avec autonomie
exit
ssh autonomie@51.77.147.143

# Tester
docker ps
```

### Problème: Impossible d'écrire dans /opt

```bash
# Donner les permissions (en tant qu'ubuntu avec sudo)
sudo chown -R autonomie:autonomie /opt/projet_autonomie_financiere
```

### Problème: Impossible de se connecter avec l'utilisateur autonomie

```bash
# Vérifier que les clés SSH sont configurées
sudo cat /home/autonomie/.ssh/authorized_keys

# Vérifier les permissions
sudo ls -la /home/autonomie/.ssh/

# Doit être:
# drwx------ autonomie autonomie .ssh
# -rw------- autonomie autonomie authorized_keys
```

### Problème: SSH ne fonctionne plus après hardening

Si vous êtes bloqué:
1. Utiliser la console OVH (KVM/IPMI)
2. Ou contacter le support OVH

Pour éviter cela, testez d'abord la connexion SSH avant de modifier la configuration.

## Notes Importantes

1. **Utilisateur ubuntu** : Utilisé uniquement pour l'installation initiale (avec sudo)
2. **Utilisateur autonomie** : Utilisateur dédié créé pour le projet (meilleure sécurité)
3. **Toujours utiliser `sudo`** pour les commandes système (en tant qu'ubuntu)
4. **Utiliser l'utilisateur autonomie** pour le travail quotidien et les services
5. **Se déconnecter/reconnecter** après ajout au groupe docker
6. **Tester SSH** avant de modifier la configuration SSH
7. **Sauvegarder** avant toute modification importante

## Architecture de Sécurité

```
ubuntu (utilisateur OVH par défaut)
  └─> Utilisé pour: Installation, administration système (avec sudo)
  
autonomie (utilisateur dédié créé)
  └─> Utilisé pour: Services, développement, travail quotidien
```

## Checklist OVH

- [ ] Connexion SSH fonctionne avec l'utilisateur ubuntu (première connexion)
- [ ] Permissions sudo fonctionnent pour ubuntu
- [ ] Projet cloné dans /opt/projet_autonomie_financiere
- [ ] Script setup.sh exécuté avec succès
- [ ] Utilisateur `autonomie` créé
- [ ] Clés SSH configurées pour l'utilisateur `autonomie`
- [ ] Connexion SSH fonctionne avec l'utilisateur `autonomie`
- [ ] Utilisateur `autonomie` dans le groupe docker
- [ ] Docker fonctionne sans sudo (avec utilisateur autonomie)
- [ ] Permissions du projet configurées (autonomie:autonomie)
- [ ] Fichier .env configuré
- [ ] Cloudflare Tunnel configuré
- [ ] Services déployés et fonctionnels
