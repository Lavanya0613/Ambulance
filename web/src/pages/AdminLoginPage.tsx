import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  Box,
  Card,
  CardContent,
  Typography,
  TextField,
  Button,
  Container,
  InputAdornment,
  IconButton,
  Alert,
} from '@mui/material';
import Visibility from '@mui/icons-material/Visibility';
import VisibilityOff from '@mui/icons-material/VisibilityOff';
import EmailIcon from '@mui/icons-material/Email';
import LockIcon from '@mui/icons-material/Lock';
import LocalHospitalIcon from '@mui/icons-material/LocalHospital';

export default function AdminLoginPage() {
  const navigate = useNavigate();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');

    if (!email) {
      setError('Email is required');
      return;
    }
    if (!password) {
      setError('Password is required');
      return;
    }

    // Temporary validation logic (ready for JWT Integration)
    setLoading(true);
    setTimeout(() => {
      setLoading(false);
      // Simulate JWT success
      if (email && password) {
        // localStorage.setItem('access_token', 'sample_jwt_token_here');
        navigate('/admin/dashboard');
      }
    }, 800);
  };

  return (
    <Box
      sx={{
        minHeight: '100vh',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        bgcolor: '#F7F8FA',
        px: 2,
      }}
    >
      <Container maxWidth="xs">
        <Card
          sx={{
            borderRadius: 4,
            boxShadow: '0 12px 40px rgba(30, 58, 95, 0.08)',
            border: '1px solid #e2e8f0',
            overflow: 'visible',
            position: 'relative',
          }}
        >
          {/* Top Logo Icon */}
          <Box
            sx={{
              position: 'absolute',
              top: -30,
              left: '50%',
              transform: 'translateX(-50%)',
              width: 60,
              height: 60,
              borderRadius: '50%',
              bgcolor: '#ffffff',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              boxShadow: '0 4px 12px rgba(0,0,0,0.1)',
            }}
          >
            <LocalHospitalIcon sx={{ color: '#E53935', fontSize: 32 }} />
          </Box>

          <CardContent sx={{ pt: 6, pb: 4, px: 4 }}>
            <Box sx={{ textAlign: 'center', mb: 4 }}>
              <Typography variant="h5" sx={{ fontWeight: 800, color: '#1E3A5F', mb: 1 }}>
                CallHealth
              </Typography>
              <Typography variant="subtitle2" sx={{ color: '#E53935', fontWeight: 700, letterSpacing: 1, textTransform: 'uppercase' }}>
                Admin Portal
              </Typography>
            </Box>

            {error && (
              <Alert severity="error" sx={{ mb: 3, borderRadius: 2 }}>
                {error}
              </Alert>
            )}

            <form onSubmit={handleSubmit}>
              <TextField
                fullWidth
                label="Email Address"
                variant="outlined"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                sx={{ mb: 3 }}
                slotProps={{
                  input: {
                    startAdornment: (
                      <InputAdornment position="start">
                        <EmailIcon color="action" />
                      </InputAdornment>
                    ),
                  }
                }}
              />

              <TextField
                fullWidth
                label="Password"
                type={showPassword ? 'text' : 'password'}
                variant="outlined"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                sx={{ mb: 4 }}
                slotProps={{
                  input: {
                    startAdornment: (
                      <InputAdornment position="start">
                        <LockIcon color="action" />
                      </InputAdornment>
                    ),
                    endAdornment: (
                      <InputAdornment position="end">
                        <IconButton
                          onClick={() => setShowPassword(!showPassword)}
                          edge="end"
                          size="small"
                        >
                          {showPassword ? <VisibilityOff /> : <Visibility />}
                        </IconButton>
                      </InputAdornment>
                    ),
                  }
                }}
              />

              <Button
                fullWidth
                type="submit"
                variant="contained"
                disabled={loading}
                sx={{
                  py: 1.5,
                  bgcolor: '#E53935',
                  color: '#ffffff',
                  fontWeight: 700,
                  fontSize: '1rem',
                  borderRadius: 24,
                  boxShadow: '0 4px 14px rgba(229, 57, 53, 0.3)',
                  '&:hover': {
                    bgcolor: '#c62828',
                    boxShadow: '0 6px 20px rgba(229, 57, 53, 0.4)',
                  },
                }}
              >
                {loading ? 'Authenticating...' : 'Sign In'}
              </Button>
            </form>
          </CardContent>
        </Card>
      </Container>
    </Box>
  );
}
