import { useState } from 'react';
import { 
  Badge, IconButton, Popover, Box, Typography, 
  List, ListItem, ListItemIcon, ListItemText, 
  Button, Divider, Tooltip 
} from '@mui/material';
import NotificationsIcon from '@mui/icons-material/Notifications';
import DirectionsCarIcon from '@mui/icons-material/DirectionsCar';
import CancelIcon from '@mui/icons-material/Cancel';
import CheckCircleIcon from '@mui/icons-material/CheckCircle';
import ErrorIcon from '@mui/icons-material/Error';
import WarningAmberIcon from '@mui/icons-material/WarningAmber';
import LocalHospitalIcon from '@mui/icons-material/LocalHospital';
import { useNotifications } from '../context/NotificationContext';
import type { AppNotification } from '../context/NotificationContext';

function timeAgo(date: Date) {
  const seconds = Math.floor((new Date().getTime() - date.getTime()) / 1000);
  if (seconds < 60) return 'just now';
  const minutes = Math.floor(seconds / 60);
  if (minutes < 60) return `${minutes}m ago`;
  const hours = Math.floor(minutes / 60);
  if (hours < 24) return `${hours}h ago`;
  return `${Math.floor(hours / 24)}d ago`;
}

export default function NotificationCenter() {
  const { notifications, unreadCount, markAllAsRead, clearAll } = useNotifications();
  const [anchorEl, setAnchorEl] = useState<HTMLButtonElement | null>(null);

  const handleClick = (event: React.MouseEvent<HTMLButtonElement>) => {
    setAnchorEl(event.currentTarget);
  };

  const handleClose = () => {
    setAnchorEl(null);
  };

  const open = Boolean(anchorEl);
  const id = open ? 'notification-popover' : undefined;

  const getIconForType = (type: AppNotification['type']) => {
    switch (type) {
      case 'NEW_BOOKING': return <LocalHospitalIcon color="primary" />;
      case 'DRIVER_ASSIGNED': return <DirectionsCarIcon color="info" />;
      case 'COMPLETED': return <CheckCircleIcon color="success" />;
      case 'CANCELLATION': return <CancelIcon color="error" />;
      case 'QUEUE_FAILURE': return <ErrorIcon color="error" />;
      case 'SYSTEM_WARNING': return <WarningAmberIcon color="warning" />;
      default: return <NotificationsIcon />;
    }
  };

  return (
    <>
      <Tooltip title="Notifications">
        <IconButton onClick={handleClick} sx={{ color: '#fff', ml: 1 }}>
          <Badge badgeContent={unreadCount} color="error">
            <NotificationsIcon />
          </Badge>
        </IconButton>
      </Tooltip>

      <Popover
        id={id}
        open={open}
        anchorEl={anchorEl}
        onClose={handleClose}
        anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }}
        transformOrigin={{ vertical: 'top', horizontal: 'right' }}
        slotProps={{ paper: { sx: { width: 360, maxHeight: 500, borderRadius: 3, mt: 1.5, boxShadow: '0 12px 32px rgba(30, 58, 95, 0.15)' } } }}
      >
        <Box sx={{ p: 2, display: 'flex', justifyContent: 'space-between', alignItems: 'center', bgcolor: '#f8fafc', borderBottom: '1px solid #e2e8f0' }}>
          <Typography variant="subtitle1" sx={{ fontWeight: 800, color: '#1E3A5F' }}>
            Notifications
          </Typography>
          {unreadCount > 0 && (
            <Button size="small" onClick={markAllAsRead} sx={{ fontSize: '0.75rem', fontWeight: 700 }}>
              Mark all read
            </Button>
          )}
        </Box>
        
        {notifications.length === 0 ? (
          <Box sx={{ p: 4, textAlign: 'center' }}>
            <NotificationsIcon sx={{ fontSize: 48, color: '#cbd5e1', mb: 1 }} />
            <Typography variant="body2" color="text.secondary" sx={{ fontWeight: 600 }}>
              You're all caught up!
            </Typography>
          </Box>
        ) : (
          <List sx={{ p: 0 }}>
            {notifications.map((n) => (
              <ListItem 
                key={n.id} 
                sx={{ 
                  bgcolor: n.read ? 'transparent' : '#f0fdf4',
                  borderBottom: '1px solid #f1f5f9',
                  alignItems: 'flex-start',
                  py: 1.5
                }}
              >
                <ListItemIcon sx={{ minWidth: 40, mt: 0.5 }}>
                  {getIconForType(n.type)}
                </ListItemIcon>
                <ListItemText 
                  primary={n.title}
                  secondary={
                    <>
                      <Typography variant="caption" sx={{ display: 'block', color: '#475569', mt: 0.5, lineHeight: 1.3 }}>
                        {n.message}
                      </Typography>
                      <Typography variant="caption" sx={{ display: 'block', color: '#94a3b8', mt: 1, fontWeight: 600 }}>
                        {timeAgo(n.timestamp)}
                      </Typography>
                    </>
                  }
                  slotProps={{ primary: { style: { fontWeight: n.read ? 600 : 800, fontSize: '0.875rem', color: '#1E3A5F' } } }}
                />
              </ListItem>
            ))}
          </List>
        )}
        
        {notifications.length > 0 && (
          <>
            <Divider />
            <Box sx={{ p: 1, textAlign: 'center', bgcolor: '#f8fafc' }}>
              <Button size="small" color="error" onClick={clearAll} sx={{ fontSize: '0.75rem', fontWeight: 700 }}>
                Clear All
              </Button>
            </Box>
          </>
        )}
      </Popover>
    </>
  );
}
