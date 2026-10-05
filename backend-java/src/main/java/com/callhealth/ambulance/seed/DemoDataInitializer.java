package com.callhealth.ambulance.seed;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

@Component
@ConditionalOnProperty(name = "app.seed.demo.enabled", havingValue = "true")
public class DemoDataInitializer implements CommandLineRunner {

    private static final Logger log = LoggerFactory.getLogger(DemoDataInitializer.class);

    private final DemoSeedService demoSeedService;

    public DemoDataInitializer(DemoSeedService demoSeedService) {
        this.demoSeedService = demoSeedService;
    }

    @Override
    public void run(String... args) throws Exception {
        log.info("[INITIALIZER] Property app.seed.demo.enabled=true detected. Triggering automatic local demo data seed...");
        demoSeedService.seedDemoData("demo-patient-uuid");
    }
}
