import { Container, Typography, Card, CardContent, Table, TableHead, TableBody, TableRow, TableCell, Chip } from '@mui/material';

export default function AdminDriversPage() {
  const drivers = [
    { id: 'D-101', name: 'John Smith', vehicle: 'AP-09-CD-1234', phone: '+91 9876543210', status: 'ON_TRIP', vendor: 'Mock Vendor System', trip: 'REQ-12345' },
    { id: 'D-102', name: 'Raj Kumar', vehicle: 'TS-07-EF-5678', phone: '+91 9876543211', status: 'IDLE', vendor: 'Mock Vendor System', trip: '-' },
  ];

  return (
    <Container maxWidth="xl" sx={{ mt: 4, mb: 8 }}>
      <Typography variant="h4" color="primary" sx={{ mb: 4, fontWeight: 'bold' }}>
        Driver Fleet
      </Typography>

      <Card>
        <CardContent sx={{ p: 0 }}>
          <Table>
            <TableHead sx={{ bgcolor: 'background.default' }}>
              <TableRow>
                <TableCell>Driver Name</TableCell>
                <TableCell>Vehicle No</TableCell>
                <TableCell>Phone</TableCell>
                <TableCell>Status</TableCell>
                <TableCell>Vendor</TableCell>
                <TableCell>Current Trip</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {drivers.map(d => (
                <TableRow key={d.id}>
                  <TableCell sx={{ fontWeight: 'bold' }}>{d.name}</TableCell>
                  <TableCell>{d.vehicle}</TableCell>
                  <TableCell>{d.phone}</TableCell>
                  <TableCell><Chip label={d.status} color={d.status === 'ON_TRIP' ? 'primary' : 'default'} size="small" /></TableCell>
                  <TableCell>{d.vendor}</TableCell>
                  <TableCell>{d.trip}</TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </CardContent>
      </Card>
    </Container>
  );
}
