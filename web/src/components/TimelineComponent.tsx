import { Box, Typography, Stepper, Step, StepLabel, StepContent, StepConnector, stepConnectorClasses } from '@mui/material';
import { styled } from '@mui/material/styles';
import CheckCircleIcon from '@mui/icons-material/CheckCircle';
import AddCircleIcon from '@mui/icons-material/AddCircle';
import SearchIcon from '@mui/icons-material/Search';
import HandshakeIcon from '@mui/icons-material/Handshake';
import AssignmentIndIcon from '@mui/icons-material/AssignmentInd';
import DirectionsCarIcon from '@mui/icons-material/DirectionsCar';
import LocationOnIcon from '@mui/icons-material/LocationOn';
import EmojiPeopleIcon from '@mui/icons-material/EmojiPeople';
import CancelIcon from '@mui/icons-material/Cancel';

// Custom Connector for Timeline
const TimelineConnector = styled(StepConnector)(({ theme }) => ({
  [`&.${stepConnectorClasses.alternativeLabel}`]: {
    top: 22,
  },
  [`&.${stepConnectorClasses.active}`]: {
    [`& .${stepConnectorClasses.line}`]: {
      borderColor: theme.palette.primary.main,
    },
  },
  [`&.${stepConnectorClasses.completed}`]: {
    [`& .${stepConnectorClasses.line}`]: {
      borderColor: theme.palette.primary.main,
    },
  },
  [`& .${stepConnectorClasses.line}`]: {
    borderColor: theme.palette.grey[300],
    borderTopWidth: 3,
    borderRadius: 1,
    minHeight: 30, // vertical height
  },
}));

interface TrackingPing {
  status: string;
  timestamp: string;
  lat?: number;
  lng?: number;
  speed?: number;
}

interface TimelineComponentProps {
  history: TrackingPing[];
}

export default function TimelineComponent({ history }: TimelineComponentProps) {
  // Sort oldest first for a natural top-to-bottom timeline flow
  const sortedHistory = [...history].sort(
    (a, b) => new Date(a.timestamp).getTime() - new Date(b.timestamp).getTime()
  );

  const getStepConfig = (status: string) => {
    switch (status) {
      case 'REQUEST_CREATED':
        return { label: 'Booking Created', icon: <AddCircleIcon color="primary" /> };
      case 'SEARCHING_DRIVER':
      case 'SEARCHING_VENDOR':
        return { label: 'Vendor Selected', icon: <SearchIcon color="warning" /> };
      case 'VENDOR_ACCEPTED':
        return { label: 'Vendor Accepted', icon: <HandshakeIcon color="info" /> };
      case 'DRIVER_ASSIGNED':
        return { label: 'Driver Assigned', icon: <AssignmentIndIcon color="info" /> };
      case 'DRIVER_STARTED':
      case 'EN_ROUTE':
        return { label: 'En Route', icon: <DirectionsCarIcon color="secondary" /> };
      case 'ARRIVED':
        return { label: 'Driver Reached Pickup', icon: <LocationOnIcon color="primary" /> };
      case 'PATIENT_ONBOARD':
        return { label: 'Patient Picked', icon: <EmojiPeopleIcon color="primary" /> };
      case 'DESTINATION_REACHED':
        return { label: 'Destination Reached', icon: <LocationOnIcon color="success" /> };
      case 'COMPLETED':
        return { label: 'Completed', icon: <CheckCircleIcon color="success" /> };
      case 'CANCELLED':
      case 'FAILED':
        return { label: 'Cancelled', icon: <CancelIcon color="error" /> };
      default:
        return { label: status.replace(/_/g, ' '), icon: <CheckCircleIcon color="disabled" /> };
    }
  };

  if (!sortedHistory || sortedHistory.length === 0) {
    return (
      <Typography color="text.secondary" align="center" sx={{ mt: 4 }}>
        No events recorded yet.
      </Typography>
    );
  }

  return (
    <Box sx={{ width: '100%' }}>
      <Stepper 
        activeStep={sortedHistory.length} 
        orientation="vertical"
        connector={<TimelineConnector />}
      >
        {sortedHistory.map((ping, index) => {
          const config = getStepConfig(ping.status);
          const date = new Date(ping.timestamp);
          
          return (
            <Step key={index} active={true}>
              <StepLabel 
                icon={config.icon}
                optional={
                  <Typography variant="caption" color="text.secondary">
                    {date.toLocaleDateString()} {date.toLocaleTimeString()}
                  </Typography>
                }
              >
                <Typography variant="subtitle1" sx={{ fontWeight: 'bold', color: '#1E3A5F' }}>
                  {config.label}
                </Typography>
              </StepLabel>
              <StepContent>
                <Box sx={{ mb: 2, p: 1.5, bgcolor: '#f8fafc', borderRadius: 1, border: '1px solid #f1f5f9' }}>
                  {ping.lat && ping.lng ? (
                    <Typography variant="caption" sx={{ display: 'block', color: '#64748b' }}>
                      Location: {ping.lat.toString().substring(0,8)}, {ping.lng.toString().substring(0,8)}
                    </Typography>
                  ) : null}
                  {ping.speed != null && ping.speed > 0 ? (
                    <Typography variant="caption" sx={{ display: 'block', color: '#64748b' }}>
                      Speed: {ping.speed} m/s
                    </Typography>
                  ) : null}
                </Box>
              </StepContent>
            </Step>
          );
        })}
      </Stepper>
    </Box>
  );
}
