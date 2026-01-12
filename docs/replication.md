# Guide de Réplication et Migration

Ce document décrit comment répliquer l'infrastructure complète sur un nouveau serveur ou restaurer après un problème.

## Vue d'ensemble

Ce guide permet de :
- Répliquer l'infrastructure sur un nouveau serveur
- Restaurer après un problème
- Cloner la configuration complète
- Migrer vers un nouveau serveur

## Prérequis pour la Réplication

### 1. Accès au serveur source
- IP du serveur : `51.77.147.143`
- Accès SSH avec clé configurée
- Accès root ou sudo

### 2. Accès au nouveau serveur
- IP du nouveau serveur
- Accès SSH avec clé configurée
- Accès root ou sudo

### 3. Informations nécessaires
- Toutes les clés API (OpenRouter, Cloudflare, etc.)
- Configuration Cloudflare (Tunnel ID, Account ID)
- Mots de passe et secrets

## Étape 1: Sauvegarde sur le Serveur Source

### 1.1 Sauvegarde complète

```bash
# Sur le serveur source (51.77.147.143)
cd /opt/projet_autonomie_financiere
./scripts/backup.sh
```

Cette commande crée une sauvegarde dans `/opt/backups/autonomie-financiere/`

### 1.2 Sauvegarde manuelle des éléments critiques

```bash
# Créer un dossier de sauvegarde
mkdir -p ~/backup_replication_$(date +%Y%m%d)
BACKUP_DIR=~/backup_replication_$(date +%Y%m%d)

# Sauvegarder la configuration
cp -r /opt/projet_autonomie_financiere $BACKUP_DIR/
cp /opt/projet_autonomie_financiere/.env $BACKUP_DIR/.env

# Sauvegarder les volumes Docker
docker run --rm \
  -v n8n_data:/data \
  -v $(pwd):/backup \
  alpine tar czf /backup/n8n_data_backup.tar.gz -C /data .

# Sauvegarder la configuration Cloudflare
cp -r ~/.cloudflared $BACKUP_DIR/cloudflared_config 2>/dev/null || true

# Créer une archive complète
tar czf ~/backup_complete_$(date +%Y%m%d).tar.gz -C ~ backup_replication_$(date +%Y%m%d)
```

### 1.3 Liste de vérification avant migration

- [ ] Fichier `.env` sauvegardé (avec tous les secrets)
- [ ] Configuration Cloudflare Tunnel sauvegardée
- [ ] Volumes Docker sauvegardés (n8n workflows, données)
- [ ] Configuration SSH sauvegardée
- [ ] Scripts de déploiement sauvegardés
- [ ] Documentation sauvegardée

## Étape 2: Préparation du Nouveau Serveur

### 2.1 Installation initiale

```bash
# Sur le nouveau serveur
# Cloner le projet
cd /opt
git clone https://github.com/1BoNoBo1/projet_autonomie_financiere.git
cd projet_autonomie_financiere

# Exécuter le script d'installation
chmod +x scripts/setup.sh
sudo ./scripts/setup.sh
```

### 2.2 Restauration des fichiers

```bash
# Transférer la sauvegarde depuis le serveur source
# Depuis votre laptop ou le serveur source
scp ~/backup_complete_YYYYMMDD.tar.gz user@new-server-ip:~/

# Sur le nouveau serveur
cd ~
tar xzf backup_complete_YYYYMMDD.tar.gz
cd backup_replication_YYYYMMDD

# Restaurer les fichiers
cp -r projet_autonomie_financiere/* /opt/projet_autonomie_financiere/
cp .env /opt/projet_autonomie_financiere/.env

# Restaurer la configuration Cloudflare
cp -r cloudflared_config ~/.cloudflared 2>/dev/null || true
```

### 2.3 Configuration des secrets

```bash
# Vérifier et mettre à jour le fichier .env
cd /opt/projet_autonomie_financiere
vim .env

# Vérifier que toutes les variables sont correctes :
# - OPENROUTER_API_KEY
# - CLOUDFLARE_TUNNEL_ID
# - CLOUDFLARE_TUNNEL_SECRET
# - CLOUDFLARE_ACCOUNT_ID
# - N8N_BASIC_AUTH_PASSWORD
# - N8N_ENCRYPTION_KEY
# - etc.
```

## Étape 3: Configuration Cloudflare

### 3.1 Si vous gardez le même domaine

Si vous gardez le même domaine (1bonobo1.com), vous devez :

1. **Mettre à jour le tunnel Cloudflare** :
   ```bash
   # Sur le nouveau serveur
   cloudflared tunnel route dns <tunnel-name> crewai.1bonobo1.com
   cloudflared tunnel route dns <tunnel-name> n8n.1bonobo1.com
   ```

2. **Ou recréer le tunnel** :
   ```bash
   cloudflared tunnel create autonomie-tunnel
   # Récupérer le Tunnel ID et Token
   # Mettre à jour dans .env
   ```

### 3.2 Si vous changez de domaine

Si vous utilisez un nouveau domaine :

1. Créer un nouveau tunnel Cloudflare
2. Configurer les routes DNS pour le nouveau domaine
3. Mettre à jour le fichier `.env`
4. Mettre à jour `infrastructure/cloudflare/tunnel.yml`

## Étape 4: Restauration des Données

### 4.1 Restauration des volumes Docker

```bash
# Restaurer les données n8n
docker run --rm \
  -v n8n_data:/data \
  -v $(pwd):/backup \
  alpine sh -c "cd /data && tar xzf /backup/n8n_data_backup.tar.gz"
```

### 4.2 Vérification

```bash
# Vérifier que les données sont restaurées
docker volume ls
docker volume inspect n8n_data
```

## Étape 5: Déploiement

### 5.1 Test de l'installation

```bash
cd /opt/projet_autonomie_financiere
./scripts/test_installation.sh
```

### 5.2 Déploiement

```bash
./scripts/deploy.sh
```

### 5.3 Vérification

```bash
# Vérifier les services
docker compose ps

# Tester l'API
./scripts/test_api.sh

# Vérifier les logs
docker compose logs -f
```

## Étape 6: Configuration SSH

### 6.1 Ajouter les clés SSH

```bash
# Sur le nouveau serveur
# Ajouter vos clés SSH dans ~/.ssh/authorized_keys
# (depuis votre laptop et smartphone)
```

### 6.2 Tester l'accès

```bash
# Depuis votre laptop
ssh user@new-server-ip
```

## Checklist de Migration Complète

### Avant la migration
- [ ] Sauvegarde complète effectuée
- [ ] Tous les secrets documentés
- [ ] Configuration Cloudflare notée
- [ ] IP du nouveau serveur connue

### Pendant la migration
- [ ] Nouveau serveur préparé (setup.sh exécuté)
- [ ] Fichiers restaurés
- [ ] Fichier .env configuré
- [ ] Cloudflare Tunnel configuré
- [ ] Volumes Docker restaurés
- [ ] Services déployés
- [ ] Tests passés

### Après la migration
- [ ] Services accessibles via domaine
- [ ] API CrewAI fonctionnelle
- [ ] n8n accessible
- [ ] Accès SSH configuré
- [ ] Sauvegardes automatiques configurées
- [ ] Monitoring en place

## Scripts Automatiques

Utilisez les scripts fournis pour automatiser le processus :

- `scripts/backup.sh` - Sauvegarde automatique
- `scripts/restore.sh` - Restauration (à créer)
- `scripts/migrate.sh` - Migration complète (à créer)

## Dépannage

### Problème: Services ne démarrent pas

```bash
# Vérifier les logs
docker compose logs

# Vérifier la configuration
docker compose config

# Vérifier les variables d'environnement
docker compose config | grep -E "OPENROUTER|CLOUDFLARE|N8N"
```

### Problème: Cloudflare Tunnel ne fonctionne pas

```bash
# Vérifier la configuration
cat infrastructure/cloudflare/tunnel.yml

# Tester manuellement
cloudflared tunnel run

# Vérifier les logs
docker compose logs cloudflared
```

### Problème: Données non restaurées

```bash
# Vérifier les volumes
docker volume ls

# Vérifier le contenu
docker run --rm -v n8n_data:/data alpine ls -la /data
```

## Notes Importantes

1. **Secrets** : Ne jamais commiter le fichier `.env` dans git
2. **Clés SSH** : Toujours avoir une sauvegarde des clés SSH
3. **Cloudflare** : Noter le Tunnel ID et Token avant migration
4. **Backups** : Configurer des sauvegardes automatiques régulières
5. **Documentation** : Maintenir cette documentation à jour

## Support

En cas de problème lors de la réplication :
1. Consultez les logs : `docker compose logs`
2. Vérifiez la configuration : `.env` et `docker-compose.yml`
3. Consultez la documentation : `docs/`
