import { BrowserRouter as Router, Routes, Route, Link, useLocation } from 'react-router-dom';
import {
  Box, AppBar, Toolbar, Container, Typography, Button,
  IconButton, Drawer, List, ListItem, ListItemButton,
  ListItemIcon, ListItemText, useMediaQuery, useTheme, Divider,
} from '@mui/material';
import { createTheme, ThemeProvider } from '@mui/material/styles';
import MenuIcon from '@mui/icons-material/Menu';
import LocalHospitalIcon from '@mui/icons-material/LocalHospital';
import HomeIcon from '@mui/icons-material/Home';
import HistoryIcon from '@mui/icons-material/History';
import CloseIcon from '@mui/icons-material/Close';
import { useState } from 'react';

import BookingPage from './pages/BookingPage';
import TrackingPage from './pages/TrackingPage';
import HistoryPage from './pages/HistoryPage';

// ── MUI Theme: White + Red + Blue ────────────────────────────
const ambulanceTheme = createTheme({
  palette: {
    mode: 'light',
    primary:   { main: '#dc2626', dark: '#b91c1c', light: '#fee2e2', contrastText: '#fff' },
    secondary: { main: '#1d4ed8', dark: '#1e3a8a', light: '#dbeafe', contrastText: '#fff' },
    background: { default: '#f8fafc', paper: '#ffffff' },
    text:       { primary: '#1e293b', secondary: '#64748b' },
    error:      { main: '#dc2626' },
    success:    { main: '#16a34a' },
    warning:    { main: '#d97706' },
    info:       { main: '#0891b2' },
  },
  typography: {
    fontFamily: "'Inter', system-ui, sans-serif",
    fontWeightBold: 700,
    h1: { fontWeight: 800 },
    h2: { fontWeight: 800 },
    h3: { fontWeight: 800 },
    h4: { fontWeight: 700 },
    h5: { fontWeight: 700 },
    h6: { fontWeight: 700 },
  },
  shape: { borderRadius: 10 },
  components: {
    MuiButton: {
      styleOverrides: {
        root: { textTransform: 'none', fontWeight: 600, borderRadius: 8 },
        contained: {
          '&.MuiButton-containedPrimary': {
            background: 'linear-gradient(135deg, #dc2626 0%, #b91c1c 100%)',
            boxShadow: '0 4px 14px rgba(220,38,38,0.3)',
            '&:hover': { boxShadow: '0 6px 20px rgba(220,38,38,0.4)' },
          },
        },
      },
    },
    MuiCard: {
      styleOverrides: {
        root: {
          border: '1px solid #e2e8f0',
          boxShadow: '0 1px 3px rgba(0,0,0,0.06), 0 1px 2px rgba(0,0,0,0.04)',
          borderRadius: 12,
        },
      },
    },
    MuiChip: {
      styleOverrides: { root: { fontWeight: 600, fontSize: '0.78rem' } },
    },
    MuiTextField: {
      defaultProps: { variant: 'outlined', size: 'small' },
    },
    MuiTableHead: {
      styleOverrides: {
        root: { '& .MuiTableCell-root': { fontWeight: 700, background: '#f8fafc' } },
      },
    },
  },
});

// ── Nav items ────────────────────────────────────────────────
const NAV_ITEMS = [
  { label: 'Home',    path: '/',        icon: <HomeIcon fontSize="small" /> },
  { label: 'History', path: '/history', icon: <HistoryIcon fontSize="small" /> },
];

// ── NavBar ───────────────────────────────────────────────────
function NavBar() {
  const location = useLocation();
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down('md'));
  const [drawerOpen, setDrawerOpen] = useState(false);

  const isActive = (path: string) =>
    path === '/' ? location.pathname === '/' : location.pathname.startsWith(path);

  return (
    <AppBar
      position="sticky"
      elevation={0}
      sx={{
        background: '#ffffff',
        borderBottom: '1px solid #e2e8f0',
        color: '#1e293b',
      }}
    >
      <Container maxWidth="xl">
        <Toolbar sx={{ justifyContent: 'space-between', px: { xs: 0, sm: 1 }, minHeight: { xs: 60, sm: 68 } }}>

          {/* Logo */}
          <Box component={Link} to="/" sx={{ display: 'flex', alignItems: 'center', gap: 1.5, textDecoration: 'none' }}>
            <Box sx={{
              width: 40, height: 40, borderRadius: '10px',
              background: 'linear-gradient(135deg, #dc2626 0%, #b91c1c 100%)',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              boxShadow: '0 4px 12px rgba(220,38,38,0.3)',
            }}>
              <LocalHospitalIcon sx={{ color: '#fff', fontSize: 22 }} />
            </Box>
            <Box>
              <Typography sx={{ fontWeight: 800, fontSize: '1.15rem', lineHeight: 1.1, color: '#1e293b', letterSpacing: -0.3 }}>
                CallHealth
              </Typography>
              <Typography sx={{ fontSize: '0.65rem', fontWeight: 600, color: '#94a3b8', letterSpacing: 1.2, textTransform: 'uppercase' }}>
                Ambulance Dispatch
              </Typography>
            </Box>
          </Box>

          {/* Desktop Nav */}
          {!isMobile && (
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}>
              {NAV_ITEMS.map((item) => (
                <Button
                  key={item.path}
                  component={Link}
                  to={item.path}
                  startIcon={item.icon}
                  sx={{
                    fontWeight: 600,
                    fontSize: '0.875rem',
                    px: 2,
                    color: isActive(item.path) ? '#dc2626' : '#475569',
                    bgcolor: isActive(item.path) ? '#fee2e2' : 'transparent',
                    borderRadius: '8px',
                    '&:hover': { bgcolor: isActive(item.path) ? '#fee2e2' : '#f1f5f9', color: isActive(item.path) ? '#dc2626' : '#1e293b' },
                  }}
                >
                  {item.label}
                </Button>
              ))}
              <Button
                component={Link}
                to="/"
                variant="contained"
                color="primary"
                sx={{ ml: 1.5, px: 2.5 }}
              >
                🚑 Book Ambulance
              </Button>
            </Box>
          )}

          {/* Mobile hamburger */}
          {isMobile && (
            <IconButton onClick={() => setDrawerOpen(true)} sx={{ color: '#475569' }}>
              <MenuIcon />
            </IconButton>
          )}
        </Toolbar>
      </Container>

      {/* Mobile Drawer */}
      <Drawer
        anchor="right"
        open={drawerOpen}
        onClose={() => setDrawerOpen(false)}
        slotProps={{ paper: { sx: { width: 260, pt: 1 } } }}
      >
        <Box sx={{ px: 2, py: 1.5, display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <Typography sx={{ fontWeight: 800, fontSize: '1rem', color: '#1e293b' }}>Menu</Typography>
          <IconButton onClick={() => setDrawerOpen(false)} size="small"><CloseIcon /></IconButton>
        </Box>
        <Divider />
        <List sx={{ pt: 1 }}>
          {NAV_ITEMS.map((item) => (
            <ListItem key={item.path} disablePadding>
              <ListItemButton
                component={Link}
                to={item.path}
                onClick={() => setDrawerOpen(false)}
                sx={{
                  mx: 1, borderRadius: '8px', mb: 0.5,
                  bgcolor: isActive(item.path) ? '#fee2e2' : 'transparent',
                  color:   isActive(item.path) ? '#dc2626' : '#475569',
                  '&:hover': { bgcolor: '#f1f5f9' },
                }}
              >
                <ListItemIcon sx={{ minWidth: 36, color: 'inherit' }}>{item.icon}</ListItemIcon>
                <ListItemText primary={item.label} slotProps={{ primary: { style: { fontWeight: 600, fontSize: '0.9rem' } } }} />
              </ListItemButton>
            </ListItem>
          ))}
          <ListItem disablePadding>
            <ListItemButton
              component={Link}
              to="/"
              onClick={() => setDrawerOpen(false)}
              sx={{ mx: 1, borderRadius: '8px', bgcolor: '#dc2626', color: '#fff', '&:hover': { bgcolor: '#b91c1c' } }}
            >
              <ListItemIcon sx={{ minWidth: 36, color: '#fff' }}><LocalHospitalIcon fontSize="small" /></ListItemIcon>
              <ListItemText primary="Book Ambulance" slotProps={{ primary: { style: { fontWeight: 700, fontSize: '0.9rem' } } }} />
            </ListItemButton>
          </ListItem>
        </List>
      </Drawer>
    </AppBar>
  );
}

// ── App ──────────────────────────────────────────────────────
function App() {
  return (
    <ThemeProvider theme={ambulanceTheme}>
      <Router>
        <Box sx={{ display: 'flex', flexDirection: 'column', minHeight: '100vh', bgcolor: '#f8fafc' }}>
          <NavBar />
          <Box component="main" sx={{ flexGrow: 1, py: { xs: 3, md: 4 } }}>
            <Routes>
              <Route path="/"                       element={<BookingPage />} />
              <Route path="/history"                element={<HistoryPage />} />
              <Route path="/tracking/:requestId"    element={<TrackingPage />} />
            </Routes>
          </Box>

          {/* Footer */}
          <Box component="footer" sx={{ borderTop: '1px solid #e2e8f0', py: 2.5, bgcolor: '#fff', mt: 'auto' }}>
            <Container maxWidth="xl">
              <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: 1 }}>
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                  <LocalHospitalIcon sx={{ color: '#dc2626', fontSize: '1.1rem' }} />
                  <Typography variant="caption" sx={{ fontWeight: 700, color: '#64748b' }}>
                    CallHealth Ambulance Dispatch System
                  </Typography>
                </Box>
                <Typography variant="caption" sx={{ color: '#94a3b8' }}>
                  Real-time emergency response • Powered by NestJS + React
                </Typography>
              </Box>
            </Container>
          </Box>
        </Box>
      </Router>
    </ThemeProvider>
  );
}

export default App;
