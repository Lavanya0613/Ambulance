import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:ambulance_app/src/core/theme/app_theme.dart';
import '../driver_auth_provider.dart';

class DriverNotificationScreen extends StatefulWidget {
  const DriverNotificationScreen({super.key});

  @override
  State<DriverNotificationScreen> createState() => _DriverNotificationScreenState();
}

class _DriverNotificationScreenState extends State<DriverNotificationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DriverAuthProvider>().fetchNotifications();
    });
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'Just now';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      return DateFormat('MMM dd, hh:mm a').format(dt);
    } catch (e) {
      return dateStr;
    }
  }

  Widget _getNotificationIcon(String type) {
    switch (type) {
      case 'NEW_TRIP':
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.airport_shuttle, color: AppColors.primary, size: 24),
        );
      case 'TRIP_CANCELLED':
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.red.shade100,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.cancel, color: Colors.red, size: 24),
        );
      case 'ROUTE_CHANGED':
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.orange.shade100,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.alt_route, color: Colors.orange, size: 24),
        );
      case 'EMERGENCY_ALERT':
      default:
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.red.shade200,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 24),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final driverProv = context.watch<DriverAuthProvider>();
    final notifications = driverProv.notifications;
    final unreadCount = driverProv.unreadCount;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: Text(
          unreadCount > 0 ? 'Notifications ($unreadCount)' : 'Notifications',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.darkBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (unreadCount > 0)
            TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              icon: const Icon(Icons.done_all, size: 18),
              label: const Text('Mark all read', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              onPressed: () {
                driverProv.markAllNotificationsAsRead();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All notifications marked as read')),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => driverProv.fetchNotifications(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => driverProv.fetchNotifications(),
        child: notifications.isEmpty
            ? ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_none_outlined, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No notifications yet',
                          style: TextStyle(fontSize: 16, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notif = notifications[index];
                  final bool isRead = notif['read'] == true;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12.0),
                    decoration: BoxDecoration(
                      color: isRead ? Colors.white : const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isRead ? Colors.grey.shade200 : AppColors.primary.withOpacity(0.3),
                        width: isRead ? 1 : 1.5,
                      ),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: _getNotificationIcon(notif['type'] ?? 'NEW_TRIP'),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              notif['title'] ?? 'Notification',
                              style: TextStyle(
                                fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                                fontSize: 16,
                                color: AppColors.darkBlue,
                              ),
                            ),
                          ),
                          if (!isRead)
                            Container(
                              width: 10,
                              height: 10,
                              margin: const EdgeInsets.only(left: 6),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 6),
                          Text(
                            notif['message'] ?? '',
                            style: TextStyle(
                              color: isRead ? AppColors.textSecondary : AppColors.textPrimary,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _formatDate(notif['createdAt']),
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                      onTap: () {
                        if (!isRead) {
                          driverProv.markNotificationAsRead(notif['id']);
                        }
                        if (notif['requestId'] != null) {
                          Navigator.pushNamed(context, '/driver/navigation');
                        }
                      },
                    ),
                  );
                },
              ),
      ),
    );
  }
}
