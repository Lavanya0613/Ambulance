import { useState } from 'react';
import { Outlet, Link, useLocation } from 'react-router-dom';
import { Box, AppBar, Toolbar, Typography, Drawer, List, ListItem, ListItemButton, ListItemIcon, ListItemText, IconButton, Divider, Avatar } from '@mui/material';
import MenuIcon from '@mui/icons-material/Menu';
import DashboardIcon from '@mui/icons-material/Dashboard';
import DirectionsCarIcon from '@mui/icons-material/DirectionsCar';
import MapIcon from '@mui/icons-material/Map';
import PeopleIcon from '@mui/icons-material/People';
import StorefrontIcon from '@mui/icons-material/Storefront';
import HistoryIcon from '@mui/icons-material/History';
import MemoryIcon from '@mui/icons-material/Memory';
import SettingsIcon from '@mui/icons-material/Settings';
import LogoutIcon from '@mui/icons-material/Logout';
import LocalHospitalIcon from '@mui/icons-material/LocalHospital';
import Brightness4Icon from '@mui/icons-material/Brightness4';
import Brightness7Icon from '@mui/icons-material/Brightness7';
import { useColorMode } from '../context/ColorModeContext';
import NotificationCenter from '../components/NotificationCenter';

const DRAWER_WIDTH = 260;

const ADMIN_NAV = [
  { label: 'Dashboard', path: '/admin/dashboard', icon: <DashboardIcon /> },
  { label: 'Requests', path: '/admin/requests', icon: <DirectionsCarIcon /> },
  { label: 'Live Monitoring', path: '/admin/live', icon: <MapIcon /> },
  { label: 'Drivers', path: '/admin/drivers', icon: <PeopleIcon /> },
  { label: 'Vendors', path: '/admin/vendors', icon: <StorefrontIcon /> },
  { label: 'Audit Logs', path: '/admin/audit', icon: <HistoryIcon /> },
  { label: 'System Health', path: '/admin/system', icon: <MemoryIcon /> },
  { label: 'Settings', path: '/admin/settings', icon: <SettingsIcon /> },
];

export default function AdminLayout() {
  const [mobileOpen, setMobileOpen] = useState(false);
  const { mode, toggleColorMode } = useColorMode();
  const location = useLocation();

  const handleDrawerToggle = () => {
    setMobileOpen(!mobileOpen);
  };

  const isActive = (path: string) => location.pathname.startsWith(path);

  const drawer = (
    <Box sx={{ display: 'flex', flexDirection: 'column', height: '100%' }}>
      <Box sx={{ p: 2, display: 'flex', alignItems: 'center', gap: 1.5, mb: 1 }}>
        <LocalHospitalIcon sx={{ color: 'primary.main', fontSize: 32 }} />
        <Box>
          <Typography variant="h6" sx={{ fontWeight: 800, lineHeight: 1.1, color: 'text.primary' }}>
            CallHealth
          </Typography>
          <Typography variant="caption" sx={{ fontWeight: 700, color: 'text.secondary', textTransform: 'uppercase', letterSpacing: 1 }}>
            Operations
          </Typography>
        </Box>
      </Box>
      <Divider />
      <List sx={{ px: 1, py: 2, flexGrow: 1 }}>
        {ADMIN_NAV.map((item) => (
          <ListItem key={item.path} disablePadding sx={{ mb: 0.5 }}>
            <ListItemButton
              component={Link}
              to={item.path}
              selected={isActive(item.path)}
              sx={{
                borderRadius: 2,
                '&.Mui-selected': { bgcolor: 'primary.main', color: 'primary.contrastText', '&:hover': { bgcolor: 'primary.dark' } },
              }}
            >
              <ListItemIcon sx={{ minWidth: 40, color: isActive(item.path) ? 'inherit' : 'text.secondary' }}>
                {item.icon}
              </ListItemIcon>
              <ListItemText primary={item.label} slotProps={{ primary: { style: { fontWeight: isActive(item.path) ? 700 : 500, fontSize: '0.9rem' } } }} />
            </ListItemButton>
          </ListItem>
        ))}
      </List>
      <Divider />
      <List sx={{ px: 1, py: 2 }}>
        <ListItem disablePadding>
          <ListItemButton sx={{ borderRadius: 2, color: 'error.main' }}>
            <ListItemIcon sx={{ minWidth: 40, color: 'inherit' }}><LogoutIcon /></ListItemIcon>
            <ListItemText primary="Logout" slotProps={{ primary: { style: { fontWeight: 600, fontSize: '0.9rem' } } }} />
          </ListItemButton>
        </ListItem>
      </List>
    </Box>
  );

  return (
    <Box sx={{ display: 'flex', minHeight: '100vh', bgcolor: 'background.default' }}>
      {/* App Bar */}
      <AppBar
        position="fixed"
        elevation={0}
        sx={{
          width: { md: `calc(100% - ${DRAWER_WIDTH}px)` },
          ml: { md: `${DRAWER_WIDTH}px` },
          bgcolor: 'background.paper',
          borderBottom: 1,
          borderColor: 'divider',
          color: 'text.primary'
        }}
      >
        <Toolbar sx={{ justifyContent: 'space-between' }}>
          <IconButton color="inherit" edge="start" onClick={handleDrawerToggle} sx={{ mr: 2, display: { md: 'none' } }}>
            <MenuIcon />
          </IconButton>
          
          <Typography variant="h6" noWrap component="div" sx={{ fontWeight: 'bold', display: { xs: 'none', sm: 'block' } }}>
            {ADMIN_NAV.find(n => isActive(n.path))?.label || 'Admin Portal'}
          </Typography>

          <Box sx={{ flexGrow: 1 }} />

          <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
            <IconButton onClick={toggleColorMode} color="inherit">
              {mode === 'dark' ? <Brightness7Icon /> : <Brightness4Icon />}
            </IconButton>
            <NotificationCenter />
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, ml: 1 }}>
              <Avatar sx={{ width: 32, height: 32, bgcolor: 'primary.main', fontSize: '0.875rem' }}>A</Avatar>
              <Box sx={{ display: { xs: 'none', md: 'block' } }}>
                <Typography variant="subtitle2" sx={{ fontWeight: 'bold', lineHeight: 1.2 }}>Admin User</Typography>
                <Typography variant="caption" color="text.secondary">Dispatcher</Typography>
              </Box>
            </Box>
          </Box>
        </Toolbar>
      </AppBar>

      {/* Sidebar */}
      <Box component="nav" sx={{ width: { md: DRAWER_WIDTH }, flexShrink: { md: 0 } }}>
        <Drawer
          variant="temporary"
          open={mobileOpen}
          onClose={handleDrawerToggle}
          ModalProps={{ keepMounted: true }}
          sx={{ display: { xs: 'block', md: 'none' }, '& .MuiDrawer-paper': { boxSizing: 'border-box', width: DRAWER_WIDTH, bgcolor: 'background.paper' } }}
        >
          {drawer}
        </Drawer>
        <Drawer
          variant="permanent"
          sx={{ display: { xs: 'none', md: 'block' }, '& .MuiDrawer-paper': { boxSizing: 'border-box', width: DRAWER_WIDTH, bgcolor: 'background.paper', borderRight: 1, borderColor: 'divider' } }}
          open
        >
          {drawer}
        </Drawer>
      </Box>

      {/* Main Content */}
      <Box component="main" sx={{ flexGrow: 1, width: { md: `calc(100% - ${DRAWER_WIDTH}px)` } }}>
        <Toolbar /> {/* Spacer for AppBar */}
        <Box sx={{ p: { xs: 2, md: 4 } }}>
          <Outlet />
        </Box>
      </Box>
    </Box>
  );
}
