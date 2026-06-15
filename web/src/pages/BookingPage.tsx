import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import axios from 'axios';
import { 
  Box, 
  Container,
  Card, 
  CardContent, 
  Typography, 
  TextField, 
  Button, 
  MenuItem, 
  Grid, 
  Alert,
  CircularProgress,
  Snackbar
} from '@mui/material';
import LocalHospitalIcon from '@mui/icons-material/LocalHospital';
import MyLocationIcon from '@mui/icons-material/MyLocation';

const API_BASE_URL = 'http://localhost:3000';

// Predefined test coordinate pairs to make manual testing seamless
const PRESETS = [
  { name: 'Hyderabad HQ', pick: { lat: 17.4483, lng: 78.3741 }, drop: { lat: 17.4933, lng: 78.3914 } },
  { name: 'Bengaluru Core', pick: { lat: 12.9716, lng: 77.5946 }, drop: { lat: 12.9724, lng: 77.5953 } },
];

export default function BookingPage() {
  const navigate = useNavigate();
  const [loading, setLoading] = useState(false);
  const [errorMsg, setErrorMsg] = useState<string | null>(null);
  const [successSnack, setSuccessSnack] = useState(false);

  // Form Fields
  const [patientName, setPatientName] = useState('Lavanya');
  const [patientPhone, setPatientPhone] = useState('+919999999999');
  const [priority, setPriority] = useState<'normal' | 'high' | 'critical'>('normal');
  const [pickupLat, setPickupLat] = useState('17.3850');
  const [pickupLng, setPickupLng] = useState('78.4860');
  const [dropLat, setDropLat] = useState('17.4100');
  const [dropLng, setDropLng] = useState('78.5000');
  const [notes, setNotes] = useState('Emergency medical request');

  const applyPreset = (preset: typeof PRESETS[0]) => {
    setPickupLat(preset.pick.lat.toString());
    setPickupLng(preset.pick.lng.toString());
    setDropLat(preset.drop.lat.toString());
    setDropLng(preset.drop.lng.toString());
  };

  const handleGetCurrentLocation = () => {
    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition(
        (position) => {
          setPickupLat(position.coords.latitude.toFixed(6));
          setPickupLng(position.coords.longitude.toFixed(6));
        },
        () => {
          setErrorMsg('Failed to fetch browser location. Using default.');
        }
      );
    } else {
      setErrorMsg('Browser location not supported.');
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setErrorMsg(null);

    const latPick = parseFloat(pickupLat);
    const lngPick = parseFloat(pickupLng);
    const latDrop = parseFloat(dropLat);
    const lngDrop = parseFloat(dropLng);

    if (isNaN(latPick) || isNaN(lngPick) || isNaN(latDrop) || isNaN(lngDrop)) {
      setErrorMsg('Please enter valid numeric latitude and longitude coordinates.');
      setLoading(false);
      return;
    }

    const requestPayload = {
      idempotencyKey: crypto.randomUUID(),
      priority,
      pickup: {
        lat: latPick,
        lng: lngPick,
        addressLine: 'Pickup Point'
      },
      drop: {
        lat: latDrop,
        lng: lngDrop,
        addressLine: 'Destination Hospital'
      },
      patient: {
        name: patientName,
        phoneE164: patientPhone
      },
      notes
    };

    try {
      const response = await axios.post(`${API_BASE_URL}/patient/requests`, requestPayload);
      setSuccessSnack(true);
      
      // Short delay for the success toast before navigation
      setTimeout(() => {
        navigate(`/tracking/${response.data.requestId}`);
      }, 1500);
    } catch (err: any) {
      const serverErr = err.response?.data?.message;
      setErrorMsg(
        Array.isArray(serverErr)
          ? serverErr.join(', ')
          : serverErr || 'An error occurred during booking. Please try again.'
      );
      setLoading(false);
    }
  };

  return (
    <Container maxWidth="md" sx={{ mt: 2 }}>
      <Box sx={{ textAlign: 'center', mb: 4 }}>
        <Typography 
          variant="h3" 
          component="h1" 
          gutterBottom
          sx={{ fontWeight: 800, background: 'linear-gradient(135deg, #f8fafc 30%, #94a3b8 100%)', WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent' }}
        >
          Book Emergency Ambulance
        </Typography>
        <Typography variant="body1" color="text.secondary" sx={{ maxWidth: '600px', mx: 'auto' }}>
          Connect instantly to our premium, automated routing matrix. Enter patient coordinates to dispatch the nearest active unit.
        </Typography>
      </Box>

      {errorMsg && (
        <Alert severity="error" sx={{ mb: 3, borderRadius: '8px' }}>
          {errorMsg}
        </Alert>
      )}

      {/* Coordinate Presets */}
      <Box sx={{ display: 'flex', gap: 2, mb: 3, justifyContent: 'center', flexWrap: 'wrap' }}>
        {PRESETS.map((preset) => (
          <Button
            key={preset.name}
            variant="outlined"
            size="small"
            color="secondary"
            onClick={() => applyPreset(preset)}
            sx={{ borderRadius: '20px' }}
          >
            Apply {preset.name}
          </Button>
        ))}
      </Box>

      <Card className="glass-panel" sx={{ border: '1px solid rgba(255, 255, 255, 0.08)' }}>
        <CardContent sx={{ p: 4 }}>
          <form onSubmit={handleSubmit}>
            <Typography variant="h5" sx={{ mb: 3, fontWeight: 700, display: 'flex', alignItems: 'center', gap: 1 }}>
              <LocalHospitalIcon color="primary" /> Patient & Urgency
            </Typography>
            <Grid container spacing={3} sx={{ mb: 4 }}>
              <Grid size={{ xs: 12, sm: 6 }}>
                <TextField
                  fullWidth
                  label="Patient Name"
                  value={patientName}
                  onChange={(e) => setPatientName(e.target.value)}
                  required
                />
              </Grid>
              <Grid size={{ xs: 12, sm: 6 }}>
                <TextField
                  fullWidth
                  label="Phone Number (E.164)"
                  value={patientPhone}
                  onChange={(e) => setPatientPhone(e.target.value)}
                  required
                  helperText="e.g. +919999999999"
                />
              </Grid>
              <Grid size={{ xs: 12, sm: 6 }}>
                <TextField
                  fullWidth
                  select
                  label="Urgency Level"
                  value={priority}
                  onChange={(e) => setPriority(e.target.value as any)}
                >
                  <MenuItem value="normal">Normal Priority</MenuItem>
                  <MenuItem value="urgent">Urgent Priority (High)</MenuItem>
                  <MenuItem value="critical">Critical Priority (Immediate)</MenuItem>
                </TextField>
              </Grid>
              <Grid size={{ xs: 12, sm: 6 }}>
                <TextField
                  fullWidth
                  label="Dispatcher Notes"
                  value={notes}
                  onChange={(e) => setNotes(e.target.value)}
                  required
                />
              </Grid>
            </Grid>

            <Typography variant="h5" sx={{ mb: 3, fontWeight: 700, display: 'flex', alignItems: 'center', gap: 1 }}>
              <MyLocationIcon color="secondary" /> Geographic Coordinates
            </Typography>
            <Grid container spacing={3} sx={{ mb: 4 }}>
              {/* Pickup Lat / Lng */}
              <Grid size={{ xs: 12, sm: 6 }}>
                <Grid container spacing={2}>
                  <Grid size={12}>
                    <Typography variant="subtitle2" color="text.secondary" gutterBottom>
                      Pickup Location
                    </Typography>
                  </Grid>
                  <Grid size={6}>
                    <TextField
                      fullWidth
                      label="Pickup Lat"
                      value={pickupLat}
                      onChange={(e) => setPickupLat(e.target.value)}
                      required
                    />
                  </Grid>
                  <Grid size={6}>
                    <TextField
                      fullWidth
                      label="Pickup Lng"
                      value={pickupLng}
                      onChange={(e) => setPickupLng(e.target.value)}
                      required
                    />
                  </Grid>
                  <Grid size={12}>
                    <Button
                      size="small"
                      startIcon={<MyLocationIcon />}
                      onClick={handleGetCurrentLocation}
                      sx={{ color: '#3b82f6' }}
                    >
                      Locate Me
                    </Button>
                  </Grid>
                </Grid>
              </Grid>

              {/* Destination Lat / Lng */}
              <Grid size={{ xs: 12, sm: 6 }}>
                <Grid container spacing={2}>
                  <Grid size={12}>
                    <Typography variant="subtitle2" color="text.secondary" gutterBottom>
                      Destination Location
                    </Typography>
                  </Grid>
                  <Grid size={6}>
                    <TextField
                      fullWidth
                      label="Drop Lat"
                      value={dropLat}
                      onChange={(e) => setDropLat(e.target.value)}
                      required
                    />
                  </Grid>
                  <Grid size={6}>
                    <TextField
                      fullWidth
                      label="Drop Lng"
                      value={dropLng}
                      onChange={(e) => setDropLng(e.target.value)}
                      required
                    />
                  </Grid>
                </Grid>
              </Grid>
            </Grid>

            <Button
              type="submit"
              variant="contained"
              color="primary"
              size="large"
              fullWidth
              disabled={loading}
              sx={{ 
                py: 1.8, 
                fontSize: '1.1rem',
                background: 'linear-gradient(90deg, #6ba539 0%, #4f8524 100%)',
                boxShadow: '0 8px 16px rgba(107, 165, 57, 0.2)'
              }}
            >
              {loading ? (
                <CircularProgress size={24} color="inherit" />
              ) : (
                'Request Ambulance'
              )}
            </Button>
          </form>
        </CardContent>
      </Card>

      <Snackbar 
        open={successSnack} 
        autoHideDuration={2000}
        anchorOrigin={{ vertical: 'bottom', horizontal: 'center' }}
      >
        <Alert severity="success" sx={{ width: '100%', borderRadius: '8px' }}>
          Ambulance request created successfully! Redirecting to live tracking...
        </Alert>
      </Snackbar>
    </Container>
  );
}
