import { BrowserRouter as Router, Routes, Route, Link } from 'react-router-dom';
import { Box, Container, AppBar, Toolbar, Typography, Button } from '@mui/material';
import LocalHospitalIcon from '@mui/icons-material/LocalHospital';
import BookingPage from './pages/BookingPage';
import TrackingPage from './pages/TrackingPage';

function App() {
  return (
    <Router>
      <Box sx={{ display: 'flex', flexDirection: 'column', minHeight: '100vh' }}>
        {/* Premium Glassmorphic Header */}
        <AppBar 
          position="sticky" 
          elevation={0}
          sx={{ 
            background: 'rgba(15, 23, 42, 0.65)', 
            backdropFilter: 'blur(12px)',
            borderBottom: '1px solid rgba(255, 255, 255, 0.08)' 
          }}
        >
          <Container maxWidth="lg">
            <Toolbar sx={{ justifyContent: 'space-between', px: { xs: 0, sm: 2 } }}>
              <Box 
                component={Link} 
                to="/" 
                sx={{ 
                  display: 'flex', 
                  alignItems: 'center', 
                  gap: 1.5, 
                  textDecoration: 'none',
                  color: 'inherit'
                }}
              >
                <LocalHospitalIcon sx={{ color: '#6ba539', fontSize: 32 }} />
                <Box>
                  <Typography 
                    variant="h5" 
                    sx={{ 
                      fontWeight: 800, 
                      letterSpacing: -0.5,
                      lineHeight: 1.1,
                      background: 'linear-gradient(90deg, #6ba539 0%, #3b82f6 100%)',
                      WebkitBackgroundClip: 'text',
                      WebkitTextFillColor: 'transparent',
                    }}
                  >
                    CallHealth
                  </Typography>
                  <Typography 
                    variant="caption" 
                    sx={{ 
                      color: 'rgba(255,255,255,0.6)', 
                      fontWeight: 600, 
                      fontSize: '0.68rem',
                      letterSpacing: 1.2,
                      textTransform: 'uppercase'
                    }}
                  >
                    Ambulance Dispatch
                  </Typography>
                </Box>
              </Box>

              <Button 
                component={Link} 
                to="/" 
                variant="outlined" 
                color="primary"
                sx={{ 
                  borderColor: 'rgba(107, 165, 57, 0.5)',
                  '&:hover': {
                    borderColor: '#6ba539',
                    backgroundColor: 'rgba(107, 165, 57, 0.08)'
                  }
                }}
              >
                Book Dispatch
              </Button>
            </Toolbar>
          </Container>
        </AppBar>

        {/* Main Body */}
        <Box component="main" sx={{ flexGrow: 1, py: 4 }}>
          <Routes>
            <Route path="/" element={<BookingPage />} />
            <Route path="/tracking/:requestId" element={<TrackingPage />} />
          </Routes>
        </Box>
      </Box>
    </Router>
  );
}

export default App;
