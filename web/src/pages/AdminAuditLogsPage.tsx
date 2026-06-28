import { useState } from 'react';
import { 
  Box, 
  Container, 
  Card, 
  CardContent, 
  Typography, 
  Table, 
  TableBody, 
  TableCell, 
  TableContainer, 
  TableHead, 
  TableRow, 
  Pagination, 
  TextField, 
  InputAdornment, 
  Paper, 
  Button, 
  Chip,
  Skeleton
} from '@mui/material';
import { ErrorState, EmptyState } from '../components/UIStates';
import SearchIcon from '@mui/icons-material/Search';
import DateRangeIcon from '@mui/icons-material/DateRange';
import FilterListIcon from '@mui/icons-material/FilterList';
import { useQuery } from '@tanstack/react-query';
import axios from 'axios';

export default function AdminAuditLogsPage() {
  const [page, setPage] = useState(1);
  const [actionFilter, setActionFilter] = useState('');
  const [requestFilter, setRequestFilter] = useState('');
  const [dateFilter, setDateFilter] = useState('');

  const [activeFilters, setActiveFilters] = useState({
    action: '',
    request: '',
    date: ''
  });

  const { data, isLoading, isError, refetch } = useQuery({
    queryKey: ['admin-audit-logs', page, activeFilters],
    queryFn: async () => {
      const params = new URLSearchParams({
        page: page.toString(),
        limit: '20',
      });
      if (activeFilters.action) params.append('action', activeFilters.action);
      if (activeFilters.request) params.append('request', activeFilters.request);
      if (activeFilters.date) params.append('date', activeFilters.date);

      const response = await axios.get(`/admin/audit-logs?${params.toString()}`);
      return response.data;
    },
    refetchInterval: 30000,
  });

  const handleApplyFilters = () => {
    setPage(1);
    setActiveFilters({
      action: actionFilter,
      request: requestFilter,
      date: dateFilter
    });
  };

  const handleClearFilters = () => {
    setActionFilter('');
    setRequestFilter('');
    setDateFilter('');
    setPage(1);
    setActiveFilters({ action: '', request: '', date: '' });
  };

  return (
    <Container maxWidth="xl" sx={{ mt: 4, mb: 8 }}>
      <Box sx={{ mb: 4 }}>
        <Typography variant="h4" color="primary" sx={{ fontWeight: 'bold' }}>
          System Audit Logs
        </Typography>
        <Typography variant="body1" color="text.secondary">
          Monitor all system events, status changes, and administrator actions.
        </Typography>
      </Box>

      {/* Filters Section */}
      <Card sx={{ mb: 4 }}>
        <CardContent>
          <Box sx={{ display: 'flex', gap: 2, alignItems: 'center', flexWrap: 'wrap' }}>
            <TextField
              size="small"
              label="Date"
              type="date"
              value={dateFilter}
              onChange={(e) => setDateFilter(e.target.value)}
              slotProps={{
                inputLabel: { shrink: true },
                input: {
                  startAdornment: (
                    <InputAdornment position="start">
                      <DateRangeIcon />
                    </InputAdornment>
                  ),
                }
              }}
            />
            <TextField
              size="small"
              label="Action Type"
              placeholder="e.g. Driver Assigned"
              value={actionFilter}
              onChange={(e) => setActionFilter(e.target.value)}
              slotProps={{
                input: {
                  startAdornment: (
                    <InputAdornment position="start">
                      <FilterListIcon />
                    </InputAdornment>
                  ),
                }
              }}
            />
            <TextField
              size="small"
              label="Request ID"
              placeholder="Search by Request ID"
              value={requestFilter}
              onChange={(e) => setRequestFilter(e.target.value)}
              slotProps={{
                input: {
                  startAdornment: (
                    <InputAdornment position="start">
                      <SearchIcon />
                    </InputAdornment>
                  ),
                }
              }}
            />
            <Button variant="contained" onClick={handleApplyFilters}>
              Apply Filters
            </Button>
            <Button variant="outlined" color="secondary" onClick={handleClearFilters}>
              Clear
            </Button>
          </Box>
        </CardContent>
      </Card>

      {/* Data Table */}
      <Card>
        {isLoading ? (
          <TableContainer component={Paper} elevation={0}>
            <Table sx={{ minWidth: 1000 }} aria-label="audit logs table">
              <TableHead sx={{ bgcolor: 'background.default' }}>
                <TableRow>
                  <TableCell sx={{ fontWeight: 'bold', width: '15%' }}>Timestamp</TableCell>
                  <TableCell sx={{ fontWeight: 'bold', width: '15%' }}>Action</TableCell>
                  <TableCell sx={{ fontWeight: 'bold', width: '20%' }}>Request ID</TableCell>
                  <TableCell sx={{ fontWeight: 'bold', width: '15%' }}>Performed By</TableCell>
                  <TableCell sx={{ fontWeight: 'bold', width: '15%' }}>IP Address</TableCell>
                  <TableCell sx={{ fontWeight: 'bold', width: '20%' }}>Description</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {[...Array(10)].map((_, i) => (
                  <TableRow key={`skeleton-${i}`}>
                    {[...Array(6)].map((_, j) => (
                      <TableCell key={`cell-${j}`}><Skeleton animation="wave" height={24} /></TableCell>
                    ))}
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </TableContainer>
        ) : isError ? (
          <Box sx={{ p: 4 }}>
            <ErrorState message="Failed to load audit logs." onRetry={refetch} />
          </Box>
        ) : !data?.data || data.data.length === 0 ? (
          <Box sx={{ p: 4 }}>
            <EmptyState title="No audit logs found" description="Adjust your date or action filters." />
          </Box>
        ) : (
          <>
            <TableContainer component={Paper} elevation={0}>
              <Table sx={{ minWidth: 1000 }} aria-label="audit logs table">
                <TableHead sx={{ bgcolor: 'grey.50' }}>
                  <TableRow>
                    <TableCell sx={{ fontWeight: 'bold', width: '15%' }}>Timestamp</TableCell>
                    <TableCell sx={{ fontWeight: 'bold', width: '15%' }}>Action</TableCell>
                    <TableCell sx={{ fontWeight: 'bold', width: '20%' }}>Request ID</TableCell>
                    <TableCell sx={{ fontWeight: 'bold', width: '15%' }}>Performed By</TableCell>
                    <TableCell sx={{ fontWeight: 'bold', width: '15%' }}>IP Address</TableCell>
                    <TableCell sx={{ fontWeight: 'bold', width: '20%' }}>Description</TableCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  {(data?.data || []).map((log: any) => (
                    <TableRow key={log.id} hover>
                        <TableCell>
                          <Typography variant="body2" sx={{ fontWeight: 500 }}>
                            {new Date(log.timestamp).toLocaleDateString()}
                          </Typography>
                          <Typography variant="caption" color="text.secondary">
                            {new Date(log.timestamp).toLocaleTimeString()}
                          </Typography>
                        </TableCell>
                        <TableCell>
                          <Chip 
                            label={log.action} 
                            size="small" 
                            color={log.action.includes('Failed') || log.action.includes('Cancel') ? 'error' : 'default'}
                            sx={{ fontWeight: 'bold', borderRadius: 1 }}
                          />
                        </TableCell>
                        <TableCell>
                          <Typography variant="body2" color="primary" sx={{ fontFamily: 'monospace' }}>
                            {log.entityId || '-'}
                          </Typography>
                        </TableCell>
                        <TableCell>{log.userId || 'System'}</TableCell>
                        <TableCell>
                          <Typography variant="body2" sx={{ fontFamily: 'monospace', color: 'text.secondary' }}>
                            {log.ipAddress || '-'}
                          </Typography>
                        </TableCell>
                        <TableCell>
                          <Typography variant="body2" sx={{ color: 'text.secondary', maxWidth: 250 }} noWrap title={log.description || log.newValue || '-'}>
                            {log.description || log.newValue || '-'}
                          </Typography>
                        </TableCell>
                      </TableRow>
                    ))
                }
                </TableBody>
              </Table>
            </TableContainer>
            
            <Box sx={{ p: 2, display: 'flex', justifyContent: 'center', borderTop: '1px solid', borderColor: 'divider' }}>
              <Pagination 
                count={data?.meta?.totalPages || 1} 
                page={page} 
                onChange={(_, value) => setPage(value)} 
                color="primary" 
                showFirstButton 
                showLastButton 
              />
            </Box>
          </>
        )}
      </Card>
    </Container>
  );
}
