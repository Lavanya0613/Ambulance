import { useEffect, useState } from 'react';
import { MapContainer, TileLayer, Marker, Polyline, useMap } from 'react-leaflet';
import 'leaflet/dist/leaflet.css';
import L from 'leaflet';
import axios from 'axios';

// Fix leaflet default icon issue
delete (L.Icon.Default.prototype as any)._getIconUrl;
L.Icon.Default.mergeOptions({
  iconRetinaUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-icon-2x.png',
  iconUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-icon.png',
  shadowUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-shadow.png',
});

// Custom Icons
const createDivIcon = (color: string, label: string) => L.divIcon({
  html: `<div style="background-color: ${color}; width: 30px; height: 30px; border-radius: 50%; display: flex; align-items: center; justify-content: center; color: white; font-weight: bold; border: 2px solid white; box-shadow: 0 2px 5px rgba(0,0,0,0.3);">${label}</div>`,
  className: '',
  iconSize: [30, 30],
  iconAnchor: [15, 15]
});

const pickupIcon = createDivIcon('#4caf50', 'P');
const dropIcon = createDivIcon('#f44336', 'H');
const ambIcon = createDivIcon('#1976d2', '🚑');

// Helper component to smoothly center map
function MapUpdater({ center, zoom }: { center: [number, number], zoom: number }) {
  const map = useMap();
  useEffect(() => {
    map.setView(center, zoom);
  }, [center, zoom, map]);
  return null;
}

interface LiveMapProps {
  request: any | null;
  liveLocation: { lat: number; lng: number } | null;
}

export default function LiveMap({ request, liveLocation }: LiveMapProps) {
  const [routeCoords, setRouteCoords] = useState<[number, number][]>([]);

  // Calculate coordinates
  const pickup = request?.pickupLat && request?.pickupLng 
    ? [request.pickupLat, request.pickupLng] as [number, number] 
    : null;
    
  const drop = request?.dropLat && request?.dropLng 
    ? [request.dropLat, request.dropLng] as [number, number] 
    : null;
    
  const ambPos = liveLocation ? [liveLocation.lat, liveLocation.lng] as [number, number] : null;

  // Determine current active start point for routing (ambulance if exists, else pickup)
  const activeStart = ambPos || pickup;

  useEffect(() => {
    if (!activeStart || !drop) {
      setRouteCoords([]);
      return;
    }

    const fetchRoute = async () => {
      try {
        const url = `https://router.project-osrm.org/route/v1/driving/${activeStart[1]},${activeStart[0]};${drop[1]},${drop[0]}?overview=full&geometries=geojson`;
        const res = await axios.get(url);
        if (res.data.routes && res.data.routes.length > 0) {
          const coords = res.data.routes[0].geometry.coordinates.map((c: [number, number]) => [c[1], c[0]]);
          setRouteCoords(coords);
        }
      } catch (err) {
        console.error("Failed to fetch OSRM route", err);
        // Fallback to straight line
        setRouteCoords([activeStart, drop]);
      }
    };

    fetchRoute();
  }, [activeStart?.[0], activeStart?.[1], drop?.[0], drop?.[1]]);

  if (!pickup || !drop) {
    return (
      <div style={{ height: '100%', width: '100%', display: 'flex', alignItems: 'center', justifyContent: 'center', backgroundColor: '#f0f4f8', borderRadius: 8 }}>
        <p style={{ color: '#64748b', margin: 0 }}>Select an active trip to view live tracking</p>
      </div>
    );
  }

  const center = ambPos || pickup;

  return (
    <div style={{ height: '100%', width: '100%', borderRadius: 8, overflow: 'hidden', position: 'relative' }}>
      <MapContainer center={center} zoom={13} style={{ height: '100%', width: '100%' }}>
        <TileLayer
          url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
          attribution='&copy; OpenStreetMap contributors'
        />
        <MapUpdater center={center} zoom={14} />
        
        {routeCoords.length > 0 && (
          <Polyline positions={routeCoords} color="#1976d2" weight={5} opacity={0.7} />
        )}

        <Marker position={pickup} icon={pickupIcon} />
        <Marker position={drop} icon={dropIcon} />
        {ambPos && <Marker position={ambPos} icon={ambIcon} />}
      </MapContainer>
    </div>
  );
}
