# Informations du Serveur

## Serveur Actuel

- **IP**: 51.77.147.143
- **Provider**: OVH
- **Spécifications**: 6 vCPU, 12 GB RAM, 100 GB disk
- **OS**: Ubuntu 25

## Accès SSH

### Configuration

```bash
# Dans ~/.ssh/config sur votre laptop
# Administration (utilisateur ubuntu par défaut OVH)
Host vps-ovh-admin
    HostName 51.77.147.143
    User ubuntu
    Port 22
    IdentityFile ~/.ssh/id_rsa
    IdentitiesOnly yes

# Travail quotidien (utilisateur autonomie dédié)
Host vps-ovh
    HostName 51.77.147.143
    User autonomie
    Port 22
    IdentityFile ~/.ssh/id_rsa
    IdentitiesOnly yes
```

### Connexion

```bash
# Administration (première connexion, installation)
ssh ubuntu@51.77.147.143
# ou
ssh vps-ovh-admin

# Travail quotidien (après création de l'utilisateur autonomie)
ssh autonomie@51.77.147.143
# ou
ssh vps-ovh
```

## Répertoires Importants

- **Projet**: `/opt/projet_autonomie_financiere`
- **Sauvegardes**: `/opt/backups/autonomie-financiere`
- **Home utilisateur**: `/home/ubuntu`
- **Logs Docker**: Accessibles via `docker compose logs`

## Utilisateurs

### Utilisateur ubuntu (OVH par défaut)
- **Rôle**: Administration système
- **Utilisation**: Installation initiale, maintenance système
- **Groupe sudo**: Oui (permissions administrateur)
- **Groupe docker**: Non (pas nécessaire)

### Utilisateur autonomie (créé pour le projet)
- **Rôle**: Utilisateur dédié pour le projet
- **Utilisation**: Services, développement, travail quotidien
- **Groupe sudo**: Non (meilleure sécurité)
- **Groupe docker**: Oui (pour exécuter Docker sans sudo)

## Services

### Ports Utilisés

- **8000**: CrewAI API
- **5678**: n8n
- **22**: SSH
- **80/443**: Cloudflare Tunnel (pas directement exposés)

### URLs Publiques

- **CrewAI**: https://crewai.1bonobo1.com
- **n8n**: https://n8n.1bonobo1.com

## Commandes Utiles

### Vérifier l'état des services

```bash
docker compose ps
```

### Voir les logs

```bash
docker compose logs -f
```

### Redémarrer un service

```bash
docker compose restart [service-name]
```

### Accéder au conteneur

```bash
docker exec -it crewai-service bash
docker exec -it n8n-service bash
```

## Sauvegardes

### Sauvegarde manuelle

```bash
cd /opt/projet_autonomie_financiere
./scripts/full_backup.sh
```

### Sauvegarde automatique

Configurée via cron (voir `scripts/backup.sh`)

## Monitoring

### Espace disque

```bash
df -h
```

### Utilisation mémoire

```bash
free -h
```

### Utilisation CPU

```bash
top
# ou
htop
```

## Maintenance

### Mise à jour du système

```bash
apt-get update && apt-get upgrade -y
```

### Mise à jour des services

```bash
cd /opt/projet_autonomie_financiere
docker compose pull
docker compose up -d
```

## Notes

- Toujours vérifier l'espace disque avant les sauvegardes
- Les logs peuvent être volumineux, configurer la rotation
- Surveiller l'utilisation des ressources (RAM, CPU, disk)
