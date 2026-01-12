FROM python:3.11-slim

WORKDIR /app

# Installer les dépendances système
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copier les fichiers de requirements
COPY requirements.txt .

# Installer les dépendances Python
RUN pip install --no-cache-dir -r requirements.txt

# Copier le code de l'application
COPY . .

# Créer les répertoires nécessaires
RUN mkdir -p /app/config /app/agents /app/logs /app/crewai

# Variables d'environnement par défaut
ENV PYTHONUNBUFFERED=1
ENV CREWAI_LOG_LEVEL=INFO
ENV PYTHONPATH=/app

# Exposer le port
EXPOSE 8000

# Commande par défaut
CMD ["python", "main.py"]
