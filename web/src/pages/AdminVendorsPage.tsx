import { Container, Typography, Card, CardContent, Table, TableHead, TableBody, TableRow, TableCell, Chip } from '@mui/material';

export default function AdminVendorsPage() {
  const vendors = [
    { id: 'V-001', name: 'Mock Vendor System', status: 'ACTIVE', successRate: '98%', avgResponse: '12s', activeTrips: 15 },
    { id: 'V-002', name: 'RedHealth API', status: 'INACTIVE', successRate: 'N/A', avgResponse: 'N/A', activeTrips: 0 },
  ];

  return (
    <Container maxWidth="xl" sx={{ mt: 4, mb: 8 }}>
      <Typography variant="h4" color="primary" sx={{ mb: 4, fontWeight: 'bold' }}>
        Vendor Management
      </Typography>

      <Card>
        <CardContent sx={{ p: 0 }}>
          <Table>
            <TableHead sx={{ bgcolor: 'background.default' }}>
              <TableRow>
                <TableCell>Vendor ID</TableCell>
                <TableCell>Name</TableCell>
                <TableCell>Status</TableCell>
                <TableCell>Success Rate</TableCell>
                <TableCell>Avg Response Time</TableCell>
                <TableCell>Active Trips</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {vendors.map(v => (
                <TableRow key={v.id}>
                  <TableCell>{v.id}</TableCell>
                  <TableCell sx={{ fontWeight: 'bold' }}>{v.name}</TableCell>
                  <TableCell><Chip label={v.status} color={v.status === 'ACTIVE' ? 'success' : 'default'} size="small" /></TableCell>
                  <TableCell>{v.successRate}</TableCell>
                  <TableCell>{v.avgResponse}</TableCell>
                  <TableCell>{v.activeTrips}</TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </CardContent>
      </Card>
    </Container>
  );
}
