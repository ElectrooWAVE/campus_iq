import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../data/models/notification_model.dart';
import '../../../data/repositories/notification_repository.dart';
import '../../auth/providers/auth_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _repo = NotificationRepository();
  List<NotificationModel> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final profile = context.read<AuthProvider>().profile!;
    setState(() => _loading = true);
    try {
      _notifications = await _repo.getForUser(profile.id);
    } catch (e) {
      debugPrint('Notifications load error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markAllRead() async {
    final profile = context.read<AuthProvider>().profile!;
    await _repo.markAllRead(profile.id);
    setState(() {
      _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
    });
  }

  Future<void> _markRead(NotificationModel n) async {
    if (!n.isRead) {
      await _repo.markRead(n.id);
      final idx = _notifications.indexWhere((x) => x.id == n.id);
      if (idx != -1) {
        setState(() => _notifications[idx] = n.copyWith(isRead: true));
      }
    }
  }

  Future<void> _delete(String id) async {
    await _repo.delete(id);
    setState(() => _notifications.removeWhere((n) => n.id == id));
  }

  List<NotificationModel> _getGroup(String group) {
    final now = DateTime.now();
    return _notifications.where((n) {
      final diff = now.difference(n.createdAt);
      if (group == 'Today') return diff.inDays == 0;
      if (group == 'This Week') return diff.inDays > 0 && diff.inDays < 7;
      return diff.inDays >= 7;
    }).toList();
  }

  Color _borderColor(String? type) {
    switch (type) {
      case 'announcement': return AppColors.accent;
      case 'deadline': return AppColors.warning;
      case 'timetable': return AppColors.primary;
      default: return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications', style: AppTextStyles.h3),
        actions: [
          TextButton(
            onPressed: _markAllRead,
            child: Text('Mark all read', style: AppTextStyles.label.copyWith(color: AppColors.primary)),
          ),
        ],
      ),
      body: _loading
          ? const SkeletonListView(count: 5)
          : _notifications.isEmpty
              ? const EmptyState(
                  message: 'No notifications yet',
                  icon: LucideIcons.bell,
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      for (final group in ['Today', 'This Week', 'Earlier'])
                        ..._buildGroup(group),
                    ],
                  ),
                ),
    );
  }

  List<Widget> _buildGroup(String group) {
    final items = _getGroup(group);
    if (items.isEmpty) return [];
    return [
      Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 4),
        child: Text(group, style: AppTextStyles.label.copyWith(color: AppColors.textMuted)),
      ),
      ...items.map((n) => _NotificationRow(
        notification: n,
        borderColor: _borderColor(n.type),
        onTap: () => _markRead(n),
        onDelete: () => _delete(n.id),
      )),
    ];
  }
}

class _NotificationRow extends StatelessWidget {
  final NotificationModel notification;
  final Color borderColor;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _NotificationRow({
    required this.notification,
    required this.borderColor,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: AppColors.danger,
        child: const Icon(LucideIcons.trash2, color: Colors.white),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: AppCard(
          padding: EdgeInsets.zero,
          border: Border(left: BorderSide(color: borderColor, width: 4)),
          borderRadius: 12,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(notification.title, style: AppTextStyles.bodyMedium),
                      if (notification.body != null)
                        Text(
                          notification.body!,
                          style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 4),
                      Text(
                        AppDateUtils.formatRelative(notification.createdAt),
                        style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                if (!notification.isRead)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.danger,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
