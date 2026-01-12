#!/bin/bash
# Script de test de l'installation sur le serveur OVH
# À exécuter sur le VPS après le déploiement

set -e

echo "=========================================="
echo "Test de l'installation"
echo "=========================================="

# Couleurs pour les messages
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Fonction pour afficher les résultats
print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Vérifier que nous sommes dans le bon répertoire
if [ ! -f "docker-compose.yml" ]; then
    print_error "Le fichier docker-compose.yml n'est pas trouvé."
    echo "Assurez-vous d'être dans le répertoire du projet."
    exit 1
fi

echo ""
echo "Étape 1: Vérification de Docker..."
if command -v docker &>/dev/null; then
    DOCKER_VERSION=$(docker --version)
    print_success "Docker est installé: $DOCKER_VERSION"
else
    print_error "Docker n'est pas installé"
    exit 1
fi

# Détecter la commande docker compose
if docker compose version &>/dev/null; then
    DOCKER_COMPOSE_CMD="docker compose"
    COMPOSE_VERSION=$(docker compose version)
    print_success "Docker Compose V2 est disponible: $COMPOSE_VERSION"
elif command -v docker-compose &>/dev/null; then
    DOCKER_COMPOSE_CMD="docker-compose"
    COMPOSE_VERSION=$(docker-compose --version)
    print_success "Docker Compose V1 est disponible: $COMPOSE_VERSION"
else
    print_error "Docker Compose n'est pas disponible"
    exit 1
fi

echo ""
echo "Étape 2: Vérification du fichier .env..."
if [ ! -f ".env" ]; then
    print_warning "Le fichier .env n'existe pas"
    echo "Créez-le à partir de .env.example avant de continuer"
    exit 1
else
    print_success "Le fichier .env existe"
    
    # Vérifier les variables essentielles
    source .env
    
    if [ -z "$OPENROUTER_API_KEY" ] || [ "$OPENROUTER_API_KEY" = "your-openrouter-api-key" ]; then
        print_warning "OPENROUTER_API_KEY n'est pas configuré"
    else
        print_success "OPENROUTER_API_KEY est configuré"
    fi
    
    if [ -z "$CLOUDFLARE_TUNNEL_SECRET" ] || [ "$CLOUDFLARE_TUNNEL_SECRET" = "your-tunnel-secret" ]; then
        print_warning "CLOUDFLARE_TUNNEL_SECRET n'est pas configuré"
    else
        print_success "CLOUDFLARE_TUNNEL_SECRET est configuré"
    fi
fi

echo ""
echo "Étape 3: Vérification de la structure du projet..."
REQUIRED_DIRS=("crewai" "n8n" "infrastructure" "scripts" "docs")
for dir in "${REQUIRED_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        print_success "Dossier $dir existe"
    else
        print_error "Dossier $dir manquant"
    fi
done

echo ""
echo "Étape 4: Vérification des fichiers Docker..."
if [ -f "docker-compose.yml" ]; then
    print_success "docker-compose.yml existe"
else
    print_error "docker-compose.yml manquant"
fi

if [ -f "crewai/Dockerfile" ]; then
    print_success "crewai/Dockerfile existe"
else
    print_error "crewai/Dockerfile manquant"
fi

echo ""
echo "Étape 5: Test de construction des images Docker..."
echo "Construction de l'image CrewAI..."
if $DOCKER_COMPOSE_CMD build crewai 2>&1 | tee /tmp/docker_build.log; then
    print_success "Image CrewAI construite avec succès"
else
    print_error "Erreur lors de la construction de l'image CrewAI"
    echo "Voir /tmp/docker_build.log pour les détails"
    exit 1
fi

echo ""
echo "Étape 6: Vérification de la syntaxe des fichiers Python..."
if command -v python3 &>/dev/null; then
    cd crewai
    if python3 -m py_compile main.py 2>/dev/null; then
        print_success "Syntaxe Python de main.py correcte"
    else
        print_warning "Erreur de syntaxe dans main.py (peut être dû aux dépendances manquantes)"
    fi
    cd ..
else
    print_warning "Python3 n'est pas disponible pour vérifier la syntaxe"
fi

echo ""
echo "Étape 7: Test de démarrage des services (dry-run)..."
# Vérifier la configuration docker-compose
if $DOCKER_COMPOSE_CMD config > /dev/null 2>&1; then
    print_success "Configuration docker-compose.yml valide"
else
    print_error "Erreur dans la configuration docker-compose.yml"
    $DOCKER_COMPOSE_CMD config
    exit 1
fi

echo ""
echo "Étape 8: Vérification des ports..."
PORTS=(8000 5678)
for port in "${PORTS[@]}"; do
    if netstat -tuln 2>/dev/null | grep -q ":$port " || ss -tuln 2>/dev/null | grep -q ":$port "; then
        print_warning "Le port $port est déjà utilisé"
    else
        print_success "Le port $port est disponible"
    fi
done

echo ""
echo "=========================================="
echo "Résumé des tests"
echo "=========================================="
echo ""
echo "Pour démarrer les services:"
echo "  $DOCKER_COMPOSE_CMD up -d"
echo ""
echo "Pour voir les logs:"
echo "  $DOCKER_COMPOSE_CMD logs -f"
echo ""
echo "Pour tester l'API CrewAI (une fois démarré):"
echo "  curl http://localhost:8000/health"
echo "  curl http://localhost:8000/agents"
echo ""
echo "Pour tester n8n (une fois démarré):"
echo "  curl http://localhost:5678/healthz"
echo ""
echo "=========================================="
