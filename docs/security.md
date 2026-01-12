# Guide de Sécurité

Ce document décrit les mesures de sécurité mises en place pour protéger l'infrastructure du projet d'autonomie financière.

## Architecture de Sécurité

### 1. Accès SSH

#### Configuration
- Authentification par clés SSH uniquement (pas de mots de passe)
- Port SSH personnalisé (recommandé, mais optionnel)
- Désactivation de l'accès root direct
- Utilisation de fail2ban pour protection contre les attaques par force brute

#### Clés SSH
- **Laptop**: Utilisez votre clé SSH existante configurée chez OVH
- **Smartphone**: Générez une clé SSH dédiée pour votre smartphone

#### Génération de clé SSH pour smartphone

Sur votre smartphone (Termux, etc.):
```bash
ssh-keygen -t rsa -b 4096 -C "mobile@1bonobo1"
# Sauvegardez la clé privée de manière sécurisée
# Copiez la clé publique vers le VPS
```

Sur le VPS:
```bash
# Ajoutez la clé publique dans ~/.ssh/authorized_keys
cat mobile_key.pub >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
chmod 700 ~/.ssh
```

### 2. Cloudflare Protection

#### Cloudflare Tunnel
- Tous les services sont accessibles uniquement via Cloudflare Tunnel
- Aucun port n'est exposé directement sur Internet
- Chiffrement end-to-end via HTTPS

#### Zero Trust Access
- Authentification requise pour accéder aux services
- Support de l'authentification par email
- Support de l'authentification multi-facteurs (MFA)
- Politiques d'accès granulaires

#### Configuration Zero Trust

1. Accédez au dashboard Cloudflare Zero Trust: https://one.dash.cloudflare.com/
2. Créez une application pour chaque service:
   - `crewai.1bonobo1.com`
   - `n8n.1bonobo1.com`
3. Configurez les politiques d'accès:
   - Autorisez uniquement les emails de confiance
   - Activez MFA pour les accès sensibles
4. Configurez les règles WAF pour protection supplémentaire

### 3. Firewall (UFW)

Le firewall est configuré pour:
- Refuser toutes les connexions entrantes par défaut
- Autoriser uniquement SSH, HTTP, HTTPS
- Bloquer toutes les autres connexions

Configuration:
```bash
sudo ./infrastructure/firewall/ufw-rules.sh
```

### 4. Gestion des Secrets

#### Variables d'Environnement
- Tous les secrets sont stockés dans le fichier `.env` (jamais commité dans git)
- Le fichier `.env.example` sert de template
- Utilisez des mots de passe forts et uniques

#### Bonnes Pratiques
- Ne jamais commiter le fichier `.env` dans git
- Utiliser des mots de passe d'au moins 32 caractères
- Régénérer les clés API régulièrement
- Utiliser des secrets différents pour dev/staging/prod

#### Rotation des Secrets
- Changez les mots de passe tous les 90 jours
- Régénérez les clés API en cas de compromission
- Utilisez un gestionnaire de mots de passe

### 5. Accès depuis Smartphone

#### Applications Recommandées
- **Termux**: Terminal SSH pour Android
- **iTerminal**: Terminal SSH pour iOS
- **JuiceSSH**: Client SSH avec support de clés

#### Configuration
1. Installez votre clé SSH sur le smartphone
2. Configurez le fichier SSH config (voir `infrastructure/ssh/config`)
3. Testez la connexion: `ssh vps-ovh`

#### Sécurité Mobile
- Utilisez un code PIN/empreinte pour protéger l'accès au smartphone
- Activez le verrouillage automatique
- Ne partagez jamais vos clés SSH
- Utilisez un VPN si vous êtes sur un réseau non sécurisé

### 6. Monitoring et Alertes

#### Logs
- Tous les services génèrent des logs
- Les logs sont accessibles via `docker compose logs` (Ubuntu 25) ou `docker-compose logs` (systèmes plus anciens)
- Configurez la rotation des logs pour éviter l'accumulation

#### Alertes
- Configurez des alertes pour les tentatives de connexion suspectes
- Surveillez les logs fail2ban
- Configurez des alertes Cloudflare pour les attaques DDoS

### 7. Mises à Jour de Sécurité

#### Système
- Mettez à jour le système régulièrement: `apt-get update && apt-get upgrade`
- Surveillez les bulletins de sécurité
- Appliquez les correctifs rapidement

#### Applications
- Mettez à jour Docker et Docker Compose régulièrement
- Mettez à jour les images Docker: `docker compose pull` (Ubuntu 25) ou `docker-compose pull` (systèmes plus anciens)
- Surveillez les vulnérabilités des dépendances

### 8. Checklist de Sécurité

- [ ] Clés SSH configurées et sécurisées
- [ ] Firewall activé et configuré
- [ ] fail2ban activé
- [ ] Cloudflare Tunnel configuré
- [ ] Zero Trust Access configuré
- [ ] Fichier .env créé et sécurisé
- [ ] Tous les mots de passe changés depuis les valeurs par défaut
- [ ] Accès SSH depuis laptop testé
- [ ] Accès SSH depuis smartphone testé
- [ ] Accès aux services via Cloudflare testé
- [ ] Sauvegardes configurées

### 9. En Cas de Compromission

Si vous suspectez une compromission:

1. **Immédiatement**:
   - Changez tous les mots de passe
   - Régénérez toutes les clés API
   - Révoquez toutes les clés SSH suspectes

2. **Investigation**:
   - Vérifiez les logs: `docker compose logs` (Ubuntu 25) ou `docker-compose logs` (systèmes plus anciens)
   - Vérifiez les connexions SSH: `last` et `/var/log/auth.log`
   - Vérifiez fail2ban: `fail2ban-client status`

3. **Restauration**:
   - Restaurez depuis une sauvegarde propre
   - Réinstallez le système si nécessaire
   - Reconfigurez tous les accès

### 10. Ressources

- [Documentation Cloudflare Zero Trust](https://developers.cloudflare.com/cloudflare-one/)
- [Documentation SSH](https://www.ssh.com/ssh/)
- [Documentation UFW](https://help.ubuntu.com/community/UFW)
- [Documentation fail2ban](https://www.fail2ban.org/wiki/index.php/Main_Page)
