import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import axios from 'axios';
import { 
  Box, Container, Card, CardContent, Typography, TextField, 
  Button, Grid, Alert, CircularProgress, Dialog, 
  Fade, Grow, Chip
} from '@mui/material';
import MyLocationIcon from '@mui/icons-material/MyLocation';
import CheckCircleIcon from '@mui/icons-material/CheckCircle';
import PersonIcon from '@mui/icons-material/Person';
import LocalHospitalIcon from '@mui/icons-material/LocalHospital';
import LocationOnIcon from '@mui/icons-material/LocationOn';
import AdminPanelSettingsIcon from '@mui/icons-material/AdminPanelSettings';
import AddressAutocomplete from '../components/AddressAutocomplete';
import type { LocationResult } from '../components/AddressAutocomplete';

const API_BASE_URL = 'http://localhost:3000';

const AMBULANCE_TYPES = [
  { id: 'BLS', title: '🟢 Standard Ambulance', desc: 'General medical emergencies and patient transport.', color: '#76B82A' },
  { id: 'ALS', title: '🟠 Emergency Ambulance', desc: 'For serious emergencies requiring advanced medical care.', color: '#F4B400' },
  { id: 'ICU', title: '🔴 Critical Care Ambulance', desc: 'For ICU-level patients needing life-support equipment.', color: '#E53935' },
];
const URGENCY_LEVELS = [
  { id: 'normal', label: 'Normal', color: '#76B82A', bg: '#f1f8eb' },
  { id: 'high', label: 'High', color: '#F4B400', bg: '#fef7e6' },
  { id: 'critical', label: 'Critical', color: '#E53935', bg: '#fcebea' },
];

const COMMON_NOTES = [
  "Difficulty breathing",
  "Needs wheelchair",
  "Severe bleeding",
  "Chest pain",
  "Unconscious",
  "Fever & Chills"
];

export default function BookingPage() {
  const navigate = useNavigate();
  const [loading, setLoading] = useState(false);
  const [errorMsg, setErrorMsg] = useState<string | null>(null);
  const [showSuccess, setShowSuccess] = useState(false);
  const [createdRequestId, setCreatedRequestId] = useState<string | null>(null);

  // Form Fields
  const [patientName, setPatientName] = useState('');
  const [patientPhone, setPatientPhone] = useState('');
  const [priority, setPriority] = useState<'normal' | 'high' | 'critical'>('normal');
  const [ambulanceType, setAmbulanceType] = useState('BLS');
  const [notes, setNotes] = useState('');
  
  // Location Fields
  const [pickupLocation, setPickupLocation] = useState<LocationResult | null>(null);
  const [pickupInput, setPickupInput] = useState('');

  const [dropLocation, setDropLocation] = useState<LocationResult | null>(null);
  const [dropInput, setDropInput] = useState('');

  const [idempotencyKey] = useState(() => crypto.randomUUID());

  const handleGetCurrentLocation = () => {
    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition(
        async (position) => {
          const lat = position.coords.latitude;
          const lng = position.coords.longitude;
          
          try {
            // Reverse geocode to get human readable address
            const res = await axios.get(`https://nominatim.openstreetmap.org/reverse?lat=${lat}&lon=${lng}&format=json`);
            if (res.data && res.data.display_name) {
              setPickupLocation({ address: res.data.display_name, lat, lng, placeId: 'current' });
              setPickupInput(res.data.display_name);
            } else {
              setPickupLocation({ address: "Current Location", lat, lng, placeId: 'current' });
              setPickupInput("Current Location");
            }
          } catch (e) {
            setPickupLocation({ address: "Current Location", lat, lng, placeId: 'current' });
            setPickupInput("Current Location");
          }
        },
        () => setErrorMsg('Failed to fetch browser location.')
      );
    } else {
      setErrorMsg('Browser location not supported.');
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!patientName || !patientPhone || !pickupLocation || !dropLocation) {
      setErrorMsg("Please fill in all required fields and select valid locations.");
      return;
    }

    setLoading(true);
    setErrorMsg(null);

    // Embed ambulanceType into notes to preserve API contract
    const finalNotes = `[${ambulanceType}] ${notes}`.trim();

    const requestPayload = {
      idempotencyKey,
      priority,
      pickup: {
        lat: pickupLocation.lat,
        lng: pickupLocation.lng,
        address: pickupLocation.address
      },
      drop: {
        lat: dropLocation.lat,
        lng: dropLocation.lng,
        address: dropLocation.address
      },
      patient: {
        name: patientName,
        phoneE164: patientPhone
      },
      notes: finalNotes
    };

    try {
      const response = await axios.post(`${API_BASE_URL}/patient/requests`, requestPayload);
      setCreatedRequestId(response.data.requestId);
      setLoading(false);
      setShowSuccess(true);
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
    <Container maxWidth="md" sx={{ mt: 2, pb: 8, position: 'relative' }}>
      
      {/* Admin Login Link in Bottom Right */}
      <Box sx={{ position: 'absolute', bottom: 16, right: 16, zIndex: 10 }}>
        <Button
          variant="outlined"
          color="secondary"
          size="small"
          startIcon={<AdminPanelSettingsIcon />}
          onClick={() => navigate('/admin/login')}
          sx={{ borderRadius: '20px', fontWeight: 600, textTransform: 'none' }}
        >
          Admin Login
        </Button>
      </Box>

      <Box sx={{ mb: 4, mt: 6, textAlign: 'center' }}>
        <Typography variant="h3" sx={{ fontWeight: 900, color: '#1E3A5F', mb: 1, fontSize: { xs: '2rem', md: '2.5rem' } }}>
          Book Emergency Ambulance
        </Typography>
        <Typography variant="subtitle1" sx={{ color: '#4b5563', mb: 4, maxWidth: '700px', mx: 'auto', fontSize: '1.1rem' }}>
          Fast, reliable emergency ambulance service. Enter your pickup location and destination to connect with the nearest available ambulance.
        </Typography>
        
        <Box sx={{ p: 3, bgcolor: '#f0f4f8', borderRadius: '16px', textAlign: 'left', borderLeft: '6px solid #76B82A' }}>
          <Typography variant="h6" sx={{ fontWeight: 800, color: '#1E3A5F', mb: 0.5 }}>
            Need an Ambulance? We're Here to Help
          </Typography>
          <Typography variant="body1" sx={{ color: '#6b7280' }}>
            Request an ambulance in just a few steps. We'll locate the nearest available unit and keep you updated until it arrives.
          </Typography>
        </Box>
      </Box>

      {errorMsg && (
        <Alert severity="error" sx={{ mb: 3, borderRadius: '12px' }}>{errorMsg}</Alert>
      )}

      <form onSubmit={handleSubmit}>
        
        {/* --- Location Card --- */}
        <Card sx={{ mb: 3, p: 1 }}>
          <CardContent>
            <Typography variant="h6" sx={{ mb: 3, fontWeight: 800, display: 'flex', alignItems: 'center', gap: 1, color: '#1E3A5F' }}>
              <LocationOnIcon color="primary" /> Location Details
            </Typography>
            
            <Grid container spacing={3}>
              <Grid size={{ xs: 12 }}>
                <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-end', mb: 1 }}>
                  <Typography variant="subtitle2" sx={{ fontWeight: 600, color: '#4b5563' }}>Pickup Location</Typography>
                  <Button 
                    size="small" 
                    startIcon={<MyLocationIcon />} 
                    onClick={handleGetCurrentLocation}
                    sx={{ textTransform: 'none', fontWeight: 700, color: '#1E3A5F', bgcolor: '#f0f4f8', borderRadius: '12px', px: 2, '&:hover': { bgcolor: '#e8ecf1' } }}
                  >
                    Locate Me
                  </Button>
                </Box>
                <AddressAutocomplete
                  placeholder="Enter pickup address or search..."
                  value={pickupLocation}
                  inputValue={pickupInput}
                  onInputValueChange={setPickupInput}
                  onSelect={setPickupLocation}
                />
              </Grid>
              
              <Grid size={{ xs: 12 }}>
                <Typography variant="subtitle2" sx={{ fontWeight: 600, mb: 1, color: '#4b5563' }}>Destination</Typography>
                <AddressAutocomplete
                  placeholder="Search hospital or destination"
                  isHospitalSearch
                  value={dropLocation}
                  inputValue={dropInput}
                  onInputValueChange={setDropInput}
                  onSelect={setDropLocation}
                />
              </Grid>
            </Grid>
          </CardContent>
        </Card>

        {/* --- Patient Info Card --- */}
        <Card sx={{ mb: 3, p: 1 }}>
          <CardContent>
            <Typography variant="h6" sx={{ mb: 3, fontWeight: 800, display: 'flex', alignItems: 'center', gap: 1, color: '#1E3A5F' }}>
              <PersonIcon color="primary" /> Patient Information
            </Typography>
            
            <Grid container spacing={3}>
              <Grid size={{ xs: 12, sm: 6 }}>
                <Typography variant="subtitle2" sx={{ fontWeight: 600, mb: 1, color: '#4b5563' }}>Patient Name</Typography>
                <TextField
                  fullWidth
                  placeholder="e.g. John Doe"
                  value={patientName}
                  onChange={(e) => setPatientName(e.target.value)}
                  slotProps={{ input: { sx: { borderRadius: '16px', bgcolor: '#F7F8FA' } } }}
                />
              </Grid>
              <Grid size={{ xs: 12, sm: 6 }}>
                <Typography variant="subtitle2" sx={{ fontWeight: 600, mb: 1, color: '#4b5563' }}>Phone Number</Typography>
                <TextField
                  fullWidth
                  placeholder="+91..."
                  value={patientPhone}
                  onChange={(e) => setPatientPhone(e.target.value)}
                  slotProps={{ input: { sx: { borderRadius: '16px', bgcolor: '#F7F8FA' } } }}
                />
              </Grid>
              
              {/* Emergency Level (Cards instead of dropdown) */}
              <Grid size={{ xs: 12 }}>
                <Typography variant="subtitle2" sx={{ fontWeight: 600, mb: 1.5, color: '#4b5563' }}>Emergency Level</Typography>
                <Box sx={{ display: 'flex', gap: 2, flexWrap: 'wrap' }}>
                  {URGENCY_LEVELS.map((level) => (
                    <Box 
                      key={level.id}
                      onClick={() => setPriority(level.id as any)}
                      sx={{ 
                        flex: 1, minWidth: '100px', p: 2, textAlign: 'center', cursor: 'pointer',
                        borderRadius: '16px', border: '2px solid',
                        borderColor: priority === level.id ? level.color : '#e5e7eb',
                        bgcolor: priority === level.id ? level.bg : '#ffffff',
                        transition: 'all 0.2s ease',
                      }}
                    >
                      <Typography sx={{ fontWeight: 700, color: priority === level.id ? level.color : '#6b7280' }}>
                        {level.label}
                      </Typography>
                    </Box>
                  ))}
                </Box>
              </Grid>
            </Grid>
          </CardContent>
        </Card>

        {/* --- Medical Details Card --- */}
        <Card sx={{ mb: 4, p: 1 }}>
          <CardContent>
            <Typography variant="h6" sx={{ mb: 3, fontWeight: 800, display: 'flex', alignItems: 'center', gap: 1, color: '#1E3A5F' }}>
              <LocalHospitalIcon color="primary" /> Medical Needs
            </Typography>

            <Grid container spacing={3}>
              {/* Ambulance Type Selection */}
              <Grid size={{ xs: 12 }}>
                <Typography variant="subtitle2" sx={{ fontWeight: 600, mb: 1.5, color: '#4b5563' }}>Ambulance Type</Typography>
                <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
                  {AMBULANCE_TYPES.map((type) => (
                    <Box 
                      key={type.id}
                      onClick={() => setAmbulanceType(type.id)}
                      sx={{ 
                        p: 2, cursor: 'pointer',
                        borderRadius: '16px', border: '2px solid',
                        borderColor: ambulanceType === type.id ? type.color : '#e5e7eb',
                        bgcolor: ambulanceType === type.id ? `${type.color}11` : '#ffffff',
                        transition: 'all 0.2s ease',
                      }}
                    >
                      <Typography sx={{ fontWeight: 800, color: '#1E3A5F', mb: 0.5 }}>{type.title}</Typography>
                      <Typography variant="body2" sx={{ color: '#6b7280' }}>{type.desc}</Typography>
                    </Box>
                  ))}
                </Box>
              </Grid>

              <Grid size={{ xs: 12 }}>
                <Typography variant="subtitle2" sx={{ fontWeight: 600, mb: 1, color: '#4b5563' }}>Patient Notes (Optional)</Typography>
                <Box sx={{ display: 'flex', gap: 1, flexWrap: 'wrap', mb: 2 }}>
                  {COMMON_NOTES.map(note => (
                    <Chip 
                      key={note} 
                      label={`+ ${note}`} 
                      onClick={() => setNotes(prev => prev ? `${prev}, ${note}` : note)}
                      sx={{ bgcolor: '#f0f4f8', color: '#1E3A5F', fontWeight: 600, '&:hover': { bgcolor: '#e8ecf1' } }}
                      clickable
                    />
                  ))}
                </Box>
                <TextField
                  fullWidth
                  multiline
                  rows={2}
                  placeholder="e.g. Difficulty breathing, needs wheelchair..."
                  value={notes}
                  onChange={(e) => setNotes(e.target.value)}
                  slotProps={{ input: { sx: { borderRadius: '16px', bgcolor: '#F7F8FA' } } }}
                />
              </Grid>
            </Grid>
          </CardContent>
        </Card>

        {/* --- Emergency Summary & CTA --- */}
        <Box sx={{ p: 3, bgcolor: '#f0f4f8', borderRadius: '24px', mb: 4, display: 'flex', alignItems: 'center', justifyContent: 'space-between', flexWrap: 'wrap', gap: 2 }}>
          <Box>
            <Typography variant="caption" sx={{ color: '#4b5563', fontWeight: 700, textTransform: 'uppercase' }}>Nearest Ambulance</Typography>
            <Typography variant="h5" sx={{ color: '#1E3A5F', fontWeight: 800 }}>~5 mins away</Typography>
            <Typography variant="body2" sx={{ color: '#6b7280' }}>Service Area: Active</Typography>
          </Box>
          <Button
            type="submit"
            variant="contained"
            color="primary"
            size="large"
            disabled={loading}
            sx={{ 
              py: 2, px: 6,
              fontSize: '1.2rem',
              borderRadius: '30px',
              minWidth: { xs: '100%', sm: 'auto' }
            }}
          >
            {loading ? <CircularProgress size={28} color="inherit" /> : 'Request Ambulance'}
          </Button>
        </Box>
      </form>

      {/* --- Success Overlay --- */}
      <Dialog 
        open={showSuccess} 
        fullScreen 
        slots={{ transition: Fade as any }}
        slotProps={{
          paper: { sx: { bgcolor: '#ffffff', display: 'flex', alignItems: 'center', justifyContent: 'center' } }
        }}
      >
        <Box sx={{ textAlign: 'center', p: 4, maxWidth: 500 }}>
          <Grow in={showSuccess} timeout={800}>
            <CheckCircleIcon sx={{ fontSize: 120, color: '#76B82A', mb: 3 }} />
          </Grow>
          <Typography variant="h3" sx={{ fontWeight: 800, color: '#1E3A5F', mb: 2 }}>
            Ambulance Requested
          </Typography>
          <Typography variant="h6" sx={{ color: '#4b5563', mb: 4, fontWeight: 500 }}>
            Your request has been confirmed. Assigning the nearest driver...
          </Typography>
          <Card sx={{ bgcolor: '#f0f4f8', mb: 5, borderRadius: '20px', p: 3 }}>
            <Typography variant="subtitle2" sx={{ color: '#6b7280', textTransform: 'uppercase', mb: 1 }}>Estimated Arrival</Typography>
            <Typography variant="h2" sx={{ color: '#76B82A', fontWeight: 900 }}>5 min</Typography>
          </Card>
          <Button
            variant="contained"
            color="primary"
            size="large"
            fullWidth
            onClick={() => navigate(`/tracking/${createdRequestId}`)}
            sx={{ py: 2, fontSize: '1.2rem', borderRadius: '30px' }}
          >
            Track Ambulance
          </Button>
        </Box>
      </Dialog>
    </Container>
  );
}
