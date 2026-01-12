# Module CrewAI - Autonomie Financière

Ce module contient le cerveau IA principal du projet, utilisant CrewAI pour orchestrer des agents spécialisés dans la recherche, l'analyse et la prise de décision pour atteindre l'autonomie financière.

## Structure

```
crewai/
├── main.py                 # Application FastAPI principale
├── Dockerfile              # Image Docker
├── requirements.txt        # Dépendances Python
├── config/
│   └── settings.yaml      # Configuration CrewAI
├── crewai/
│   ├── agents/            # Agents IA
│   │   ├── research_agent.py
│   │   ├── analysis_agent.py
│   │   └── decision_agent.py
│   └── tools/             # Outils pour les agents
│       ├── research_tools.py
│       ├── analysis_tools.py
│       ├── decision_tools.py
│       ├── n8n_tools.py
│       └── api_tools.py
└── agents/                # Dossier pour futurs agents personnalisés
```

## Agents

### 1. Agent de Recherche
- **Rôle**: Chercheur d'Opportunités Financières
- **Objectif**: Identifier les meilleures opportunités pour l'autonomie financière
- **Outils**: Recherche web, analyse de marché

### 2. Agent d'Analyse
- **Rôle**: Analyste Financier
- **Objectif**: Analyser en profondeur les opportunités et évaluer leur viabilité
- **Outils**: Calcul ROI, analyse de données, évaluation des risques

### 3. Agent de Décision
- **Rôle**: Preneur de Décision Stratégique
- **Objectif**: Prendre des décisions éclairées basées sur les recherches et analyses
- **Outils**: Prise de décision, création de plans d'action, exécution

## Outils

### Outils de Recherche
- **WebSearch**: Recherche d'informations sur Internet
- **MarketAnalysis**: Analyse des tendances du marché

### Outils d'Analyse
- **CalculateROI**: Calcul du retour sur investissement
- **AnalyzeFinancialData**: Analyse de données financières
- **EvaluateRisk**: Évaluation des risques

### Outils de Décision
- **MakeDecision**: Prise de décision basée sur des critères
- **CreateActionPlan**: Création de plans d'action
- **ExecuteDecision**: Exécution de décisions

### Outils d'Intégration
- **TriggerN8NWorkflow**: Déclenchement de workflows n8n
- **CallOpenRouterAPI**: Appels API personnalisés à OpenRouter

## API Endpoints

### GET /
Endpoint racine avec informations sur le service

### GET /health
Health check endpoint

### GET /agents
Liste tous les agents disponibles

### GET /tools
Liste tous les outils disponibles

### POST /execute
Exécute une tâche avec un agent spécifique
```json
{
  "task_type": "research|analysis|decision",
  "description": "Description de la tâche",
  "context": {}
}
```

### POST /crew/execute
Exécute une tâche avec un crew complet (tous les agents en séquence)
```json
{
  "task_type": "crew",
  "description": "Description de la tâche complète",
  "context": {}
}
```

## Configuration

### Variables d'environnement

- `OPENROUTER_API_KEY`: Clé API OpenRouter
- `OPENROUTER_BASE_URL`: URL de base OpenRouter (défaut: https://openrouter.ai/api/v1)
- `OPENROUTER_DEFAULT_MODEL`: Modèle par défaut (défaut: openai/gpt-4-turbo)
- `CREWAI_TEMPERATURE`: Température du LLM (défaut: 0.7)
- `CREWAI_LOG_LEVEL`: Niveau de log (défaut: INFO)
- `CREWAI_PORT`: Port du serveur (défaut: 8000)
- `CREWAI_HOST`: Host du serveur (défaut: 0.0.0.0)
- `N8N_WEBHOOK_URL`: URL des webhooks n8n
- `N8N_BASIC_AUTH_USER`: Utilisateur n8n
- `N8N_BASIC_AUTH_PASSWORD`: Mot de passe n8n

## Utilisation

### Développement local

```bash
# Installer les dépendances
pip install -r requirements.txt

# Configurer les variables d'environnement
cp ../.env.example ../.env
# Éditer .env avec vos valeurs

# Lancer le serveur
python main.py
```

### Avec Docker

```bash
# Construire l'image
docker build -t crewai-autonomie .

# Lancer le conteneur
docker run -d \
  --name crewai \
  -p 8000:8000 \
  --env-file ../.env \
  crewai-autonomie
```

### Exemple d'utilisation

```python
import requests

# Exécuter une recherche
response = requests.post("http://localhost:8000/execute", json={
    "task_type": "research",
    "description": "Rechercher des opportunités de revenus passifs en 2024"
})

print(response.json())
```

## Développement

### Ajouter un nouvel agent

1. Créer un fichier dans `crewai/agents/`
2. Implémenter la fonction `create_<nom>_agent()`
3. Ajouter l'import dans `crewai/agents/__init__.py`
4. Mettre à jour `main.py` pour l'utiliser

### Ajouter un nouvel outil

1. Créer un fichier dans `crewai/tools/`
2. Implémenter les fonctions d'outil
3. Créer la fonction `get_<nom>_tools()` qui retourne une liste de `Tool`
4. Ajouter l'import dans `crewai/tools/__init__.py`

## Notes

- Les agents utilisent OpenRouter pour accéder à différents modèles IA
- Les outils peuvent déclencher des workflows n8n pour l'automatisation
- L'API FastAPI permet d'intégrer CrewAI avec d'autres services
