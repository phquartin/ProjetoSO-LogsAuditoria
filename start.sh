#!/bin/bash
set -e

# Detecta gerenciador de pacotes (pacman para Arch, apt para Debian/Ubuntu)
if command -v pacman &> /dev/null; then
    PKG_MGR="pacman -S --noconfirm"
    JAVA_PKG="jdk17-openjdk maven"
elif command -v apt-get &> /dev/null; then
    PKG_MGR="apt-get install -y"
    JAVA_PKG="openjdk-17-jdk maven"
else
    echo "Gerenciador de pacotes não suportado automaticamente. Instale Java 17 e Maven manualmente."
    exit 1
fi

# 1. Instalação de Dependências (Java/Maven)
if ! command -v mvn &> /dev/null; then
    echo ">>> Instalando Maven e JDK..."
    sudo $PKG_MGR $JAVA_PKG
fi

# 2. Instalação do Docker (se necessário)
if ! command -v docker &> /dev/null; then
    echo ">>> Instalando Docker..."
    curl -fsSL https://get.docker.com | sh
    sudo systemctl enable --now docker
fi

# 3. Build do Projeto Java
echo ">>> Compilando aplicação Java..."
mvn clean package -DskipTests -q
JAR_PATH=$(find target -name "*.jar" | head -n 1)

# 4. Preparação do Ambiente Docker
mkdir -p deploy/logs deploy/pgdata
cp "$JAR_PATH" deploy/app.jar

# 5. Criação do docker-compose.yml unificado
cat <<EOF > deploy/docker-compose.yml
version: '3.8'

services:
  # Simulando Maquina B
  db_server:
    image: postgres:15-alpine
    container_name: maquina_b_db
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

  # Simulando Maquina A
  app_client:
    image: eclipse-temurin:17-jdk-alpine
    container_name: maquina_a_app
    depends_on:
      db_server:
        condition: service_healthy
    volumes:
      - ./app.jar:/app.jar
      - ./logs:/app/logs
    environment:
      # Conecta usando o nome do serviço docker (DNS interno)
      SPRING_DATASOURCE_URL: jdbc:postgresql://db_server:5432/sistema_db
      SPRING_DATASOURCE_USERNAME: user_prod
      SPRING_DATASOURCE_PASSWORD: senha_forte
      LOGGING_FILE_NAME: /app/logs/spring.log
    command: ["java", "-jar", "/app.jar"]
EOF

# 6. Execução
echo ">>> Iniciando containers..."
cd deploy
sudo docker compose up -d

echo ">>> TUDO PRONTO."
echo ">>> Logs disponíveis em: $(pwd)/logs/spring.log"
echo ">>> Para ver logs em tempo real: tail -f logs/spring.log"
