import { Outlet, Link, useLocation } from 'react-router-dom';
import { Box, AppBar, Toolbar, Container, Typography, Button, IconButton, Drawer, List, ListItem, ListItemButton, ListItemIcon, ListItemText, useMediaQuery, useTheme, Divider } from '@mui/material';
import { useState } from 'react';
import LocalHospitalIcon from '@mui/icons-material/LocalHospital';
import HistoryIcon from '@mui/icons-material/History';
import PersonIcon from '@mui/icons-material/Person';
import MenuIcon from '@mui/icons-material/Menu';
import CloseIcon from '@mui/icons-material/Close';
import { useColorMode } from '../context/ColorModeContext';
import Brightness4Icon from '@mui/icons-material/Brightness4';
import Brightness7Icon from '@mui/icons-material/Brightness7';

const NAV_ITEMS = [
  { label: 'Book Ambulance', path: '/',        icon: <LocalHospitalIcon fontSize="small" /> },
  { label: 'My Requests',    path: '/my-requests', icon: <HistoryIcon fontSize="small" /> },
  { label: 'Profile',        path: '/profile', icon: <PersonIcon fontSize="small" /> },
];

export default function PatientLayout() {
  const location = useLocation();
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down('md'));
  const [drawerOpen, setDrawerOpen] = useState(false);
  const { mode, toggleColorMode } = useColorMode();

  const isActive = (path: string) =>
    path === '/' ? location.pathname === '/' : location.pathname.startsWith(path);

  return (
    <Box sx={{ display: 'flex', flexDirection: 'column', minHeight: '100vh', bgcolor: 'background.default' }}>
      <AppBar position="sticky" elevation={0} sx={{ background: '#76B82A', color: '#ffffff' }}>
        <Container maxWidth="xl">
          <Toolbar sx={{ justifyContent: 'space-between', px: { xs: 0, sm: 1 }, minHeight: { xs: 60, sm: 68 } }}>
            {/* Logo */}
            <Box component={Link} to="/" sx={{ display: 'flex', alignItems: 'center', gap: 1.5, textDecoration: 'none' }}>
              <Box sx={{ width: 40, height: 40, borderRadius: '50%', background: '#ffffff', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                <LocalHospitalIcon sx={{ color: '#76B82A', fontSize: 24 }} />
              </Box>
              <Box>
                <Typography sx={{ fontWeight: 800, fontSize: '1.15rem', lineHeight: 1.1, color: '#ffffff', letterSpacing: -0.3 }}>
                  CallHealth
                </Typography>
                <Typography sx={{ fontSize: '0.65rem', fontWeight: 600, color: '#edf6e1', letterSpacing: 1.2, textTransform: 'uppercase' }}>
                  Emergency Services
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
                      fontWeight: 700,
                      fontSize: '0.875rem',
                      px: 2.5,
                      py: 1,
                      color: isActive(item.path) ? '#76B82A' : '#ffffff',
                      bgcolor: isActive(item.path) ? '#ffffff' : 'transparent',
                      borderRadius: '24px',
                      '&:hover': { bgcolor: isActive(item.path) ? '#ffffff' : 'rgba(255,255,255,0.2)' },
                    }}
                  >
                    {item.label}
                  </Button>
                ))}
                <Button
                  variant="outlined"
                  sx={{ ml: 1.5, px: 3, borderColor: '#ffffff', color: '#ffffff', '&:hover': { bgcolor: 'rgba(255,255,255,0.1)', borderColor: '#ffffff' }, borderRadius: 24, fontWeight: 700 }}
                >
                  📞 Emergency Helpline
                </Button>
                <IconButton onClick={toggleColorMode} sx={{ color: '#ffffff', ml: 1 }}>
                  {mode === 'dark' ? <Brightness7Icon /> : <Brightness4Icon />}
                </IconButton>
              </Box>
            )}

            {/* Mobile hamburger */}
            {isMobile && (
              <Box sx={{ display: 'flex', alignItems: 'center' }}>
                <IconButton onClick={toggleColorMode} sx={{ color: '#ffffff' }}>
                  {mode === 'dark' ? <Brightness7Icon /> : <Brightness4Icon />}
                </IconButton>
                <IconButton onClick={() => setDrawerOpen(true)} sx={{ color: '#ffffff' }}>
                  <MenuIcon />
                </IconButton>
              </Box>
            )}
          </Toolbar>
        </Container>

        {/* Mobile Drawer */}
        <Drawer anchor="right" open={drawerOpen} onClose={() => setDrawerOpen(false)} slotProps={{ paper: { sx: { width: 260, pt: 1 } } }}>
          <Box sx={{ px: 2, py: 1.5, display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
            <Typography sx={{ fontWeight: 800, fontSize: '1rem', color: '#1e293b' }}>Menu</Typography>
            <IconButton onClick={() => setDrawerOpen(false)} size="small"><CloseIcon /></IconButton>
          </Box>
          <Divider />
          <List sx={{ pt: 1 }}>
            {NAV_ITEMS.map((item) => (
              <ListItem key={item.path} disablePadding>
                <ListItemButton component={Link} to={item.path} onClick={() => setDrawerOpen(false)}>
                  <ListItemIcon sx={{ minWidth: 36, color: 'inherit' }}>{item.icon}</ListItemIcon>
                  <ListItemText primary={item.label} slotProps={{ primary: { style: { fontWeight: 600, fontSize: '0.9rem' } } }} />
                </ListItemButton>
              </ListItem>
            ))}
            <ListItem disablePadding>
              <ListItemButton sx={{ mx: 1, borderRadius: '8px', border: '1px solid #1E3A5F', color: '#1E3A5F', mt: 1 }}>
                <ListItemIcon sx={{ minWidth: 36, color: '#1E3A5F' }}>📞</ListItemIcon>
                <ListItemText primary="Emergency Helpline" slotProps={{ primary: { style: { fontWeight: 700, fontSize: '0.9rem' } } }} />
              </ListItemButton>
            </ListItem>
          </List>
        </Drawer>
      </AppBar>

      {/* Main Content Area */}
      <Box component="main" sx={{ flexGrow: 1, py: { xs: 3, md: 4 } }}>
        <Outlet />
      </Box>

      {/* Footer */}
      <Box component="footer" sx={{ borderTop: 1, borderColor: 'divider', py: 2.5, bgcolor: 'background.paper', mt: 'auto' }}>
        <Container maxWidth="xl">
          <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: 1 }}>
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
              <LocalHospitalIcon sx={{ color: 'text.secondary', fontSize: '1.1rem' }} />
              <Typography variant="caption" sx={{ fontWeight: 700, color: 'text.secondary' }}>
                CallHealth Emergency Services
              </Typography>
            </Box>
            <Typography variant="caption" sx={{ color: 'text.secondary' }}>
              Premium healthcare at your fingertips
            </Typography>
          </Box>
        </Container>
      </Box>
    </Box>
  );
}
