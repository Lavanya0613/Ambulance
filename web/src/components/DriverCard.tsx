import { Card, CardContent, Typography, Grid, Divider, Avatar, Box, Button } from '@mui/material';
import CallIcon from '@mui/icons-material/Call';
import SpeedIcon from '@mui/icons-material/Speed';
import LocationOnIcon from '@mui/icons-material/LocationOn';
import AccessTimeIcon from '@mui/icons-material/AccessTime';
import BadgeIcon from '@mui/icons-material/Badge';
import DirectionsCarIcon from '@mui/icons-material/DirectionsCar';

interface DriverCardProps {
  request: any;
}

export default function DriverCard({ request }: DriverCardProps) {
  // Get latest telemetry from tracking history if available
  let currentSpeed = 0;
  let currentLocation = 'Unknown';
  
  if (request.trackingHistory && request.trackingHistory.length > 0) {
    const latestPing = request.trackingHistory[request.trackingHistory.length - 1];
    currentSpeed = latestPing.speed || 0;
    if (latestPing.lat && latestPing.lng) {
      currentLocation = `${latestPing.lat.toString().substring(0,8)}, ${latestPing.lng.toString().substring(0,8)}`;
    }
  }

  const etaMinutes = request.eta?.seconds != null ? Math.floor(request.eta.seconds / 60) : null;

  return (
    <Card>
      <CardContent>
        <Typography variant="h6" color="secondary" sx={{ mb: 2, fontWeight: 'bold' }}>Vendor & Fleet Details</Typography>
        <Divider sx={{ mb: 3 }} />
        
        <Box sx={{ display: 'flex', gap: 3, mb: 3, flexWrap: 'wrap' }}>
          {/* Driver Profile Section */}
          <Box sx={{ display: 'flex', flexDirection: 'column', alignItems: 'center', minWidth: 120 }}>
            <Avatar 
              src="https://via.placeholder.com/150" 
              alt="Driver" 
              sx={{ width: 80, height: 80, mb: 1, border: '3px solid #f1f5f9' }}
            />
            <Typography variant="subtitle1" sx={{ fontWeight: 'bold', color: '#1E3A5F' }}>
              {request.driver?.name || 'Unassigned'}
            </Typography>
            <Typography variant="caption" color="text.secondary" sx={{ mb: 1 }}>
              {request.vendor?.name || 'No Vendor'}
            </Typography>
            <Button 
              variant="contained" 
              color="primary" 
              size="small" 
              startIcon={<CallIcon />}
              sx={{ borderRadius: 4, textTransform: 'none', px: 2 }}
              disabled={!request.driver?.phone}
            >
              Call Driver
            </Button>
          </Box>

          <Divider orientation="vertical" flexItem sx={{ display: { xs: 'none', sm: 'block' } }} />

          {/* Details Grid */}
          <Grid container spacing={2} sx={{ flex: 1 }}>
            <Grid size={{ xs: 12, sm: 6 }}>
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                <CallIcon color="action" fontSize="small" />
                <Box>
                  <Typography variant="caption" color="text.secondary" sx={{ display: 'block' }}>Phone</Typography>
                  <Typography variant="body2" sx={{ fontWeight: 500 }}>{request.driver?.phone || '-'}</Typography>
                </Box>
              </Box>
            </Grid>
            <Grid size={{ xs: 12, sm: 6 }}>
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                <BadgeIcon color="action" fontSize="small" />
                <Box>
                  <Typography variant="caption" color="text.secondary" sx={{ display: 'block' }}>Vehicle No.</Typography>
                  <Typography variant="body2" sx={{ fontWeight: 500 }}>{request.vehicle?.number || '-'}</Typography>
                </Box>
              </Box>
            </Grid>
            <Grid size={{ xs: 12, sm: 6 }}>
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                <DirectionsCarIcon color="action" fontSize="small" />
                <Box>
                  <Typography variant="caption" color="text.secondary" sx={{ display: 'block' }}>Vehicle Type</Typography>
                  <Typography variant="body2" sx={{ fontWeight: 500 }}>{request.vehicle?.type || 'ALS Ambulance'}</Typography>
                </Box>
              </Box>
            </Grid>
            <Grid size={{ xs: 12, sm: 6 }}>
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                <SpeedIcon color="action" fontSize="small" />
                <Box>
                  <Typography variant="caption" color="text.secondary" sx={{ display: 'block' }}>Current Speed</Typography>
                  <Typography variant="body2" sx={{ fontWeight: 500 }}>{currentSpeed} m/s</Typography>
                </Box>
              </Box>
            </Grid>
            <Grid size={{ xs: 12, sm: 6 }}>
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                <LocationOnIcon color="action" fontSize="small" />
                <Box>
                  <Typography variant="caption" color="text.secondary" sx={{ display: 'block' }}>Current Location</Typography>
                  <Typography variant="body2" sx={{ fontWeight: 500 }}>{currentLocation}</Typography>
                </Box>
              </Box>
            </Grid>
            <Grid size={{ xs: 12, sm: 6 }}>
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                <AccessTimeIcon color="error" fontSize="small" />
                <Box>
                  <Typography variant="caption" color="text.secondary" sx={{ display: 'block' }}>Live ETA</Typography>
                  <Typography variant="body2" sx={{ fontWeight: 700, color: '#E53935' }}>
                    {etaMinutes != null ? `${etaMinutes} mins` : '-'}
                  </Typography>
                </Box>
              </Box>
            </Grid>
          </Grid>
        </Box>
      </CardContent>
    </Card>
  );
}
