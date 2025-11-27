# Relatório Técnico: Simulação de Auditoria e Persistência em Sistemas Distribuídos

## 1. Objetivo

Demonstrar a viabilidade técnica de um sistema distribuído conteinerizado (Cliente Java e Servidor Banco de Dados) com foco em **resiliência de auditoria**.  
O projeto valida a comunicação TCP/IP e garante que registros de eventos (logs) sobrevivam ao ciclo de vida dos containers.

---

## 2. Arquitetura da Solução

O ambiente simula dois nós físicos isolados operando na mesma rede:

- **Nó Servidor (PostgreSQL 15)**  
  Escuta na porta `5432`. Armazena dados transacionais.

- **Nó Cliente (Spring Boot 3 / Java 17)**  
  Realiza conexões JDBC cíclicas. Gera logs de aplicação.

- **Camada de Persistência (Logs)**  
  Utilização de **Bind Mounts** para espelhar a escrita de logs do container diretamente no disco do Host (`/deploy/logs`).

---

## 3. Metodologia de Execução (Etapas)

A implementação foi automatizada via Shell Script (`start.sh`), seguindo este fluxo lógico:

1. **Provisionamento de Dependências**  
   Verificação e instalação de JDK 17, Maven e Docker Engine no Host (Arch Linux/Debian).

2. **Compilação (Build)**  
   O código Java é compilado via Maven, gerando o artefato executável (`app.jar`).

3. **Orquestração**  
   Geração dinâmica do manifesto `docker-compose.yml`, injetando variáveis de ambiente para configuração de rede e caminhos de log.

4. **Deploy**  
   Inicialização dos containers em modo *detached*, com verificação de saúde (*healthcheck*) no banco de dados antes da subida da aplicação.

---

## 4. Observações Obtidas

### 4.1. Cenário de Operação Normal

- **Comportamento:** A aplicação estabelece conexão TCP com sucesso.  
- **Registro no Host:** O arquivo `spring.log` recebe entradas com a tag **[SUCESSO]**.  
- **Conclusão:** A resolução de DNS interno do Docker e o mapeamento de volumes funcionam conforme esperado.

---

### 4.2. Cenário de Falha (Simulação de Queda)

- **Ação:** Interrupção forçada do container de banco de dados (`docker stop`).  
- **Comportamento:** A aplicação Java captura `ConnectException` ou `JDBCConnectionException`.  
- **Registro no Host:** O arquivo `spring.log` registra a falha e o stacktrace do erro.  
- **Conclusão:** O sistema de log **independe** da disponibilidade da rede ou do banco de dados alvo.

---

### 4.3. Persistência Pós-Destruição

- **Ação:** Remoção total do ambiente (`docker compose down`).  
- **Resultado:** Os arquivos em `deploy/logs/` permanecem intactos no disco.  
- **Conclusão:** A estratégia de **Bind Mount** garante auditoria forense mesmo após a perda total da infraestrutura virtualizada.

---

## 5. Contextualização: Aplicabilidade no Mundo Real

Embora ambientes corporativos utilizem sistemas centralizados de logs (ELK Stack, Splunk, Datadog), a persistência local aplicada neste projeto é fundamental por dois motivos:

---

### A. Buffer de Contingência (*Edge Buffering*)

Em cenários onde a rede entre a aplicação e o servidor central de logs falha:

- Logs enviados apenas via rede (TCP/UDP) podem ser **perdidos** durante a queda.
- Ao escrever no disco local (como neste projeto), cria-se um *buffer*.  
  Um agente coletor (Filebeat, Fluentd etc.) lê o arquivo e reenvia ao servidor central assim que a conexão retorna.

---

### B. Diagnóstico de Boot

Se o container falhar antes de conectar na rede de logs centralizada, o arquivo local é a **única fonte de diagnóstico**, permitindo análise de erros de inicialização (ex.: *CrashLoopBackOff*).

---
