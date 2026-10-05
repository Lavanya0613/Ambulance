import { Box, Typography, Stepper, Step, StepLabel, StepContent, StepConnector, stepConnectorClasses } from '@mui/material';
import { styled } from '@mui/material/styles';
import CheckCircleIcon from '@mui/icons-material/CheckCircle';
import AddCircleIcon from '@mui/icons-material/AddCircle';
import HandshakeIcon from '@mui/icons-material/Handshake';
import AssignmentIndIcon from '@mui/icons-material/AssignmentInd';
import DirectionsCarIcon from '@mui/icons-material/DirectionsCar';
import LocationOnIcon from '@mui/icons-material/LocationOn';
import EmojiPeopleIcon from '@mui/icons-material/EmojiPeople';

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
  status: string;
}

const LIFECYCLE_STEPS = [
  { key: 'REQUEST_CREATED', label: 'Booking Received', icon: <AddCircleIcon /> },
  { key: 'VENDOR_ACCEPTED', label: 'Accepted', icon: <HandshakeIcon /> },
  { key: 'DRIVER_ASSIGNED', label: 'Driver Assigned', icon: <AssignmentIndIcon /> },
  { key: 'EN_ROUTE', label: 'En Route', icon: <DirectionsCarIcon /> },
  { key: 'ARRIVED', label: 'Arrived', icon: <LocationOnIcon /> },
  { key: 'PATIENT_ONBOARD', label: 'Patient Onboard', icon: <EmojiPeopleIcon /> },
  { key: 'COMPLETED', label: 'Completed', icon: <CheckCircleIcon /> },
];

function getStepIndex(status: string) {
  const map: Record<string, number> = {
    'PENDING': 0, 'REQUEST_CREATED': 0, 'SEARCHING_DRIVER': 0,
    'VENDOR_ACCEPTED': 1, 
    'ASSIGNED': 2, 'DRIVER_ASSIGNED': 2,
    'EN_ROUTE': 3, 
    'ARRIVED': 4, 
    'PATIENT_ONBOARD': 5, 'IN_PROGRESS': 5, 'DESTINATION_REACHED': 5, 
    'COMPLETED': 6,
  };
  return map[status] ?? 0;
}

export default function TimelineComponent({ history, status }: TimelineComponentProps) {
  const currentStep = getStepIndex(status);

  return (
    <Box sx={{ width: '100%' }}>
      <Stepper 
        activeStep={currentStep} 
        orientation="vertical"
        connector={<TimelineConnector />}
      >
        {LIFECYCLE_STEPS.map((step, index) => {
          // Find the earliest timestamp for this step in history
          const eventInHistory = history.find(h => getStepIndex(h.status) === index);
          const date = eventInHistory ? new Date(eventInHistory.timestamp) : null;
          
          return (
            <Step key={step.key}>
              <StepLabel 
                icon={
                  <Box sx={{ color: index <= currentStep ? 'primary.main' : 'text.disabled' }}>
                    {step.icon}
                  </Box>
                }
                optional={
                  date && (
                    <Typography variant="caption" color="text.secondary">
                      {date.toLocaleDateString()} {date.toLocaleTimeString()}
                    </Typography>
                  )
                }
              >
                <Typography variant="subtitle1" sx={{ fontWeight: 'bold', color: index <= currentStep ? '#1E3A5F' : 'text.disabled' }}>
                  {step.label}
                </Typography>
              </StepLabel>
              <StepContent>
                {/* We don't necessarily need step content for future steps, but we could put something here */}
              </StepContent>
            </Step>
          );
        })}
      </Stepper>
    </Box>
  );
}
