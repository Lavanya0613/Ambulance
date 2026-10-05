package com.callhealth.ambulance.util;

public class GeoUtil {

    private GeoUtil() {}

    /**
     * Calculates the Haversine distance between two geographic coordinates in kilometers.
     * @param lat1 Latitude of the first point
     * @param lon1 Longitude of the first point
     * @param lat2 Latitude of the second point
     * @param lon2 Longitude of the second point
     * @returns Distance in kilometers
     */
    public static double haversineDistanceKm(double lat1, double lon1, double lat2, double lon2) {
        double R = 6371; // Radius of the earth in km
        double dLat = Math.toRadians(lat2 - lat1);
        double dLon = Math.toRadians(lon2 - lon1);
        double a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
                Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2)) *
                Math.sin(dLon / 2) * Math.sin(dLon / 2);
        double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        return R * c;
    }

    /**
     * Calculates the Haversine distance between two geographic coordinates in meters.
     */
    public static double haversineDistanceMeters(double lat1, double lon1, double lat2, double lon2) {
        return haversineDistanceKm(lat1, lon1, lat2, lon2) * 1000.0;
    }

    /**
     * Calculates initial bearing (heading angle) in degrees (0..360) from point 1 to point 2.
     */
    public static double calculateBearingDeg(double lat1, double lon1, double lat2, double lon2) {
        double φ1 = Math.toRadians(lat1);
        double φ2 = Math.toRadians(lat2);
        double Δλ = Math.toRadians(lon2 - lon1);

        double y = Math.sin(Δλ) * Math.cos(φ2);
        double x = Math.cos(φ1) * Math.sin(φ2) - Math.sin(φ1) * Math.cos(φ2) * Math.cos(Δλ);
        double θ = Math.atan2(y, x);
        return (Math.toDegrees(θ) + 360) % 360;
    }

    /**
     * Moves a coordinate from (lat1, lon1) towards (lat2, lon2) by stepDistanceMeters.
     * If the distance to target is <= stepDistanceMeters, returns the target coordinates [lat2, lon2].
     * @return double[] {newLat, newLng}
     */
    public static double[] moveTowards(double lat1, double lon1, double lat2, double lon2, double stepDistanceMeters) {
        double distMeters = haversineDistanceMeters(lat1, lon1, lat2, lon2);
        if (distMeters <= stepDistanceMeters || distMeters <= 0.0001) {
            return new double[]{lat2, lon2};
        }
        double fraction = stepDistanceMeters / distMeters;
        double newLat = lat1 + fraction * (lat2 - lat1);
        double newLng = lon1 + fraction * (lon2 - lon1);
        return new double[]{newLat, newLng};
    }
}
