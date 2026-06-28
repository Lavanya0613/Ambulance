import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import axios from 'axios';
import {
  Box, Container, Typography, Card, CardContent, Chip, Button,
  TextField, InputAdornment, MenuItem,
  Alert, Skeleton, CircularProgress, Grid
} from '@mui/material';
import SearchIcon from '@mui/icons-material/Search';
import RefreshIcon from '@mui/icons-material/Refresh';
import FilterListIcon from '@mui/icons-material/FilterList';
import TrackChangesIcon from '@mui/icons-material/TrackChanges';
import LocalHospitalIcon from '@mui/icons-material/LocalHospital';

const API_BASE_URL = 'http://localhost:3000';

interface AmbulanceRequest {
  requestId: string;
  requestNumber: string;
  status: string;
  patientName: string;
  pickupLat: number;
  pickupLng: number;
  pickupAddress?: string;
  dropAddress?: string;
  createdAt: string;
  updatedAt: string;
  etaSeconds: number | null;
}

const STATUS_META: Record<string, { label: string; color: string; bg: string }> = {
  PENDING:     { label: 'Pending',     color: '#6b7280', bg: '#f3f4f6' },
  ASSIGNED:    { label: 'Assigned',    color: '#1E3A5F', bg: '#e8ecf1' },
  EN_ROUTE:    { label: 'En Route',    color: '#1E3A5F', bg: '#e8ecf1' },
  ARRIVED:     { label: 'Arrived',     color: '#76B82A', bg: '#f1f8eb' },
  IN_PROGRESS: { label: 'In Progress', color: '#1E3A5F', bg: '#e8ecf1' },
  COMPLETED:   { label: 'Completed',   color: '#76B82A', bg: '#f1f8eb' },
  CANCELLED:   { label: 'Cancelled',   color: '#E53935', bg: '#fcebea' },
  FAILED:      { label: 'Failed',      color: '#E53935', bg: '#fcebea' },
};

const ALL_STATUSES = ['ALL', 'PENDING', 'ASSIGNED', 'EN_ROUTE', 'ARRIVED', 'COMPLETED', 'CANCELLED'];

function formatDate(iso: string) {
  const d = new Date(iso);
  return d.toLocaleDateString('en-IN', { day: 'numeric', month: 'long', year: 'numeric' }) +
    ' • ' + d.toLocaleTimeString('en-IN', { hour: '2-digit', minute: '2-digit' });
}

export default function HistoryPage() {
  const navigate = useNavigate();
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('ALL');

  const { data: requests = [], isLoading, error, refetch, isFetching } = useQuery<AmbulanceRequest[]>({
    queryKey: ['requests-history'],
    queryFn: async () => {
      const res = await axios.get(`${API_BASE_URL}/patient/requests`);
      return res.data.data || res.data;
    },
    refetchInterval: 15000,
    staleTime: 5000,
  });

  const filtered = requests.filter((r) => {
    const matchStatus = statusFilter === 'ALL' || r.status === statusFilter;
    const q = search.toLowerCase();
    const matchSearch = !q || 
      r.patientName.toLowerCase().includes(q) || 
      (r.pickupAddress || '').toLowerCase().includes(q) ||
      (r.dropAddress || '').toLowerCase().includes(q);
    return matchStatus && matchSearch;
  });

  return (
    <Container maxWidth="lg" sx={{ pb: 8 }}>
      
      {/* ── Page Header ── */}
      <Box sx={{ mb: 4, display: 'flex', alignItems: 'center', justifyContent: 'space-between', flexWrap: 'wrap', gap: 2 }}>
        <Box>
          <Typography variant="h3" sx={{ fontWeight: 900, color: '#1E3A5F', mb: 1 }}>
            My Requests
          </Typography>
          <Typography variant="body1" color="text.secondary">
            View your ambulance history and past trips.
          </Typography>
        </Box>
        <Button 
          startIcon={isFetching ? <CircularProgress size={16} /> : <RefreshIcon />} 
          onClick={() => refetch()} 
          variant="outlined" 
          disabled={isFetching}
          sx={{ borderRadius: '24px', borderColor: '#e5e7eb', color: '#4b5563' }}
        >
          Refresh
        </Button>
      </Box>

      {/* ── Filters ── */}
      <Box sx={{ display: 'flex', gap: 2, mb: 4, flexWrap: 'wrap' }}>
        <TextField
          placeholder="Search by name or address..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          size="medium"
          sx={{ flex: 1, minWidth: 280 }}
          slotProps={{
            input: {
              startAdornment: <InputAdornment position="start"><SearchIcon sx={{ color: '#9ca3af' }} /></InputAdornment>,
              sx: { borderRadius: '16px', bgcolor: '#ffffff' }
            }
          }}
        />
        <TextField
          select
          value={statusFilter}
          onChange={(e) => setStatusFilter(e.target.value)}
          sx={{ minWidth: 200 }}
          slotProps={{
            input: {
              startAdornment: <InputAdornment position="start"><FilterListIcon sx={{ color: '#9ca3af' }} /></InputAdornment>,
              sx: { borderRadius: '16px', bgcolor: '#ffffff' }
            }
          }}
        >
          {ALL_STATUSES.map((s) => (
            <MenuItem key={s} value={s}>{s === 'ALL' ? 'All Statuses' : (STATUS_META[s]?.label ?? s)}</MenuItem>
          ))}
        </TextField>
      </Box>

      {/* ── Content ── */}
      {error && (
        <Alert severity="error" sx={{ mb: 4, borderRadius: '12px' }}>
          Failed to load requests. Please check your connection.
        </Alert>
      )}

      {isLoading ? (
        <Grid container spacing={3}>
          {[1, 2, 3, 4].map(i => (
            <Grid size={{ xs: 12, md: 6 }} key={i}>
              <Skeleton variant="rectangular" height={200} sx={{ borderRadius: '24px' }} />
            </Grid>
          ))}
        </Grid>
      ) : filtered.length === 0 ? (
        <Box sx={{ textAlign: 'center', py: 10, bgcolor: '#ffffff', borderRadius: '32px', border: '1px dashed #e5e7eb' }}>
          <LocalHospitalIcon sx={{ fontSize: 80, color: '#e8ecf1', mb: 2 }} />
          <Typography variant="h5" sx={{ fontWeight: 800, color: '#1E3A5F', mb: 1 }}>No bookings found</Typography>
          <Typography variant="body1" sx={{ color: '#6b7280', mb: 4 }}>You have no ambulance requests matching this filter.</Typography>
          <Button variant="contained" size="large" onClick={() => navigate('/')} sx={{ borderRadius: '30px', px: 4, bgcolor: '#76B82A', '&:hover': { bgcolor: '#5b961f' } }}>
            Book Your First Ambulance
          </Button>
        </Box>
      ) : (
        <Grid container spacing={3}>
          {filtered.map((req) => {
            const meta = STATUS_META[req.status] || STATUS_META.PENDING;
            const isTerminal = ['COMPLETED', 'CANCELLED', 'FAILED'].includes(req.status);
            
            // Calculate pseudo duration if completed
            let durationStr = "—";
            if (req.status === 'COMPLETED') {
              const start = new Date(req.createdAt).getTime();
              const end = new Date(req.updatedAt).getTime();
              const mins = Math.round((end - start) / 60000);
              durationStr = mins > 0 ? `${mins} mins` : "< 1 min";
            }

            return (
              <Grid size={{ xs: 12, md: 6 }} key={req.requestId}>
                <Card 
                  onClick={() => navigate(`/tracking/${req.requestId}`)}
                  sx={{ 
                    borderRadius: '24px', 
                    cursor: 'pointer', 
                    transition: 'all 0.2s', 
                    border: '1px solid transparent',
                    '&:hover': { transform: 'translateY(-4px)', boxShadow: '0 12px 32px rgba(30,58,95,0.08)', borderColor: '#e8ecf1' } 
                  }}
                >
                  <CardContent sx={{ p: 3 }}>
                    <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', mb: 2 }}>
                      <Box>
                        <Typography variant="caption" sx={{ fontWeight: 700, color: '#9ca3af', textTransform: 'uppercase', letterSpacing: 1 }}>
                          {formatDate(req.createdAt)}
                        </Typography>
                        <Typography variant="h6" sx={{ fontWeight: 800, color: '#1F2937', mt: 0.5 }}>
                          {req.requestNumber}
                        </Typography>
                      </Box>
                      <Chip 
                        label={meta.label} 
                        sx={{ bgcolor: meta.bg, color: meta.color, fontWeight: 700, borderRadius: '12px' }} 
                      />
                    </Box>

                    <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1.5, mb: 3 }}>
                      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                        <Typography variant="body2" color="text.secondary">Driver Assigned</Typography>
                        <Typography variant="body2" sx={{ fontWeight: 600 }}>{req.status === 'PENDING' || req.status === 'SEARCHING_DRIVER' || req.status === 'REQUEST_CREATED' ? 'No' : 'Yes'}</Typography>
                      </Box>
                      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                        <Typography variant="body2" color="text.secondary">Estimated Arrival</Typography>
                        <Typography variant="body2" sx={{ fontWeight: 600 }}>
                           {req.status === 'COMPLETED' ? `Duration: ${durationStr}` : (req.etaSeconds != null ? `${Math.ceil(req.etaSeconds / 60)} mins` : 'Pending')}
                        </Typography>
                      </Box>
                    </Box>

                    <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', pt: 2, borderTop: '1px solid #f3f4f6' }}>
                      {(req.status === 'PENDING' || req.status === 'SEARCHING_DRIVER' || req.status === 'REQUEST_CREATED') ? (
                         <Button color="error" onClick={(e) => { e.stopPropagation(); navigate(`/tracking/${req.requestId}`); }}>
                           Cancel
                         </Button>
                      ) : (
                        <Box />
                      )}
                      <Button endIcon={<TrackChangesIcon />} sx={{ color: '#1E3A5F', fontWeight: 700 }}>
                        {isTerminal ? 'View Details' : 'Track Live'}
                      </Button>
                    </Box>
                  </CardContent>
                </Card>
              </Grid>
            );
          })}
        </Grid>
      )}
    </Container>
  );
}
