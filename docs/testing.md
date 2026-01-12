# Guide de Test

Ce document décrit comment tester l'installation et le fonctionnement du système sur le serveur OVH.

## Tests sur le Serveur OVH

### Prérequis

1. Avoir accès SSH au serveur OVH
2. Avoir exécuté `scripts/setup.sh` pour l'installation initiale
3. Avoir configuré le fichier `.env` avec vos secrets

### Test 1: Vérification de l'Installation

Ce test vérifie que tous les composants sont correctement installés et configurés.

```bash
# Sur le serveur OVH
cd /opt/projet_autonomie_financiere  # ou votre répertoire de projet
chmod +x scripts/test_installation.sh
./scripts/test_installation.sh
```

Le script vérifie:
- ✅ Installation de Docker et Docker Compose
- ✅ Présence et configuration du fichier .env
- ✅ Structure du projet (dossiers et fichiers)
- ✅ Construction des images Docker
- ✅ Syntaxe des fichiers Python
- ✅ Configuration docker-compose.yml
- ✅ Disponibilité des ports

### Test 2: Déploiement des Services

Une fois les tests d'installation réussis, déployez les services:

```bash
# Option 1: Utiliser le script de déploiement
./scripts/deploy.sh

# Option 2: Déploiement manuel
docker compose up -d
```

Vérifiez que les services sont démarrés:

```bash
docker compose ps
```

Vous devriez voir:
- `crewai-service` - Status: Up
- `n8n-service` - Status: Up
- `cloudflared-tunnel` - Status: Up

### Test 3: Vérification des Logs

Vérifiez les logs pour détecter d'éventuelles erreurs:

```bash
# Logs de tous les services
docker compose logs

# Logs d'un service spécifique
docker compose logs crewai
docker compose logs n8n
docker compose logs cloudflared

# Logs en temps réel
docker compose logs -f
```

### Test 4: Test de l'API CrewAI

Testez l'API CrewAI localement (sur le serveur):

```bash
# Test simple
curl http://localhost:8000/health

# Test avec le script dédié
chmod +x scripts/test_api.sh
./scripts/test_api.sh
```

Le script teste:
- ✅ Health check endpoint
- ✅ Root endpoint
- ✅ Liste des agents
- ✅ Liste des outils
- ✅ Exécution d'une tâche

### Test 5: Test via Cloudflare Tunnel

Une fois Cloudflare Tunnel configuré, testez l'accès via le domaine:

```bash
# Depuis votre laptop
curl https://crewai.1bonobo1.com/health
curl https://crewai.1bonobo1.com/agents

# Test n8n
curl https://n8n.1bonobo1.com/healthz
```

### Test 6: Test d'une Tâche Complète

Testez l'exécution d'une tâche complète avec un crew:

```bash
curl -X POST https://crewai.1bonobo1.com/crew/execute \
  -H "Content-Type: application/json" \
  -d '{
    "task_type": "crew",
    "description": "Rechercher et analyser les opportunités de revenus passifs pour 2024",
    "context": {}
  }'
```

## Dépannage

### Problème: Docker Compose non trouvé

```bash
# Vérifier l'installation
docker compose version

# Si non disponible, installer
sudo apt-get update
sudo apt-get install docker-compose-plugin
```

### Problème: Erreur de construction Docker

```bash
# Voir les logs détaillés
docker compose build --no-cache crewai

# Vérifier les erreurs spécifiques
docker compose logs crewai
```

### Problème: Service ne démarre pas

```bash
# Vérifier les logs
docker compose logs [service-name]

# Vérifier la configuration
docker compose config

# Redémarrer un service
docker compose restart [service-name]
```

### Problème: Port déjà utilisé

```bash
# Vérifier quel processus utilise le port
sudo netstat -tulpn | grep :8000
sudo lsof -i :8000

# Arrêter le processus ou changer le port dans docker-compose.yml
```

### Problème: Erreur OpenRouter API

```bash
# Vérifier la clé API dans .env
grep OPENROUTER_API_KEY .env

# Tester la connexion
curl -H "Authorization: Bearer $OPENROUTER_API_KEY" \
     https://openrouter.ai/api/v1/models
```

### Problème: Cloudflare Tunnel ne fonctionne pas

```bash
# Vérifier les logs
docker compose logs cloudflared

# Vérifier la configuration
cat infrastructure/cloudflare/tunnel.yml

# Tester manuellement
cloudflared tunnel run
```

## Checklist de Test

Avant de considérer l'installation comme complète:

- [ ] Script `test_installation.sh` passe sans erreur
- [ ] Tous les services Docker sont démarrés (`docker compose ps`)
- [ ] Health check CrewAI répond (`curl http://localhost:8000/health`)
- [ ] Health check n8n répond (`curl http://localhost:5678/healthz`)
- [ ] API CrewAI retourne la liste des agents
- [ ] API CrewAI peut exécuter une tâche simple
- [ ] Cloudflare Tunnel est actif (si configuré)
- [ ] Accès via domaine fonctionne (si configuré)
- [ ] Logs ne montrent pas d'erreurs critiques

## Tests Automatisés (Futur)

Des tests automatisés plus complets pourront être ajoutés:
- Tests unitaires pour les agents
- Tests d'intégration pour les workflows
- Tests de performance
- Tests de sécurité

## Support

En cas de problème:
1. Consultez les logs: `docker compose logs`
2. Vérifiez la documentation: `docs/`
3. Vérifiez la configuration: `.env` et `docker-compose.yml`
