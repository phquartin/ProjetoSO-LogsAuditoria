# ProjetoSO-LogsAuditoria

# Guia de Simulação: Auditoria de Logs em Sistema Distribuído

Este guia descreve os passos para executar, validar e encerrar a simulação de comunicação TCP/IP entre um container Cliente (Java/Spring Boot) e um container Servidor (PostgreSQL), com foco na persistência de logs de auditoria no Host.

## 1. Pré-requisitos

* **SO:** Linux (Testado em Arch Linux e Ubuntu).
* **Pacotes Necessários:**
    * `git`
    * `docker` e `docker-compose` (ou plugin `docker-compose-plugin`)
    * `java-17-openjdk` (JDK 17)
    * `maven`

## 2. Instalação e Configuração

1.  **Clone o repositório:**
    ```bash
    git clone [https://github.com/phquartin/ProjetoSO-LogsAuditoria.git](https://github.com/phquartin/ProjetoSO-LogsAuditoria.git)
    cd ProjetoSO-LogsAuditoria
    ```

2.  **Conceda permissão de execução ao orquestrador:**
    ```bash
    chmod +x start.sh
    ```

## 3. Execução da Simulação

Execute o script de automação única. Ele irá verificar dependências, compilar o código Java, construir as imagens Docker e iniciar o ambiente.

```bash
./start.sh
