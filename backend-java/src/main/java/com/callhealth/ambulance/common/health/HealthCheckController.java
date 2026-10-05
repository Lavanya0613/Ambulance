package com.callhealth.ambulance.common.health;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.Instant;
import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/health")
public class HealthCheckController {

    private static final Logger log = LoggerFactory.getLogger(HealthCheckController.class);

    private final JdbcTemplate jdbcTemplate;
    private final StringRedisTemplate redisTemplate;

    public HealthCheckController(JdbcTemplate jdbcTemplate, StringRedisTemplate redisTemplate) {
        this.jdbcTemplate = jdbcTemplate;
        this.redisTemplate = redisTemplate;
    }

    @GetMapping
    public ResponseEntity<Map<String, Object>> checkHealth() {
        Map<String, Object> response = new HashMap<>();
        response.put("status", "UP");
        response.put("service", "ambulance-backend-java");
        response.put("timestamp", Instant.now().toString());

        Map<String, Object> details = new HashMap<>();

        // Test PostgreSQL Connectivity
        try {
            Integer dbResult = jdbcTemplate.queryForObject("SELECT 1", Integer.class);
            details.put("database", Map.of(
                "status", "UP",
                "database", "PostgreSQL",
                "responsive", dbResult != null && dbResult == 1
            ));
        } catch (Exception e) {
            log.error("Database health check failed: {}", e.getMessage());
            details.put("database", Map.of(
                "status", "DOWN",
                "error", e.getMessage()
            ));
            response.put("status", "DOWN");
        }

        // Test Redis Connectivity
        try {
            String pingResult = redisTemplate.getConnectionFactory().getConnection().ping();
            details.put("redis", Map.of(
                "status", "UP",
                "ping", pingResult != null ? pingResult : "PONG"
            ));
        } catch (Exception e) {
            log.error("Redis health check failed: {}", e.getMessage());
            details.put("redis", Map.of(
                "status", "DOWN",
                "error", e.getMessage()
            ));
            response.put("status", "DOWN");
        }

        response.put("components", details);

        if ("DOWN".equals(response.get("status"))) {
            return ResponseEntity.status(503).body(response);
        }

        return ResponseEntity.ok(response);
    }
}
