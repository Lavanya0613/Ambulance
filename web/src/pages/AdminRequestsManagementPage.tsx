import { useState } from 'react';
import {
  Box, Container, Card, CardContent, Typography, TextField, 
  Select, MenuItem, FormControl, InputLabel, InputAdornment,
  Table, TableBody, TableCell, TableContainer, TableHead, TableRow, Paper,
  Chip, Pagination, Skeleton
} from '@mui/material';
import { ErrorState, EmptyState } from '../components/UIStates';
import { useQuery } from '@tanstack/react-query';
import axios from 'axios';
import { useNavigate } from 'react-router-dom';
import SearchIcon from '@mui/icons-material/Search';

export default function AdminRequestsManagementPage() {
  const navigate = useNavigate();

  // Filters state
  const [page, setPage] = useState(1);
  const [limit] = useState(20);
  const [search, setSearch] = useState('');
  const [status, setStatus] = useState('ALL');
  const [date, setDate] = useState('');

  const { data, isLoading, isError, refetch } = useQuery({
    queryKey: ['admin-requests', page, limit, search, status, date],
    queryFn: async () => {
      const params: any = { page, limit };
      if (search) params.search = search;
      if (status !== 'ALL') params.status = status;
      if (date) params.date = date;

      const response = await axios.get('/admin/requests', { params });
      return response.data; // { data: [...], total: X, page: Y, limit: Z }
    },
    refetchInterval: 30000, // Background refresh every 30s as fallback to sockets
  });

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'REQUEST_CREATED':
      case 'SEARCHING_DRIVER': return 'warning';
      case 'VENDOR_ACCEPTED':
      case 'DRIVER_ASSIGNED': return 'info';
      case 'EN_ROUTE': 
      case 'ARRIVED':
      case 'PATIENT_ONBOARD': return 'primary';
      case 'DESTINATION_REACHED':
      case 'COMPLETED': return 'success';
      case 'CANCELLED':
      case 'FAILED': return 'error';
      default: return 'default';
    }
  };

  const requestsData = data?.data || data;
  const requests = Array.isArray(requestsData) ? requestsData : [];
  const totalRecords = data?.total || 0;
  const totalPages = Math.ceil(totalRecords / limit);

  return (
    <Container maxWidth="xl" sx={{ mb: 8, mt: 4 }}>
      <Box sx={{ mb: 4 }}>
        <Typography variant="h4" color="primary" sx={{ fontWeight: 'bold' }}>
          Requests Management
        </Typography>
        <Typography variant="body2" color="text.secondary">
          Browse, filter, and view details for all historical and active ambulance requests.
        </Typography>
      </Box>

      <Card sx={{ mb: 4 }}>
        <CardContent>
          {/* Filters Row */}
          <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 2, mb: 3 }}>
            <TextField
              size="small"
              placeholder="Search by Patient or Request #"
              value={search}
              onChange={(e) => {
                setSearch(e.target.value);
                setPage(1); // Reset page on filter change
              }}
              slotProps={{
                input: { startAdornment: <InputAdornment position="start"><SearchIcon fontSize="small" /></InputAdornment> }
              }}
              sx={{ minWidth: 280 }}
            />

            <FormControl size="small" sx={{ width: 180 }}>
              <InputLabel>Status</InputLabel>
              <Select
                value={status}
                label="Status"
                onChange={(e) => {
                  setStatus(e.target.value);
                  setPage(1);
                }}
              >
                <MenuItem value="ALL">All Statuses</MenuItem>
                <MenuItem value="REQUEST_CREATED">Request Created</MenuItem>
                <MenuItem value="SEARCHING_DRIVER">Searching Driver</MenuItem>
                <MenuItem value="VENDOR_ACCEPTED">Vendor Accepted</MenuItem>
                <MenuItem value="DRIVER_ASSIGNED">Driver Assigned</MenuItem>
                <MenuItem value="EN_ROUTE">En Route</MenuItem>
                <MenuItem value="ARRIVED">Arrived</MenuItem>
                <MenuItem value="PATIENT_ONBOARD">Patient Onboard</MenuItem>
                <MenuItem value="DESTINATION_REACHED">Destination Reached</MenuItem>
                <MenuItem value="COMPLETED">Completed</MenuItem>
                <MenuItem value="CANCELLED">Cancelled</MenuItem>
                <MenuItem value="FAILED">Failed</MenuItem>
              </Select>
            </FormControl>

            <TextField
              size="small"
              type="date"
              label="Date"
              slotProps={{ inputLabel: { shrink: true } }}
              value={date}
              onChange={(e) => {
                setDate(e.target.value);
                setPage(1);
              }}
              sx={{ width: 180 }}
            />
          </Box>

          {/* Table Area */}
          <TableContainer component={Paper} elevation={0} sx={{ border: '1px solid #e2e8f0' }}>
            <Table size="small">
              <TableHead>
                <TableRow>
                  <TableCell>Request #</TableCell>
                  <TableCell>Patient</TableCell>
                  <TableCell>Phone</TableCell>
                  <TableCell>Pickup</TableCell>
                  <TableCell>Destination</TableCell>
                  <TableCell>Status</TableCell>
                  <TableCell>Vendor</TableCell>
                  <TableCell>ETA</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {isLoading ? (
                  [...Array(10)].map((_, i) => (
                    <TableRow key={`skeleton-${i}`}>
                      {[...Array(8)].map((_, j) => (
                        <TableCell key={`cell-${j}`}><Skeleton animation="wave" height={24} /></TableCell>
                      ))}
                    </TableRow>
                  ))
                ) : isError ? (
                  <TableRow>
                    <TableCell colSpan={8} align="center" sx={{ py: 4, borderBottom: 'none' }}>
                      <ErrorState message="Failed to load requests" onRetry={refetch} />
                    </TableCell>
                  </TableRow>
                ) : requests.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={8} align="center" sx={{ py: 4, borderBottom: 'none' }}>
                      <EmptyState title="No requests found" description="Adjust your filters or try again later." />
                    </TableCell>
                  </TableRow>
                ) : (
                  requests.map((req: any) => (
                    <TableRow 
                      key={req.id} 
                      hover 
                      onClick={() => navigate(`/admin/requests/${req.id}`)}
                      sx={{ cursor: 'pointer', '&:last-child td, &:last-child th': { border: 0 } }}
                    >
                      <TableCell sx={{ fontWeight: 600 }}>{req.requestNumber}</TableCell>
                      <TableCell>{req.patientName}</TableCell>
                      <TableCell>{req.patientPhone || '-'}</TableCell>
                      <TableCell>
                        <Typography noWrap sx={{ maxWidth: 150, fontSize: '0.875rem' }}>
                          {req.pickupAddress}
                        </Typography>
                      </TableCell>
                      <TableCell>
                        <Typography noWrap sx={{ maxWidth: 150, fontSize: '0.875rem' }}>
                          {req.destinationAddress}
                        </Typography>
                      </TableCell>
                      <TableCell>
                        <Chip label={req.status?.replace(/_/g, ' ')} size="small" color={getStatusColor(req.status) as any} />
                      </TableCell>
                      <TableCell>
                        {req.vendorName || req.vendorDriverName || '-'}
                      </TableCell>
                      <TableCell>
                        {req.etaSeconds != null ? `${Math.floor(req.etaSeconds / 60)}m` : '-'}
                      </TableCell>
                    </TableRow>
                  ))
                )}
              </TableBody>
            </Table>
          </TableContainer>

          {/* Pagination */}
          {!isLoading && !isError && totalPages > 1 && (
            <Box sx={{ display: 'flex', justifyContent: 'center', mt: 3 }}>
              <Pagination 
                count={totalPages} 
                page={page} 
                onChange={(_, value) => setPage(value)} 
                color="primary" 
              />
            </Box>
          )}

        </CardContent>
      </Card>
    </Container>
  );
}
