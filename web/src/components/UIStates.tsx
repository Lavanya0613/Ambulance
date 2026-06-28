import { Box, Typography, Button, Skeleton, Card, CardContent } from '@mui/material';
import ErrorIcon from '@mui/icons-material/Error';
import InboxIcon from '@mui/icons-material/Inbox';

// ── Error State ────────────────────────────────────────────────────────
export function ErrorState({ message = "Something went wrong.", onRetry }: { message?: string, onRetry?: () => void }) {
  return (
    <Box sx={{ py: 8, px: 3, textAlign: 'center', bgcolor: 'background.paper', borderRadius: 4, border: '1px dashed', borderColor: 'divider' }}>
      <ErrorIcon sx={{ fontSize: 64, color: 'error.main', mb: 2, opacity: 0.8 }} />
      <Typography variant="h6" color="text.primary" gutterBottom>{message}</Typography>
      <Typography variant="body2" color="text.secondary" sx={{ mb: 4, maxWidth: 400, mx: 'auto' }}>
        We encountered an error while loading this data. Please check your connection or try again.
      </Typography>
      {onRetry && (
        <Button variant="outlined" color="primary" onClick={onRetry} sx={{ px: 4 }}>
          Retry Request
        </Button>
      )}
    </Box>
  );
}

// ── Empty State ────────────────────────────────────────────────────────
export function EmptyState({ title = "No Data Found", description = "There are currently no records to display." }: { title?: string, description?: string }) {
  return (
    <Box sx={{ py: 10, px: 3, textAlign: 'center', bgcolor: 'background.paper', borderRadius: 4, border: '1px dashed', borderColor: 'divider' }}>
      <InboxIcon sx={{ fontSize: 72, color: 'text.secondary', mb: 2, opacity: 0.3 }} />
      <Typography variant="h6" color="text.primary" gutterBottom>{title}</Typography>
      <Typography variant="body2" color="text.secondary">
        {description}
      </Typography>
    </Box>
  );
}

// ── Card Skeleton ──────────────────────────────────────────────────────
export function CardSkeleton({ height = 120 }: { height?: number }) {
  return (
    <Card sx={{ height: '100%' }}>
      <CardContent>
        <Skeleton variant="text" width="60%" height={32} sx={{ mb: 1 }} />
        <Skeleton variant="rectangular" width="100%" height={height} sx={{ borderRadius: 2 }} />
      </CardContent>
    </Card>
  );
}
