package com.callhealth.ambulance.service;

import com.callhealth.ambulance.dto.EtaResult;
import com.callhealth.ambulance.util.GeoUtil;
import org.springframework.stereotype.Service;

@Service
public class EtaService {

    /**
     * Calculates dynamic ETA and distance to target.
     * @param currentLat Current latitude of the ambulance
     * @param currentLng Current longitude of the ambulance
     * @param targetLat Target latitude
     * @param targetLng Target longitude
     * @param currentSpeedKmph Current speed. Defaults to 40 if 0 or null.
     * @param arrivalThresholdKm Distance in km under which the ambulance is considered arrived (default 0.05 = 50m)
     */
    public EtaResult calculateEta(
            double currentLat,
            double currentLng,
            double targetLat,
            double targetLng,
            Double currentSpeedKmph,
            double arrivalThresholdKm
    ) {
        double distanceKm = GeoUtil.haversineDistanceKm(currentLat, currentLng, targetLat, targetLng);

        // Check if arrived
        if (distanceKm <= arrivalThresholdKm) {
            return new EtaResult(0, distanceKm, true);
        }

        double speed = (currentSpeedKmph != null && currentSpeedKmph > 0) ? currentSpeedKmph : 40.0;
        int etaSeconds = (int) Math.floor((distanceKm / speed) * 3600.0);

        return new EtaResult(Math.max(0, etaSeconds), distanceKm, false);
    }

    public EtaResult calculateEta(double currentLat, double currentLng, double targetLat, double targetLng, Double currentSpeedKmph) {
        return calculateEta(currentLat, currentLng, targetLat, targetLng, currentSpeedKmph, 0.05);
    }
}
