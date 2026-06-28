import { Injectable } from '@nestjs/common';
import { haversineDistanceKm } from '../../common/utils/geo.util';

export interface EtaResult {
  etaSeconds: number;
  distanceKm: number;
  hasArrived: boolean;
}

@Injectable()
export class EtaService {
  /**
   * Calculates dynamic ETA and distance to target.
   * @param currentLat Current latitude of the ambulance
   * @param currentLng Current longitude of the ambulance
   * @param targetLat Target latitude
   * @param targetLng Target longitude
   * @param currentSpeedKmph Current speed. Defaults to 40 if 0 or undefined.
   * @param arrivalThresholdKm Distance in km under which the ambulance is considered arrived (default 0.05 = 50m)
   */
  calculateEta(
    currentLat: number,
    currentLng: number,
    targetLat: number,
    targetLng: number,
    currentSpeedKmph?: number,
    arrivalThresholdKm = 0.05,
  ): EtaResult {
    const distanceKm = haversineDistanceKm(currentLat, currentLng, targetLat, targetLng);
    
    // Check if arrived
    if (distanceKm <= arrivalThresholdKm) {
      return { etaSeconds: 0, distanceKm, hasArrived: true };
    }

    const speed = currentSpeedKmph && currentSpeedKmph > 0 ? currentSpeedKmph : 40;
    const etaSeconds = Math.floor((distanceKm / speed) * 3600);

    return {
      etaSeconds: Math.max(0, etaSeconds),
      distanceKm,
      hasArrived: false,
    };
  }
}
