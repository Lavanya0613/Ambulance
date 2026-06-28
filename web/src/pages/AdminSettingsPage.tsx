import { Box, Container, Typography, Card, CardContent, Divider, Switch, FormControlLabel, Button, TextField } from '@mui/material';

export default function AdminSettingsPage() {
  return (
    <Container maxWidth="lg" sx={{ mt: 4, mb: 8 }}>
      <Typography variant="h4" color="primary" sx={{ mb: 4, fontWeight: 'bold' }}>
        System Settings
      </Typography>

      <Card sx={{ mb: 4 }}>
        <CardContent>
          <Typography variant="h6" sx={{ mb: 2, fontWeight: 'bold' }}>Vendor Integrations</Typography>
          <Divider sx={{ mb: 3 }} />
          <FormControlLabel control={<Switch defaultChecked />} label="Enable Mock Vendor Fallback" />
          <FormControlLabel control={<Switch defaultChecked />} label="Enable RedHealth API Integration" sx={{ display: 'block', mt: 1 }} />
        </CardContent>
      </Card>

      <Card sx={{ mb: 4 }}>
        <CardContent>
          <Typography variant="h6" sx={{ mb: 2, fontWeight: 'bold' }}>Queue Configuration</Typography>
          <Divider sx={{ mb: 3 }} />
          <Box sx={{ display: 'flex', gap: 2, alignItems: 'center' }}>
            <TextField label="Max Retries" type="number" defaultValue={3} size="small" />
            <TextField label="Retry Delay (ms)" type="number" defaultValue={5000} size="small" />
            <Button variant="contained">Save Settings</Button>
          </Box>
        </CardContent>
      </Card>
    </Container>
  );
}
