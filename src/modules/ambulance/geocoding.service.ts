import { Injectable, Logger } from '@nestjs/common';

@Injectable()
export class GeocodingService {
  private readonly logger = new Logger(GeocodingService.name);

  async reverseGeocode(lat: number, lng: number): Promise<string | undefined> {
    try {
      const url = `https://nominatim.openstreetmap.org/reverse?format=json&lat=${lat}&lon=${lng}`;
      const response = await fetch(url, {
        headers: {
          'User-Agent': 'AmbulanceBookingApp/1.0',
          'Accept-Language': 'en-US,en;q=0.9',
        },
      });

      if (!response.ok) {
        this.logger.warn(`Nominatim API returned status: ${response.status}`);
        return undefined;
      }

      const data = await response.json();
      if (data && data.display_name) {
        return data.display_name;
      }

      return undefined;
    } catch (err: any) {
      this.logger.error(`Failed to reverse geocode [${lat}, ${lng}]: ${err.message}`, err.stack);
      return undefined;
    }
  }
}
