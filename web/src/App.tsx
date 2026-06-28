import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { CssBaseline } from '@mui/material';
import { createTheme, ThemeProvider } from '@mui/material/styles';
import { useMemo } from 'react';

import BookingPage from './pages/BookingPage';
import TrackingPage from './pages/TrackingPage';
import HistoryPage from './pages/HistoryPage';
import ProfilePage from './pages/ProfilePage';
import AdminLoginPage from './pages/AdminLoginPage';
import AdminDashboardPage from './pages/AdminDashboardPage';
import AdminRequestsManagementPage from './pages/AdminRequestsManagementPage';
import AdminRequestDetailsPage from './pages/AdminRequestDetailsPage';
import AdminAuditLogsPage from './pages/AdminAuditLogsPage';
import AdminSystemMonitoringPage from './pages/AdminSystemMonitoringPage';
import AdminLiveMonitoringPage from './pages/AdminLiveMonitoringPage';
import AdminDriversPage from './pages/AdminDriversPage';
import AdminVendorsPage from './pages/AdminVendorsPage';
import AdminSettingsPage from './pages/AdminSettingsPage';

import { NotificationProvider } from './context/NotificationContext';
import { ColorModeProvider, useColorMode } from './context/ColorModeContext';

import PatientLayout from './layouts/PatientLayout';
import AdminLayout from './layouts/AdminLayout';
// import ProtectedRoute from './components/ProtectedRoute';



// ── App Configuration ────────────────────────────────────────
function AppContent() {
  const { mode } = useColorMode();

  const ambulanceTheme = useMemo(
    () =>
      createTheme({
        palette: {
          mode,
          ...(mode === 'light'
            ? {
                primary:   { main: '#76B82A', dark: '#5b961f', light: '#f1f8eb', contrastText: '#fff' },
                secondary: { main: '#1E3A5F', dark: '#112238', light: '#e8ecf1', contrastText: '#fff' },
                background: { default: '#F7F8FA', paper: '#ffffff' },
                text:       { primary: '#1F2937', secondary: '#6b7a9e' },
                error:      { main: '#E53935' },
                success:    { main: '#76B82A' },
                warning:    { main: '#F4B400' },
                info:       { main: '#1E3A5F' },
              }
            : {
                primary:   { main: '#76B82A', dark: '#5b961f', light: '#1e293b', contrastText: '#fff' },
                secondary: { main: '#94a3b8', dark: '#64748b', light: '#cbd5e1', contrastText: '#1E3A5F' },
                background: { default: '#0F172A', paper: '#1E293B' },
                text:       { primary: '#F8FAFC', secondary: '#94A3B8' },
                error:      { main: '#EF4444' },
                success:    { main: '#22C55E' },
                warning:    { main: '#F59E0B' },
                info:       { main: '#3B82F6' },
              }),
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
        shape: { borderRadius: 16 },
        components: {
          MuiCssBaseline: {
            styleOverrides: {
              body: {
                transition: 'background-color 0.3s ease, color 0.3s ease',
              },
            },
          },
          MuiButton: {
            styleOverrides: {
              root: { textTransform: 'none', fontWeight: 600, borderRadius: 24, padding: '8px 24px', transition: 'all 0.3s ease' },
              contained: {
                '&.MuiButton-containedPrimary': {
                  background: '#76B82A',
                  boxShadow: mode === 'light' ? '0 4px 14px rgba(118, 184, 42, 0.3)' : '0 4px 14px rgba(118, 184, 42, 0.1)',
                  '&:hover': { background: '#5b961f', boxShadow: mode === 'light' ? '0 6px 20px rgba(118, 184, 42, 0.4)' : '0 6px 20px rgba(118, 184, 42, 0.2)' },
                },
              },
            },
          },
          MuiCard: {
            styleOverrides: {
              root: {
                border: mode === 'dark' ? '1px solid #334155' : 'none',
                boxShadow: mode === 'light' ? '0 8px 24px rgba(30, 58, 95, 0.04), 0 2px 8px rgba(30, 58, 95, 0.02)' : '0 8px 24px rgba(0,0,0,0.4)',
                borderRadius: 22,
                transition: 'all 0.3s ease-in-out',
                backgroundImage: 'none',
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
              root: { '& .MuiTableCell-root': { fontWeight: 700, background: mode === 'light' ? '#f8fafc' : '#0F172A' } },
            },
          },
        },
      }),
    [mode]
  );

  return (
    <ThemeProvider theme={ambulanceTheme}>
      <CssBaseline />
      <NotificationProvider>
        <Router>
          <Routes>
            {/* Patient Portal */}
            <Route element={<PatientLayout />}>
              <Route path="/" element={<BookingPage />} />
              <Route path="/book" element={<Navigate to="/" replace />} />
              <Route path="/my-requests" element={<HistoryPage />} />
              <Route path="/tracking/:requestId" element={<TrackingPage />} />
              <Route path="/profile" element={<ProfilePage />} />
            </Route>

            {/* Admin Portal (Standalone Login) */}
            <Route path="/admin/login" element={<AdminLoginPage />} />

            {/* Admin Portal (Sidebar Layout) */}
            <Route element={<AdminLayout />}>
              <Route path="/admin" element={<Navigate to="/admin/dashboard" replace />} />
              <Route path="/admin/dashboard" element={<AdminDashboardPage />} />
              <Route path="/admin/requests" element={<AdminRequestsManagementPage />} />
              <Route path="/admin/request/:id" element={<AdminRequestDetailsPage />} />
              <Route path="/admin/live" element={<AdminLiveMonitoringPage />} />
              <Route path="/admin/drivers" element={<AdminDriversPage />} />
              <Route path="/admin/vendors" element={<AdminVendorsPage />} />
              <Route path="/admin/audit" element={<AdminAuditLogsPage />} />
              <Route path="/admin/system" element={<AdminSystemMonitoringPage />} />
              <Route path="/admin/settings" element={<AdminSettingsPage />} />
            </Route>
          </Routes>
        </Router>
      </NotificationProvider>
    </ThemeProvider>
  );
}

function App() {
  return (
    <ColorModeProvider>
      <AppContent />
    </ColorModeProvider>
  );
}

export default App;
