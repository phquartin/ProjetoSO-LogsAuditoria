#!/bin/bash

DB_IP=$1

if [ -z "$DB_IP" ]; then
    echo "ERRO: Informe o IP da Máquina B."
    echo "Exemplo: ./setup_client.sh 192.168.0.20"
    exit 1
fi

# 1. Instalação do Docker
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com | sh
    systemctl enable --now docker
fi

# 2. Estrutura de Diretórios
BASE_DIR="/deploy/app"
mkdir -p "$BASE_DIR/logs"
cd "$BASE_DIR"

# 3. Criação do docker-compose.yml
cat <<EOF > docker-compose.yml
version: '3.8'

services:
  backend:
    image: eclipse-temurin:17-jdk-alpine
    container_name: spring_app
    restart: always
    working_dir: /app
    volumes:
      - ./app.jar:/app/app.jar
      - ./logs:/app/logs
    ports:
      - "8080:8080"
    environment:
      SPRING_DATASOURCE_URL: jdbc:postgresql://${DB_IP}:5432/sistema_db
      SPRING_DATASOURCE_USERNAME: user_prod
      SPRING_DATASOURCE_PASSWORD: senha_forte_db
      LOGGING_FILE_NAME: /app/logs/spring.log
    command: ["java", "-jar", "app.jar"]
    logging:
      driver: "json-file"
      options:
        max-size: "50m"
        max-file: "5"
EOF

echo "Configuração concluída em $BASE_DIR."
echo "IMPORTANTE: Copie seu 'app.jar' para $BASE_DIR antes de rodar 'docker compose up -d'."
