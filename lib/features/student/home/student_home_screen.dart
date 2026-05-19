import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/image_viewer.dart';
import '../../../core/widgets/notification_banner.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../data/models/announcement_model.dart';
import '../../../data/models/deadline_model.dart';
import '../../../data/models/timetable_model.dart';
import '../../../data/repositories/announcement_repository.dart';
import '../../../data/repositories/deadline_repository.dart';
import '../../../data/repositories/notification_repository.dart';
import '../../../data/repositories/timetable_repository.dart';
import '../../../data/services/realtime_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../widgets/student_bottom_nav.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen>
    with WidgetsBindingObserver {
  final _timetableRepo = TimetableRepository();
  final _deadlineRepo = DeadlineRepository();
  final _announcementRepo = AnnouncementRepository();
  final _notifRepo = NotificationRepository();
  final _realtime = RealtimeService();

  TimetableModel? _latestTimetable;
  List<DeadlineModel> _deadlines = [];
  AnnouncementModel? _latestAnnouncement;
  int _unreadCount = 0;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }

  Future<void> _load() async {
    if (!mounted) return;

    final auth = context.read<AuthProvider>();
    final profile = auth.profile;
    if (profile == null) return; // Guard: don't proceed without a profile

    if (mounted) setState(() { _loading = true; _error = null; });

    final branch = profile.branch;
    final year = profile.year ?? 1;

    // Fetch each independently — one failure won't block the others
    TimetableModel? timetable;
    List<DeadlineModel> deadlines = [];
    AnnouncementModel? announcement;
    int unreadCount = 0;

    try {
      timetable = await _timetableRepo.getLatest(branch, year);
    } catch (e) {
      debugPrint('Timetable fetch error: $e');
    }

    try {
      deadlines = await _deadlineRepo.getUpcoming(branch, year, limit: 3);
    } catch (e) {
      debugPrint('Deadlines fetch error: $e');
    }

    try {
      announcement = await _announcementRepo.getLatest(branch, year);
    } catch (e) {
      debugPrint('Announcement fetch error: $e');
    }

    try {
      unreadCount = await _notifRepo.getUnreadCount(profile.id);
    } catch (e) {
      debugPrint('Notification count error (non-fatal): $e');
      unreadCount = 0;
    }

    if (!mounted) return;

    setState(() {
      _latestTimetable = timetable;
      _deadlines = deadlines;
      _latestAnnouncement = announcement;
      _unreadCount = unreadCount;
      _loading = false;
    });

    // Subscribe to realtime (best-effort)
    try {
      _realtime.subscribeToNotifications(profile.id, (data) {
        if (mounted) {
          setState(() => _unreadCount++);
          NotificationBanner.show(
            context,
            data['title'] ?? 'New notification',
            body: data['body'],
          );
        }
      });
    } catch (e) {
      debugPrint('Realtime subscribe error (non-fatal): $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _realtime.unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final profile = auth.profile;
    if (profile == null) return const SizedBox.shrink();

    final urgentAnnouncement =
        _latestAnnouncement?.priority == 'urgent' ? _latestAnnouncement : null;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: CustomScrollView(
            slivers: [
              // App bar
              SliverAppBar(
                floating: true,
                pinned: false,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                elevation: 0,
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${AppDateUtils.getGreeting()}, ${profile.firstName} 👋',
                      style: AppTextStyles.h3
                          .copyWith(color: AppColors.textPrimary),
                    ),
                  ],
                ),
                actions: [
                  Stack(
                    children: [
                      IconButton(
                        icon: const Icon(LucideIcons.bell),
                        onPressed: () =>
                            context.go('/student/notifications'),
                      ),
                      if (_unreadCount > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: const BoxDecoration(
                              color: AppColors.danger,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                _unreadCount > 9 ? '9+' : '$_unreadCount',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Branch + Year pills
                      Row(
                        children: [
                          AppBadge(
                            label: profile.branch,
                            color: AppColors.primary.withOpacity(0.12),
                            textColor: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          AppBadge(
                            label: 'Year ${profile.year}',
                            color: AppColors.accent.withOpacity(0.12),
                            textColor: AppColors.accent,
                          ),
                        ],
                      ),

                      // Urgent banner
                      if (urgentAnnouncement != null) ...[
                        const SizedBox(height: 16),
                        _UrgentBanner(
                          title: urgentAnnouncement.title,
                          onDismiss: () =>
                              setState(() => _latestAnnouncement = null),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Today's Timetable
                      _SectionHeader(
                        title: "Today's Timetable",
                        onViewAll: () => context.go('/student/schedule'),
                      ),
                      const SizedBox(height: 12),
                      if (_loading)
                        const SkeletonLoader(
                            width: double.infinity,
                            height: 200,
                            borderRadius: 16)
                      else if (_latestTimetable == null)
                        const EmptyState(message: 'No timetable posted yet')
                      else
                        _TimetableCard(timetable: _latestTimetable!),

                      const SizedBox(height: 24),

                      // Upcoming Deadlines
                      _SectionHeader(
                        title: 'Upcoming Deadlines',
                        onViewAll: () => context.go('/student/deadlines'),
                      ),
                      const SizedBox(height: 12),
                      if (_loading)
                        ...List.generate(
                            2,
                            (_) => const Padding(
                                  padding: EdgeInsets.only(bottom: 8),
                                  child: SkeletonCard(),
                                ))
                      else if (_deadlines.isEmpty)
                        const EmptyState(message: 'No upcoming deadlines')
                      else
                        ..._deadlines.map((d) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _DeadlineListItem(deadline: d),
                            )),

                      const SizedBox(height: 24),

                      // Latest Announcement
                      _SectionHeader(
                        title: 'Latest Announcement',
                        onViewAll: () =>
                            context.go('/student/announcements'),
                      ),
                      const SizedBox(height: 12),
                      if (_loading)
                        const SkeletonCard()
                      else if (_latestAnnouncement == null)
                        const EmptyState(message: 'No announcements yet')
                      else
                        _AnnouncementCard(
                            announcement: _latestAnnouncement!),

                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar:
          StudentBottomNav(currentIndex: 0, unreadCount: _unreadCount),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onViewAll;

  const _SectionHeader({required this.title, this.onViewAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTextStyles.h3),
        if (onViewAll != null)
          GestureDetector(
            onTap: onViewAll,
            child: Text(
              'View All',
              style:
                  AppTextStyles.label.copyWith(color: AppColors.primary),
            ),
          ),
      ],
    );
  }
}

class _UrgentBanner extends StatelessWidget {
  final String title;
  final VoidCallback onDismiss;

  const _UrgentBanner({required this.title, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.danger.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.danger.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.alertTriangle,
              color: AppColors.danger, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(title,
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.danger)),
          ),
          GestureDetector(
            onTap: onDismiss,
            child:
                const Icon(LucideIcons.x, size: 16, color: AppColors.danger),
          ),
        ],
      ),
    );
  }
}

class _TimetableCard extends StatelessWidget {
  final TimetableModel timetable;

  const _TimetableCard({required this.timetable});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => ImageViewer.show(context, timetable.imageUrl),
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: CachedNetworkImage(
                imageUrl: timetable.imageUrl,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                placeholder: (_, __) => const SkeletonLoader(
                    width: double.infinity, height: 200, borderRadius: 0),
                errorWidget: (_, __, ___) => const SizedBox(
                    height: 200,
                    child: Center(child: Icon(LucideIcons.image))),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(timetable.title, style: AppTextStyles.bodyMedium),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(LucideIcons.calendar,
                        size: 12, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                        AppDateUtils.formatDate(timetable.effectiveDate),
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textMuted)),
                  ],
                ),
                if (timetable.description != null) ...[
                  const SizedBox(height: 4),
                  Text(timetable.description!,
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textMuted),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DeadlineListItem extends StatelessWidget {
  final DeadlineModel deadline;

  const _DeadlineListItem({required this.deadline});

  Color get _borderColor {
    switch (deadline.priority) {
      case 'urgent':
        return AppColors.danger;
      case 'high':
        return AppColors.warning;
      case 'medium':
        return AppColors.accent;
      default:
        return AppColors.success;
    }
  }

  Color get _chipColor {
    if (deadline.isUrgent) return AppColors.danger;
    if (deadline.isThisWeek) return AppColors.warning;
    return AppColors.success;
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      border: Border(left: BorderSide(color: _borderColor, width: 4)),
      borderRadius: 12,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppBadge(
                    label: deadline.subjectName,
                    color: AppColors.primary.withOpacity(0.1),
                    textColor: AppColors.primary,
                  ),
                  const SizedBox(height: 4),
                  Text(deadline.title, style: AppTextStyles.bodyMedium),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _chipColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                AppDateUtils.formatCountdown(deadline.dueDate),
                style: AppTextStyles.caption.copyWith(
                    color: _chipColor, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnnouncementCard extends StatefulWidget {
  final AnnouncementModel announcement;

  const _AnnouncementCard({required this.announcement});

  @override
  State<_AnnouncementCard> createState() => _AnnouncementCardState();
}

class _AnnouncementCardState extends State<_AnnouncementCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final a = widget.announcement;
    return AppCard(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppBadge.priority(a.priority),
              const Spacer(),
              Text(AppDateUtils.formatRelative(a.createdAt),
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textMuted)),
            ],
          ),
          const SizedBox(height: 8),
          Text(a.title, style: AppTextStyles.bodyMedium),
          const SizedBox(height: 4),
          Text(
            a.body,
            style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
            maxLines: _expanded ? null : 2,
            overflow: _expanded ? null : TextOverflow.ellipsis,
          ),
          if (a.imageUrl != null && _expanded) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: a.imageUrl!,
                width: double.infinity,
                height: 160,
                fit: BoxFit.cover,
              ),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            _expanded ? 'Show less' : 'Show more',
            style:
                AppTextStyles.caption.copyWith(color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}
