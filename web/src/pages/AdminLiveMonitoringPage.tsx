import { useEffect, useState, useMemo } from 'react';
import {
  Box, Container, Grid, Card, CardContent, Typography, CircularProgress, 
  Table, TableBody, TableCell, TableContainer, TableHead, TableRow, Paper, 
  Chip, Button,
  Select, MenuItem, FormControl, InputLabel, TextField, InputAdornment
} from '@mui/material';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import axios from 'axios';
import { io, Socket } from 'socket.io-client';
import LocalShippingIcon from '@mui/icons-material/LocalShipping';
import CheckCircleIcon from '@mui/icons-material/CheckCircle';
import AccessTimeIcon from '@mui/icons-material/AccessTime';
import SpeedIcon from '@mui/icons-material/Speed';
import LayersIcon from '@mui/icons-material/Layers';
import CancelIcon from '@mui/icons-material/Cancel';
import SearchIcon from '@mui/icons-material/Search';

const API_BASE_URL = 'http://localhost:3000';

export default function AdminLiveMonitoringPage() {
  const queryClient = useQueryClient();
  const [socket, setSocket] = useState<Socket | null>(null);
  
  // Dialog State

  // Table Controls
  const [searchQuery, setSearchQuery] = useState('');
  const [statusFilter, setStatusFilter] = useState('ALL');
  const [sortBy, setSortBy] = useState<'newest' | 'oldest' | 'eta_asc'>('newest');

  // Queries (AuthContext handles Axios headers automatically)
  const { data: stats, isLoading: statsLoading } = useQuery({
    queryKey: ['dashboard-stats'],
    queryFn: async () => (await axios.get(`/dispatcher/dashboard`)).data,
  });

  const { data: activeRequests, isLoading: requestsLoading } = useQuery({
    queryKey: ['dashboard-active-requests'],
    queryFn: async () => {
      const res = await axios.get(`/dispatcher/requests`);
      return res.data.data;
    },
  });



  // WebSocket Connection
  useEffect(() => {
    const token = localStorage.getItem('access_token');
    if (!token) return;

    const newSocket = io(`${API_BASE_URL}/ws`, {
      transports: ['websocket'],
      auth: { token },
      forceNew: true
    });

    newSocket.on('connect', () => console.log('Dispatcher connected to socket room'));

    const invalidateDashboard = () => {
      queryClient.invalidateQueries({ queryKey: ['dashboard-stats'] });
      queryClient.invalidateQueries({ queryKey: ['dashboard-active-requests'] });
      queryClient.invalidateQueries({ queryKey: ['dashboard-drivers'] });
    };

    newSocket.on('new_request', invalidateDashboard);
    newSocket.on('status_updated', invalidateDashboard);
    newSocket.on('trip_started', invalidateDashboard);
    newSocket.on('trip_completed', invalidateDashboard);
    newSocket.on('trip_cancelled', invalidateDashboard);
    newSocket.on('eta_updated', (data) => {
      queryClient.setQueryData(['dashboard-active-requests'], (old: any) => {
        if (!old) return old;
        return old.map((r: any) => r.id === data.requestId ? { ...r, etaSeconds: data.etaSeconds } : r);
      });
    });

    setSocket(newSocket);

    return () => { newSocket.disconnect(); };
  }, [queryClient]);

  // Derived / Filtered Data
  const filteredRequests = useMemo(() => {
    if (!activeRequests) return [];
    
    let result = [...activeRequests];

    // Search
    if (searchQuery) {
      const lowerQ = searchQuery.toLowerCase();
      result = result.filter(r => 
        r.requestNumber.toLowerCase().includes(lowerQ) ||
        (r.patientName && r.patientName.toLowerCase().includes(lowerQ)) ||
        (r.pickupAddress && r.pickupAddress.toLowerCase().includes(lowerQ))
      );
    }

    // Filter
    if (statusFilter !== 'ALL') {
      result = result.filter(r => {
        if (statusFilter === 'PENDING') return r.status === 'REQUEST_CREATED' || r.status === 'SEARCHING_DRIVER';
        if (statusFilter === 'ASSIGNED') return r.status === 'DRIVER_ASSIGNED' || r.status === 'VENDOR_ACCEPTED';
        if (statusFilter === 'EN_ROUTE') return r.status === 'EN_ROUTE' || r.status === 'ARRIVED' || r.status === 'PATIENT_ONBOARD';
        if (statusFilter === 'COMPLETED') return r.status === 'COMPLETED';
        return r.status === statusFilter;
      });
    }

    // Sort
    result.sort((a, b) => {
      if (sortBy === 'newest') return new Date(b.createdAt || 0).getTime() - new Date(a.createdAt || 0).getTime();
      if (sortBy === 'oldest') return new Date(a.createdAt || 0).getTime() - new Date(b.createdAt || 0).getTime();
      if (sortBy === 'eta_asc') {
        const etaA = a.etaSeconds ?? 999999;
        const etaB = b.etaSeconds ?? 999999;
        return etaA - etaB;
      }
      return 0;
    });

    return result;
  }, [activeRequests, searchQuery, statusFilter, sortBy]);



  const handleCompleteTrip = async (id: string) => {
    try { await axios.post(`/dispatcher/requests/${id}/complete`); } 
    catch (err) { alert('Failed to complete trip'); }
  };

  const handleCancelTrip = async (id: string) => {
    try { await axios.post(`/dispatcher/requests/${id}/cancel`, { reasonCode: 'DISPATCHER_CANCELLED' }); } 
    catch (err) { alert('Failed to cancel trip'); }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'PENDING':
      case 'REQUEST_CREATED':
      case 'SEARCHING_DRIVER': return 'warning';
      case 'VENDOR_ACCEPTED':
      case 'DRIVER_ASSIGNED': return 'info';
      case 'EN_ROUTE': return 'primary';
      case 'ARRIVED':
      case 'PATIENT_ONBOARD': return 'secondary';
      case 'COMPLETED': return 'success';
      case 'CANCELLED':
      case 'FAILED': return 'error';
      default: return 'default';
    }
  };

  const MetricCard = ({ title, value, icon, color }: any) => (
    <Card sx={{ height: '100%', position: 'relative', overflow: 'hidden' }}>
      <Box sx={{ position: 'absolute', top: -20, right: -20, opacity: 0.1, transform: 'scale(2.5)' }}>{icon}</Box>
      <CardContent sx={{ position: 'relative', zIndex: 1 }}>
        <Typography variant="subtitle2" color="text.secondary" sx={{ fontWeight: 700, textTransform: 'uppercase', letterSpacing: 1, mb: 1 }}>
          {title}
        </Typography>
        <Typography variant="h3" color={color || 'text.primary'} sx={{ fontWeight: 800 }}>
          {statsLoading ? <CircularProgress size={30} /> : value}
        </Typography>
      </CardContent>
    </Card>
  );

  return (
    <Container maxWidth="xl" sx={{ mb: 8 }}>
      <Box sx={{ mb: 4, display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
        <Box>
          <Typography variant="h4" gutterBottom color="primary" sx={{ mb: 4, fontWeight: 'bold' }}>
          Operations Dashboard
        </Typography>
          <Typography variant="body2" color="text.secondary" sx={{ fontWeight: 600 }}>
            Live multi-cast feed of system health, active trips, and driver fleets.
          </Typography>
        </Box>
        {socket?.connected && (
          <Chip label="Live Sync Active" color="success" variant="outlined" size="small" />
        )}
      </Box>

      {/* Top Metrics Row */}
      <Grid container spacing={2} sx={{ mb: 4 }}>
        <Grid size={{ xs: 6, sm: 3, md: 2 }}><MetricCard title="Pending" value={stats?.pending || 0} icon={<AccessTimeIcon color="warning" />} color="#f57c00" /></Grid>
        <Grid size={{ xs: 6, sm: 3, md: 2 }}><MetricCard title="Assigned" value={stats?.assigned || 0} icon={<CheckCircleIcon color="info" />} color="#0288d1" /></Grid>
        <Grid size={{ xs: 6, sm: 3, md: 2 }}><MetricCard title="En Route" value={stats?.enroute || 0} icon={<LocalShippingIcon color="primary" />} color="#1976d2" /></Grid>
        <Grid size={{ xs: 6, sm: 3, md: 2 }}><MetricCard title="Completed" value={stats?.completed || 0} icon={<CheckCircleIcon color="success" />} color="#388e3c" /></Grid>
        <Grid size={{ xs: 6, sm: 3, md: 2 }}><MetricCard title="Cancelled" value={stats?.cancelled || 0} icon={<CancelIcon color="error" />} color="#d32f2f" /></Grid>
        <Grid size={{ xs: 6, sm: 3, md: 2 }}><MetricCard title="Queue" value={stats?.queueSize || 0} icon={<LayersIcon color="secondary" />} color="#7b1fa2" /></Grid>
        <Grid size={{ xs: 6, sm: 3, md: 2 }}><MetricCard title="D. Avail" value={stats?.driversAvailable || 0} icon={<SpeedIcon color="success" />} color="#388e3c" /></Grid>
        <Grid size={{ xs: 6, sm: 3, md: 2 }}><MetricCard title="D. Busy" value={stats?.driversBusy || 0} icon={<SpeedIcon color="warning" />} color="#f57c00" /></Grid>
      </Grid>

      <Grid container spacing={3}>
        {/* Main Table Area */}
        <Grid size={{ xs: 12, lg: 9 }}>
          <Card sx={{ height: '100%' }}>
            <CardContent>
              {/* Controls */}
              <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 2, mb: 3, alignItems: 'center' }}>
                <Typography variant="h6" color="secondary" sx={{ flexGrow: 1 }}>Recent Requests</Typography>
                
                <TextField
                  size="small"
                  placeholder="Search name or req #"
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  slotProps={{
                    input: { startAdornment: <InputAdornment position="start"><SearchIcon fontSize="small" /></InputAdornment> }
                  }}
                  sx={{ width: 220 }}
                />

                <FormControl size="small" sx={{ width: 140 }}>
                  <InputLabel>Status</InputLabel>
                  <Select value={statusFilter} label="Status" onChange={(e) => setStatusFilter(e.target.value)}>
                    <MenuItem value="ALL">All</MenuItem>
                    <MenuItem value="PENDING">Pending</MenuItem>
                    <MenuItem value="ASSIGNED">Assigned</MenuItem>
                    <MenuItem value="EN_ROUTE">En Route</MenuItem>
                    <MenuItem value="COMPLETED">Completed</MenuItem>
                  </Select>
                </FormControl>

                <FormControl size="small" sx={{ width: 140 }}>
                  <InputLabel>Sort By</InputLabel>
                  <Select value={sortBy} label="Sort By" onChange={(e) => setSortBy(e.target.value as any)}>
                    <MenuItem value="newest">Newest First</MenuItem>
                    <MenuItem value="oldest">Oldest First</MenuItem>
                    <MenuItem value="eta_asc">Lowest ETA</MenuItem>
                  </Select>
                </FormControl>
              </Box>

              <TableContainer component={Paper} elevation={0} sx={{ border: '1px solid #e2e8f0', borderRadius: 2 }}>
                <Table size="small">
                  <TableHead>
                    <TableRow>
                      <TableCell>Req #</TableCell>
                      <TableCell>Patient</TableCell>
                      <TableCell>Status</TableCell>
                      <TableCell align="center">ETA</TableCell>
                      <TableCell align="right">Actions</TableCell>
                    </TableRow>
                  </TableHead>
                  <TableBody>
                    {requestsLoading ? (
                      <TableRow><TableCell colSpan={5} align="center" sx={{ py: 3 }}><CircularProgress size={24} /></TableCell></TableRow>
                    ) : filteredRequests.length === 0 ? (
                      <TableRow><TableCell colSpan={5} align="center" sx={{ py: 3, color: 'text.secondary' }}>No trips found matching criteria.</TableCell></TableRow>
                    ) : (
                      filteredRequests.map((req: any) => (
                        <TableRow key={req.id || req.requestId} hover sx={{ '&:last-child td, &:last-child th': { border: 0 } }}>
                          <TableCell sx={{ fontWeight: 600, color: '#1E3A5F' }}>{req.requestNumber}</TableCell>
                          <TableCell>
                            <Box>
                              <Typography variant="body2" sx={{ fontWeight: 700 }}>{req.patientName}</Typography>
                              <Typography variant="caption" color="text.secondary" sx={{ display: 'block', maxWidth: 200 }} noWrap>
                                {req.pickupAddress}
                              </Typography>
                            </Box>
                          </TableCell>
                          <TableCell>
                            <Chip label={req.status.replace(/_/g, ' ')} color={getStatusColor(req.status) as any} size="small" sx={{ fontWeight: 700, fontSize: '0.7rem' }} />
                          </TableCell>
                          <TableCell align="center" sx={{ fontWeight: 700 }}>
                            {req.etaSeconds != null ? `${Math.floor(req.etaSeconds / 60)}m` : '-'}
                          </TableCell>
                          <TableCell align="right">

                            {(req.status !== 'COMPLETED' && req.status !== 'CANCELLED' && req.status !== 'REQUEST_CREATED' && req.status !== 'SEARCHING_DRIVER') && (
                              <Box sx={{ display: 'flex', justifyContent: 'flex-end', gap: 1 }}>
                                <Button size="small" variant="contained" color="success" onClick={() => handleCompleteTrip(req.id || req.requestId)}>
                                  Complete
                                </Button>
                                <Button size="small" variant="outlined" color="error" onClick={() => handleCancelTrip(req.id || req.requestId)}>
                                  Cancel
                                </Button>
                              </Box>
                            )}
                            {(req.status === 'COMPLETED' || req.status === 'CANCELLED') && (
                              <Typography variant="caption" color="text.secondary">Archived</Typography>
                            )}
                          </TableCell>
                        </TableRow>
                      ))
                    )}
                  </TableBody>
                </Table>
              </TableContainer>
            </CardContent>
          </Card>
        </Grid>

      </Grid>
    </Container>
  );
}
