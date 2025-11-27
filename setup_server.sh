# !/bin/bash

# 1. Instalação do Docker (Genérico para Linux)
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com | sh
    systemctl enable --now docker
fi

# 2. Estrutura de Diretórios
BASE_DIR="/deploy/postgres"
mkdir -p "$BASE_DIR/data"
cd "$BASE_DIR"

# 3. Criação do docker-compose.yml
cat <<EOF > docker-compose.yml
version: '3.8'

services:
  database:
    image: postgres:15-alpine
    container_name: pg_server
    restart: always
    ports:
      - "5432:5432"
    environment:
      POSTGRES_USER: "user_prod"
      POSTGRES_PASSWORD: "senha_forte_db"
      POSTGRES_DB: "sistema_db"
    volumes:
      - ./data:/var/lib/postgresql/data
    logging:
      driver: "json-file"
      options:
        max-size: "50m"
        max-file: "5"
EOF

# 4. Configuração de Firewall (UFW)
if command -v ufw > /dev/null; then
    ufw allow 5432/tcp
    ufw reload
    echo "Porta 5432 liberada no UFW."
fi

# 5. Execução
docker compose up -d
echo "Banco de dados rodando. IP da Máquina: $(hostname -I | awk '{print $1}')"
