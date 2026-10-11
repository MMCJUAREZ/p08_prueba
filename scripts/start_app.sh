#!/bin/bash
set -euo pipefail

APP_DIR="/opt/mi-app"
APP_VERSION="${APP_VERSION:-latest}"
export APP_VERSION

cd "$APP_DIR"

# Autentica Docker con ECR usando el rol de la instancia (sin credenciales hardcodeadas)
AWS_REGION="${AWS_REGION:-}"
ECR_REGISTRY="${ECR_REGISTRY:-}"
if [[ -z "$AWS_REGION" ]]; then
  echo "ERROR: AWS_REGION no está definido" >&2
  exit 1
fi
export AWS_REGION
if [[ -z "$ECR_REGISTRY" ]]; then
  ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
  ECR_REGISTRY="${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
fi
export ECR_REGISTRY

aws ecr get-login-password --region "$AWS_REGION" | \
  docker login --username AWS --password-stdin \
  "$ECR_REGISTRY"

# Descarga las nuevas imágenes (backend + frontend)
docker compose -f docker-compose.yml pull

# Detiene los contenedores actuales y levanta los nuevos
docker compose -f docker-compose.yml down --remove-orphans
docker compose -f docker-compose.yml up -d

# Limpia imágenes antiguas para no llenar el disco
docker image prune -f