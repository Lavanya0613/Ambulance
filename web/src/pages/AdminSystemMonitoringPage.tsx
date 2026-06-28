import { Box, Container, Typography, Grid, Card, CardContent, CircularProgress, IconButton, Tooltip, Chip } from '@mui/material';
import { ErrorState, CardSkeleton } from '../components/UIStates';
import { useQuery } from '@tanstack/react-query';
import axios from 'axios';
import CheckCircleIcon from '@mui/icons-material/CheckCircle';
import ErrorIcon from '@mui/icons-material/Error';
import WarningIcon from '@mui/icons-material/Warning';
import RefreshIcon from '@mui/icons-material/Refresh';
import StorageIcon from '@mui/icons-material/Storage';
import MemoryIcon from '@mui/icons-material/Memory';
import SyncAltIcon from '@mui/icons-material/SyncAlt';
import DynamicFeedIcon from '@mui/icons-material/DynamicFeed';
import GroupWorkIcon from '@mui/icons-material/GroupWork';
import WarningAmberIcon from '@mui/icons-material/WarningAmber';

const StatusCard = ({ title, status, value, icon: Icon, warningOverride }: any) => {
  let color = 'success.main';
  let StatusIcon = CheckCircleIcon;

  if (status === 'down' || status === 'error' || (title === 'Failed Jobs' && value > 0)) {
    color = 'error.main';
    StatusIcon = ErrorIcon;
  } else if (warningOverride || (title === 'Retry Jobs' && value > 0)) {
    color = 'warning.main';
    StatusIcon = WarningIcon;
  }

  return (
    <Card sx={{ height: '100%', position: 'relative', overflow: 'visible' }}>
      <Box sx={{ 
        position: 'absolute', top: -12, right: -12, 
        bgcolor: '#fff', borderRadius: '50%', p: 0.5, boxShadow: 1
      }}>
        <StatusIcon sx={{ color, fontSize: 32 }} />
      </Box>
      <CardContent sx={{ display: 'flex', flexDirection: 'column', height: '100%', pt: 3 }}>
        <Box sx={{ display: 'flex', alignItems: 'center', mb: 2, gap: 1.5 }}>
          <Box sx={{ p: 1, borderRadius: 2, bgcolor: `${color}15` }}>
            <Icon sx={{ color }} />
          </Box>
          <Typography variant="h6" color="secondary" sx={{ fontWeight: 'bold' }}>{title}</Typography>
        </Box>
        <Typography variant="h3" sx={{ fontWeight: 800, mt: 'auto', color: '#1E3A5F' }}>
          {value}
        </Typography>
      </CardContent>
    </Card>
  );
};

export default function AdminSystemMonitoringPage() {
  const { data: statusData, isLoading, isError, refetch, isRefetching } = useQuery({
    queryKey: ['admin-system-status'],
    queryFn: async () => {
      const response = await axios.get('/admin/system-status');
      return response.data;
    },
    refetchInterval: 30000, // Refresh every 30 seconds
  });

  if (isLoading) {
    return (
      <Container maxWidth="xl" sx={{ mb: 8, mt: 4 }}>
        <Box sx={{ mb: 4 }}><CardSkeleton height={40} /></Box>
        <Grid container spacing={3}>
          {[...Array(8)].map((_, i) => (
            <Grid key={i} size={{ xs: 12, sm: 6, md: 4, lg: 3 }}>
              <CardSkeleton height={140} />
            </Grid>
          ))}
        </Grid>
      </Container>
    );
  }

  if (isError) {
    return (
      <Container maxWidth="xl" sx={{ mt: 8 }}>
        <ErrorState message="Failed to load system monitoring data." onRetry={refetch} />
      </Container>
    );
  }

  const isSystemDown = !statusData || statusData.database === 'down' || statusData.redis === 'down';

  return (
    <Container maxWidth="xl" sx={{ mb: 8, mt: 4 }}>
      <Box sx={{ mb: 4, display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
        <Box>
          <Typography variant="h4" color="primary" sx={{ fontWeight: 'bold', display: 'flex', alignItems: 'center', gap: 2 }}>
            System Monitoring
            {isSystemDown && <Chip label="CRITICAL FAILURE" color="error" size="small" sx={{ fontWeight: 'bold' }} />}
          </Typography>
          <Typography variant="body1" color="text.secondary" sx={{ mt: 1 }}>
            Real-time health of database, redis, websockets, and background queues.
          </Typography>
        </Box>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
          {isRefetching && <CircularProgress size={20} />}
          <Tooltip title="Force Refresh">
            <IconButton onClick={() => refetch()} color="primary" sx={{ bgcolor: 'white', boxShadow: 1 }}>
              <RefreshIcon />
            </IconButton>
          </Tooltip>
        </Box>
      </Box>

      <Grid container spacing={3}>
        <Grid size={{ xs: 12, sm: 6, md: 4, lg: 3 }}>
          <StatusCard 
            title="Backend Server" 
            status={statusData?.backend} 
            value={statusData?.backend === 'up' ? 'Healthy' : 'Down'} 
            icon={StorageIcon} 
          />
        </Grid>
        <Grid size={{ xs: 12, sm: 6, md: 4, lg: 3 }}>
          <StatusCard 
            title="Database Status" 
            status={statusData?.database} 
            value={statusData?.database === 'up' ? 'Connected' : 'Offline'} 
            icon={StorageIcon} 
          />
        </Grid>
        <Grid size={{ xs: 12, sm: 6, md: 4, lg: 3 }}>
          <StatusCard 
            title="Redis Status" 
            status={statusData?.redis} 
            value={statusData?.redis === 'up' ? 'Connected' : 'Offline'} 
            icon={MemoryIcon} 
          />
        </Grid>
        <Grid size={{ xs: 12, sm: 6, md: 4, lg: 3 }}>
          <StatusCard 
            title="WebSocket Status" 
            status={statusData?.websocket?.status} 
            value={`${statusData?.websocket?.connectedClients || 0} Clients`} 
            icon={SyncAltIcon} 
          />
        </Grid>
        
        <Grid size={{ xs: 12, sm: 6, md: 4, lg: 3 }}>
          <StatusCard 
            title="Active Queue Jobs" 
            status={statusData?.queues?.status} 
            value={statusData?.queues?.activeJobs || 0} 
            icon={DynamicFeedIcon} 
          />
        </Grid>
        <Grid size={{ xs: 12, sm: 6, md: 4, lg: 3 }}>
          <StatusCard 
            title="Workers Running" 
            status={statusData?.queues?.status} 
            value={statusData?.workers?.count || 0} 
            icon={GroupWorkIcon} 
            warningOverride={statusData?.workers?.count === 0 && statusData?.queues?.waitingJobs > 0}
          />
        </Grid>
        <Grid size={{ xs: 12, sm: 6, md: 4, lg: 3 }}>
          <StatusCard 
            title="Failed Jobs" 
            status={statusData?.queues?.failedJobs > 0 ? 'error' : 'up'} 
            value={statusData?.queues?.failedJobs || 0} 
            icon={ErrorIcon} 
          />
        </Grid>
        <Grid size={{ xs: 12, sm: 6, md: 4, lg: 3 }}>
          <StatusCard 
            title="Retry Jobs" 
            status={statusData?.queues?.retryJobs > 0 ? 'warning' : 'up'} 
            value={statusData?.queues?.retryJobs || 0} 
            icon={WarningAmberIcon} 
          />
        </Grid>
      </Grid>
    </Container>
  );
}
