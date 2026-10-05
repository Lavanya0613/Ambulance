import { useEffect, useMemo, useState, type Dispatch, type SetStateAction } from 'react';
import {
  Alert,
  Box,
  Button,
  Card,
  CardContent,
  Chip,
  Collapse,
  Container,
  Divider,
  FormControl,
  IconButton,
  InputAdornment,
  InputLabel,
  MenuItem,
  Paper,
  Select,
  Skeleton,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TablePagination,
  TableRow,
  TextField,
  Tooltip,
  Typography,
} from '@mui/material';
import type { SelectChangeEvent } from '@mui/material/Select';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import axios from 'axios';
import { io, type Socket } from 'socket.io-client';
import SearchIcon from '@mui/icons-material/Search';
import FilterAltOutlinedIcon from '@mui/icons-material/FilterAltOutlined';
import DownloadIcon from '@mui/icons-material/Download';
import TableChartIcon from '@mui/icons-material/TableChart';
import PictureAsPdfIcon from '@mui/icons-material/PictureAsPdf';
import KeyboardArrowDownIcon from '@mui/icons-material/KeyboardArrowDown';
import KeyboardArrowUpIcon from '@mui/icons-material/KeyboardArrowUp';
import ScheduleIcon from '@mui/icons-material/Schedule';
import { ErrorState, EmptyState } from '../components/UIStates';

const API_BASE_URL = 'http://localhost:3000';

type AuditResultFilter = '' | 'success' | 'failure' | 'warning' | 'info';

interface AuditLog {
  id: string;
  timestamp: string;
  action: string;
  bookingId?: string;
  description?: string;
  performedBy?: string;
  performedByRole?: string;
  performedById?: string;
  patientName?: string;
  vendorId?: string;
  vendorName?: string;
  driverId?: string;
  driverName?: string;
  vehicleNumber?: string;
  previousStatus?: string;
  newStatus?: string;
  requestSource?: string;
  apiEndpoint?: string;
  success?: boolean;
  errorMessage?: string;
  metadata?: Record<string, any>;
}

function formatDateTime(value: string) {
  const date = new Date(value);
  return {
    date: date.toLocaleDateString(),
    time: date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', second: '2-digit' }),
  };
}

function escapeCsv(value: unknown) {
  const text = value == null ? '' : String(value);
  if (/[",\n]/.test(text)) {
    return `"${text.replace(/"/g, '""')}"`;
  }
  return text;
}

function stringifyMetadata(metadata?: Record<string, any>) {
  if (!metadata) return '-';
  try {
    return JSON.stringify(metadata, null, 2);
  } catch {
    return '-';
  }
}

export default function AdminAuditLogsPage() {
  const queryClient = useQueryClient();
  const [socket, setSocket] = useState<Socket | null>(null);
  const [page, setPage] = useState(0);
  const [rowsPerPage, setRowsPerPage] = useState(20);
  const [expandedRowId, setExpandedRowId] = useState<string | null>(null);
  const [selectedBookingId, setSelectedBookingId] = useState('');
  const [filters, setFilters] = useState({
    action: '',
    bookingId: '',
    patientName: '',
    vendorName: '',
    driverName: '',
    vehicleNumber: '',
    status: '',
    date: '',
    result: '' as AuditResultFilter,
  });
  const [draftFilters, setDraftFilters] = useState(filters);

  useEffect(() => {
    const token = localStorage.getItem('access_token');
    if (!token) return;

    const newSocket: Socket = io(`${API_BASE_URL}/ws`, {
      transports: ['websocket'],
      auth: { token },
      forceNew: true,
    });

    newSocket.on('audit_event', (event) => {
      queryClient.invalidateQueries({ queryKey: ['admin-audit-logs'] });
      if (selectedBookingId) {
        queryClient.invalidateQueries({ queryKey: ['admin-audit-timeline', selectedBookingId] });
      }
      if (event?.bookingId && selectedBookingId === event.bookingId) {
        queryClient.invalidateQueries({ queryKey: ['admin-audit-timeline', selectedBookingId] });
      }
    });

    setSocket(newSocket);
    return () => {
      newSocket.disconnect();
      setSocket(null);
    };
  }, [queryClient, selectedBookingId]);

  const auditQuery = useQuery({
    queryKey: ['admin-audit-logs', page, rowsPerPage, filters],
    queryFn: async () => {
      const params = new URLSearchParams({
        page: String(page + 1),
        limit: String(rowsPerPage),
        sortOrder: 'DESC',
      });

      if (filters.action) params.append('action', filters.action);
      if (filters.bookingId) params.append('bookingId', filters.bookingId);
      if (filters.patientName) params.append('patientName', filters.patientName);
      if (filters.vendorName) params.append('vendorName', filters.vendorName);
      if (filters.driverName) params.append('driverName', filters.driverName);
      if (filters.vehicleNumber) params.append('vehicleNumber', filters.vehicleNumber);
      if (filters.status) params.append('status', filters.status);
      if (filters.date) params.append('date', filters.date);
      if (filters.result) params.append('result', filters.result);

      const response = await axios.get(`/admin/audit-logs?${params.toString()}`);
      return response.data;
    },
    refetchInterval: 30000,
  });

  const timelineBookingId = selectedBookingId || filters.bookingId;
  const timelineQuery = useQuery({
    queryKey: ['admin-audit-timeline', timelineBookingId],
    queryFn: async () => {
      const params = new URLSearchParams({
        page: '1',
        limit: '200',
        sortOrder: 'ASC',
      });
      if (timelineBookingId) params.append('bookingId', timelineBookingId);
      const response = await axios.get(`/admin/audit-logs?${params.toString()}`);
      return response.data;
    },
    enabled: Boolean(timelineBookingId),
    refetchInterval: 30000,
  });

  const logs: AuditLog[] = useMemo(() => auditQuery.data?.data || [], [auditQuery.data]);
  const timelineLogs: AuditLog[] = useMemo(() => timelineQuery.data?.data || [], [timelineQuery.data]);

  const handleApplyFilters = () => {
    setPage(0);
    setFilters(draftFilters);
    if (draftFilters.bookingId) {
      setSelectedBookingId(draftFilters.bookingId);
    }
  };

  const handleClearFilters = () => {
    const cleared = {
      action: '',
      bookingId: '',
      patientName: '',
      vendorName: '',
      driverName: '',
      vehicleNumber: '',
      status: '',
      date: '',
      result: '' as AuditResultFilter,
    };
    setDraftFilters(cleared);
    setFilters(cleared);
    setSelectedBookingId('');
    setExpandedRowId(null);
    setPage(0);
  };

  const exportRows = logs;

  const exportCsv = () => {
    const headers = [
      'Time', 'Action', 'Booking ID', 'Patient', 'Vendor', 'Driver', 'Vehicle', 'Performed By', 'Status', 'Result', 'Source', 'Endpoint', 'Description', 'Error Message',
    ];
    const lines = [
      headers.join(','),
      ...exportRows.map((log) => {
        const result = log.success === false ? 'Error' : log.previousStatus && log.newStatus && log.previousStatus !== log.newStatus ? 'Warning' : 'Success';
        const status = log.newStatus || log.previousStatus || '-';
        return [
          escapeCsv(new Date(log.timestamp).toISOString()),
          escapeCsv(log.action),
          escapeCsv(log.bookingId || '-'),
          escapeCsv(log.patientName || '-'),
          escapeCsv(log.vendorName || log.vendorId || '-'),
          escapeCsv(log.driverName || log.driverId || '-'),
          escapeCsv(log.vehicleNumber || '-'),
          escapeCsv(log.performedBy || log.performedByRole || '-'),
          escapeCsv(status),
          escapeCsv(result),
          escapeCsv(log.requestSource || '-'),
          escapeCsv(log.apiEndpoint || '-'),
          escapeCsv(log.description || '-'),
          escapeCsv(log.errorMessage || '-'),
        ].join(',');
      }),
    ];

    const blob = new Blob([lines.join('\n')], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const anchor = document.createElement('a');
    anchor.href = url;
    anchor.download = `audit-logs-${new Date().toISOString().slice(0, 10)}.csv`;
    anchor.click();
    URL.revokeObjectURL(url);
  };

  const exportExcel = async () => {
    const XLSX = await import('xlsx');
    const sheet = XLSX.utils.json_to_sheet(
      exportRows.map((log) => ({
        Time: new Date(log.timestamp).toISOString(),
        Action: log.action,
        BookingID: log.bookingId || '',
        Patient: log.patientName || '',
        Vendor: log.vendorName || log.vendorId || '',
        Driver: log.driverName || log.driverId || '',
        Vehicle: log.vehicleNumber || '',
        PerformedBy: log.performedBy || log.performedByRole || '',
        Status: log.newStatus || log.previousStatus || '',
        Result: log.success === false ? 'Error' : log.previousStatus && log.newStatus && log.previousStatus !== log.newStatus ? 'Warning' : 'Success',
        Source: log.requestSource || '',
        Endpoint: log.apiEndpoint || '',
        Description: log.description || '',
        ErrorMessage: log.errorMessage || '',
      })),
    );
    const workbook = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(workbook, sheet, 'Audit Logs');
    XLSX.writeFile(workbook, `audit-logs-${new Date().toISOString().slice(0, 10)}.xlsx`);
  };

  const exportPdf = async () => {
    const { jsPDF } = await import('jspdf');
    const autoTableModule = await import('jspdf-autotable');
    const autoTable = autoTableModule.default ?? autoTableModule;

    const doc = new jsPDF({ orientation: 'landscape' });
    doc.setFontSize(16);
    doc.text('Audit Logs', 14, 16);
    doc.setFontSize(10);
    doc.text(`Generated: ${new Date().toLocaleString()}`, 14, 23);

    autoTable(doc, {
      startY: 28,
      head: [['Time', 'Action', 'Booking ID', 'Patient', 'Vendor', 'Driver', 'Vehicle', 'Performed By', 'Status', 'Result']],
      body: exportRows.map((log) => {
        const result = log.success === false ? 'Error' : log.previousStatus && log.newStatus && log.previousStatus !== log.newStatus ? 'Warning' : 'Success';
        return [
          new Date(log.timestamp).toLocaleString(),
          log.action,
          log.bookingId || '-',
          log.patientName || '-',
          log.vendorName || log.vendorId || '-',
          log.driverName || log.driverId || '-',
          log.vehicleNumber || '-',
          log.performedBy || log.performedByRole || '-',
          log.newStatus || log.previousStatus || '-',
          result,
        ];
      }),
      styles: { fontSize: 8, cellPadding: 2 },
      headStyles: { fillColor: [30, 58, 95] },
    });

    doc.save(`audit-logs-${new Date().toISOString().slice(0, 10)}.pdf`);
  };

  const getResultTone = (log: AuditLog) => {
    if (log.success === false) return 'error';
    if (log.errorMessage) return 'error';
    if (log.previousStatus && log.newStatus && log.previousStatus !== log.newStatus) return 'warning';
    return 'success';
  };

  const getResultLabel = (log: AuditLog) => {
    if (log.success === false || log.errorMessage) return 'Error';
    if (log.previousStatus && log.newStatus && log.previousStatus !== log.newStatus) return 'Warning';
    return 'Success';
  };

  const filterSummary = [
    filters.action,
    filters.bookingId,
    filters.patientName,
    filters.vendorName,
    filters.driverName,
    filters.vehicleNumber,
    filters.status,
    filters.date,
    filters.result,
  ].filter(Boolean).length;

  return (
    <Container maxWidth="xl" sx={{ py: 3 }}>
      <Box
        sx={{
          mb: 3,
          p: 3,
          borderRadius: 4,
          color: 'white',
          background: 'linear-gradient(135deg, #1E3A5F 0%, #0f2746 100%)',
          boxShadow: '0 18px 40px rgba(30,58,95,0.18)',
        }}
      >
        <Box sx={{ display: 'flex', flexDirection: { xs: 'column', md: 'row' }, gap: 2, alignItems: { md: 'center' }, justifyContent: 'space-between' }}>
          <Box>
            <Typography variant="h4" sx={{ fontWeight: 900, letterSpacing: -0.4 }}>
              Enterprise Audit Console
            </Typography>
            <Typography sx={{ mt: 1, color: 'rgba(255,255,255,0.8)', maxWidth: 780 }}>
              Complete operational visibility for ambulance requests, vendor actions, queue processing, and security-sensitive events.
            </Typography>
          </Box>
          <Box sx={{ display: 'flex', gap: 1, flexWrap: 'wrap', justifyContent: 'flex-end' }}>
            <Chip label={`${auditQuery.data?.meta?.total || 0} events`} sx={{ bgcolor: 'rgba(255,255,255,0.12)', color: 'white', fontWeight: 700 }} />
            <Chip label={filters.bookingId ? `Booking ${filters.bookingId}` : 'All bookings'} sx={{ bgcolor: 'rgba(255,255,255,0.12)', color: 'white', fontWeight: 700 }} />
            <Chip label={socket?.connected ? 'Live' : 'Offline'} color={socket?.connected ? 'success' : 'warning'} sx={{ fontWeight: 700 }} />
          </Box>
        </Box>
      </Box>

      <Card sx={{ mb: 3 }}>
        <CardContent>
          <Box sx={{ display: 'flex', flexDirection: { xs: 'column', lg: 'row' }, gap: 2, alignItems: { lg: 'center' }, justifyContent: 'space-between' }}>
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
              <FilterAltOutlinedIcon color="primary" />
              <Typography variant="h6" sx={{ fontWeight: 800 }}>
                Search and filters
              </Typography>
              {filterSummary > 0 && <Chip label={`${filterSummary} active`} size="small" color="primary" />}
            </Box>
            <Box sx={{ display: 'flex', gap: 1, flexWrap: 'wrap' }}>
              <Tooltip title="Export CSV">
                <Button startIcon={<DownloadIcon />} variant="outlined" onClick={exportCsv} disabled={!exportRows.length}>
                  CSV
                </Button>
              </Tooltip>
              <Tooltip title="Export Excel">
                <Button startIcon={<TableChartIcon />} variant="outlined" onClick={exportExcel} disabled={!exportRows.length}>
                  Excel
                </Button>
              </Tooltip>
              <Tooltip title="Export PDF">
                <Button startIcon={<PictureAsPdfIcon />} variant="outlined" onClick={exportPdf} disabled={!exportRows.length}>
                  PDF
                </Button>
              </Tooltip>
              <Button variant="text" onClick={handleClearFilters} disabled={filterSummary === 0}>
                Clear filters
              </Button>
            </Box>
          </Box>

          <GridLikeFilters
            draftFilters={draftFilters}
            setDraftFilters={setDraftFilters}
            onApply={handleApplyFilters}
          />
        </CardContent>
      </Card>

      <Card sx={{ mb: 3 }}>
        {auditQuery.isLoading ? (
          <TableContainer component={Paper} elevation={0}>
            <Table sx={{ minWidth: 1200 }}>
              <TableHead>
                <TableRow>
                  {['Time', 'Action', 'Booking ID', 'Patient', 'Vendor', 'Driver', 'Vehicle', 'Performed By', 'Status', 'Result'].map((h) => (
                    <TableCell key={h} sx={{ fontWeight: 800 }}>
                      {h}
                    </TableCell>
                  ))}
                </TableRow>
              </TableHead>
              <TableBody>
                {[...Array(8)].map((_, rowIndex) => (
                  <TableRow key={rowIndex}>
                    {[...Array(10)].map((__, cellIndex) => (
                      <TableCell key={cellIndex}><Skeleton animation="wave" height={28} /></TableCell>
                    ))}
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </TableContainer>
        ) : auditQuery.isError ? (
          <Box sx={{ p: 3 }}>
            <ErrorState message="Failed to load audit logs." onRetry={() => auditQuery.refetch()} />
          </Box>
        ) : logs.length === 0 ? (
          <Box sx={{ p: 3 }}>
            <EmptyState title="No audit logs found" description="Adjust filters or wait for new activity." />
          </Box>
        ) : (
          <>
            <TableContainer component={Paper} elevation={0} sx={{ overflowX: 'auto' }}>
              <Table sx={{ minWidth: 1200 }}>
                <TableHead>
                  <TableRow>
                    <TableCell sx={{ fontWeight: 800, width: 60 }} />
                    <TableCell sx={{ fontWeight: 800 }}>Time</TableCell>
                    <TableCell sx={{ fontWeight: 800 }}>Action</TableCell>
                    <TableCell sx={{ fontWeight: 800 }}>Booking ID</TableCell>
                    <TableCell sx={{ fontWeight: 800 }}>Patient</TableCell>
                    <TableCell sx={{ fontWeight: 800 }}>Vendor</TableCell>
                    <TableCell sx={{ fontWeight: 800 }}>Driver</TableCell>
                    <TableCell sx={{ fontWeight: 800 }}>Vehicle</TableCell>
                    <TableCell sx={{ fontWeight: 800 }}>Performed By</TableCell>
                    <TableCell sx={{ fontWeight: 800 }}>Status</TableCell>
                    <TableCell sx={{ fontWeight: 800 }}>Result</TableCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  {logs.map((log) => {
                    const isExpanded = expandedRowId === log.id;
                    const dateTime = formatDateTime(log.timestamp);
                    return (
                      <>
                        <TableRow hover key={log.id} sx={{ cursor: 'pointer' }} onClick={() => { setExpandedRowId(isExpanded ? null : log.id); if (log.bookingId) setSelectedBookingId(log.bookingId); }}>
                          <TableCell>
                            <IconButton size="small">
                              {isExpanded ? <KeyboardArrowUpIcon /> : <KeyboardArrowDownIcon />}
                            </IconButton>
                          </TableCell>
                          <TableCell>
                            <Box>
                              <Typography variant="body2" sx={{ fontWeight: 700 }}>
                                {dateTime.date}
                              </Typography>
                              <Typography variant="caption" color="text.secondary">
                                {dateTime.time}
                              </Typography>
                            </Box>
                          </TableCell>
                          <TableCell>
                            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                              <Chip label={log.action} size="small" color="primary" sx={{ fontWeight: 800 }} />
                              {log.requestSource && <Chip label={log.requestSource} size="small" variant="outlined" />}
                            </Box>
                          </TableCell>
                          <TableCell>{log.bookingId || '-'}</TableCell>
                          <TableCell>{log.patientName || '-'}</TableCell>
                          <TableCell>{log.vendorName || log.vendorId || '-'}</TableCell>
                          <TableCell>{log.driverName || log.driverId || '-'}</TableCell>
                          <TableCell>{log.vehicleNumber || '-'}</TableCell>
                          <TableCell>{log.performedBy || log.performedByRole || '-'}</TableCell>
                          <TableCell>
                            <Chip
                              label={log.newStatus || log.previousStatus || '-'}
                              size="small"
                              color={log.success === false ? 'error' : 'info'}
                              variant="outlined"
                              sx={{ fontWeight: 700 }}
                            />
                          </TableCell>
                          <TableCell>
                            <Chip
                              label={getResultLabel(log)}
                              size="small"
                              color={getResultTone(log)}
                              sx={{ fontWeight: 800 }}
                            />
                          </TableCell>
                        </TableRow>
                        <TableRow key={`${log.id}-details`}>
                          <TableCell colSpan={11} sx={{ py: 0, borderBottom: isExpanded ? '1px solid' : 'none', borderColor: 'divider' }}>
                            <Collapse in={isExpanded} timeout="auto" unmountOnExit>
                              <Box sx={{ py: 2, px: 1.5, bgcolor: 'grey.50' }}>
                                <Box sx={{ display: 'flex', flexDirection: { xs: 'column', lg: 'row' }, gap: 3 }}>
                                  <Box sx={{ flex: 2 }}>
                                    <Typography variant="subtitle1" sx={{ fontWeight: 800, mb: 1 }}>
                                      Event details
                                    </Typography>
                                    <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1 }}>
                                      <DetailLine label="Description" value={log.description || '-'} />
                                      <DetailLine label="Previous Status" value={log.previousStatus || '-'} />
                                      <DetailLine label="New Status" value={log.newStatus || '-'} />
                                      <DetailLine label="Request Source" value={log.requestSource || '-'} />
                                      <DetailLine label="API Endpoint" value={log.apiEndpoint || '-'} />
                                      <DetailLine label="Error Message" value={log.errorMessage || '-'} error={Boolean(log.errorMessage)} />
                                    </Box>
                                  </Box>
                                  <Box sx={{ flex: 1 }}>
                                    <Typography variant="subtitle1" sx={{ fontWeight: 800, mb: 1 }}>
                                      Related context
                                    </Typography>
                                    <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1 }}>
                                      <DetailLine label="Performed By" value={`${log.performedBy || log.performedByRole || '-'}${log.performedById ? ` (${log.performedById})` : ''}`} />
                                      <DetailLine label="Patient" value={log.patientName || '-'} />
                                      <DetailLine label="Vendor" value={log.vendorName || log.vendorId || '-'} />
                                      <DetailLine label="Driver" value={log.driverName || log.driverId || '-'} />
                                      <DetailLine label="Vehicle" value={log.vehicleNumber || '-'} />
                                      <DetailLine label="Metadata" value={stringifyMetadata(log.metadata)} mono />
                                    </Box>
                                  </Box>
                                </Box>
                              </Box>
                            </Collapse>
                          </TableCell>
                        </TableRow>
                      </>
                    );
                  })}
                </TableBody>
              </Table>
            </TableContainer>
            <Divider />
            <TablePagination
              component="div"
              rowsPerPageOptions={[10, 20, 50, 100]}
              count={auditQuery.data?.meta?.total || 0}
              rowsPerPage={rowsPerPage}
              page={page}
              onPageChange={(_, nextPage) => setPage(nextPage)}
              onRowsPerPageChange={(event) => {
                setRowsPerPage(Number(event.target.value));
                setPage(0);
              }}
            />
          </>
        )}
      </Card>

      <Card sx={{ mb: 4 }}>
        <CardContent>
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5, mb: 2 }}>
            <ScheduleIcon color="primary" />
            <Box>
              <Typography variant="h6" sx={{ fontWeight: 800 }}>
                Booking Timeline
              </Typography>
              <Typography variant="body2" color="text.secondary">
                Chronological event stream for the selected booking.
              </Typography>
            </Box>
          </Box>

          {!timelineBookingId ? (
            <Alert severity="info">Select a row or enter a Booking ID filter to load the timeline.</Alert>
          ) : timelineQuery.isLoading ? (
            <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1 }}>
              {[...Array(6)].map((_, index) => (
                <Skeleton key={index} height={58} />
              ))}
            </Box>
          ) : timelineLogs.length === 0 ? (
            <EmptyState title="No timeline events" description="This booking has no audit trail yet." />
          ) : (
            <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
              {timelineLogs.map((log, index) => (
                <Box key={log.id} sx={{ display: 'flex', gap: 2, alignItems: 'stretch' }}>
                  <Box sx={{ width: 90, pt: 0.5 }}>
                    <Typography variant="subtitle2" sx={{ fontWeight: 800 }}>
                      {new Date(log.timestamp).toLocaleDateString()}
                    </Typography>
                    <Typography variant="caption" color="text.secondary">
                      {new Date(log.timestamp).toLocaleTimeString()}
                    </Typography>
                  </Box>
                  <Box sx={{ display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
                    <Box sx={{ width: 14, height: 14, borderRadius: '50%', bgcolor: getResultTone(log) === 'error' ? 'error.main' : getResultTone(log) === 'warning' ? 'warning.main' : 'success.main', mt: 1 }} />
                    {index < timelineLogs.length - 1 && <Box sx={{ width: 2, flex: 1, bgcolor: 'divider', mt: 0.5 }} />}
                  </Box>
                  <Card variant="outlined" sx={{ flex: 1, bgcolor: 'grey.50' }}>
                    <CardContent>
                      <Box sx={{ display: 'flex', flexDirection: { xs: 'column', md: 'row' }, gap: 2, justifyContent: 'space-between' }}>
                        <Box>
                          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 1, flexWrap: 'wrap' }}>
                            <Chip label={log.action} size="small" color="primary" sx={{ fontWeight: 800 }} />
                            <Chip label={getResultLabel(log)} size="small" color={getResultTone(log)} sx={{ fontWeight: 800 }} />
                          </Box>
                          <Typography variant="body2" sx={{ fontWeight: 600 }}>
                            {log.description || 'No description provided.'}
                          </Typography>
                          <Typography variant="caption" color="text.secondary">
                            {log.performedBy || log.performedByRole || 'System'} · {log.requestSource || 'SYSTEM'} · {log.apiEndpoint || '-'}
                          </Typography>
                        </Box>
                        <Box sx={{ textAlign: { xs: 'left', md: 'right' } }}>
                          <Typography variant="body2" sx={{ fontWeight: 700 }}>
                            {log.newStatus || log.previousStatus || '-'}
                          </Typography>
                          <Typography variant="caption" color="text.secondary">
                            Booking {log.bookingId || '-'}
                          </Typography>
                        </Box>
                      </Box>
                    </CardContent>
                  </Card>
                </Box>
              ))}
            </Box>
          )}
        </CardContent>
      </Card>
    </Container>
  );
}

function GridLikeFilters({
  draftFilters,
  setDraftFilters,
  onApply,
}: {
  draftFilters: {
    action: string;
    bookingId: string;
    patientName: string;
    vendorName: string;
    driverName: string;
    vehicleNumber: string;
    status: string;
    date: string;
    result: AuditResultFilter;
  };
  setDraftFilters: Dispatch<SetStateAction<{
    action: string;
    bookingId: string;
    patientName: string;
    vendorName: string;
    driverName: string;
    vehicleNumber: string;
    status: string;
    date: string;
    result: AuditResultFilter;
  }>>;
  onApply: () => void;
}) {
  return (
    <Box sx={{ mt: 3 }}>
      <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
        <Box sx={{ display: 'flex', flexDirection: { xs: 'column', md: 'row' }, gap: 2 }}>
          <TextField
            fullWidth
            label="Action"
            placeholder="Driver Assigned"
            value={draftFilters.action}
            onChange={(event) => setDraftFilters((prev) => ({ ...prev, action: event.target.value }))}
            slotProps={{
              input: {
                startAdornment: <InputAdornment position="start"><SearchIcon /></InputAdornment>,
              },
            }}
          />
          <TextField
            fullWidth
            label="Booking ID"
            placeholder="AR-..."
            value={draftFilters.bookingId}
            onChange={(event) => setDraftFilters((prev) => ({ ...prev, bookingId: event.target.value }))}
          />
          <TextField
            fullWidth
            label="Date"
            type="date"
            value={draftFilters.date}
            onChange={(event) => setDraftFilters((prev) => ({ ...prev, date: event.target.value }))}
            slotProps={{ inputLabel: { shrink: true } }}
          />
        </Box>

        <Box sx={{ display: 'flex', flexDirection: { xs: 'column', md: 'row' }, gap: 2 }}>
          <TextField
            fullWidth
            label="Patient"
            value={draftFilters.patientName}
            onChange={(event) => setDraftFilters((prev) => ({ ...prev, patientName: event.target.value }))}
          />
          <TextField
            fullWidth
            label="Vendor"
            value={draftFilters.vendorName}
            onChange={(event) => setDraftFilters((prev) => ({ ...prev, vendorName: event.target.value }))}
          />
          <TextField
            fullWidth
            label="Driver"
            value={draftFilters.driverName}
            onChange={(event) => setDraftFilters((prev) => ({ ...prev, driverName: event.target.value }))}
          />
          <TextField
            fullWidth
            label="Vehicle"
            value={draftFilters.vehicleNumber}
            onChange={(event) => setDraftFilters((prev) => ({ ...prev, vehicleNumber: event.target.value }))}
          />
        </Box>

        <Box sx={{ display: 'flex', flexDirection: { xs: 'column', md: 'row' }, gap: 2 }}>
          <TextField
            fullWidth
            label="Status"
            placeholder="COMPLETED"
            value={draftFilters.status}
            onChange={(event) => setDraftFilters((prev) => ({ ...prev, status: event.target.value }))}
          />
          <FormControl fullWidth>
            <InputLabel>Result</InputLabel>
            <Select
              label="Result"
              value={draftFilters.result}
              onChange={(event: SelectChangeEvent) => setDraftFilters((prev) => ({ ...prev, result: event.target.value as AuditResultFilter }))}
            >
              <MenuItem value="">All</MenuItem>
              <MenuItem value="success">Success</MenuItem>
              <MenuItem value="warning">Warning</MenuItem>
              <MenuItem value="failure">Failure</MenuItem>
              <MenuItem value="info">Info</MenuItem>
            </Select>
          </FormControl>
          <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'flex-end', minWidth: { md: 220 } }}>
            <Button fullWidth variant="contained" onClick={onApply} sx={{ height: 56, fontWeight: 800 }}>
              Apply filters
            </Button>
          </Box>
        </Box>
      </Box>
    </Box>
  );
}

function DetailLine({
  label,
  value,
  error = false,
  mono = false,
}: {
  label: string;
  value: string;
  error?: boolean;
  mono?: boolean;
}) {
  return (
    <Box sx={{ display: 'flex', gap: 1.5, alignItems: 'flex-start' }}>
      <Typography variant="caption" sx={{ minWidth: 130, fontWeight: 800, color: 'text.secondary', textTransform: 'uppercase', letterSpacing: 0.8 }}>
        {label}
      </Typography>
      <Typography
        variant="body2"
        sx={{
          fontFamily: mono ? 'monospace' : 'inherit',
          whiteSpace: 'pre-wrap',
          color: error ? 'error.main' : 'text.primary',
          fontWeight: error ? 700 : 500,
          wordBreak: 'break-word',
        }}
      >
        {value}
      </Typography>
    </Box>
  );
}
