import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final user = SupabaseService().getCurrentUser();
      if (user != null) {
        final data = await SupabaseService().getNotifications(user.id);
        if (mounted) {
          setState(() {
            _notifications = data;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error loading notifications: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsRead(int index) async {
    final notification = _notifications[index];
    if (notification['is_read'] == true) return;
    try {
      await SupabaseService().markNotificationAsRead(notification['id']);
      if (mounted) {
        setState(() => _notifications[index]['is_read'] = true);
      }
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  Future<void> _deleteNotification(int index) async {
    final notification = _notifications[index];
    try {
      await SupabaseService().deleteNotification(notification['id']);
      if (mounted) {
        setState(() => _notifications.removeAt(index));
      }
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
  }

  IconData _iconFromType(String? type) {
    switch (type) {
      case 'promo':
        return Icons.local_offer;
      case 'report':
        return Icons.description;
      case 'system':
        return Icons.system_update;
      case 'transaction':
        return Icons.check_circle;
      case 'warning':
        return Icons.warning;
      default:
        return Icons.notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        elevation: 0,
        backgroundColor: const Color(0xFF8B2E6E),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _notifications.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_none,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Tidak ada notifikasi',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadNotifications,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _notifications.length,
                      itemBuilder: (context, index) {
                        final notification = _notifications[index];
                        final bool isRead = notification['is_read'] == true;
                        final String title =
                            notification['title'] ?? 'Notifikasi';
                        final String message =
                            notification['message'] ?? '';
                        final String time =
                            notification['created_at'] != null
                                ? _formatTime(notification['created_at'])
                                : '';
                        return GestureDetector(
                          onTap: () => _markAsRead(index),
                          child: Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: isRead ? 1 : 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            color: isRead
                                ? Colors.white
                                : const Color(0xFF8B2E6E)
                                    .withValues(alpha: 0.05),
                            child: ListTile(
                              leading: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF8B2E6E)
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  _iconFromType(notification['type']),
                                  color: const Color(0xFF8B2E6E),
                                ),
                              ),
                              title: Text(
                                title,
                                style: TextStyle(
                                  fontWeight: isRead
                                      ? FontWeight.w500
                                      : FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(message),
                                  const SizedBox(height: 4),
                                  Text(
                                    time,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: GestureDetector(
                                onTap: () => _deleteNotification(index),
                                child: Icon(
                                  Icons.close,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                              isThreeLine: true,
                              contentPadding: const EdgeInsets.all(12),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
      ),
    );
  }

  String _formatTime(String isoString) {
    try {
      final dt = DateTime.parse(isoString).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes} menit yang lalu';
      if (diff.inHours < 24) return '${diff.inHours} jam yang lalu';
      return '${diff.inDays} hari yang lalu';
    } catch (_) {
      return isoString;
    }
  }
}