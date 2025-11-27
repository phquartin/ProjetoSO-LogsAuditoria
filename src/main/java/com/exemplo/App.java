package com.exemplo;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.context.annotation.Bean;

@SpringBootApplication
public class App {
    private static final Logger logger = LoggerFactory.getLogger(App.class);

    public static void main(String[] args) {
        SpringApplication.run(App.class, args);
    }

    @Bean
    public CommandLineRunner executaTeste(JdbcTemplate jdbcTemplate) {
        return args -> {
            while(true) {
                try {
                    logger.info(">>> [AUDITORIA] Tentando conectar ao Banco de Dados...");
                    jdbcTemplate.execute("SELECT 1");
                    logger.info(">>> [AUDITORIA] SUCESSO: Conexão TCP estabelecida e Query executada.");
                } catch (Exception e) {
                    logger.error(">>> [AUDITORIA] FALHA: Não foi possível conectar ao Banco.", e);
                }
                Thread.sleep(5000); // Tenta a cada 5 segundos
            }
        };
    }
}
