# Dockerfile optimisé pour le cache Docker avec multi-stage build
FROM node:18-alpine AS builder

WORKDIR /app

# Copier les fichiers de dépendances en premier (pour optimiser le cache)
COPY package*.json ./

# Installer toutes les dépendances (dev + prod pour les tests)
RUN npm ci

# Copier le code source
COPY . .

# Executer les tests
RUN npm test

# Stage de production
FROM node:18-alpine AS production

WORKDIR /app

# Copier les fichiers de dépendances
COPY package*.json ./

# Installer seulement les dépendances de production
RUN npm ci --only=production && npm cache clean --force

# Copier le code source depuis le stage builder
COPY --from=builder /app/src ./src

# Créer un utilisateur non-root pour la sécurité
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodeuser -u 1001 && \
    chown -R nodeuser:nodejs /app

USER nodeuser

# Exposer le port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD node -e "const http=require('http');http.get('http://localhost:3000/health',(r)=>process.exit(r.statusCode===200?0:1)).on('error',()=>process.exit(1))"

# Démarrer l'application
CMD ["npm", "start"]
