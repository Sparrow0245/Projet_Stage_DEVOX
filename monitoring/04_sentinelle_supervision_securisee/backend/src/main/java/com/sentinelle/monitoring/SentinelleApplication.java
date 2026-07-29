package com.sentinelle.monitoring;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@EnableScheduling
public class SentinelleApplication {

    public static void main(String[] args) {
        SpringApplication.run(SentinelleApplication.class, args);
    }
}
