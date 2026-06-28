import { Container, Typography, Card, CardContent, Button, Box, Divider } from '@mui/material';
import PersonIcon from '@mui/icons-material/Person';
import LogoutIcon from '@mui/icons-material/Logout';
import { useNavigate } from 'react-router-dom';

export default function ProfilePage() {
  const navigate = useNavigate();

  const handleLogout = () => {
    // Basic logout logic for now
    localStorage.removeItem('access_token');
    navigate('/');
  };

  return (
    <Container maxWidth="md" sx={{ mt: 4, mb: 8 }}>
      <Typography variant="h4" color="primary" sx={{ mb: 4, fontWeight: 'bold' }}>
        My Profile
      </Typography>

      <Card>
        <CardContent sx={{ p: 4 }}>
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 3, mb: 4 }}>
            <Box sx={{ p: 3, bgcolor: 'primary.light', borderRadius: '50%', color: 'primary.main' }}>
              <PersonIcon sx={{ fontSize: 48 }} />
            </Box>
            <Box>
              <Typography variant="h5" sx={{ fontWeight: 'bold' }}>John Doe</Typography>
              <Typography color="text.secondary">+91 9876543210</Typography>
            </Box>
          </Box>
          
          <Divider sx={{ mb: 4 }} />
          
          <Typography variant="h6" sx={{ mb: 2 }}>Account Information</Typography>
          <Typography variant="body1" sx={{ mb: 4 }}>
            You have made <strong>3</strong> past requests.
            You can view them in the <Button variant="text" onClick={() => navigate('/my-requests')}>My Requests</Button> tab.
          </Typography>

          <Button variant="outlined" color="error" startIcon={<LogoutIcon />} onClick={handleLogout}>
            Logout
          </Button>
        </CardContent>
      </Card>
    </Container>
  );
}
