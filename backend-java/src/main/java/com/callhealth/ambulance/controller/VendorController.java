package com.callhealth.ambulance.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.*;

@RestController
@RequestMapping("/vendor")
@CrossOrigin(originPatterns = "*")
public class VendorController {

    private final List<Map<String, Object>> drivers = new ArrayList<>(List.of(
            new HashMap<>(Map.of("id", "drv-001", "name", "Rajesh Kumar", "phone", "+919876543210", "vehicleNumber", "KA-01-EA-1234", "ambulanceType", "ICU Advanced", "status", "AVAILABLE")),
            new HashMap<>(Map.of("id", "drv-002", "name", "Suresh Sharma", "phone", "+919876543211", "vehicleNumber", "KA-01-EA-5678", "ambulanceType", "Basic Life Support", "status", "BUSY")),
            new HashMap<>(Map.of("id", "drv-003", "name", "Amit Patel", "phone", "+919876543212", "vehicleNumber", "KA-01-EA-9012", "ambulanceType", "Patient Transport", "status", "AVAILABLE"))
    ));

    private final List<Map<String, Object>> ambulances = new ArrayList<>(List.of(
            new HashMap<>(Map.of("id", "amb-001", "vehicleNumber", "KA-01-EA-1234", "ambulanceType", "ICU Advanced", "status", "AVAILABLE", "driverName", "Rajesh Kumar")),
            new HashMap<>(Map.of("id", "amb-002", "vehicleNumber", "KA-01-EA-5678", "ambulanceType", "Basic Life Support", "status", "BUSY", "driverName", "Suresh Sharma")),
            new HashMap<>(Map.of("id", "amb-003", "vehicleNumber", "KA-01-EA-9012", "ambulanceType", "Patient Transport", "status", "AVAILABLE", "driverName", "Amit Patel"))
    ));

    @GetMapping("/dashboard")
    public ResponseEntity<Map<String, Object>> getDashboard() {
        Map<String, Object> metrics = Map.of(
                "pendingRequests", 5,
                "assignedRequests", 3,
                "activeTrips", 2,
                "completedToday", 12,
                "availableDrivers", 4,
                "availableAmbulances", 6
        );

        Map<String, Object> charts = Map.of(
                "hourlyRequests", List.of(2, 4, 3, 7, 5, 8, 4, 6),
                "completionRate", 94.5
        );

        Map<String, Object> tables = Map.of(
                "latestRequests", List.of(),
                "activeTrips", List.of()
        );

        Map<String, Object> response = new HashMap<>();
        response.put("metrics", metrics);
        response.put("charts", charts);
        response.put("tables", tables);
        response.put("totalBookings", 42);
        response.put("activeTrips", 2);
        response.put("availableDrivers", 4);
        response.put("fleetSize", 6);
        response.put("revenueToday", 14500);

        return ResponseEntity.ok(response);
    }

    @GetMapping("/drivers")
    public ResponseEntity<List<Map<String, Object>>> getDrivers(
            @RequestParam(value = "search", required = false) String search,
            @RequestParam(value = "status", required = false) String status
    ) {
        List<Map<String, Object>> result = drivers.stream()
                .filter(d -> search == null || search.isBlank() || String.valueOf(d.get("name")).toLowerCase().contains(search.toLowerCase()) || String.valueOf(d.get("phone")).contains(search))
                .filter(d -> status == null || status.isBlank() || status.equalsIgnoreCase(String.valueOf(d.get("status"))))
                .toList();
        return ResponseEntity.ok(result);
    }

    @PostMapping("/drivers")
    public ResponseEntity<Map<String, Object>> createDriver(@RequestBody Map<String, Object> body) {
        String id = "drv-" + (drivers.size() + 1);
        Map<String, Object> newDriver = new HashMap<>(body);
        newDriver.put("id", id);
        newDriver.put("status", "AVAILABLE");
        drivers.add(newDriver);
        return ResponseEntity.ok(newDriver);
    }

    @PatchMapping("/drivers/{id}/status")
    public ResponseEntity<Map<String, Object>> updateDriverStatus(
            @PathVariable("id") String id,
            @RequestBody Map<String, String> body
    ) {
        for (Map<String, Object> d : drivers) {
            if (Objects.equals(d.get("id"), id)) {
                d.put("status", body.get("status"));
                return ResponseEntity.ok(d);
            }
        }
        return ResponseEntity.notFound().build();
    }

    @GetMapping("/ambulances")
    public ResponseEntity<List<Map<String, Object>>> getAmbulances(
            @RequestParam(value = "search", required = false) String search,
            @RequestParam(value = "status", required = false) String status
    ) {
        List<Map<String, Object>> result = ambulances.stream()
                .filter(a -> search == null || search.isBlank() || String.valueOf(a.get("vehicleNumber")).toLowerCase().contains(search.toLowerCase()))
                .filter(a -> status == null || status.isBlank() || status.equalsIgnoreCase(String.valueOf(a.get("status"))))
                .toList();
        return ResponseEntity.ok(result);
    }

    @PostMapping("/ambulances")
    public ResponseEntity<Map<String, Object>> createAmbulance(@RequestBody Map<String, Object> body) {
        String id = "amb-" + (ambulances.size() + 1);
        Map<String, Object> newAmb = new HashMap<>(body);
        newAmb.put("id", id);
        newAmb.put("status", "AVAILABLE");
        ambulances.add(newAmb);
        return ResponseEntity.ok(newAmb);
    }

    @PatchMapping("/ambulances/{id}/status")
    public ResponseEntity<Map<String, Object>> updateAmbulanceStatus(
            @PathVariable("id") String id,
            @RequestBody Map<String, String> body
    ) {
        for (Map<String, Object> a : ambulances) {
            if (Objects.equals(a.get("id"), id)) {
                a.put("status", body.get("status"));
                return ResponseEntity.ok(a);
            }
        }
        return ResponseEntity.notFound().build();
    }
}
