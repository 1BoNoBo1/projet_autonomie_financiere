#!/bin/bash
# Script de test de l'API CrewAI
# À exécuter après le démarrage des services

set -e

API_URL="${1:-http://localhost:8000}"

echo "=========================================="
echo "Test de l'API CrewAI"
echo "API URL: $API_URL"
echo "=========================================="

# Couleurs
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${YELLOW}ℹ${NC} $1"
}

# Test 1: Health check
echo ""
echo "Test 1: Health check..."
if curl -s -f "$API_URL/health" > /dev/null; then
    RESPONSE=$(curl -s "$API_URL/health")
    print_success "Health check réussi"
    echo "Réponse: $RESPONSE"
else
    print_error "Health check échoué"
    exit 1
fi

# Test 2: Root endpoint
echo ""
echo "Test 2: Root endpoint..."
RESPONSE=$(curl -s "$API_URL/")
print_success "Root endpoint accessible"
echo "Réponse: $RESPONSE"

# Test 3: Liste des agents
echo ""
echo "Test 3: Liste des agents..."
RESPONSE=$(curl -s "$API_URL/agents")
print_success "Liste des agents récupérée"
echo "$RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$RESPONSE"

# Test 4: Liste des outils
echo ""
echo "Test 4: Liste des outils..."
RESPONSE=$(curl -s "$API_URL/tools")
print_success "Liste des outils récupérée"
echo "$RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$RESPONSE"

# Test 5: Exécution d'une tâche simple (optionnel)
echo ""
echo "Test 5: Exécution d'une tâche de recherche..."
TASK_JSON='{
  "task_type": "research",
  "description": "Rechercher des informations sur les revenus passifs en 2024",
  "context": {}
}'

RESPONSE=$(curl -s -X POST "$API_URL/execute" \
    -H "Content-Type: application/json" \
    -d "$TASK_JSON")

if echo "$RESPONSE" | grep -q "success"; then
    print_success "Tâche exécutée avec succès"
    echo "$RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$RESPONSE"
else
    print_error "Erreur lors de l'exécution de la tâche"
    echo "$RESPONSE"
fi

echo ""
echo "=========================================="
echo "Tests terminés"
echo "=========================================="
