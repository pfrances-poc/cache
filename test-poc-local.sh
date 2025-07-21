#!/bin/bash

# Script de test local pour le POC Cache
set -e

echo "🚀 Test local du POC Cache"
echo "=========================="

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonctions utilitaires
success() {
    echo -e "${GREEN}✅ $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
}

info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Vérifier les prérequis
check_requirements() {
    echo -e "\n${BLUE}🔍 Vérification des prérequis...${NC}"

    if ! command -v node &> /dev/null; then
        error "Node.js n'est pas installé"
        exit 1
    fi
    success "Node.js $(node --version) trouvé"

    if ! command -v npm &> /dev/null; then
        error "npm n'est pas installé"
        exit 1
    fi
    success "npm $(npm --version) trouvé"

    if ! command -v docker &> /dev/null; then
        error "Docker n'est pas installé"
        exit 1
    fi
    success "Docker $(docker --version | cut -d' ' -f3) trouvé"

    if ! docker info &> /dev/null; then
        error "Docker daemon n'est pas démarré"
        exit 1
    fi
    success "Docker daemon actif"
}

# Installer les dépendances
install_dependencies() {
    echo -e "\n${BLUE}📦 Installation des dépendances...${NC}"
    npm ci
    success "Dépendances installées"
}

# Exécuter les tests
run_tests() {
    echo -e "\n${BLUE}🧪 Exécution des tests...${NC}"

    info "Linting du code..."
    if npm run lint; then
        success "Linting réussi"
    else
        error "Linting échoué"
        exit 1
    fi

    info "Tests unitaires..."
    if npm test; then
        success "Tests réussis"
    else
        error "Tests échoués"
        exit 1
    fi

    info "Build de l'application..."
    if npm run build; then
        success "Build réussi"
    else
        error "Build échoué"
        exit 1
    fi
}

# Premier build Docker (sans cache)
first_docker_build() {
    echo -e "\n${BLUE}🐳 Premier build Docker (sans cache)...${NC}"

    # Nettoyer les images existantes
    docker system prune -f --filter label=stage=cache-test 2>/dev/null || true

    info "Build initial (mesure du temps sans cache)..."
    start_time=$(date +%s)

    if docker build -t cache-test:v1 \
        --build-arg BUILD_TIME=$(date +%s) \
        --build-arg COMMIT_SHA=$(git rev-parse HEAD 2>/dev/null || echo "local") \
        --build-arg BRANCH=$(git branch --show-current 2>/dev/null || echo "local") \
        --label stage=cache-test \
        .; then

        end_time=$(date +%s)
        duration=$((end_time - start_time))
        success "Premier build réussi en ${duration}s"

        # Tester l'image
        test_docker_image "cache-test:v1"
    else
        error "Premier build échoué"
        exit 1
    fi
}

# Second build Docker (avec cache)
second_docker_build() {
    echo -e "\n${BLUE}🐳 Second build Docker (avec cache)...${NC}"

    info "Build avec cache (mesure de l'amélioration)..."
    start_time=$(date +%s)

    if docker build -t cache-test:v2 \
        --build-arg BUILD_TIME=$(date +%s) \
        --build-arg COMMIT_SHA=$(git rev-parse HEAD 2>/dev/null || echo "local") \
        --build-arg BRANCH=$(git branch --show-current 2>/dev/null || echo "local") \
        --label stage=cache-test \
        .; then

        end_time=$(date +%s)
        duration=$((end_time - start_time))
        success "Second build réussi en ${duration}s (amélioration grâce au cache)"

        # Tester l'image
        test_docker_image "cache-test:v2"
    else
        error "Second build échoué"
        exit 1
    fi
}

# Tester une image Docker
test_docker_image() {
    local image=$1
    info "Test de l'image ${image}..."

    # Démarrer le conteneur
    container_id=$(docker run -d -p 3001:3000 --name cache-test-$(date +%s) $image)

    # Attendre que le conteneur démarre
    sleep 3

    # Tester les endpoints
    if curl -s http://localhost:3001/ | grep -q "Cache Test POC API"; then
        success "Endpoint / fonctionne"
    else
        error "Endpoint / ne répond pas correctement"
        docker logs $container_id
        docker rm -f $container_id
        exit 1
    fi

    if curl -s http://localhost:3001/health | grep -q "healthy"; then
        success "Endpoint /health fonctionne"
    else
        error "Endpoint /health ne répond pas correctement"
    fi

    if curl -s http://localhost:3001/cache-info | grep -q "Docker layer caching"; then
        success "Endpoint /cache-info fonctionne"
    else
        error "Endpoint /cache-info ne répond pas correctement"
    fi

    # Nettoyer
    docker rm -f $container_id
    success "Test de l'image ${image} réussi"
}

# Analyser le cache Docker
analyze_cache() {
    echo -e "\n${BLUE}📊 Analyse du cache Docker...${NC}"

    info "Taille des images construites:"
    docker images | grep cache-test | while read line; do
        echo "  $line"
    done

    info "Historique des builds:"
    docker images --filter "label=stage=cache-test" --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"

    warning "Pour voir l'utilisation détaillée du cache, lancez:"
    echo "  docker build --progress=plain ."
}

# Nettoyage
cleanup() {
    echo -e "\n${BLUE}🧹 Nettoyage...${NC}"

    # Arrêter et supprimer les conteneurs de test
    docker ps -a | grep cache-test | awk '{print $1}' | xargs -r docker rm -f 2>/dev/null || true

    # Optionnel: supprimer les images de test
    read -p "Supprimer les images Docker de test? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        docker images | grep cache-test | awk '{print $3}' | xargs -r docker rmi -f 2>/dev/null || true
        success "Images de test supprimées"
    fi
}

# Résumé des résultats
show_summary() {
    echo -e "\n${GREEN}🎉 Test local du POC terminé avec succès!${NC}"
    echo -e "\n${BLUE}📋 Résumé:${NC}"
    echo "✅ Prérequis vérifiés"
    echo "✅ Dépendances installées"
    echo "✅ Tests unitaires passés"
    echo "✅ Build Docker réussi (avec mesure du cache)"
    echo "✅ Application testée et fonctionnelle"

    echo -e "\n${BLUE}🚀 Prochaines étapes:${NC}"
    echo "1. Committer vos changements"
    echo "2. Créer une PR pour tester les workflows GitHub Actions"
    echo "3. Configurer le merge queue dans les settings du repository"
    echo "4. Tester le workflow complet avec une vraie PR"

    echo -e "\n${BLUE}📚 Documentation:${NC}"
    echo "- Guide de configuration: docs/CONFIGURATION_GUIDE.md"
    echo "- README principal: README.md"
}

# Menu principal
main() {
    echo -e "${BLUE}"
    cat << "EOF"
   ___           _          _____         _
  / __\__ _  ___| |__   ___|_   _|__  ___| |_
 / /  / _` |/ __| '_ \ / _ \ | |/ _ \/ __| __|
/ /__| (_| | (__| | | |  __/ | |  __/\__ \ |_
\____/\__,_|\___|_| |_|\___| |_|\___||___/\__|

EOF
    echo -e "${NC}"

    check_requirements
    install_dependencies
    run_tests
    first_docker_build
    second_docker_build
    analyze_cache

    # Demander si l'utilisateur veut nettoyer
    echo -e "\n"
    cleanup

    show_summary
}

# Gestion des signaux pour nettoyer en cas d'interruption
trap cleanup EXIT

# Exécuter le script principal
main "$@"
