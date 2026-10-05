package com.callhealth.ambulance.config;

import com.corundumstudio.socketio.SocketIOServer;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class SocketIOConfig {

    private static final Logger log = LoggerFactory.getLogger(SocketIOConfig.class);

    @Value("${socketio.host:0.0.0.0}")
    private String host;

    @Value("${socketio.port:8085}")
    private int port;

    @Bean(destroyMethod = "stop")
    public SocketIOServer socketIOServer() {
        com.corundumstudio.socketio.Configuration config = new com.corundumstudio.socketio.Configuration();
        config.setHostname(host);
        config.setPort(port);
        config.setContext("/ws");
        config.setAllowHeaders("*");
        config.setPingInterval(25000);
        config.setPingTimeout(60000);
        config.setOrigin("*");

        SocketIOServer server = new SocketIOServer(config);
        try {
            server.start();
            log.info("[SOCKET.IO] SocketIO server started on {}:{} with context /ws", host, port);
        } catch (Exception e) {
            log.warn("[SOCKET.IO] SocketIO server failed to bind on port {}: {}", port, e.getMessage());
        }
        return server;
    }
}
