# Projet Autonomie Financière

Projet d'automatisation intelligente pour atteindre l'autonomie financière grâce à l'IA et aux automatisations.

## 🎯 Objectif

Créer un système automatisé utilisant CrewAI comme cerveau principal et n8n pour l'orchestration, permettant de générer des revenus passifs et d'atteindre l'autonomie financière.

## 🏗️ Architecture

Le projet utilise une architecture modulaire et sécurisée:

- **CrewAI**: Cerveau IA principal pour la prise de décision intelligente
- **n8n**: Orchestration des workflows et automatisations
- **Cloudflare**: Protection et accès sécurisé via Tunnel et Zero Trust
- **VPS OVH**: Infrastructure d'hébergement (6 vCPU, 12 GB RAM, 100 GB disk)

## 📁 Structure du Projet

```
projet_autonomie_financiere/
├── infrastructure/      # Configuration infrastructure (Cloudflare, SSH, Firewall)
├── crewai/             # Module CrewAI (agents, configurations)
├── n8n/                # Module n8n (workflows)
├── scripts/            # Scripts d'automatisation
├── docs/               # Documentation
└── secrets/            # Gestion des secrets (gitignored)
```

## 🚀 Démarrage Rapide

### Prérequis

- VPS OVH avec accès root
- Clé SSH configurée
- Compte Cloudflare avec domaine 1bonobo1.com
- Compte OpenRouter avec clé API
- Docker et Docker Compose installés

### Installation

1. **Cloner le projet**
   ```bash
   git clone https://github.com/1BoNoBo1/projet_autonomie_financiere.git
   cd projet_autonomie_financiere
   ```

2. **Configurer les secrets**
   ```bash
   cp .env.example .env
   vim .env  # Remplir avec vos valeurs
   ```

3. **Installer l'infrastructure** (sur le VPS)
   ```bash
   chmod +x scripts/setup.sh
   sudo ./scripts/setup.sh
   ```

4. **Tester l'installation** (sur le serveur)
   ```bash
   chmod +x scripts/test_installation.sh
   ./scripts/test_installation.sh
   ```

5. **Déployer les services**
   ```bash
   chmod +x scripts/deploy.sh
   ./scripts/deploy.sh
   ```

6. **Tester l'API** (après déploiement)
   ```bash
   chmod +x scripts/test_api.sh
   ./scripts/test_api.sh
   ```

7. **Accéder aux services**
   - CrewAI: https://crewai.1bonobo1.com
   - n8n: https://n8n.1bonobo1.com

## 📚 Documentation

- **[Guide de Sécurité](docs/security.md)**: Configuration et bonnes pratiques de sécurité
- **[Guide de Déploiement](docs/deployment.md)**: Instructions détaillées de déploiement
- **[Guide de Test](docs/testing.md)**: Guide complet pour tester l'installation
- **[Architecture](docs/architecture.md)**: Architecture détaillée du système

## 🔐 Sécurité

Le projet met en place plusieurs couches de sécurité:

- Authentification SSH par clés uniquement
- Cloudflare Tunnel pour accès sécurisé
- Zero Trust Access pour authentification
- Firewall UFW configuré
- Fail2Ban pour protection contre les attaques
- Gestion sécurisée des secrets

Voir [docs/security.md](docs/security.md) pour plus de détails.

## 🛠️ Services Disponibles

### CrewAI
Cerveau IA principal pour l'automatisation intelligente.

**Accès**: https://crewai.1bonobo1.com

### n8n
Orchestration des workflows et automatisations.

**Accès**: https://n8n.1bonobo1.com

## 📦 Ressources

- **VPS**: OVH (6 vCPU, 12 GB RAM, 100 GB disk)
- **Domaine**: 1bonobo1.com (Cloudflare)
- **IA**: OpenRouter API
- **GitHub**: 1BoNoBo1

## 🔄 Maintenance

### Mise à jour des services
```bash
# Ubuntu 25 (Docker Compose V2)
docker compose pull
docker compose up -d

# Systèmes plus anciens
docker-compose pull
docker-compose up -d
```

### Voir les logs
```bash
# Ubuntu 25
docker compose logs -f [service-name]

# Systèmes plus anciens
docker-compose logs -f [service-name]
```

### Sauvegardes
Les sauvegardes sont automatiques via cron (configuré dans `scripts/backup.sh`).

## 📝 Développement

### Structure Modulaire

Le projet est organisé de manière modulaire pour faciliter:
- L'ajout de nouveaux agents CrewAI
- L'ajout de nouveaux workflows n8n
- L'intégration de nouveaux services
- La maintenance et les mises à jour

### Ajouter un nouvel agent CrewAI

1. Créer le fichier dans `crewai/agents/`
2. Configurer dans `crewai/config/settings.yaml`
3. Redémarrer le service: `docker compose restart crewai` (ou `docker-compose restart crewai`)

### Ajouter un nouveau workflow n8n

1. Créer le workflow dans l'interface n8n
2. Exporter dans `n8n/workflows/`
3. Le workflow sera automatiquement chargé au redémarrage

## 🤝 Contribution

Ce projet est en développement actif. Les contributions sont les bienvenues!

## 📄 Licence

[À définir]

## 🔗 Liens Utiles

- [Documentation CrewAI](https://docs.crewai.com/)
- [Documentation n8n](https://docs.n8n.io/)
- [Documentation Cloudflare](https://developers.cloudflare.com/)
- [OpenRouter](https://openrouter.ai/)

## ⚠️ Avertissements

- **Ne jamais commiter le fichier `.env`** dans git
- **Toujours utiliser des mots de passe forts**
- **Configurer Zero Trust Access** avant de déployer en production
- **Faire des sauvegardes régulières**

## 📞 Support

Pour toute question ou problème:
1. Consultez la documentation dans `docs/`
2. Vérifiez les logs des services
3. Consultez la documentation officielle de chaque service

---

**Note**: Ce projet est en développement actif. L'architecture et les fonctionnalités peuvent évoluer.
