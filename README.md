# ProjetoSO-LogsAuditoria

# Simulação de Auditoria Distribuída

Projeto para validação de comunicação TCP/IP entre containers e persistência de logs no host.

## 1. Estrutura do Projeto
* **Máquina A (App):** Java 17 + Spring Boot (Cliente).
* **Máquina B (DB):** PostgreSQL 15 (Servidor).
* **Automação:** Script único (`start.sh`) que realiza build e deploy.

## 2. Pré-requisitos
* Sistema Operacional Linux (Arch Linux, Ubuntu, Debian, etc).
* Git instalado.
* Conexão com a internet (para baixar imagens Docker e dependências Maven).

## 3. Como Rodar (Automação Completa)

Este repositório contém um script orquestrador que instala dependências (Maven, Docker), compila o código Java e inicia o ambiente.

1.  **Dê permissão de execução ao script:**
    ```bash
    chmod +x start.sh
    ```

2.  **Execute o script:**
    ```bash
    ./start.sh
    ```
    *O script solicitará senha de `sudo` se precisar instalar o Docker ou Java.*

3.  **Resultado Esperado:**
    O script finalizará com a mensagem `>>> SUCESSO. Simulação rodando.` e criará a pasta `deploy/` contendo os containers ativos.

    **O que o script faz:**
    * Verifica e instala Java/Maven/Docker se necessário.
    * Compila o projeto Java (`mvn package`).
    * Gera o arquivo `docker-compose.yml`.
    * Inicia os containers.

## 4. Monitoramento e Logs

A simulação gera logs persistentes no disco da sua máquina física. Abra terminais separados para visualizar:

### A. Log de Auditoria (Arquivo Físico)
Este arquivo persiste mesmo se os containers forem destruídos. Mostra o sucesso ou falha da conexão TCP.
```bash
tail -f deploy/logs/spring.log
```

### B. Logs do Container (Aplicação)
Saída padrão do processo Java.
```bash
sudo docker logs -f maquina_a_app
```

## 5. Teste de Falha
Para provar que o log funciona, derrube o banco de dados e veja o erro aparecer no arquivo físico:

1.  Pare o banco: `sudo docker stop maquina_b_db`
2.  Veja o log: `tail -f deploy/logs/spring.log` (Deverá mostrar erros de conexão).
3.  Inicie o banco: `sudo docker start maquina_b_db` (A conexão deve voltar).

## 6. Como Parar
Para encerrar a simulação e remover os containers:
```bash
cd deploy
sudo docker compose down
```

## 7. Relatorio
Veja o [Relatorio](RELATORIO.md)

