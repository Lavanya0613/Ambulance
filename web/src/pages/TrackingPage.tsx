import { useEffect, useRef, useState, useCallback } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import axios from 'axios';
import { io, Socket } from 'socket.io-client';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';
import {
  Box, Container, Grid, Card, CardContent, Typography, Chip, Button, Avatar, Alert, CircularProgress, Dialog, DialogTitle, DialogContent, DialogActions, TextField, MenuItem, Snackbar
} from '@mui/material';
import PhoneIcon from '@mui/icons-material/Phone';
import WifiIcon from '@mui/icons-material/Wifi';
import WifiOffIcon from '@mui/icons-material/WifiOff';
import PersonIcon from '@mui/icons-material/Person';
import CheckCircleIcon from '@mui/icons-material/CheckCircle';
import ArrowBackIcon from '@mui/icons-material/ArrowBack';
import LocationOnIcon from '@mui/icons-material/LocationOn';

const API_BASE_URL = 'http://localhost:3000';

// Fallback patient mock token if not logged in as dispatcher
const getAuthToken = () => {
  const token = localStorage.getItem('access_token');
  if (token) return token;
  return 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ0ZXN0LXVzZXIiLCJpZCI6InRlc3QtdXNlciIsInJvbGUiOiJwYXRpZW50IiwiaWF0IjoxNzgxODQzMDA1LCJleHAiOjQ5Mzc2MDMwMDV9.PaQ2nZb25EAIKpbPEU6Jm2QDd0Dkt_ZL8VxRC-eFmNQ';
};

const patientIcon = L.divIcon({
  className: '',
  html: `
    <div style="position:relative;width:36px;height:36px;display:flex;align-items:center;justify-content:center;">
      <div style="position:absolute;border:2px solid #76B82A;border-radius:50%;width:36px;height:36px;animation:pulsate 1.8s ease-out infinite;opacity:0;"></div>
      <div style="background:linear-gradient(135deg,#76B82A,#5b961f);border:2.5px solid #fff;border-radius:50%;width:20px;height:20px;box-shadow:0 0 12px rgba(118,184,42,0.7);display:flex;align-items:center;justify-content:center;">
        <svg style="width:11px;height:11px;fill:white;" viewBox="0 0 24 24"><path d="M12 12c2.7 0 4.8-2.1 4.8-4.8S14.7 2.4 12 2.4 7.2 4.5 7.2 7.2 9.3 12 12 12zm0 2.4c-3.2 0-9.6 1.6-9.6 4.8v2.4h19.2v-2.4c0-3.2-6.4-4.8-9.6-4.8z"/></svg>
      </div>
    </div>`,
  iconSize: [36, 36],
  iconAnchor: [18, 18],
});

const hospitalIcon = L.divIcon({
  className: '',
  html: `
    <div style="position:relative;width:36px;height:36px;display:flex;align-items:center;justify-content:center;">
      <div style="position:absolute;border:2px solid #E53935;border-radius:50%;width:36px;height:36px;animation:pulsate 2s ease-out infinite;opacity:0;"></div>
      <div style="background:linear-gradient(135deg,#E53935,#b91c1c);border:2.5px solid #fff;border-radius:50%;width:20px;height:20px;box-shadow:0 0 12px rgba(229,57,53,0.7);display:flex;align-items:center;justify-content:center;">
        <svg style="width:12px;height:12px;fill:white;" viewBox="0 0 24 24"><path d="M19 8h-2v3h-3v2h3v3h2v-3h3v-2h-3V8zM4 6H2v14c0 1.1.9 2 2 2h14v-2H4V6zm14-4H8C6.9 2 6 2.9 6 4v12c0 1.1.9 2 2 2h10c1.1 0 2-.9 2-2V4c0-1.1-.9-2-2-2z"/></svg>
      </div>
    </div>`,
  iconSize: [36, 36],
  iconAnchor: [18, 18],
});

const ambulanceIcon = L.divIcon({
  className: '',
  html: `
    <div style="position:relative;width:46px;height:46px;display:flex;align-items:center;justify-content:center;">
      <div style="position:absolute;border:2.5px solid #1E3A5F;border-radius:50%;width:46px;height:46px;animation:pulsate 1.4s ease-out infinite;opacity:0;"></div>
      <div style="background:linear-gradient(135deg,#1E3A5F,#112238);border:3px solid #fff;border-radius:50%;width:30px;height:30px;box-shadow:0 0 16px rgba(30,58,95,0.9);display:flex;align-items:center;justify-content:center;font-size:15px;transition:transform 2s linear;">
        🚑
      </div>
    </div>`,
  iconSize: [46, 46],
  iconAnchor: [23, 23],
});

const STATUS_STEPS = [
  { key: 'REQUEST_CREATED',    label: 'Request Created',  icon: '📋', color: '#6b7280' },
  { key: 'SEARCHING_DRIVER',   label: 'Searching',        icon: '🔍', color: '#F4B400' },
  { key: 'VENDOR_ACCEPTED',    label: 'Accepted',         icon: '🤝', color: '#1E3A5F' },
  { key: 'DRIVER_ASSIGNED',    label: 'Driver Assigned',  icon: '👨‍✈️', color: '#1E3A5F' },
  { key: 'EN_ROUTE',           label: 'En Route',         icon: '🚑', color: '#1E3A5F' },
  { key: 'ARRIVED',            label: 'Arriving',         icon: '📍', color: '#1E3A5F' },
  { key: 'PATIENT_ONBOARD',    label: 'Patient Onboard',  icon: '🛏️', color: '#1E3A5F' },
  { key: 'DESTINATION_REACHED',label: 'At Hospital',      icon: '🏥', color: '#1E3A5F' },
  { key: 'COMPLETED',          label: 'Completed',        icon: '✅', color: '#76B82A' },
];

const TERMINAL_STATUSES = ['COMPLETED', 'CANCELLED', 'FAILED'];

const getStatusMeta = (status: string) => {
  switch (status) {
    case 'PENDING':
    case 'REQUEST_CREATED': return { color: '#6b7280', bg: '#f3f4f6' };
    case 'SEARCHING_DRIVER':return { color: '#F4B400', bg: '#fef3c7' };
    case 'VENDOR_ACCEPTED': return { color: '#1E3A5F', bg: '#e8ecf1' };
    case 'ASSIGNED':
    case 'DRIVER_ASSIGNED': return { color: '#1E3A5F', bg: '#e8ecf1' };
    case 'EN_ROUTE':        return { color: '#1E3A5F', bg: '#e8ecf1' };
    case 'ARRIVED':         return { color: '#76B82A', bg: '#f1f8eb' };
    case 'PATIENT_ONBOARD': return { color: '#1E3A5F', bg: '#e8ecf1' };
    case 'IN_PROGRESS':     return { color: '#1E3A5F', bg: '#e8ecf1' };
    case 'DESTINATION_REACHED': return { color: '#76B82A', bg: '#f1f8eb' };
    case 'COMPLETED':       return { color: '#76B82A', bg: '#f1f8eb' };
    case 'CANCELLED':
    case 'FAILED':          return { color: '#E53935', bg: '#fcebea' };
    default:                return { color: '#6b7280', bg: '#f3f4f6' };
  }
};

const getStepIndex = (status: string) => {
  const map: Record<string, number> = {
    PENDING:             0,
    REQUEST_CREATED:     0,
    SEARCHING_DRIVER:    1,
    VENDOR_ACCEPTED:     2,
    ASSIGNED:            3,
    DRIVER_ASSIGNED:     3,
    EN_ROUTE:            4,
    ARRIVED:             5,
    PATIENT_ONBOARD:     6,
    IN_PROGRESS:         6,
    DESTINATION_REACHED: 7,
    COMPLETED:           8,
    CANCELLED:           0,
    FAILED:              0,
  };
  return map[status] ?? 0;
};

interface Driver { vendorDriverRef: string; name: string; phoneE164: string; vehicleNumber: string; ambulanceType: string; ambulanceNumber?: string; photoUrl?: string; }
interface Location { vendorEventId: string; lat: number; lng: number; speedKmph?: number; headingDeg?: number; capturedAt: string; }
interface TrackingData { requestId: string; requestNumber: string; status: string; patientName: string; pickupLat: number; pickupLng: number; pickupAddress: string; dropLat: number; dropLng: number; dropAddress: string; driver: Driver | null; etaSeconds: number | null; lastLocation: Location | null; updatedAt: string; }

export default function TrackingPage() {
  const { requestId } = useParams<{ requestId: string }>();
  const navigate = useNavigate();

  const [socketConnected, setSocketConnected] = useState(false);
  const [liveStatus,   setLiveStatus]   = useState<string | null>(null);
  const [liveEta,      setLiveEta]      = useState<number | null>(null);
  const [liveDriver,   setLiveDriver]   = useState<Driver | null>(null);
  const [liveLocation, setLiveLocation] = useState<Location | null>(null);

  const [toastMsg, setToastMsg] = useState('');
  const [cancelOpen,   setCancelOpen]   = useState(false);
  const [cancelling,   setCancelling]   = useState(false);

  const mapContainerRef    = useRef<HTMLDivElement>(null);
  const mapInstance        = useRef<L.Map | null>(null);
  const pickupMarkerRef    = useRef<L.Marker | null>(null);
  const dropMarkerRef      = useRef<L.Marker | null>(null);
  const ambulanceMarkerRef = useRef<L.Marker | null>(null);
  const routeLineRef       = useRef<L.Polyline | null>(null);
  const mapInitialized     = useRef(false);

  const { data: request, isLoading, error, refetch } = useQuery<TrackingData>({
    queryKey: ['tracking', requestId],
    queryFn: async () => {
      const token = getAuthToken();
      const endpoint = localStorage.getItem('access_token') 
        ? `/dispatcher/requests/${requestId}` 
        : `/patient/requests/${requestId}/track`;
        
      const res = await axios.get(`${API_BASE_URL}${endpoint}`, {
        headers: { Authorization: `Bearer ${token}` }
      });
      return res.data;
    },
    refetchInterval: socketConnected ? false : 5000,
    enabled: !!requestId,
  });

  useEffect(() => {
    if (!request) return;
    setLiveStatus(s   => s   ?? request.status);
    setLiveEta(e      => e   ?? request.etaSeconds);
    setLiveDriver(d   => d   ?? request.driver);
    setLiveLocation(l => l   ?? request.lastLocation);
  }, [request]);

  const showToast = (msg: string) => {
    setToastMsg(msg);
  };

  useEffect(() => {
    if (!requestId) return;
    // 2. Setup WebSocket for real-time tracking
    const token = getAuthToken();
    const socket: Socket = io(`${API_BASE_URL}/ws`, { transports: ['websocket', 'polling'], auth: { token } });
    
    socket.on('connect', () => {
      setSocketConnected(true);
      socket.emit('subscribe', { requestId });
    });
    socket.on('disconnect', () => setSocketConnected(false));
    
    socket.on('ambulance_assigned', (data: any) => {
      if (data.driver) setLiveDriver(data.driver);
      if (data.etaSeconds != null) setLiveEta(data.etaSeconds);
      setLiveStatus('ASSIGNED');
      showToast('Driver Assigned!');
      refetch();
    });
    
    socket.on('location_updated', (pos: Location) => {
      setLiveLocation(pos);
    });
    socket.on('eta_updated', (data: { etaSeconds: number }) => {
      setLiveEta(data.etaSeconds);
    });
    socket.on('status_updated', (data: { status: string }) => {
      setLiveStatus(data.status);
      showToast(`Status Updated: ${data.status.replace('_', ' ')}`);
      refetch();
    });
    socket.on('ride_completed', () => {
      setLiveStatus('COMPLETED');
      setLiveEta(0);
      showToast('Trip completed. Thank you!');
      refetch();
    });
    socket.on('en_route',  () => { setLiveStatus('EN_ROUTE'); showToast('Ambulance is En Route'); });
    socket.on('arrived',   () => { setLiveStatus('ARRIVED'); showToast('Driver has arrived'); });

    return () => { socket.disconnect(); };
  }, [requestId]);

  useEffect(() => {
    if (!mapContainerRef.current || mapInitialized.current || !request) return;
    mapInitialized.current = true;
    const map = L.map(mapContainerRef.current, { zoomControl: false, attributionControl: false }).setView([(request.pickupLat + request.dropLat) / 2, (request.pickupLng + request.dropLng) / 2], 13);
    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', { maxZoom: 19 }).addTo(map);
    mapInstance.current = map;

    pickupMarkerRef.current = L.marker([request.pickupLat, request.pickupLng], { icon: patientIcon }).addTo(map);
    dropMarkerRef.current = L.marker([request.dropLat, request.dropLng], { icon: hospitalIcon }).addTo(map);
    routeLineRef.current = L.polyline([[request.pickupLat, request.pickupLng], [request.dropLat, request.dropLng]], { color: '#1E3A5F', weight: 4, opacity: 0.6, dashArray: '8, 10' }).addTo(map);
    map.fitBounds([[request.pickupLat, request.pickupLng], [request.dropLat, request.dropLng]], { padding: [50, 50] });

    return () => {
      if (mapInstance.current) { mapInstance.current.remove(); mapInstance.current = null; mapInitialized.current = false; }
    };
  }, [request]);

  useEffect(() => {
    const map = mapInstance.current;
    if (!map || !liveLocation?.lat || !liveLocation?.lng) return;
    const ambPos: L.LatLngExpression = [liveLocation.lat, liveLocation.lng];
    if (!ambulanceMarkerRef.current) {
      ambulanceMarkerRef.current = L.marker(ambPos, { icon: ambulanceIcon }).addTo(map);
    } else {
      ambulanceMarkerRef.current.setLatLng(ambPos);
      
      // Smooth marker transition hack using CSS
      const iconElement = ambulanceMarkerRef.current.getElement();
      if (iconElement) {
        iconElement.style.transition = 'transform 2s linear';
      }
    }
    if (request && routeLineRef.current) {
      // Draw route from ambulance to destination
      routeLineRef.current.setLatLngs([ambPos, [request.dropLat, request.dropLng]]);
      // Fit bounds to keep pickup, drop, and ambulance visible
      map.fitBounds([[request.pickupLat, request.pickupLng], ambPos, [request.dropLat, request.dropLng]], { padding: [50, 50], maxZoom: 16 });
    }
  }, [liveLocation, request]);

  const handleCancelSubmit = useCallback(async () => {
    if (!requestId) return;
    setCancelling(true);
    try {
      await axios.post(`${API_BASE_URL}/patient/requests/${requestId}/cancel`, { reasonCode: 'patient_cancelled' });
      setLiveStatus('CANCELLED');
      setCancelOpen(false);
      refetch();
    } catch (err) {} finally { setCancelling(false); }
  }, [requestId, refetch]);

  if (isLoading && !request) return <Box sx={{ display: 'flex', justifyContent: 'center', mt: 10 }}><CircularProgress /></Box>;
  if (error || !request) return <Container maxWidth="sm" sx={{ mt: 8 }}><Alert severity="error">Could not load tracking data.</Alert></Container>;

  const effectiveStatus   = liveStatus   ?? request.status;
  const effectiveEta      = liveEta      ?? request.etaSeconds ?? null;
  const effectiveDriver   = liveDriver   ?? request.driver   ?? null;
  const currentStep  = getStepIndex(effectiveStatus);
  const isTerminal   = TERMINAL_STATUSES.includes(effectiveStatus);
  const { color: statusColor, bg: statusBg } = getStatusMeta(effectiveStatus);

  const getEtaLabel = () => {
    if (effectiveEta === null) return 'Calculated shortly';
    if (effectiveEta <= 0) return 'Arrived';
    const mins = Math.ceil(effectiveEta / 60);
    return `${mins} min`;
  };

  return (
    <Box sx={{ pb: 6 }}>
      
      {/* ── Top Info / Status Hero ── */}
      <Box sx={{ bgcolor: '#ffffff', pt: 3, pb: 4, borderBottom: '1px solid #e5e7eb', mb: 3 }}>
        <Container maxWidth="xl">
          <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', flexWrap: 'wrap', gap: 2 }}>
            <Box>
              <Button startIcon={<ArrowBackIcon />} onClick={() => navigate('/')} sx={{ mb: 1, color: '#6b7280' }}>Back to Booking</Button>
              <Typography variant="h3" sx={{ fontWeight: 900, color: '#1E3A5F', mb: 1 }}>
                Ambulance On The Way
              </Typography>
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                <Chip 
                  label={effectiveStatus.replace('_', ' ')}
                  sx={{ bgcolor: statusBg, color: statusColor, fontWeight: 800, fontSize: '0.9rem', borderRadius: '16px' }} 
                />
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5, color: socketConnected ? '#76B82A' : '#F4B400' }}>
                  {socketConnected ? <WifiIcon fontSize="small" /> : <WifiOffIcon fontSize="small" />}
                  <Typography variant="caption" sx={{ fontWeight: 600 }}>{socketConnected ? 'Live' : 'Offline'}</Typography>
                </Box>
              </Box>
            </Box>

            {/* ETA Countdown */}
            <Box sx={{ textAlign: 'right' }}>
              <Typography variant="subtitle1" sx={{ color: '#6b7280', fontWeight: 600, textTransform: 'uppercase' }}>Estimated Arrival</Typography>
              <Typography variant="h1" sx={{ fontWeight: 900, color: statusColor, lineHeight: 1 }}>
                {getEtaLabel()}
              </Typography>
            </Box>
          </Box>

          {/* ── Patient Progress Timeline ── */}
          <Box sx={{ mt: 5, display: 'flex', alignItems: 'center', justifyContent: 'space-between', position: 'relative' }}>
            <Box sx={{ position: 'absolute', top: '35%', left: '5%', right: '5%', height: 4, bgcolor: '#f3f4f6', borderRadius: 2, zIndex: 0 }} />
            <Box sx={{ position: 'absolute', top: '35%', left: '5%', width: `${Math.min((currentStep / (STATUS_STEPS.length - 1)) * 90, 90)}%`, height: 4, bgcolor: statusColor, borderRadius: 2, zIndex: 1, transition: 'width 0.6s ease' }} />
            {STATUS_STEPS.map((step, idx) => {
              const isActive = idx === currentStep && !isTerminal;
              const isCompleted = idx < currentStep || effectiveStatus === 'COMPLETED';
              return (
                <Box key={step.key} sx={{ display: 'flex', flexDirection: 'column', alignItems: 'center', zIndex: 2, flex: 1 }}>
                  <Box sx={{
                    width: { xs: 32, sm: 48 }, height: { xs: 32, sm: 48 }, borderRadius: '50%',
                    display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '1.2rem',
                    bgcolor: isCompleted ? step.color : isActive ? step.color : '#ffffff',
                    border: `3px solid ${isCompleted ? step.color : isActive ? step.color : '#e5e7eb'}`,
                    color: isCompleted || isActive ? '#fff' : '#d1d5db',
                    boxShadow: isActive ? `0 0 0 6px ${step.color}33` : 'none',
                    transition: 'all 0.3s ease'
                  }}>
                    {isCompleted ? <CheckCircleIcon sx={{ fontSize: '1.4rem' }} /> : step.icon}
                  </Box>
                  <Typography variant="caption" sx={{ mt: 1.5, fontWeight: isActive ? 800 : 600, color: isActive ? step.color : isCompleted ? '#4b5563' : '#9ca3af', display: { xs: 'none', sm: 'block' }, textAlign: 'center' }}>
                    {step.label}
                  </Typography>
                </Box>
              );
            })}
          </Box>
        </Container>
      </Box>

      {/* ── Main Layout (Map + Driver Card) ── */}
      <Container maxWidth="xl">
        <Grid container spacing={4}>
          
          {/* Map Section */}
          <Grid size={{ xs: 12, lg: 8 }}>
            <Card sx={{ height: { xs: 400, md: 500 }, borderRadius: '24px', overflow: 'hidden', boxShadow: '0 12px 32px rgba(30,58,95,0.06)' }}>
              <div ref={mapContainerRef} style={{ width: '100%', height: '100%' }} />
            </Card>
          </Grid>

          {/* Right Side Info */}
          <Grid size={{ xs: 12, lg: 4 }}>
            <Box sx={{ display: 'flex', flexDirection: 'column', gap: 3 }}>
              
              {/* Driver Card */}
              <Card sx={{ borderRadius: '24px', boxShadow: '0 8px 24px rgba(30,58,95,0.06)', p: 1 }}>
                <CardContent>
                  <Typography variant="h6" sx={{ fontWeight: 800, color: '#1E3A5F', mb: 3 }}>Driver Details</Typography>
                  {effectiveDriver ? (
                    <Box>
                      <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mb: 3 }}>
                        <Avatar src={effectiveDriver.photoUrl} sx={{ width: 64, height: 64, bgcolor: '#f0f4f8', color: '#1E3A5F' }}>
                          {!effectiveDriver.photoUrl && <PersonIcon sx={{ fontSize: 40 }} />}
                        </Avatar>
                        <Box>
                          <Typography variant="h5" sx={{ fontWeight: 800, color: '#1F2937' }}>{effectiveDriver.name}</Typography>
                          <Typography variant="subtitle1" sx={{ color: '#1F2937', fontWeight: 900, mt: 0.5, mb: 0.5, display: 'flex', alignItems: 'center', gap: 1 }}>
                            <Box component="span" sx={{ bgcolor: '#F4B400', color: '#000', px: 1.5, py: 0.5, borderRadius: 1, border: '1px solid #000' }}>
                              {effectiveDriver.vehicleNumber}
                            </Box>
                            {effectiveDriver.ambulanceNumber && (
                              <Chip label={effectiveDriver.ambulanceNumber} size="small" sx={{ fontWeight: 800, bgcolor: '#1E3A5F', color: '#fff', borderRadius: '8px' }} />
                            )}
                          </Typography>
                          <Typography variant="subtitle2" sx={{ color: '#6b7280', fontWeight: 600 }}>
                            {effectiveDriver.ambulanceType === 'BLS' ? 'Standard Ambulance' : effectiveDriver.ambulanceType === 'ALS' ? 'Emergency Ambulance' : effectiveDriver.ambulanceType === 'ICU' ? 'Critical Care Ambulance' : effectiveDriver.ambulanceType}
                          </Typography>
                          <Typography variant="body2" sx={{ color: '#4b5563', fontWeight: 600, mt: 0.5 }}>
                            {effectiveDriver.phoneE164}
                          </Typography>
                        </Box>
                      </Box>
                      
                      {/* Driver Speed & ETA row */}
                      <Grid container spacing={2} sx={{ mb: 3 }}>
                        <Grid size={{ xs: 6 }}>
                          <Box sx={{ p: 1.5, bgcolor: '#f8fafc', borderRadius: 2, border: '1px solid #e2e8f0' }}>
                            <Typography variant="caption" sx={{ color: '#64748b', display: 'block', mb: 0.5 }}>Current Speed</Typography>
                            <Typography variant="body1" sx={{ fontWeight: 800, color: '#0f172a' }}>
                              {liveLocation?.speedKmph ? Math.round(liveLocation.speedKmph) : '--'} km/h
                            </Typography>
                          </Box>
                        </Grid>
                        <Grid size={{ xs: 6 }}>
                          <Box sx={{ p: 1.5, bgcolor: '#f8fafc', borderRadius: 2, border: '1px solid #e2e8f0' }}>
                            <Typography variant="caption" sx={{ color: '#64748b', display: 'block', mb: 0.5 }}>ETA</Typography>
                            <Typography variant="body1" sx={{ fontWeight: 800, color: '#059669' }}>
                              {getEtaLabel()}
                            </Typography>
                          </Box>
                        </Grid>
                      </Grid>
                      <Button
                        fullWidth variant="contained" size="large" startIcon={<PhoneIcon />} href={`tel:${effectiveDriver.phoneE164}`}
                        sx={{ bgcolor: '#76B82A', '&:hover': { bgcolor: '#5b961f' }, borderRadius: '30px', py: 1.5, fontSize: '1.1rem', mb: 2 }}
                      >
                        Call Driver
                      </Button>
                      <Button 
                        fullWidth variant="outlined" startIcon={<LocationOnIcon />} 
                        onClick={() => {
                          if (mapInstance.current && liveLocation) {
                            mapInstance.current.setView([liveLocation.lat, liveLocation.lng], 16, { animate: true });
                          }
                        }}
                        sx={{ borderRadius: '30px', py: 1.2, color: '#1E3A5F', borderColor: '#1E3A5F' }}
                      >
                        Live Location
                      </Button>
                    </Box>
                  ) : (
                    <Box sx={{ textAlign: 'center', py: 4 }}>
                      <CircularProgress size={40} sx={{ color: '#1E3A5F', mb: 2 }} />
                      <Typography variant="subtitle1" sx={{ color: '#4b5563', fontWeight: 600 }}>Assigning nearest ambulance...</Typography>
                    </Box>
                  )}
                </CardContent>
              </Card>

              {/* Action Buttons */}
              <Card sx={{ borderRadius: '24px', boxShadow: 'none', border: '1px solid #e5e7eb', bgcolor: '#F7F8FA', p: 1 }}>
                <CardContent sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
                  <Button variant="contained" color="secondary" size="large" sx={{ borderRadius: '30px', py: 1.5 }}>
                    Emergency Support
                  </Button>
                  {!isTerminal && (
                    <Button variant="text" color="error" onClick={() => setCancelOpen(true)} sx={{ fontWeight: 700 }}>
                      Cancel Request
                    </Button>
                  )}
                </CardContent>
              </Card>
            </Box>
          </Grid>
        </Grid>
      </Container>

      {/* Toasts */}
      <Snackbar
        open={!!toastMsg} autoHideDuration={3000} onClose={() => setToastMsg('')}
        anchorOrigin={{ vertical: 'bottom', horizontal: 'center' }}
      >
        <Alert severity="info" icon={false} sx={{ bgcolor: '#1E3A5F', color: '#fff', borderRadius: '12px', fontWeight: 600, fontSize: '1rem' }}>
          {toastMsg}
        </Alert>
      </Snackbar>

      <Dialog open={cancelOpen} onClose={() => setCancelOpen(false)} slotProps={{ paper: { sx: { borderRadius: '24px', p: 1 } } }}>
        <DialogTitle sx={{ fontWeight: 800 }}>Cancel Ambulance Request</DialogTitle>
        <DialogContent>
          <Alert severity="warning" sx={{ mb: 3, borderRadius: '12px' }}>This action cannot be undone.</Alert>
          <TextField fullWidth select label="Cancellation Reason" value={cancelling ? '' : 'PATIENT_RECOVERED'} onChange={() => {}}>
            <MenuItem value="PATIENT_RECOVERED">Patient recovered</MenuItem>
          </TextField>
        </DialogContent>
        <DialogActions sx={{ px: 3, pb: 3 }}>
          <Button onClick={() => setCancelOpen(false)} color="inherit" sx={{ fontWeight: 600 }}>Dismiss</Button>
          <Button onClick={handleCancelSubmit} color="error" variant="contained" sx={{ borderRadius: '20px' }}>Confirm Cancel</Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}
