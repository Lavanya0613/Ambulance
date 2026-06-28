import { Box, Container, Card, CardContent, Typography, Grid, Chip, Divider, IconButton, Skeleton } from '@mui/material';
import { ErrorState, CardSkeleton } from '../components/UIStates';
import { useQuery } from '@tanstack/react-query';
import axios from 'axios';
import { useParams, useNavigate } from 'react-router-dom';
import ArrowBackIcon from '@mui/icons-material/ArrowBack';
import TimelineComponent from '../components/TimelineComponent';
import DriverCard from '../components/DriverCard';

export default function AdminRequestDetailsPage() {
  const { id } = useParams();
  const navigate = useNavigate();

  const { data: request, isLoading, isError, refetch } = useQuery({
    queryKey: ['admin-request-details', id],
    queryFn: async () => {
      const response = await axios.get(`/admin/requests/${id}`);
      return response.data;
    },
    enabled: !!id,
    refetchInterval: 15000, // Refresh every 15s to catch new positions
  });

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'REQUEST_CREATED':
      case 'SEARCHING_DRIVER': return 'warning';
      case 'VENDOR_ACCEPTED':
      case 'DRIVER_ASSIGNED': return 'info';
      case 'EN_ROUTE': 
      case 'ARRIVED':
      case 'PATIENT_ONBOARD': return 'primary';
      case 'DESTINATION_REACHED':
      case 'COMPLETED': return 'success';
      case 'CANCELLED':
      case 'FAILED': return 'error';
      default: return 'default';
    }
  };

  if (isLoading) {
    return (
      <Container maxWidth="xl" sx={{ mt: 8 }}>
        <Box sx={{ mb: 4 }}><Skeleton variant="text" width="40%" height={48} /></Box>
        <Grid container spacing={3}>
          <Grid size={{ xs: 12, md: 8 }}>
            <CardSkeleton height={200} />
            <Box sx={{ mt: 3 }}><CardSkeleton height={150} /></Box>
          </Grid>
          <Grid size={{ xs: 12, md: 4 }}>
            <CardSkeleton height={400} />
          </Grid>
        </Grid>
      </Container>
    );
  }

  if (isError || !request) {
    return (
      <Container maxWidth="xl" sx={{ mt: 8 }}>
        <ErrorState message="Failed to load request details." onRetry={refetch} />
      </Container>
    );
  }

  return (
    <Container maxWidth="xl" sx={{ mb: 8, mt: 4 }}>
      <Box sx={{ mb: 4, display: 'flex', alignItems: 'center', gap: 2 }}>
        <IconButton onClick={() => navigate(-1)} sx={{ bgcolor: 'white', boxShadow: 1 }}>
          <ArrowBackIcon />
        </IconButton>
        <Box>
          <Typography variant="h4" color="primary" sx={{ fontWeight: 'bold' }}>
            Request Details: {request.requestNumber}
          </Typography>
          <Box sx={{ display: 'flex', gap: 1, mt: 1, alignItems: 'center' }}>
            <Chip label={request.status?.replace(/_/g, ' ')} color={getStatusColor(request.status) as any} size="small" sx={{ fontWeight: 'bold' }} />
            <Typography variant="body2" color="text.secondary">
              ID: {request.id}
            </Typography>
          </Box>
        </Box>
      </Box>

      <Grid container spacing={3}>
        {/* Left Column: Details Cards */}
        <Grid size={{ xs: 12, md: 8 }}>
          <Card sx={{ mb: 3 }}>
            <CardContent>
              <Typography variant="h6" color="secondary" sx={{ mb: 2, fontWeight: 'bold' }}>Patient & Location</Typography>
              <Divider sx={{ mb: 2 }} />
              <Grid container spacing={2}>
                <Grid size={{ xs: 6 }}>
                  <Typography variant="caption" color="text.secondary">Patient Name</Typography>
                  <Typography variant="body1" sx={{ fontWeight: 500 }}>{request.patient?.name || '-'}</Typography>
                </Grid>
                <Grid size={{ xs: 6 }}>
                  <Typography variant="caption" color="text.secondary">Contact Number</Typography>
                  <Typography variant="body1" sx={{ fontWeight: 500 }}>{request.patient?.phone || '-'}</Typography>
                </Grid>
                <Grid size={{ xs: 12 }}>
                  <Typography variant="caption" color="text.secondary">Pickup Location</Typography>
                  <Typography variant="body1" sx={{ fontWeight: 500 }}>{request.pickup?.address || '-'}</Typography>
                  {request.pickup?.lat && (
                    <Typography variant="caption" color="text.disabled">
                      Lat: {request.pickup.lat}, Lng: {request.pickup.lng}
                    </Typography>
                  )}
                </Grid>
                <Grid size={{ xs: 12 }}>
                  <Typography variant="caption" color="text.secondary">Destination Location</Typography>
                  <Typography variant="body1" sx={{ fontWeight: 500 }}>{request.destination?.address || '-'}</Typography>
                </Grid>
              </Grid>
            </CardContent>
          </Card>

          <DriverCard request={request} />
        </Grid>

        {/* Right Column: Tracking History */}
        <Grid size={{ xs: 12, md: 4 }}>
          <Card sx={{ height: '100%' }}>
            <CardContent>
              <Typography variant="h6" color="secondary" sx={{ mb: 2, fontWeight: 'bold' }}>Tracking History</Typography>
              <Divider sx={{ mb: 2 }} />
              
              <Box sx={{ maxHeight: 500, overflow: 'auto', pr: 1 }}>
                <TimelineComponent history={request.trackingHistory || []} />
              </Box>
            </CardContent>
          </Card>
        </Grid>
      </Grid>
    </Container>
  );
}
