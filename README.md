# Cache Test POC

Ce POC démontre une solution de cache pour les builds Docker dans un environnement où les images sont construites et poussées uniquement pendant les merge groups.

## Architecture

- **Application**: Une simple API Node.js
- **Cache Strategy**: Utilisation de Docker layer caching et registry cache
- **CI/CD**: GitHub Actions avec merge queue
- **Registry**: Docker Hub ou GitHub Container Registry

## Composants

1. **Application Node.js** (`src/`)
2. **Dockerfile optimisé** pour le cache
3. **GitHub Actions workflow** avec cache strategy
4. **Merge queue configuration**

## Fonctionnement

1. Les développeurs créent des PRs normales
2. Le merge queue valide les changements
3. Seuls les builds dans le merge queue construisent et poussent les images
4. Le cache est partagé entre les builds pour optimiser les temps de construction

## Utilisation

```bash
# Installation des dépendances
npm install

# Développement local
npm run dev

# Build de l'image Docker
docker build -t cache-test .

# Run de l'image
docker run -p 3000:3000 cache-test
```
