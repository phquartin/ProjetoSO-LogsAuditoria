#!/bin/bash
set -e

# Detecta gerenciador de pacotes e define pacotes
if command -v pacman &> /dev/null; then
    PKG_MGR="pacman -S --noconfirm"
    # Adicionado 'docker-compose' na lista
    DEPENDENCIES="jdk17-openjdk maven docker docker-compose"
elif command -v apt-get &> /dev/null; then
    PKG_MGR="apt-get install -y"
    DEPENDENCIES="openjdk-17-jdk maven docker.io docker-compose-plugin"
else
    echo "Gerenciador não suportado. Instale Java 17, Maven e Docker Compose manualmente."
    exit 1
fi

# 1. Instalação de Dependências
echo ">>> Verificando e instalando dependências..."
sudo $PKG_MGR $DEPENDENCIES

# Habilita serviço Docker
sudo systemctl enable --now docker

# 2. Build do Projeto Java
echo ">>> Compilando aplicação Java..."
mvn clean package -DskipTests -q
JAR_PATH=$(find target -name "*.jar" | head -n 1)

if [ -z "$JAR_PATH" ]; then
    echo "ERRO: Build falhou. Arquivo .jar não encontrado."
    exit 1
fi

# 3. Preparação do Ambiente
mkdir -p deploy/logs deploy/pgdata
cp "$JAR_PATH" deploy/app.jar

# 4. Criação do docker-compose.yml
cat <<EOF > deploy/docker-compose.yml
version: '3.8'

services:
  # Servidor Banco de Dados
  db_server:
    image: postgres:15-alpine
    container_name: maquina_b_db
    restart: always
    environment:
      POSTGRES_USER: user_prod
      POSTGRES_PASSWORD: senha_forte
      POSTGRES_DB: sistema_db
    ports:
      - "5432:5432"
    volumes:
      - ./pgdata:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U user_prod -d sistema_db"]
      interval: 5s
      timeout: 5s
      retries: 5

  # Cliente Aplicação
  app_client:
    image: eclipse-temurin:17-jdk-alpine
    container_name: maquina_a_app
    restart: always
    depends_on:
      db_server:
        condition: service_healthy
    volumes:
      - ./app.jar:/app.jar
      - ./logs:/app/logs
    environment:
      # Conecta usando o nome do serviço (DNS do Docker)
      SPRING_DATASOURCE_URL: jdbc:postgresql://db_server:5432/sistema_db
      SPRING_DATASOURCE_USERNAME: user_prod
      SPRING_DATASOURCE_PASSWORD: senha_forte
      LOGGING_FILE_NAME: /app/logs/spring.log
    command: ["java", "-jar", "/app.jar"]
EOF

# 5. Execução (Tenta com plugin v2, se falhar usa o v1 com hífen)
echo ">>> Iniciando containers..."
cd deploy

if docker compose version &> /dev/null; then
    CMD="docker compose"
else
    CMD="docker-compose"
fi

echo ">>> Usando comando: $CMD"
sudo $CMD up -d --force-recreate

echo ">>> SUCESSO! O sistema está rodando."
echo ">>> Acompanhe os logs com: tail -f logs/spring.log"
