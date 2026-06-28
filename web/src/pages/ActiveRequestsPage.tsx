import { useEffect, useState, useMemo } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  Box, Container, Grid, Card, Typography, CircularProgress,
  Chip, Button,
  TextField, InputAdornment, Pagination, Divider, Stack,
  FormControl, InputLabel, Select, MenuItem
} from '@mui/material';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import axios from 'axios';
import { io } from 'socket.io-client';
import LocalHospitalIcon from '@mui/icons-material/LocalHospital';
import SearchIcon from '@mui/icons-material/Search';
import PersonIcon from '@mui/icons-material/Person';
import AssignmentIndIcon from '@mui/icons-material/AssignmentInd';
import CheckCircleIcon from '@mui/icons-material/CheckCircle';
import CancelIcon from '@mui/icons-material/Cancel';
import RouteIcon from '@mui/icons-material/Route';

const API_BASE_URL = 'http://localhost:3000';
const ITEMS_PER_PAGE = 9; // Grid of 3x3

export default function ActiveRequestsPage() {
  const queryClient = useQueryClient();
  const navigate = useNavigate();



  // Controls State
  const [searchQuery, setSearchQuery] = useState('');
  const [statusFilter, setStatusFilter] = useState('ALL');
  const [page, setPage] = useState(1);

  // Fetch Active Requests
  const { data: requests, isLoading } = useQuery({
    queryKey: ['active-requests-cards'],
    queryFn: async () => {
      const res = await axios.get(`/dispatcher/requests`);
      return res.data.data;
    },
  });



  // Live Auto-Refresh
  useEffect(() => {
    const token = localStorage.getItem('access_token');
    if (!token) return;

    const newSocket = io(`${API_BASE_URL}/ws`, {
      transports: ['websocket'],
      auth: { token },
      forceNew: true
    });

    const invalidate = () => {
      queryClient.invalidateQueries({ queryKey: ['active-requests-cards'] });
    };

    newSocket.on('new_request', invalidate);
    newSocket.on('status_updated', invalidate);
    newSocket.on('trip_started', invalidate);
    newSocket.on('trip_completed', invalidate);
    newSocket.on('trip_cancelled', invalidate);
    newSocket.on('eta_updated', (data) => {
      queryClient.setQueryData(['active-requests-cards'], (old: any) => {
        if (!old) return old;
        return old.map((r: any) => r.id === data.requestId ? { ...r, etaSeconds: data.etaSeconds } : r);
      });
    });

    return () => { newSocket.disconnect(); };
  }, [queryClient]);

  // Derived Data (Search, Filter, Pagination)
  const filteredRequests = useMemo(() => {
    if (!requests) return [];
    
    let result = [...requests];

    if (searchQuery) {
      const q = searchQuery.toLowerCase();
      result = result.filter(r => 
        r.requestNumber.toLowerCase().includes(q) ||
        (r.patientName && r.patientName.toLowerCase().includes(q))
      );
    }

    if (statusFilter !== 'ALL') {
      result = result.filter(r => r.status === statusFilter);
    }

    // Always sort newest first
    result.sort((a, b) => new Date(b.createdAt || 0).getTime() - new Date(a.createdAt || 0).getTime());

    return result;
  }, [requests, searchQuery, statusFilter]);

  const totalPages = Math.ceil(filteredRequests.length / ITEMS_PER_PAGE);
  const paginatedRequests = filteredRequests.slice((page - 1) * ITEMS_PER_PAGE, page * ITEMS_PER_PAGE);



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

  const getPriorityColor = (priority: string) => {
    if (priority === 'CRITICAL') return '#d32f2f'; // Red
    if (priority === 'HIGH') return '#ed6c02';     // Orange
    return '#2e7d32'; // Green
  };

  return (
    <Container maxWidth="xl" sx={{ mb: 8 }}>
      <Box sx={{ mb: 4, display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', flexWrap: 'wrap', gap: 2 }}>
        <Box>
          <Typography variant="h4" color="secondary" gutterBottom sx={{ fontWeight: 800 }}>
            Active Requests
          </Typography>
          <Typography variant="body2" color="text.secondary" sx={{ fontWeight: 600 }}>
            Manage all active and pending emergency dispatches.
          </Typography>
        </Box>
        
        {/* Controls */}
        <Box sx={{ display: 'flex', gap: 2, flexWrap: 'wrap' }}>
          <TextField
            size="small"
            placeholder="Search by name or ID..."
            value={searchQuery}
            onChange={(e) => { setSearchQuery(e.target.value); setPage(1); }}
            slotProps={{ input: { startAdornment: <InputAdornment position="start"><SearchIcon fontSize="small" /></InputAdornment> } }}
            sx={{ width: 260, bgcolor: '#fff', borderRadius: 1 }}
          />
          <FormControl size="small" sx={{ width: 180, bgcolor: '#fff', borderRadius: 1 }}>
            <InputLabel>Status</InputLabel>
            <Select 
              value={statusFilter} 
              label="Status" 
              onChange={(e) => { setStatusFilter(e.target.value); setPage(1); }}
            >
              <MenuItem value="ALL">All Active</MenuItem>
              <MenuItem value="REQUEST_CREATED">Pending</MenuItem>
              <MenuItem value="DRIVER_ASSIGNED">Assigned</MenuItem>
              <MenuItem value="EN_ROUTE">En Route</MenuItem>
              <MenuItem value="PATIENT_ONBOARD">Patient Onboard</MenuItem>
            </Select>
          </FormControl>
        </Box>
      </Box>

      {isLoading ? (
        <Box sx={{ display: 'flex', justifyContent: 'center', my: 10 }}>
          <CircularProgress />
        </Box>
      ) : filteredRequests.length === 0 ? (
        <Card sx={{ p: 10, textAlign: 'center', bgcolor: '#f8fafc', border: '1px dashed #cbd5e1' }}>
          <LocalHospitalIcon sx={{ fontSize: 64, color: '#94a3b8', mb: 2 }} />
          <Typography variant="h6" color="text.secondary">No requests found.</Typography>
        </Card>
      ) : (
        <>
          <Grid container spacing={3}>
            {paginatedRequests.map((req: any) => {
              const reqId = req.id || req.requestId;
              const isPending = req.status === 'REQUEST_CREATED' || req.status === 'SEARCHING_DRIVER';
              const isActive = req.status !== 'COMPLETED' && req.status !== 'CANCELLED' && req.status !== 'FAILED';

              return (
                <Grid size={{ xs: 12, md: 6, lg: 4 }} key={reqId}>
                  <Card sx={{ 
                    height: '100%', 
                    display: 'flex', 
                    flexDirection: 'column',
                    transition: 'transform 0.2s, box-shadow 0.2s',
                    '&:hover': { transform: 'translateY(-4px)', boxShadow: '0 12px 24px rgba(30, 58, 95, 0.1)' }
                  }}>
                    {/* Card Header */}
                    <Box sx={{ p: 2, display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', bgcolor: '#f8fafc', borderBottom: '1px solid #e2e8f0' }}>
                      <Box>
                        <Typography variant="subtitle2" sx={{ fontWeight: 800, color: '#1E3A5F' }}>{req.requestNumber}</Typography>
                        <Typography variant="caption" sx={{ fontWeight: 600, color: getPriorityColor(req.priority) }}>
                          {req.priority || 'NORMAL'} PRIORITY
                        </Typography>
                      </Box>
                      <Chip label={req.status.replace(/_/g, ' ')} color={getStatusColor(req.status) as any} size="small" sx={{ fontWeight: 700 }} />
                    </Box>

                    {/* Card Body */}
                    <Box sx={{ p: 2, flexGrow: 1 }}>
                      <Stack spacing={2}>
                        
                        {/* Patient */}
                        <Box sx={{ display: 'flex', gap: 1.5 }}>
                          <PersonIcon sx={{ color: '#94a3b8' }} />
                          <Box>
                            <Typography variant="body2" sx={{ fontWeight: 700, color: '#334155' }}>{req.patientName}</Typography>
                            <Typography variant="caption" sx={{ color: '#64748b' }}>{req.patientPhone || 'No Phone'}</Typography>
                          </Box>
                        </Box>

                        <Divider />

                        {/* Route */}
                        <Box>
                          <Box sx={{ display: 'flex', gap: 1.5, mb: 1.5 }}>
                            <Box sx={{ display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
                              <Box sx={{ width: 10, height: 10, borderRadius: '50%', bgcolor: '#76B82A', mt: 0.5 }} />
                              <Box sx={{ width: 2, height: 20, bgcolor: '#e2e8f0', my: 0.5 }} />
                              <Box sx={{ width: 10, height: 10, borderRadius: '50%', bgcolor: '#E53935' }} />
                            </Box>
                            <Box sx={{ flexGrow: 1 }}>
                              <Typography variant="body2" sx={{ fontWeight: 600, color: '#334155' }} noWrap>{req.pickupAddress || 'No Pickup'}</Typography>
                              <Typography variant="caption" sx={{ color: '#94a3b8', display: 'block', mb: 1 }}>Pickup</Typography>
                              
                              <Typography variant="body2" sx={{ fontWeight: 600, color: '#334155' }} noWrap>{req.dropAddress || 'No Drop'}</Typography>
                              <Typography variant="caption" sx={{ color: '#94a3b8' }}>Destination</Typography>
                            </Box>
                          </Box>
                        </Box>

                        <Divider />

                        {/* Driver & ETA */}
                        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                          {req.driver ? (
                            <Box sx={{ display: 'flex', gap: 1, alignItems: 'center' }}>
                              <AssignmentIndIcon sx={{ color: '#3b82f6', fontSize: 20 }} />
                              <Box>
                                <Typography variant="body2" sx={{ fontWeight: 700, color: '#1E3A5F' }}>{req.driver.name}</Typography>
                                <Typography variant="caption" sx={{ color: '#64748b' }}>{req.driver.vehicleNumber} ({req.driver.ambulanceCategory})</Typography>
                              </Box>
                            </Box>
                          ) : (
                            <Typography variant="body2" sx={{ color: '#f59e0b', fontWeight: 600 }}>Unassigned</Typography>
                          )}

                          <Box sx={{ textAlign: 'right' }}>
                            <Typography variant="caption" sx={{ color: '#94a3b8', display: 'block' }}>ETA</Typography>
                            <Typography variant="body2" sx={{ fontWeight: 800, color: '#1E3A5F' }}>
                              {req.etaSeconds != null ? `${Math.floor(req.etaSeconds / 60)} min` : '--'}
                            </Typography>
                          </Box>
                        </Box>

                      </Stack>
                    </Box>

                    {/* Actions Footer */}
                    <Box sx={{ p: 2, pt: 0, display: 'flex', gap: 1, flexWrap: 'wrap' }}>

                      
                      <Button 
                        size="small" 
                        variant="outlined" 
                        color="primary" 
                        startIcon={<RouteIcon />}
                        onClick={() => navigate(`/tracking/${reqId}`)}
                        sx={{ flexGrow: 1 }}
                      >
                        Track Map
                      </Button>

                      {isActive && !isPending && (
                        <Button 
                          size="small" 
                          variant="contained" 
                          color="success" 
                          startIcon={<CheckCircleIcon />}
                          onClick={() => handleCompleteTrip(reqId)}
                          sx={{ flexGrow: 1 }}
                        >
                          Complete
                        </Button>
                      )}

                      {isActive && (
                        <Button 
                          size="small" 
                          variant="outlined" 
                          color="error" 
                          startIcon={<CancelIcon />}
                          onClick={() => handleCancelTrip(reqId)}
                          sx={{ flexGrow: 1 }}
                        >
                          Cancel
                        </Button>
                      )}
                    </Box>
                  </Card>
                </Grid>
              );
            })}
          </Grid>

          {/* Pagination */}
          {totalPages > 1 && (
            <Box sx={{ display: 'flex', justifyContent: 'center', mt: 6 }}>
              <Pagination 
                count={totalPages} 
                page={page} 
                onChange={(_, p) => setPage(p)} 
                color="primary" 
                size="large" 
              />
            </Box>
          )}
        </>
      )}



    </Container>
  );
}
