import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import axios from 'axios';
import {
  Box, Container, Card, CardContent, Typography, TextField,
  Button, Grid, Alert, CircularProgress, Dialog,
  Fade, Grow, Chip, Switch, FormControlLabel, Divider, Stack
} from '@mui/material';
import MyLocationIcon from '@mui/icons-material/MyLocation';
import CheckCircleIcon from '@mui/icons-material/CheckCircle';
import ErrorIcon from '@mui/icons-material/Error';
import LocationOnIcon from '@mui/icons-material/LocationOn';
import AdminPanelSettingsIcon from '@mui/icons-material/AdminPanelSettings';
import AccountBalanceWalletIcon from '@mui/icons-material/AccountBalanceWallet';
import LockIcon from '@mui/icons-material/Lock';
import AddressAutocomplete from '../components/AddressAutocomplete';
import type { LocationResult } from '../components/AddressAutocomplete';

const API_BASE_URL = 'http://localhost:3000';

const AMBULANCE_TYPES = [
  { id: 'BLS', title: '🟢 Standard Ambulance', desc: 'General medical emergencies and patient transport.', color: '#76B82A', baseFare: 1250 },
  { id: 'ALS', title: '🟠 Emergency Ambulance', desc: 'For serious emergencies requiring advanced medical care.', color: '#F4B400', baseFare: 2500 },
  { id: 'ICU', title: '🔴 Critical Care Ambulance', desc: 'For ICU-level patients needing life-support equipment.', color: '#E53935', baseFare: 3500 },
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
  
  // Payment Flow State: 'idle' | 'processing' | 'success' | 'failed'
  const [paymentState, setPaymentState] = useState<'idle' | 'processing' | 'success' | 'failed'>('idle');
  const [paymentModalOpen, setPaymentModalOpen] = useState(false);
  const [createdRequestId, setCreatedRequestId] = useState<string | null>(null);
  const [transactionRef, setTransactionRef] = useState<string | null>(null);
  const [paymentError, setPaymentError] = useState<string | null>(null);

  // Form Fields
  const [patientName, setPatientName] = useState('');
  const [patientPhone, setPatientPhone] = useState('');
  const [priority, setPriority] = useState<'normal' | 'high' | 'critical'>('normal');
  const [ambulanceType, setAmbulanceType] = useState('BLS');
  const [notes, setNotes] = useState('');

  // Wallet State
  const [walletEligible, setWalletEligible] = useState(false);
  const [applyWallet, setApplyWallet] = useState(true);
  const walletAmount = 50;

  // Location Fields
  const [pickupLocation, setPickupLocation] = useState<LocationResult | null>(null);
  const [pickupInput, setPickupInput] = useState('');
  const [dropLocation, setDropLocation] = useState<LocationResult | null>(null);
  const [dropInput, setDropInput] = useState('');

  const [idempotencyKey] = useState(() => crypto.randomUUID());

  // Calculate local Order Summary amounts
  const selectedTypeObj = AMBULANCE_TYPES.find(t => t.id === ambulanceType) || AMBULANCE_TYPES[0];
  const baseFare = selectedTypeObj.baseFare;
  const walletDiscount = (walletEligible && applyWallet) ? walletAmount : 0;
  const totalPayable = Math.max(0, baseFare - walletDiscount);

  useEffect(() => {
    // Fetch wallet eligibility on load
    axios.get(`${API_BASE_URL}/patient/requests/wallet`, {
      headers: { Authorization: `Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJtb2NrLXBhdGllbnQtaWQiLCJpZCI6Im1vY2stcGF0aWVudC1pZCIsInJvbGUiOiJwYXRpZW50IiwiaWF0IjoxNzgxODQzMDA1LCJleHAiOjQ5Mzc2MDMwMDV9.mock_signature` }
    }).then(res => {
      if (res.data && res.data.ambulanceBenefitEligible) {
        setWalletEligible(true);
        setApplyWallet(true);
      } else {
        setWalletEligible(false);
        setApplyWallet(false);
      }
    }).catch(() => {
      setWalletEligible(false);
    });
  }, []);

  const handleGetCurrentLocation = () => {
    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition(
        async (position) => {
          const lat = position.coords.latitude;
          const lng = position.coords.longitude;
          try {
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

  // Step 1: User clicks "Pay Now" -> Create request & initiate payment state machine
  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (loading) return; // Prevent duplicate clicks

    if (!patientName || !patientPhone || !pickupLocation || !dropLocation) {
      setErrorMsg("Please fill in all required fields and select valid locations.");
      return;
    }

    setLoading(true);
    setErrorMsg(null);
    setPaymentError(null);

    const finalNotes = `[${ambulanceType}] ${notes}`.trim();
    const requestPayload = {
      idempotencyKey,
      priority,
      ambulanceType,
      applyWallet: walletEligible && applyWallet,
      pickup: { lat: pickupLocation.lat, lng: pickupLocation.lng, address: pickupLocation.address },
      drop: { lat: dropLocation.lat, lng: dropLocation.lng, address: dropLocation.address },
      patient: { name: patientName, phoneE164: patientPhone },
      notes: finalNotes
    };

    try {
      // Create request on backend (paymentStatus: PENDING)
      const response = await axios.post(`${API_BASE_URL}/patient/requests`, requestPayload);
      const reqId = response.data.requestId;
      setCreatedRequestId(reqId);
      
      // Open Payment Overlay in PROCESSING state
      setPaymentModalOpen(true);
      setPaymentState('processing');

      // Initiate payment transaction in backend (PENDING)
      await axios.post(`${API_BASE_URL}/patient/requests/${reqId}/payment/initiate`);

      // UX delay (1.5s) to reflect processing state
      await new Promise(resolve => setTimeout(resolve, 1500));

      // Process payment in backend (PROCESSING -> SUCCESS / FAILED)
      await runPaymentProcess(reqId);
    } catch (err: any) {
      const serverErr = err.response?.data?.message;
      setErrorMsg(
        Array.isArray(serverErr)
          ? serverErr.join(', ')
          : serverErr || 'An error occurred during booking. Please try again.'
      );
      setLoading(false);
      setPaymentModalOpen(false);
    }
  };

  // Execute payment processing call on backend
  const runPaymentProcess = async (reqId: string, simulateFail = false) => {
    setPaymentState('processing');
    setPaymentError(null);
    try {
      const res = await axios.post(`${API_BASE_URL}/patient/requests/${reqId}/payment/process`, { simulateFail });
      if (res.data && res.data.status === 'SUCCESS') {
        setTransactionRef(res.data.transactionRef);
        setPaymentState('success');
        setLoading(false);
      } else {
        setPaymentError(res.data?.message || 'Payment failed.');
        setPaymentState('failed');
        setLoading(false);
      }
    } catch (err: any) {
      setPaymentError(err.response?.data?.message || 'Payment processing failed. Please retry.');
      setPaymentState('failed');
      setLoading(false);
    }
  };

  const handleRetryPayment = () => {
    if (createdRequestId) {
      runPaymentProcess(createdRequestId, false);
    }
  };

  return (
    <Container maxWidth="md" sx={{ mt: 2, pb: 8, position: 'relative' }}>

      {/* Admin Login Link */}
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
          Fast, reliable emergency ambulance service. Enter your details to calculate fare and dispatch nearest unit.
        </Typography>
      </Box>

      {errorMsg && (
        <Alert severity="error" sx={{ mb: 3, borderRadius: '12px' }}>{errorMsg}</Alert>
      )}

      <form onSubmit={handleSubmit}>

        {/* --- Location Card --- */}
        <Card sx={{ mb: 3, p: 1, borderRadius: '20px' }}>
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
                  placeholder="Search pickup address..."
                  value={pickupInput}
                  onChange={setPickupInput}
                  onSelectLocation={setPickupLocation}
                />
              </Grid>

              <Grid size={{ xs: 12 }}>
                <Typography variant="subtitle2" sx={{ fontWeight: 600, mb: 1, color: '#4b5563' }}>Drop / Hospital Location</Typography>
                <AddressAutocomplete
                  placeholder="Search hospital or destination address..."
                  value={dropInput}
                  onChange={setDropInput}
                  onSelectLocation={setDropLocation}
                />
              </Grid>
            </Grid>
          </CardContent>
        </Card>

        {/* --- Patient Details Card --- */}
        <Card sx={{ mb: 3, p: 1, borderRadius: '20px' }}>
          <CardContent>
            <Typography variant="h6" sx={{ mb: 3, fontWeight: 800, display: 'flex', alignItems: 'center', gap: 1, color: '#1E3A5F' }}>
              <LocalHospitalIcon color="primary" /> Patient & Emergency Details
            </Typography>

            <Grid container spacing={3}>
              <Grid size={{ xs: 12, md: 6 }}>
                <Typography variant="subtitle2" sx={{ fontWeight: 600, mb: 1, color: '#4b5563' }}>Patient Full Name</Typography>
                <TextField
                  fullWidth
                  placeholder="e.g. John Doe"
                  value={patientName}
                  onChange={(e) => setPatientName(e.target.value)}
                  slotProps={{ input: { sx: { borderRadius: '16px', bgcolor: '#F7F8FA' } } }}
                />
              </Grid>

              <Grid size={{ xs: 12, md: 6 }}>
                <Typography variant="subtitle2" sx={{ fontWeight: 600, mb: 1, color: '#4b5563' }}>Contact Phone</Typography>
                <TextField
                  fullWidth
                  placeholder="e.g. +91 9876543210"
                  value={patientPhone}
                  onChange={(e) => setPatientPhone(e.target.value)}
                  slotProps={{ input: { sx: { borderRadius: '16px', bgcolor: '#F7F8FA' } } }}
                />
              </Grid>

              <Grid size={{ xs: 12 }}>
                <Typography variant="subtitle2" sx={{ fontWeight: 600, mb: 1, color: '#4b5563' }}>Urgency Level</Typography>
                <Box sx={{ display: 'flex', gap: 2, flexWrap: 'wrap' }}>
                  {URGENCY_LEVELS.map((u) => (
                    <Chip
                      key={u.id}
                      label={u.label}
                      onClick={() => setPriority(u.id as any)}
                      sx={{
                        px: 2, py: 2.5,
                        borderRadius: '12px',
                        fontWeight: 700,
                        fontSize: '0.95rem',
                        bgcolor: priority === u.id ? u.color : u.bg,
                        color: priority === u.id ? '#ffffff' : u.color,
                        border: `2px solid ${u.color}`,
                        cursor: 'pointer',
                        '&:hover': { bgcolor: u.color, color: '#ffffff' }
                      }}
                    />
                  ))}
                </Box>
              </Grid>

              <Grid size={{ xs: 12 }}>
                <Typography variant="subtitle2" sx={{ fontWeight: 600, mb: 1, color: '#4b5563' }}>Ambulance Type</Typography>
                <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', md: '1fr 1fr 1fr' }, gap: 2 }}>
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
                      <Typography variant="body2" sx={{ color: '#6b7280', mb: 1 }}>{type.desc}</Typography>
                      <Typography variant="subtitle2" sx={{ fontWeight: 800, color: type.color }}>Fare: ₹{type.baseFare}</Typography>
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

        {/* --- Order Summary & Wallet Card --- */}
        <Card sx={{ mb: 4, p: 1, borderRadius: '20px', border: '1px solid #76B82A44' }}>
          <CardContent>
            <Typography variant="h6" sx={{ mb: 2, fontWeight: 800, color: '#1E3A5F', display: 'flex', alignItems: 'center', gap: 1 }}>
              <AccountBalanceWalletIcon sx={{ color: '#76B82A' }} /> Order & Billing Summary
            </Typography>

            {walletEligible && (
              <Box sx={{ p: 2, bgcolor: '#f1f8eb', borderRadius: '12px', mb: 2, display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                  <AccountBalanceWalletIcon sx={{ color: '#76B82A' }} />
                  <Typography variant="subtitle2" sx={{ fontWeight: 700, color: '#1E3A5F' }}>
                    Apply ₹50 Ambulance Wallet Benefit
                  </Typography>
                </Box>
                <Switch
                  checked={applyWallet}
                  onChange={(e) => setApplyWallet(e.target.checked)}
                  color="success"
                />
              </Box>
            )}

            <Stack spacing={1.5} sx={{ mt: 2 }}>
              <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                <Typography variant="body2" sx={{ color: '#6b7280' }}>Base Fare ({selectedTypeObj.id})</Typography>
                <Typography variant="body2" sx={{ fontWeight: 700, color: '#1E3A5F' }}>₹{baseFare}</Typography>
              </Box>

              {walletDiscount > 0 && (
                <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                  <Typography variant="body2" sx={{ color: '#76B82A', fontWeight: 600 }}>Wallet Benefit Discount</Typography>
                  <Typography variant="body2" sx={{ fontWeight: 700, color: '#76B82A' }}>-₹{walletDiscount}</Typography>
                </Box>
              )}

              <Divider />

              <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <Typography variant="subtitle1" sx={{ fontWeight: 800, color: '#1E3A5F' }}>Total Payable Amount</Typography>
                <Typography variant="h5" sx={{ fontWeight: 900, color: '#1E3A5F' }}>₹{totalPayable}</Typography>
              </Box>
            </Stack>
          </CardContent>
        </Card>

        {/* --- Emergency CTA --- */}
        <Box sx={{ p: 3, bgcolor: '#f0f4f8', borderRadius: '24px', mb: 4, display: 'flex', alignItems: 'center', justifyContent: 'space-between', flexWrap: 'wrap', gap: 2 }}>
          <Box>
            <Typography variant="caption" sx={{ color: '#4b5563', fontWeight: 700, textTransform: 'uppercase' }}>Nearest Ambulance</Typography>
            <Typography variant="h5" sx={{ color: '#1E3A5F', fontWeight: 800 }}>~5 mins away</Typography>
            <Typography variant="body2" sx={{ color: '#6b7280', display: 'flex', alignItems: 'center', gap: 0.5, mt: 0.5 }}>
              <LockIcon sx={{ fontSize: 14, color: '#334155' }} /> 24/7 Secure Dispatch
            </Typography>
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
              minWidth: { xs: '100%', sm: 'auto' },
              fontWeight: 800,
            }}
          >
            {loading ? <CircularProgress size={28} color="inherit" /> : `Pay Now (₹${totalPayable})`}
          </Button>
        </Box>
      </form>

      {/* --- PAYMENT STATE FLOW MODAL --- */}
      <Dialog
        open={paymentModalOpen}
        fullScreen
        slots={{ transition: Fade as any }}
        slotProps={{
          paper: { sx: { bgcolor: '#ffffff', display: 'flex', alignItems: 'center', justifyContent: 'center' } }
        }}
      >
        <Box sx={{ textAlign: 'center', p: 4, maxWidth: 520, width: '100%' }}>
          
          {/* STATE: PROCESSING */}
          {paymentState === 'processing' && (
            <Box>
              <Box sx={{ display: 'inline-flex', p: 3, bgcolor: '#f1f8eb', borderRadius: '50%', mb: 3 }}>
                <CircularProgress size={60} sx={{ color: '#76B82A' }} />
              </Box>
              <Typography variant="h4" sx={{ fontWeight: 900, color: '#1E3A5F', mb: 1 }}>
                Processing Payment
              </Typography>
              <Typography variant="subtitle1" sx={{ color: '#6b7280', mb: 4 }}>
                Verifying and confirming your payment...
              </Typography>
              <Card sx={{ bgcolor: '#f0f4f8', borderRadius: '16px', p: 3, textAlign: 'left', mb: 3 }}>
                <Typography variant="caption" sx={{ color: '#6b7280', fontWeight: 700, textTransform: 'uppercase' }}>Amount to Pay</Typography>
                <Typography variant="h4" sx={{ color: '#1E3A5F', fontWeight: 900, mb: 1 }}>₹{totalPayable}</Typography>
                <Typography variant="body2" sx={{ color: '#4b5563' }}>Ambulance Type: <strong>{selectedTypeObj.title}</strong></Typography>
              </Card>
              <Typography variant="caption" sx={{ color: '#9ca3af' }}>Do not refresh or close this page.</Typography>
            </Box>
          )}

          {/* STATE: SUCCESS */}
          {paymentState === 'success' && (
            <Box>
              <Grow in={paymentState === 'success'} timeout={600}>
                <CheckCircleIcon sx={{ fontSize: 100, color: '#76B82A', mb: 2 }} />
              </Grow>
              <Typography variant="h3" sx={{ fontWeight: 900, color: '#1E3A5F', mb: 1 }}>
                Payment Successful ✓
              </Typography>
              <Typography variant="subtitle1" sx={{ color: '#4b5563', mb: 3, fontWeight: 500 }}>
                Ambulance booking confirmed. Dispatching nearest driver...
              </Typography>
              
              <Card sx={{ bgcolor: '#f0f4f8', mb: 4, borderRadius: '20px', p: 3, textAlign: 'left' }}>
                <Stack spacing={1.5}>
                  <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                    <Typography variant="body2" sx={{ color: '#6b7280' }}>Booking ID</Typography>
                    <Typography variant="body2" sx={{ fontWeight: 800, color: '#1E3A5F' }}>{createdRequestId?.split('-')[0].toUpperCase()}</Typography>
                  </Box>
                  <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                    <Typography variant="body2" sx={{ color: '#6b7280' }}>Payment Reference</Typography>
                    <Typography variant="body2" sx={{ fontWeight: 800, color: '#76B82A' }}>{transactionRef || 'MOCK-SUCCESS'}</Typography>
                  </Box>
                  <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                    <Typography variant="body2" sx={{ color: '#6b7280' }}>Amount Paid</Typography>
                    <Typography variant="body2" sx={{ fontWeight: 900, color: '#1E3A5F' }}>₹{totalPayable}</Typography>
                  </Box>
                  <Divider />
                  <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                    <Typography variant="body2" sx={{ color: '#6b7280' }}>Estimated Arrival</Typography>
                    <Typography variant="body2" sx={{ fontWeight: 800, color: '#76B82A' }}>5 mins</Typography>
                  </Box>
                </Stack>
              </Card>

              <Button
                variant="contained"
                color="primary"
                size="large"
                fullWidth
                onClick={() => navigate(`/tracking/${createdRequestId}`)}
                sx={{ py: 2, fontSize: '1.2rem', borderRadius: '30px', fontWeight: 800 }}
              >
                Track Ambulance
              </Button>
            </Box>
          )}

          {/* STATE: FAILED */}
          {paymentState === 'failed' && (
            <Box>
              <Grow in={paymentState === 'failed'} timeout={600}>
                <ErrorIcon sx={{ fontSize: 100, color: '#E53935', mb: 2 }} />
              </Grow>
              <Typography variant="h3" sx={{ fontWeight: 900, color: '#E53935', mb: 1 }}>
                Payment Failed
              </Typography>
              <Typography variant="subtitle1" sx={{ color: '#4b5563', mb: 3, fontWeight: 500 }}>
                {paymentError || 'Your payment was not completed. Please try again.'}
              </Typography>

              <Stack spacing={2} sx={{ mt: 4 }}>
                <Button
                  variant="contained"
                  color="primary"
                  size="large"
                  fullWidth
                  onClick={handleRetryPayment}
                  sx={{ py: 1.8, fontSize: '1.1rem', borderRadius: '30px', fontWeight: 800 }}
                >
                  Try Again
                </Button>

                <Button
                  variant="outlined"
                  color="secondary"
                  size="large"
                  fullWidth
                  onClick={() => setPaymentModalOpen(false)}
                  sx={{ py: 1.5, fontSize: '1rem', borderRadius: '30px' }}
                >
                  Cancel & Return to Booking
                </Button>
              </Stack>
            </Box>
          )}

        </Box>
      </Dialog>
    </Container>
  );
}
