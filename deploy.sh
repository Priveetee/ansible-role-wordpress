#!/bin/bash

echo "=== WordPress Deployment Script ==="

# Couleurs
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
  echo -e "${GREEN}[$(date +'%H:%M:%S')]${NC} $1"
}

error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

warning() {
  echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Arrêt des conteneurs existants
log "Arrêt des conteneurs existants..."
docker-compose down 2>/dev/null || true

# Démarrage des conteneurs
log "Démarrage des conteneurs..."
docker-compose up -d

if [ $? -ne 0 ]; then
  error "Échec du démarrage des conteneurs"
  exit 1
fi

# Attente
log "Attente de la disponibilité des conteneurs..."
sleep 20

# Test de connectivité SSH
log "Test de connectivité SSH..."
for i in {1..5}; do
  if ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no -p 2281 root@localhost 'echo "Ubuntu ready"' 2>/dev/null; then
    log "Ubuntu container accessible"
    break
  fi
  if [ $i -eq 5 ]; then
    error "Impossible de se connecter au conteneur Ubuntu"
    exit 1
  fi
  sleep 5
done

for i in {1..5}; do
  if ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no -p 2282 root@localhost 'echo "Rocky ready"' 2>/dev/null; then
    log "Rocky container accessible"
    break
  fi
  if [ $i -eq 5 ]; then
    error "Impossible de se connecter au conteneur Rocky"
    exit 1
  fi
  sleep 5
done

# Test Ansible
log "Test de connectivité Ansible..."
ansible all -m ping -o

# Lancement du playbook
log "Lancement du playbook WordPress..."
ansible-playbook site.yml

if [ $? -eq 0 ]; then
  log "Déploiement WordPress terminé avec succès!"
  echo ""
  echo "============================================="
  echo "         DÉPLOIEMENT WORDPRESS RÉUSSI       "
  echo "============================================="
  echo ""
  echo "🌐 ACCÈS AUX SITES:"
  echo "   • Ubuntu : http://localhost:8081"
  echo "   • Rocky  : http://localhost:8082"
  echo ""
  echo "🗄️  INFORMATIONS BASE DE DONNÉES:"
  echo "   • Database : wordpress"
  echo "   • User     : wpuser"
  echo "   • Password : localhost123"
  echo "   • Host     : localhost"
  echo ""
  echo "🚀 PROCHAINES ÉTAPES:"
  echo "   1. Ouvrez votre navigateur web"
  echo "   2. Allez sur http://localhost:8081 ou 8082"
  echo "   3. Complétez l'installation WordPress"
  echo "   4. Créez votre compte administrateur"
  echo ""
  echo "============================================="
else
  error "Échec du déploiement WordPress"
  docker-compose ps
  exit 1
fi
