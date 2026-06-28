import { createContext, useContext, useEffect, useState } from 'react';
import type { ReactNode } from 'react';
import { io, Socket } from 'socket.io-client';

export interface AppNotification {
  id: string;
  type: 'NEW_BOOKING' | 'DRIVER_ASSIGNED' | 'CANCELLATION' | 'COMPLETED' | 'QUEUE_FAILURE' | 'SYSTEM_WARNING';
  title: string;
  message: string;
  timestamp: Date;
  read: boolean;
}

interface NotificationContextType {
  notifications: AppNotification[];
  unreadCount: number;
  markAllAsRead: () => void;
  clearAll: () => void;
}

const NotificationContext = createContext<NotificationContextType | undefined>(undefined);

const API_BASE_URL = 'http://localhost:3000';

export const NotificationProvider = ({ children }: { children: ReactNode }) => {
  const [notifications, setNotifications] = useState<AppNotification[]>(() => {
    const saved = localStorage.getItem('app_notifications');
    if (saved) {
      try {
        const parsed = JSON.parse(saved);
        return parsed.map((n: any) => ({ ...n, timestamp: new Date(n.timestamp) }));
      } catch (e) {
        return [];
      }
    }
    return [];
  });

  useEffect(() => {
    localStorage.setItem('app_notifications', JSON.stringify(notifications));
  }, [notifications]);

  useEffect(() => {
    const token = localStorage.getItem('access_token');
    if (!token) return;

    const socket: Socket = io(`${API_BASE_URL}/ws`, {
      transports: ['websocket'],
      auth: { token },
      forceNew: true
    });

    const addNotification = (n: Omit<AppNotification, 'id' | 'timestamp' | 'read'>) => {
      setNotifications(prev => [
        {
          ...n,
          id: Math.random().toString(36).substring(7),
          timestamp: new Date(),
          read: false
        },
        ...prev
      ]);
    };

    socket.on('request_created', (data) => {
      addNotification({
        type: 'NEW_BOOKING',
        title: 'New Booking Request',
        message: `Request #${data.requestNumber} needs a driver.`,
      });
    });

    socket.on('driver_assigned', (data) => {
      addNotification({
        type: 'DRIVER_ASSIGNED',
        title: 'Driver Assigned',
        message: `Vendor ${data.vendorId || 'Assigned'} is en route for request #${data.requestNumber || data.requestId}.`,
      });
    });

    socket.on('request_completed', (data) => {
      addNotification({
        type: 'COMPLETED',
        title: 'Booking Completed',
        message: `Request #${data.requestNumber || data.requestId} successfully completed.`,
      });
    });

    socket.on('request_updated', (data) => {
      if (data.status === 'CANCELLED' || data.status === 'FAILED') {
        addNotification({
          type: 'CANCELLATION',
          title: 'Booking Cancelled',
          message: `Request #${data.requestNumber || data.requestId} was cancelled.`,
        });
      }
    });

    socket.on('queue_failure', (data) => {
      addNotification({
        type: 'QUEUE_FAILURE',
        title: 'Queue Failure',
        message: `Job ${data.jobId} in ${data.queueName} failed. Added to DLQ.`,
      });
    });

    socket.on('system_warning', (data) => {
      addNotification({
        type: 'SYSTEM_WARNING',
        title: 'System Warning',
        message: data.message,
      });
    });

    return () => {
      socket.disconnect();
    };
  }, []);

  const markAllAsRead = () => {
    setNotifications(prev => prev.map(n => ({ ...n, read: true })));
  };

  const clearAll = () => {
    setNotifications([]);
  };

  const unreadCount = notifications.filter(n => !n.read).length;

  return (
    <NotificationContext.Provider value={{ notifications, unreadCount, markAllAsRead, clearAll }}>
      {children}
    </NotificationContext.Provider>
  );
};

export const useNotifications = () => {
  const context = useContext(NotificationContext);
  if (context === undefined) {
    throw new Error('useNotifications must be used within a NotificationProvider');
  }
  return context;
};
