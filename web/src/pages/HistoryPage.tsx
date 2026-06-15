import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import axios from 'axios';
import {
  Box, Container, Typography, Card, CardContent, Table, TableBody,
  TableCell, TableContainer, TableHead, TableRow, Chip, Button,
  IconButton, Tooltip, TextField, InputAdornment, MenuItem,
  Alert, Avatar, Skeleton,
} from '@mui/material';
import TrackChangesIcon from '@mui/icons-material/TrackChanges';
import SearchIcon from '@mui/icons-material/Search';
import RefreshIcon from '@mui/icons-material/Refresh';
import HistoryIcon from '@mui/icons-material/History';
import FilterListIcon from '@mui/icons-material/FilterList';
import LocalHospitalIcon from '@mui/icons-material/LocalHospital';
import PriorityHighIcon from '@mui/icons-material/PriorityHigh';

const API_BASE_URL = 'http://localhost:3000';

// ── Types ────────────────────────────────────────────────────
interface AmbulanceRequest {
  requestId: string;
  requestNumber: string;
  status: string;
  priority: string;
  patientName: string;
  patientPhone: string;
  assignedVendorId: string | null;
  driver: { name: string; vehicleNumber: string; ambulanceType: string } | null;
  etaSeconds: number | null;
  cancelReason: string | null;
  createdAt: string;
  updatedAt: string;
}

// ── Helpers ──────────────────────────────────────────────────
const STATUS_META: Record<string, { label: string; color: string; bg: string; border: string }> = {
  PENDING:     { label: 'Pending',     color: '#92400e', bg: '#fef3c7', border: '#fcd34d' },
  ASSIGNED:    { label: 'Assigned',    color: '#5b21b6', bg: '#ede9fe', border: '#c4b5fd' },
  EN_ROUTE:    { label: 'En Route',    color: '#1e40af', bg: '#dbeafe', border: '#93c5fd' },
  ARRIVED:     { label: 'Arrived',     color: '#155e75', bg: '#cffafe', border: '#67e8f9' },
  IN_PROGRESS: { label: 'In Progress', color: '#1e40af', bg: '#dbeafe', border: '#93c5fd' },
  COMPLETED:   { label: 'Completed',   color: '#166534', bg: '#dcfce7', border: '#86efac' },
  CANCELLED:   { label: 'Cancelled',   color: '#991b1b', bg: '#fee2e2', border: '#fca5a5' },
  FAILED:      { label: 'Failed',      color: '#9d174d', bg: '#fce7f3', border: '#f9a8d4' },
};

const PRIORITY_META: Record<string, { label: string; color: string; icon?: boolean }> = {
  normal:   { label: 'Normal',   color: '#64748b' },
  high:     { label: 'High',     color: '#d97706', icon: true },
  critical: { label: 'Critical', color: '#dc2626', icon: true },
  urgent:   { label: 'Urgent',   color: '#dc2626', icon: true },
};

const ALL_STATUSES = ['ALL', 'PENDING', 'ASSIGNED', 'EN_ROUTE', 'ARRIVED', 'COMPLETED', 'CANCELLED', 'FAILED'];

function StatusChip({ status }: { status: string }) {
  const meta = STATUS_META[status] ?? { label: status, color: '#64748b', bg: '#f1f5f9', border: '#e2e8f0' };
  return (
    <Chip
      label={meta.label}
      size="small"
      sx={{ bgcolor: meta.bg, color: meta.color, border: `1px solid ${meta.border}`, fontWeight: 700, fontSize: '0.72rem' }}
    />
  );
}

function PriorityBadge({ priority }: { priority: string }) {
  const meta = PRIORITY_META[priority?.toLowerCase()] ?? { label: priority, color: '#64748b' };
  return (
    <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}>
      {meta.icon && <PriorityHighIcon sx={{ fontSize: '0.9rem', color: meta.color }} />}
      <Typography variant="caption" sx={{ fontWeight: 600, color: meta.color, textTransform: 'capitalize' }}>
        {meta.label}
      </Typography>
    </Box>
  );
}

function formatDate(iso: string) {
  const d = new Date(iso);
  return d.toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric' }) +
    ' ' + d.toLocaleTimeString('en-IN', { hour: '2-digit', minute: '2-digit' });
}

// ── Component ────────────────────────────────────────────────
export default function HistoryPage() {
  const navigate = useNavigate();
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('ALL');

  const { data: requests = [], isLoading, error, refetch, isFetching } = useQuery<AmbulanceRequest[]>({
    queryKey: ['requests-history'],
    queryFn: async () => {
      const res = await axios.get(`${API_BASE_URL}/patient/requests`);
      return res.data;
    },
    refetchInterval: 15000,
    staleTime: 5000,
  });

  // Filter
  const filtered = requests.filter((r) => {
    const matchStatus = statusFilter === 'ALL' || r.status === statusFilter;
    const q = search.toLowerCase();
    const matchSearch = !q || r.requestNumber.toLowerCase().includes(q) ||
      r.patientName.toLowerCase().includes(q) || r.requestId.toLowerCase().includes(q);
    return matchStatus && matchSearch;
  });

  const stats = {
    total:     requests.length,
    active:    requests.filter(r => ['PENDING','ASSIGNED','EN_ROUTE','ARRIVED','IN_PROGRESS'].includes(r.status)).length,
    completed: requests.filter(r => r.status === 'COMPLETED').length,
    cancelled: requests.filter(r => r.status === 'CANCELLED').length,
  };

  return (
    <Container maxWidth="xl">

      {/* ── Page Header ── */}
      <Box sx={{ mb: 4 }}>
        <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', flexWrap: 'wrap', gap: 2 }}>
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
            <Box sx={{
              width: 48, height: 48, borderRadius: '12px',
              background: 'linear-gradient(135deg, #dc2626 0%, #b91c1c 100%)',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              boxShadow: '0 4px 14px rgba(220,38,38,0.3)',
            }}>
              <HistoryIcon sx={{ color: '#fff', fontSize: 24 }} />
            </Box>
            <Box>
              <Typography variant="h4" sx={{ fontWeight: 800, color: '#1e293b', lineHeight: 1.2 }}>
                Request History
              </Typography>
              <Typography variant="body2" color="text.secondary">
                All ambulance dispatches — updated in real time
              </Typography>
            </Box>
          </Box>
          <Tooltip title="Refresh">
            <IconButton
              onClick={() => refetch()}
              disabled={isFetching}
              sx={{ bgcolor: '#f1f5f9', '&:hover': { bgcolor: '#e2e8f0' } }}
            >
              <RefreshIcon sx={{ animation: isFetching ? 'spin 1s linear infinite' : 'none' }} />
            </IconButton>
          </Tooltip>
        </Box>
      </Box>

      {/* ── Summary Cards ── */}
      <Box sx={{ display: 'grid', gridTemplateColumns: { xs: 'repeat(2,1fr)', md: 'repeat(4,1fr)' }, gap: 2, mb: 3 }}>
        {[
          { label: 'Total Requests', value: stats.total,     color: '#1d4ed8', bg: '#dbeafe', icon: '📋' },
          { label: 'Active',         value: stats.active,    color: '#dc2626', bg: '#fee2e2', icon: '🚑' },
          { label: 'Completed',      value: stats.completed, color: '#16a34a', bg: '#dcfce7', icon: '✅' },
          { label: 'Cancelled',      value: stats.cancelled, color: '#64748b', bg: '#f1f5f9', icon: '❌' },
        ].map((s) => (
          <Card key={s.label} sx={{ border: `1px solid ${s.bg}` }}>
            <CardContent sx={{ p: 2.5, '&:last-child': { pb: 2.5 } }}>
              <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                <Box>
                  <Typography variant="caption" sx={{ color: '#64748b', fontWeight: 600, textTransform: 'uppercase', letterSpacing: 0.8 }}>
                    {s.label}
                  </Typography>
                  <Typography variant="h3" sx={{ fontWeight: 800, color: s.color, lineHeight: 1.1, mt: 0.3 }}>
                    {isLoading ? <Skeleton width={40} /> : s.value}
                  </Typography>
                </Box>
                <Box sx={{
                  width: 44, height: 44, borderRadius: '12px', bgcolor: s.bg,
                  display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '1.4rem',
                }}>
                  {s.icon}
                </Box>
              </Box>
            </CardContent>
          </Card>
        ))}
      </Box>

      {/* ── Filters ── */}
      <Card sx={{ mb: 2.5 }}>
        <CardContent sx={{ p: 2, '&:last-child': { pb: 2 } }}>
          <Box sx={{ display: 'flex', gap: 2, flexWrap: 'wrap', alignItems: 'center' }}>
            <TextField
              placeholder="Search by name, request #, or ID…"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              size="small"
              sx={{ flex: 1, minWidth: 220 }}
              slotProps={{
                input: {
                  startAdornment: <InputAdornment position="start"><SearchIcon sx={{ color: '#94a3b8', fontSize: '1.1rem' }} /></InputAdornment>,
                }
              }}
            />
            <TextField
              select
              size="small"
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value)}
              sx={{ minWidth: 160 }}
              slotProps={{
                input: {
                  startAdornment: <InputAdornment position="start"><FilterListIcon sx={{ color: '#94a3b8', fontSize: '1.1rem' }} /></InputAdornment>,
                }
              }}
            >
              {ALL_STATUSES.map((s) => (
                <MenuItem key={s} value={s}>{s === 'ALL' ? 'All Statuses' : (STATUS_META[s]?.label ?? s)}</MenuItem>
              ))}
            </TextField>
            <Typography variant="caption" color="text.secondary" sx={{ fontWeight: 600 }}>
              {filtered.length} of {requests.length} records
            </Typography>
          </Box>
        </CardContent>
      </Card>

      {/* ── Error ── */}
      {error && (
        <Alert severity="error" sx={{ mb: 2, borderRadius: 2 }}>
          Failed to load request history. Make sure the backend is running.
        </Alert>
      )}

      {/* ── Table ── */}
      <Card>
        <TableContainer>
          <Table sx={{ minWidth: 750 }}>
            <TableHead>
              <TableRow sx={{ '& .MuiTableCell-root': { fontWeight: 700, color: '#475569', fontSize: '0.78rem', textTransform: 'uppercase', letterSpacing: 0.6, bgcolor: '#f8fafc', py: 1.5 } }}>
                <TableCell>Request #</TableCell>
                <TableCell>Patient</TableCell>
                <TableCell>Status</TableCell>
                <TableCell>Priority</TableCell>
                <TableCell>Driver / Vehicle</TableCell>
                <TableCell>ETA</TableCell>
                <TableCell>Created</TableCell>
                <TableCell align="center">Actions</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {isLoading ? (
                Array.from({ length: 5 }).map((_, i) => (
                  <TableRow key={i}>
                    {Array.from({ length: 8 }).map((_, j) => (
                      <TableCell key={j}><Skeleton variant="text" /></TableCell>
                    ))}
                  </TableRow>
                ))
              ) : filtered.length === 0 ? (
                <TableRow>
                  <TableCell colSpan={8}>
                    <Box sx={{ textAlign: 'center', py: 6 }}>
                      <LocalHospitalIcon sx={{ fontSize: 48, color: '#e2e8f0', mb: 1.5 }} />
                      <Typography variant="body1" color="text.secondary" sx={{ fontWeight: 600 }}>
                        {requests.length === 0 ? 'No ambulance requests yet.' : 'No results match your filter.'}
                      </Typography>
                      {requests.length === 0 && (
                        <Button
                          variant="contained"
                          color="primary"
                          sx={{ mt: 2 }}
                          onClick={() => navigate('/')}
                        >
                          Book First Ambulance
                        </Button>
                      )}
                    </Box>
                  </TableCell>
                </TableRow>
              ) : (
                filtered.map((req) => (
                  <TableRow
                    key={req.requestId}
                    hover
                    sx={{ cursor: 'pointer', '&:hover': { bgcolor: '#fafafa' }, '& .MuiTableCell-root': { py: 1.5 } }}
                    onClick={() => navigate(`/tracking/${req.requestId}`)}
                  >
                    {/* Request # */}
                    <TableCell>
                      <Box>
                        <Typography variant="body2" sx={{ fontWeight: 700, color: '#1e293b', fontFamily: 'monospace', fontSize: '0.8rem' }}>
                          {req.requestNumber}
                        </Typography>
                        <Typography variant="caption" sx={{ color: '#94a3b8', fontFamily: 'monospace', fontSize: '0.68rem' }}>
                          {req.requestId.slice(0, 8)}…
                        </Typography>
                      </Box>
                    </TableCell>

                    {/* Patient */}
                    <TableCell>
                      <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.2 }}>
                        <Avatar sx={{ width: 30, height: 30, fontSize: '0.75rem', fontWeight: 700, bgcolor: '#dbeafe', color: '#1d4ed8' }}>
                          {req.patientName?.charAt(0)?.toUpperCase()}
                        </Avatar>
                        <Box>
                          <Typography variant="body2" sx={{ fontWeight: 600, lineHeight: 1.2 }}>{req.patientName}</Typography>
                          <Typography variant="caption" color="text.secondary">{req.patientPhone}</Typography>
                        </Box>
                      </Box>
                    </TableCell>

                    {/* Status */}
                    <TableCell><StatusChip status={req.status} /></TableCell>

                    {/* Priority */}
                    <TableCell><PriorityBadge priority={req.priority} /></TableCell>

                    {/* Driver */}
                    <TableCell>
                      {req.driver ? (
                        <Box>
                          <Typography variant="body2" sx={{ fontWeight: 600 }}>{req.driver.name}</Typography>
                          <Typography variant="caption" color="text.secondary">{req.driver.vehicleNumber}</Typography>
                        </Box>
                      ) : (
                        <Typography variant="caption" color="text.secondary">—</Typography>
                      )}
                    </TableCell>

                    {/* ETA */}
                    <TableCell>
                      {req.etaSeconds != null ? (
                        <Typography variant="body2" sx={{ fontWeight: 600, color: '#1d4ed8' }}>
                          {req.etaSeconds <= 0 ? 'Arrived' : `${Math.ceil(req.etaSeconds / 60)} min`}
                        </Typography>
                      ) : (
                        <Typography variant="caption" color="text.secondary">—</Typography>
                      )}
                    </TableCell>

                    {/* Created */}
                    <TableCell>
                      <Typography variant="caption" sx={{ color: '#64748b', whiteSpace: 'nowrap' }}>
                        {formatDate(req.createdAt)}
                      </Typography>
                    </TableCell>

                    {/* Actions */}
                    <TableCell align="center" onClick={(e) => e.stopPropagation()}>
                      <Tooltip title="View Live Tracking">
                        <Button
                          size="small"
                          variant="outlined"
                          color="primary"
                          startIcon={<TrackChangesIcon fontSize="small" />}
                          onClick={() => navigate(`/tracking/${req.requestId}`)}
                          sx={{ whiteSpace: 'nowrap', fontSize: '0.75rem', borderColor: '#dc2626', color: '#dc2626', '&:hover': { bgcolor: '#fee2e2', borderColor: '#dc2626' } }}
                        >
                          Track
                        </Button>
                      </Tooltip>
                    </TableCell>
                  </TableRow>
                ))
              )}
            </TableBody>
          </Table>
        </TableContainer>
      </Card>

    </Container>
  );
}
