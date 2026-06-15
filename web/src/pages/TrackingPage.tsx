import { useEffect, useRef, useState, useCallback } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import axios from 'axios';
import { io, Socket } from 'socket.io-client';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';
import {
  Box,
  Container,
  Grid,
  Card,
  CardContent,
  Typography,
  Chip,
  Button,
  Avatar,
  Divider,
  Alert,
  CircularProgress,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  MenuItem,
  Tooltip,
  IconButton,
} from '@mui/material';
import PhoneIcon from '@mui/icons-material/Phone';
import CancelIcon from '@mui/icons-material/Cancel';
import AccessTimeIcon from '@mui/icons-material/AccessTime';
import DirectionsCarIcon from '@mui/icons-material/DirectionsCar';
import LocalHospitalIcon from '@mui/icons-material/LocalHospital';
import WifiIcon from '@mui/icons-material/Wifi';
import WifiOffIcon from '@mui/icons-material/WifiOff';
import RefreshIcon from '@mui/icons-material/Refresh';
import SpeedIcon from '@mui/icons-material/Speed';
import PersonIcon from '@mui/icons-material/Person';
import BadgeIcon from '@mui/icons-material/Badge';
import NavigationIcon from '@mui/icons-material/Navigation';
import CheckCircleIcon from '@mui/icons-material/CheckCircle';
import RadioButtonUncheckedIcon from '@mui/icons-material/RadioButtonUnchecked';
import HourglassEmptyIcon from '@mui/icons-material/HourglassEmpty';
import ArrowBackIcon from '@mui/icons-material/ArrowBack';

const API_BASE_URL = 'http://localhost:3000';

// ─── Leaflet Custom Icons ────────────────────────────────────────────────────

const patientIcon = L.divIcon({
  className: '',
  html: `
    <div style="position:relative;width:36px;height:36px;display:flex;align-items:center;justify-content:center;">
      <div style="position:absolute;border:2px solid #6ba539;border-radius:50%;width:36px;height:36px;animation:pulsate 1.8s ease-out infinite;opacity:0;"></div>
      <div style="background:linear-gradient(135deg,#6ba539,#4f8524);border:2.5px solid #fff;border-radius:50%;width:20px;height:20px;box-shadow:0 0 12px rgba(107,165,57,0.7);display:flex;align-items:center;justify-content:center;">
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
      <div style="position:absolute;border:2px solid #ef4444;border-radius:50%;width:36px;height:36px;animation:pulsate 2s ease-out infinite;opacity:0;"></div>
      <div style="background:linear-gradient(135deg,#ef4444,#b91c1c);border:2.5px solid #fff;border-radius:50%;width:20px;height:20px;box-shadow:0 0 12px rgba(239,68,68,0.7);display:flex;align-items:center;justify-content:center;">
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
      <div style="position:absolute;border:2.5px solid #3b82f6;border-radius:50%;width:46px;height:46px;animation:pulsate 1.4s ease-out infinite;opacity:0;"></div>
      <div style="background:linear-gradient(135deg,#3b82f6,#1d4ed8);border:3px solid #fff;border-radius:50%;width:30px;height:30px;box-shadow:0 0 16px rgba(59,130,246,0.9);display:flex;align-items:center;justify-content:center;font-size:15px;">
        🚑
      </div>
    </div>`,
  iconSize: [46, 46],
  iconAnchor: [23, 23],
});

// ─── Status Config ───────────────────────────────────────────────────────────

const STATUS_STEPS = [
  { key: 'PENDING',    label: 'Pending',    icon: '🕐', color: '#f59e0b' },
  { key: 'ASSIGNED',   label: 'Assigned',   icon: '✅', color: '#8b5cf6' },
  { key: 'EN_ROUTE',   label: 'En Route',   icon: '🚑', color: '#3b82f6' },
  { key: 'ARRIVED',    label: 'Arrived',    icon: '📍', color: '#06b6d4' },
  { key: 'COMPLETED',  label: 'Completed',  icon: '🏥', color: '#6ba539' },
];

const TERMINAL_STATUSES = ['COMPLETED', 'CANCELLED', 'FAILED'];

const getStatusMeta = (status: string) => {
  switch (status) {
    case 'PENDING':     return { color: '#f59e0b', bg: 'rgba(245,158,11,0.12)',  muiColor: 'warning'   as const };
    case 'ASSIGNED':    return { color: '#8b5cf6', bg: 'rgba(139,92,246,0.12)', muiColor: 'secondary' as const };
    case 'EN_ROUTE':
    case 'IN_PROGRESS': return { color: '#3b82f6', bg: 'rgba(59,130,246,0.12)', muiColor: 'info'      as const };
    case 'ARRIVED':     return { color: '#06b6d4', bg: 'rgba(6,182,212,0.12)',  muiColor: 'info'      as const };
    case 'COMPLETED':   return { color: '#6ba539', bg: 'rgba(107,165,57,0.12)', muiColor: 'success'   as const };
    case 'CANCELLED':
    case 'FAILED':      return { color: '#ef4444', bg: 'rgba(239,68,68,0.12)',  muiColor: 'error'     as const };
    default:            return { color: '#94a3b8', bg: 'rgba(148,163,184,0.12)',muiColor: 'default'   as const };
  }
};

const getStepIndex = (status: string) => {
  const idx = STATUS_STEPS.findIndex(s => s.key === status);
  return idx === -1 ? 0 : idx;
};

// ─── Types ───────────────────────────────────────────────────────────────────

interface Driver {
  vendorDriverRef: string;
  name: string;
  phoneE164: string;
  vehicleNumber: string;
  ambulanceType: string;
}

interface Location {
  vendorEventId: string;
  lat: number;
  lng: number;
  speedKmph?: number;
  headingDeg?: number;
  capturedAt: string;
}

interface TrackingData {
  requestId: string;
  requestNumber: string;
  status: string;
  patientName: string;
  pickupLat: number;
  pickupLng: number;
  dropLat: number;
  dropLng: number;
  driver: Driver | null;
  etaSeconds: number | null;
  lastLocation: Location | null;
  updatedAt: string;
}

// ─── Component ───────────────────────────────────────────────────────────────

export default function TrackingPage() {
  const { requestId } = useParams<{ requestId: string }>();
  const navigate = useNavigate();

  // Connection state
  const [socketConnected, setSocketConnected] = useState(false);
  const [lastPollAt, setLastPollAt] = useState<Date>(new Date());

  // Live overrides from WebSocket events
  const [liveStatus,   setLiveStatus]   = useState<string | null>(null);
  const [liveEta,      setLiveEta]      = useState<number | null>(null);
  const [liveDriver,   setLiveDriver]   = useState<Driver | null>(null);
  const [liveLocation, setLiveLocation] = useState<Location | null>(null);
  const [liveUpdatedAt, setLiveUpdatedAt] = useState<Date | null>(null);

  // Cancel dialog
  const [cancelOpen,   setCancelOpen]   = useState(false);
  const [cancelReason, setCancelReason] = useState('PATIENT_RECOVERED');
  const [cancelling,   setCancelling]   = useState(false);

  // Map refs
  const mapContainerRef    = useRef<HTMLDivElement>(null);
  const mapInstance        = useRef<L.Map | null>(null);
  const pickupMarkerRef    = useRef<L.Marker | null>(null);
  const dropMarkerRef      = useRef<L.Marker | null>(null);
  const ambulanceMarkerRef = useRef<L.Marker | null>(null);
  const routeLineRef       = useRef<L.Polyline | null>(null);
  const socketRef          = useRef<Socket | null>(null);
  const mapInitialized     = useRef(false);

  // ── Polling (primary + fallback) ─────────────────────────────────────────
  const { data: request, isLoading, error, refetch } = useQuery<TrackingData>({
    queryKey: ['tracking', requestId],
    queryFn: async () => {
      const res = await axios.get(`${API_BASE_URL}/patient/requests/${requestId}/track`);
      setLastPollAt(new Date());
      return res.data;
    },
    refetchInterval: socketConnected ? false : 5000, // poll every 5s when WS offline
    enabled: !!requestId,
    staleTime: 0,
  });

  // Sync API data → local live state (only if WS hasn't set it yet)
  useEffect(() => {
    if (!request) return;
    setLiveStatus(s   => s   ?? request.status);
    setLiveEta(e      => e   ?? request.etaSeconds);
    setLiveDriver(d   => d   ?? request.driver);
    setLiveLocation(l => l   ?? request.lastLocation);
    setLiveUpdatedAt(u => u  ?? new Date(request.updatedAt));
  }, [request]);

  // ── WebSocket Layer ───────────────────────────────────────────────────────
  useEffect(() => {
    if (!requestId) return;

    const socket: Socket = io(`${API_BASE_URL}/ws`, {
      transports: ['websocket', 'polling'],
      auth: { token: 'bypass' },
      reconnectionAttempts: 10,
      reconnectionDelay: 1000,
    });

    socketRef.current = socket;

    socket.on('connect', () => {
      setSocketConnected(true);
      socket.emit('subscribe', { requestId });
    });

    socket.on('disconnect', () => setSocketConnected(false));
    socket.on('connect_error', () => setSocketConnected(false));

    // ambulance_assigned → driver + eta + status upgrade
    socket.on('ambulance_assigned', (data: any) => {
      if (data.driver)      setLiveDriver(data.driver);
      if (data.etaSeconds != null) setLiveEta(data.etaSeconds);
      setLiveStatus('ASSIGNED');
      setLiveUpdatedAt(new Date());
      refetch();
    });

    // live GPS position stream
    socket.on('location_updated', (pos: Location) => {
      setLiveLocation(pos);
      setLiveUpdatedAt(new Date());
    });

    // ETA tick from backend
    socket.on('eta_updated', (data: { etaSeconds: number }) => {
      setLiveEta(data.etaSeconds);
      setLiveUpdatedAt(new Date());
    });

    // Generic status change (EN_ROUTE, ARRIVED, etc.)
    socket.on('status_updated', (data: { status: string }) => {
      setLiveStatus(data.status);
      setLiveUpdatedAt(new Date());
      refetch();
    });

    // Terminal: ride done
    socket.on('ride_completed', () => {
      setLiveStatus('COMPLETED');
      setLiveEta(0);
      setLiveUpdatedAt(new Date());
      refetch();
    });

    // Alias events emitted by emitStatusUpdated
    socket.on('en_route',  () => { setLiveStatus('EN_ROUTE');  setLiveUpdatedAt(new Date()); });
    socket.on('arrived',   () => { setLiveStatus('ARRIVED');   setLiveUpdatedAt(new Date()); });
    socket.on('cancelled', () => { setLiveStatus('CANCELLED'); setLiveUpdatedAt(new Date()); refetch(); });

    return () => { socket.disconnect(); };
  }, [requestId]);

  // ── Leaflet Map Init (runs once request data arrives) ────────────────────
  useEffect(() => {
    if (!mapContainerRef.current || mapInitialized.current || !request) return;
    mapInitialized.current = true;

    const centerLat = (request.pickupLat + request.dropLat) / 2;
    const centerLng = (request.pickupLng + request.dropLng) / 2;

    const map = L.map(mapContainerRef.current, {
      zoomControl: true,
      attributionControl: false,
    }).setView([centerLat, centerLng], 13);

    // Dark-mode OSM tiles
    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      maxZoom: 19,
    }).addTo(map);
    mapContainerRef.current.classList.add('dark-map');
    mapInstance.current = map;

    // Static markers: Pickup (patient) & Drop (hospital)
    pickupMarkerRef.current = L.marker([request.pickupLat, request.pickupLng], { icon: patientIcon })
      .addTo(map)
      .bindPopup(`<b>🧑 Patient Pickup</b><br/>${request.patientName}`);

    dropMarkerRef.current = L.marker([request.dropLat, request.dropLng], { icon: hospitalIcon })
      .addTo(map)
      .bindPopup('<b>🏥 Destination Hospital</b>');

    // Dashed baseline route line
    routeLineRef.current = L.polyline(
      [[request.pickupLat, request.pickupLng], [request.dropLat, request.dropLng]],
      { color: '#3b82f6', weight: 3, opacity: 0.5, dashArray: '8, 10' }
    ).addTo(map);

    // Fit bounds to show both endpoints
    map.fitBounds([
      [request.pickupLat, request.pickupLng],
      [request.dropLat,   request.dropLng],
    ], { padding: [60, 60] });

    return () => {
      if (mapInstance.current) {
        mapInstance.current.remove();
        mapInstance.current = null;
        mapInitialized.current = false;
      }
    };
  }, [request]);

  // ── Ambulance marker live update ──────────────────────────────────────────
  useEffect(() => {
    const map = mapInstance.current;
    if (!map || !liveLocation?.lat || !liveLocation?.lng) return;

    const ambPos: L.LatLngExpression = [liveLocation.lat, liveLocation.lng];

    if (!ambulanceMarkerRef.current) {
      ambulanceMarkerRef.current = L.marker(ambPos, { icon: ambulanceIcon })
        .addTo(map)
        .bindPopup('🚑 Ambulance');
    } else {
      ambulanceMarkerRef.current.setLatLng(ambPos);
    }

    // Update route line: pickup → ambulance → drop (only if we have the request)
    if (request && routeLineRef.current) {
      routeLineRef.current.setLatLngs([
        [request.pickupLat, request.pickupLng],
        ambPos,
        [request.dropLat,   request.dropLng],
      ]);
    }

    // Re-fit bounds to keep all three points visible
    if (request) {
      map.fitBounds([
        [request.pickupLat, request.pickupLng],
        ambPos,
        [request.dropLat,   request.dropLng],
      ], { padding: [50, 50], maxZoom: 16 });
    }
  }, [liveLocation, request]);

  // ── Helpers ───────────────────────────────────────────────────────────────

  const formatEta = (seconds: number | null) => {
    if (seconds === null) return { label: 'Calculating…', sublabel: '' };
    if (seconds <= 0)     return { label: 'Arrived',       sublabel: 'Ambulance is here' };
    const mins = Math.ceil(seconds / 60);
    return { label: `${mins} min${mins > 1 ? 's' : ''}`, sublabel: `≈ ${seconds}s remaining` };
  };

  const formatTimestamp = (date: Date | string | null) => {
    if (!date) return '—';
    const d = typeof date === 'string' ? new Date(date) : date;
    return d.toLocaleTimeString('en-IN', { hour: '2-digit', minute: '2-digit', second: '2-digit' });
  };

  const formatAmbulanceType = (type: string) => {
    const map: Record<string, string> = {
      als: 'Advanced Life Support (ALS)',
      bls: 'Basic Life Support (BLS)',
      icu: 'Mobile ICU',
      neonatal: 'Neonatal ICU',
    };
    return map[type?.toLowerCase()] ?? type?.toUpperCase() ?? 'ALS';
  };

  const handleCancelSubmit = useCallback(async () => {
    if (!requestId) return;
    setCancelling(true);
    try {
      await axios.post(`${API_BASE_URL}/patient/requests/${requestId}/cancel`, { reasonCode: cancelReason });
      setLiveStatus('CANCELLED');
      setCancelOpen(false);
      refetch();
    } catch (err) {
      console.error('Cancellation failed:', err);
    } finally {
      setCancelling(false);
    }
  }, [requestId, cancelReason, refetch]);

  // ── Derived display values ────────────────────────────────────────────────
  const effectiveStatus   = liveStatus   ?? request?.status   ?? 'PENDING';
  const effectiveEta      = liveEta      ?? request?.etaSeconds ?? null;
  const effectiveDriver   = liveDriver   ?? request?.driver   ?? null;
  const effectiveLocation = liveLocation ?? request?.lastLocation ?? null;
  const effectiveUpdatedAt = liveUpdatedAt ?? (request?.updatedAt ? new Date(request.updatedAt) : null);

  const { color: statusColor, bg: statusBg } = getStatusMeta(effectiveStatus);
  const currentStep  = getStepIndex(effectiveStatus);
  const isTerminal   = TERMINAL_STATUSES.includes(effectiveStatus);
  const { label: etaLabel, sublabel: etaSublabel } = formatEta(effectiveEta);

  // ── Render: Loading ───────────────────────────────────────────────────────
  if (isLoading && !request) {
    return (
      <Box sx={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', height: '70vh', gap: 2 }}>
        <CircularProgress size={56} sx={{ color: '#6ba539' }} />
        <Typography variant="h6" color="text.secondary">Loading tracking data…</Typography>
      </Box>
    );
  }

  // ── Render: Error ─────────────────────────────────────────────────────────
  if (error || !request) {
    return (
      <Container maxWidth="sm" sx={{ mt: 8 }}>
        <Alert severity="error" variant="filled" sx={{ borderRadius: 2, mb: 2 }}>
          Could not load tracking data for request <strong>{requestId}</strong>. Please check the URL and try again.
        </Alert>
        <Button startIcon={<ArrowBackIcon />} onClick={() => navigate('/')} variant="outlined">
          Back to Booking
        </Button>
      </Container>
    );
  }

  // ── Render: Main ──────────────────────────────────────────────────────────
  return (
    <Container maxWidth="xl" sx={{ pb: 6 }}>

      {/* ── Top Header ── */}
      <Card className="glass-panel" sx={{ mb: 3, px: 3, py: 2 }}>
        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: 2 }}>
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
            <IconButton onClick={() => navigate('/')} size="small" sx={{ color: 'text.secondary' }}>
              <ArrowBackIcon />
            </IconButton>
            <Box>
              <Typography variant="h6" sx={{ fontWeight: 800, lineHeight: 1.2 }}>
                Live Ambulance Tracking
              </Typography>
              <Typography variant="caption" color="text.secondary" sx={{ fontFamily: 'monospace', letterSpacing: 0.5 }}>
                {request.requestNumber} &bull; ID: {requestId?.slice(0, 8)}…
              </Typography>
            </Box>
          </Box>

          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
            {/* Connection badge */}
            <Tooltip title={socketConnected ? 'Live WebSocket connected' : `HTTP polling every 5s • Last: ${formatTimestamp(lastPollAt)}`}>
              <Chip
                icon={socketConnected ? <WifiIcon sx={{ fontSize: '0.9rem !important' }} /> : <WifiOffIcon sx={{ fontSize: '0.9rem !important' }} />}
                label={socketConnected ? 'Live' : 'Polling'}
                size="small"
                sx={{
                  bgcolor: socketConnected ? 'rgba(107,165,57,0.15)' : 'rgba(245,158,11,0.15)',
                  color:   socketConnected ? '#6ba539' : '#f59e0b',
                  border:  `1px solid ${socketConnected ? 'rgba(107,165,57,0.4)' : 'rgba(245,158,11,0.4)'}`,
                  fontWeight: 700,
                }}
              />
            </Tooltip>

            {/* Status badge */}
            <Chip
              label={effectiveStatus.replace('_', ' ')}
              sx={{
                bgcolor: statusBg,
                color:   statusColor,
                border:  `1px solid ${statusColor}44`,
                fontWeight: 800,
                fontSize: '0.85rem',
                px: 0.5,
              }}
            />

            {/* Manual refresh */}
            <Tooltip title="Refresh now">
              <IconButton size="small" onClick={() => refetch()} sx={{ color: 'text.secondary' }}>
                <RefreshIcon fontSize="small" />
              </IconButton>
            </Tooltip>

            {/* Cancel button */}
            {!isTerminal && (
              <Button
                variant="outlined"
                color="error"
                size="small"
                startIcon={<CancelIcon />}
                onClick={() => setCancelOpen(true)}
                sx={{ borderColor: 'rgba(239,68,68,0.4)', '&:hover': { borderColor: '#ef4444', bgcolor: 'rgba(239,68,68,0.08)' } }}
              >
                Cancel
              </Button>
            )}
          </Box>
        </Box>
      </Card>

      {/* ── Status Timeline Stepper ── */}
      <Card className="glass-panel" sx={{ mb: 3, px: 3, py: 2.5 }}>
        <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', position: 'relative' }}>
          {/* Connector line behind steps */}
          <Box sx={{
            position: 'absolute', top: '50%', left: '5%', right: '5%', height: 3,
            background: 'rgba(255,255,255,0.06)', borderRadius: 2, zIndex: 0,
            transform: 'translateY(-50%)',
          }} />
          {/* Filled connector showing progress */}
          <Box sx={{
            position: 'absolute', top: '50%', left: '5%',
            width: `${Math.min((currentStep / (STATUS_STEPS.length - 1)) * 90, 90)}%`,
            height: 3, borderRadius: 2, zIndex: 1,
            transform: 'translateY(-50%)',
            background: `linear-gradient(90deg, ${statusColor}, ${statusColor}88)`,
            transition: 'width 0.6s ease',
          }} />

          {STATUS_STEPS.map((step, idx) => {
            const isActive    = idx === currentStep && !isTerminal;
            const isCompleted = idx < currentStep || effectiveStatus === 'COMPLETED';
            const isCancelled = effectiveStatus === 'CANCELLED' || effectiveStatus === 'FAILED';

            return (
              <Box key={step.key} sx={{ display: 'flex', flexDirection: 'column', alignItems: 'center', zIndex: 2, flex: 1 }}>
                <Box sx={{
                  width: 40, height: 40, borderRadius: '50%',
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  fontSize: isActive ? '1.3rem' : '1rem',
                  border: `2.5px solid ${isCompleted ? step.color : isActive ? step.color : 'rgba(255,255,255,0.1)'}`,
                  bgcolor: isCompleted ? `${step.color}22` : isActive ? `${step.color}33` : 'rgba(15,23,42,0.8)',
                  boxShadow: isActive ? `0 0 14px ${step.color}88` : 'none',
                  transition: 'all 0.4s ease',
                  position: 'relative',
                }}>
                  {isCompleted ? (
                    <CheckCircleIcon sx={{ color: step.color, fontSize: '1.1rem' }} />
                  ) : isActive ? (
                    <Box sx={{ fontSize: '1.1rem' }}>{step.icon}</Box>
                  ) : isCancelled && idx > currentStep ? (
                    <RadioButtonUncheckedIcon sx={{ color: 'rgba(255,255,255,0.15)', fontSize: '1rem' }} />
                  ) : (
                    <HourglassEmptyIcon sx={{ color: 'rgba(255,255,255,0.2)', fontSize: '0.9rem' }} />
                  )}
                  {isActive && (
                    <Box sx={{
                      position: 'absolute', inset: -4, borderRadius: '50%',
                      border: `2px solid ${step.color}`,
                      animation: 'pulsate 1.5s ease-out infinite',
                    }} />
                  )}
                </Box>
                <Typography
                  variant="caption"
                  sx={{
                    mt: 0.8,
                    fontWeight: isActive ? 800 : isCompleted ? 600 : 400,
                    color: isActive ? step.color : isCompleted ? 'rgba(255,255,255,0.7)' : 'rgba(255,255,255,0.25)',
                    fontSize: '0.7rem',
                    display: { xs: 'none', sm: 'block' },
                    textAlign: 'center',
                  }}
                >
                  {step.label}
                </Typography>
              </Box>
            );
          })}

          {/* CANCELLED / FAILED override badge */}
          {(effectiveStatus === 'CANCELLED' || effectiveStatus === 'FAILED') && (
            <Chip
              label={effectiveStatus}
              sx={{
                position: 'absolute', right: -8, top: -8,
                bgcolor: 'rgba(239,68,68,0.2)', color: '#ef4444',
                border: '1px solid rgba(239,68,68,0.4)', fontWeight: 800, fontSize: '0.75rem',
              }}
            />
          )}
        </Box>
      </Card>

      {/* ── Main Content Grid ── */}
      <Grid container spacing={3}>

        {/* ── Map Column ── */}
        <Grid size={{ xs: 12, lg: 8 }}>
          <Card className="glass-panel" sx={{ height: { xs: 380, md: 560 }, p: 1.5, position: 'relative' }}>
            <div ref={mapContainerRef} style={{ width: '100%', height: '100%', borderRadius: 10 }} />

            {/* Map Legend */}
            <Box sx={{
              position: 'absolute', bottom: 20, left: 20,
              bgcolor: 'rgba(7,10,19,0.85)', backdropFilter: 'blur(8px)',
              border: '1px solid rgba(255,255,255,0.1)', borderRadius: 2,
              px: 1.5, py: 1, display: 'flex', flexDirection: 'column', gap: 0.6, zIndex: 1000,
            }}>
              <LegendItem color="#6ba539" emoji="🧑" label={`Pickup · ${request.patientName}`} />
              <LegendItem color="#ef4444" emoji="🏥" label="Destination Hospital" />
              {effectiveLocation && <LegendItem color="#3b82f6" emoji="🚑" label="Ambulance (Live)" />}
            </Box>

            {/* Ambulance speed overlay */}
            {effectiveLocation?.speedKmph != null && (
              <Box sx={{
                position: 'absolute', top: 20, right: 20,
                bgcolor: 'rgba(7,10,19,0.85)', backdropFilter: 'blur(8px)',
                border: '1px solid rgba(59,130,246,0.3)', borderRadius: 2,
                px: 2, py: 1, display: 'flex', alignItems: 'center', gap: 1, zIndex: 1000,
              }}>
                <SpeedIcon sx={{ color: '#3b82f6', fontSize: '1.1rem' }} />
                <Typography variant="body2" sx={{ fontWeight: 700, color: '#3b82f6' }}>
                  {effectiveLocation.speedKmph} km/h
                </Typography>
              </Box>
            )}
          </Card>
        </Grid>

        {/* ── Info Column ── */}
        <Grid size={{ xs: 12, lg: 4 }}>
          <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2.5, height: '100%' }}>

            {/* ETA Card */}
            <Card sx={{
              background: `linear-gradient(135deg, rgba(15,23,42,0.9) 0%, ${statusBg} 100%)`,
              border: `1px solid ${statusColor}44`,
              boxShadow: `0 8px 32px ${statusColor}22`,
              backdropFilter: 'blur(16px)',
            }}>
              <CardContent sx={{ textAlign: 'center', py: 3.5 }}>
                <AccessTimeIcon sx={{ fontSize: 44, color: statusColor, mb: 1 }} />
                <Typography variant="body2" color="text.secondary" sx={{ fontWeight: 600, mb: 0.5, textTransform: 'uppercase', letterSpacing: 1 }}>
                  Estimated Arrival
                </Typography>
                <Typography variant="h2" sx={{ fontWeight: 900, color: '#fff', lineHeight: 1.1, mb: 0.5 }}>
                  {etaLabel}
                </Typography>
                {etaSublabel && (
                  <Typography variant="caption" color="text.secondary">{etaSublabel}</Typography>
                )}
                <Divider sx={{ my: 2, borderColor: 'rgba(255,255,255,0.06)' }} />
                <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <Typography variant="caption" color="text.secondary">Last Updated</Typography>
                  <Typography variant="caption" sx={{ fontWeight: 700, color: '#94a3b8', fontFamily: 'monospace' }}>
                    {formatTimestamp(effectiveUpdatedAt)}
                  </Typography>
                </Box>
              </CardContent>
            </Card>

            {/* Driver Card */}
            <Card className="glass-panel" sx={{ flex: 1 }}>
              <CardContent sx={{ p: 2.5 }}>
                <Typography variant="subtitle1" sx={{ fontWeight: 700, display: 'flex', alignItems: 'center', gap: 1, mb: 2 }}>
                  <DirectionsCarIcon sx={{ color: '#3b82f6' }} />
                  Driver & Vehicle
                </Typography>

                {effectiveDriver ? (
                  <Box>
                    {/* Driver avatar + name */}
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mb: 2.5 }}>
                      <Avatar sx={{
                        width: 54, height: 54,
                        background: 'linear-gradient(135deg,#6ba539,#4f8524)',
                        fontSize: '1.3rem', fontWeight: 800,
                        boxShadow: '0 4px 12px rgba(107,165,57,0.4)',
                      }}>
                        {effectiveDriver.name?.charAt(0)?.toUpperCase()}
                      </Avatar>
                      <Box>
                        <Typography variant="h6" sx={{ fontWeight: 800, lineHeight: 1.2 }}>
                          {effectiveDriver.name}
                        </Typography>
                        <Typography variant="caption" sx={{
                          color: '#6ba539', fontWeight: 600,
                          background: 'rgba(107,165,57,0.1)', px: 1, py: 0.3,
                          borderRadius: 1, border: '1px solid rgba(107,165,57,0.2)',
                        }}>
                          {formatAmbulanceType(effectiveDriver.ambulanceType)}
                        </Typography>
                      </Box>
                    </Box>

                    <Divider sx={{ mb: 2, borderColor: 'rgba(255,255,255,0.05)' }} />

                    {/* Detail rows */}
                    <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1.5 }}>
                      <DriverRow icon={<BadgeIcon fontSize="small" sx={{ color: '#94a3b8' }} />}
                        label="Vehicle No." value={effectiveDriver.vehicleNumber} />
                      <DriverRow icon={<PersonIcon fontSize="small" sx={{ color: '#94a3b8' }} />}
                        label="Driver Ref" value={effectiveDriver.vendorDriverRef} mono />
                      {effectiveLocation?.headingDeg != null && (
                        <DriverRow icon={<NavigationIcon fontSize="small" sx={{ color: '#94a3b8' }} />}
                          label="Heading" value={`${effectiveLocation.headingDeg}°`} />
                      )}
                    </Box>

                    <Divider sx={{ my: 2, borderColor: 'rgba(255,255,255,0.05)' }} />

                    {/* Call button */}
                    <Button
                      fullWidth
                      variant="contained"
                      startIcon={<PhoneIcon />}
                      href={`tel:${effectiveDriver.phoneE164}`}
                      sx={{
                        background: 'linear-gradient(90deg,#6ba539,#4f8524)',
                        fontWeight: 700,
                        boxShadow: '0 4px 12px rgba(107,165,57,0.3)',
                        '&:hover': { boxShadow: '0 6px 18px rgba(107,165,57,0.4)' },
                      }}
                    >
                      Call Driver · {effectiveDriver.phoneE164}
                    </Button>
                  </Box>
                ) : (
                  <Box sx={{ textAlign: 'center', py: 4 }}>
                    <CircularProgress size={36} sx={{ color: '#3b82f6', mb: 2 }} />
                    <Typography variant="body2" color="text.secondary" sx={{ fontWeight: 600 }}>
                      Waiting for driver assignment…
                    </Typography>
                    <Typography variant="caption" color="text.secondary" sx={{ mt: 0.5, display: 'block' }}>
                      Our dispatch system is routing the nearest unit
                    </Typography>
                  </Box>
                )}
              </CardContent>
            </Card>

            {/* Request Details Card */}
            <Card className="glass-panel">
              <CardContent sx={{ p: 2.5 }}>
                <Typography variant="subtitle2" sx={{ fontWeight: 700, display: 'flex', alignItems: 'center', gap: 1, mb: 1.5 }}>
                  <LocalHospitalIcon sx={{ color: '#6ba539', fontSize: '1.1rem' }} />
                  Request Info
                </Typography>
                <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1 }}>
                  <InfoRow label="Patient"  value={request.patientName} />
                  <InfoRow label="Ref No."  value={request.requestNumber} mono />
                  <InfoRow label="Pickup"   value={`${request.pickupLat.toFixed(4)}, ${request.pickupLng.toFixed(4)}`} mono />
                  <InfoRow label="Drop"     value={`${request.dropLat.toFixed(4)}, ${request.dropLng.toFixed(4)}`} mono />
                  {effectiveLocation?.capturedAt && (
                    <InfoRow label="GPS Time" value={formatTimestamp(effectiveLocation.capturedAt)} mono />
                  )}
                </Box>
              </CardContent>
            </Card>
          </Box>
        </Grid>
      </Grid>

      {/* ── Cancel Dialog ── */}
      <Dialog
        open={cancelOpen}
        onClose={() => setCancelOpen(false)}
        slotProps={{ paper: { sx: { bgcolor: 'rgba(10,15,30,0.97)', backdropFilter: 'blur(20px)', border: '1px solid rgba(255,255,255,0.08)', borderRadius: 3, minWidth: 360 } } }}
      >
        <DialogTitle sx={{ fontWeight: 800, pb: 0 }}>Cancel Ambulance Request</DialogTitle>
        <DialogContent sx={{ pt: 2 }}>
          <Alert severity="warning" sx={{ mb: 2.5, borderRadius: 2, bgcolor: 'rgba(245,158,11,0.08)', border: '1px solid rgba(245,158,11,0.2)' }}>
            Are you sure? This action cannot be undone.
          </Alert>
          <TextField
            fullWidth select label="Cancellation Reason"
            value={cancelReason}
            onChange={(e) => setCancelReason(e.target.value)}
            variant="outlined"
          >
            <MenuItem value="PATIENT_RECOVERED">Patient recovered / no longer required</MenuItem>
            <MenuItem value="DELAYED_ARRIVAL">Ambulance delay is too long</MenuItem>
            <MenuItem value="OTHER_TRANSPORT">Found alternative transport</MenuItem>
            <MenuItem value="INCORRECT_ADDRESS">Address / details entered incorrectly</MenuItem>
            <MenuItem value="OTHER">Other reason</MenuItem>
          </TextField>
        </DialogContent>
        <DialogActions sx={{ px: 3, pb: 3, gap: 1 }}>
          <Button onClick={() => setCancelOpen(false)} color="inherit" variant="outlined" disabled={cancelling}>
            Dismiss
          </Button>
          <Button
            onClick={handleCancelSubmit}
            color="error" variant="contained"
            disabled={cancelling}
            startIcon={cancelling ? <CircularProgress size={16} color="inherit" /> : <CancelIcon />}
          >
            {cancelling ? 'Cancelling…' : 'Confirm Cancel'}
          </Button>
        </DialogActions>
      </Dialog>
    </Container>
  );
}

// ─── Sub-components ──────────────────────────────────────────────────────────

function LegendItem({ color, emoji, label }: { color: string; emoji: string; label: string }) {
  return (
    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
      <Box sx={{ width: 10, height: 10, borderRadius: '50%', bgcolor: color, flexShrink: 0 }} />
      <Typography variant="caption" sx={{ color: 'rgba(255,255,255,0.7)', fontWeight: 500, whiteSpace: 'nowrap' }}>
        {emoji} {label}
      </Typography>
    </Box>
  );
}

function DriverRow({ icon, label, value, mono }: { icon: React.ReactNode; label: string; value: string; mono?: boolean }) {
  return (
    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
      {icon}
      <Box sx={{ display: 'flex', justifyContent: 'space-between', flex: 1, alignItems: 'center' }}>
        <Typography variant="caption" color="text.secondary" sx={{ fontWeight: 500 }}>{label}</Typography>
        <Typography variant="body2" sx={{ fontWeight: 700, fontFamily: mono ? 'monospace' : 'inherit', color: '#f1f5f9' }}>
          {value}
        </Typography>
      </Box>
    </Box>
  );
}

function InfoRow({ label, value, mono }: { label: string; value: string; mono?: boolean }) {
  return (
    <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
      <Typography variant="caption" color="text.secondary">{label}</Typography>
      <Typography variant="caption" sx={{ fontWeight: 600, fontFamily: mono ? 'monospace' : 'inherit', color: '#cbd5e1' }}>
        {value}
      </Typography>
    </Box>
  );
}
