import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../data/models/announcement_model.dart';
import '../../../data/models/deadline_model.dart';
import '../../../data/repositories/announcement_repository.dart';
import '../../../data/repositories/deadline_repository.dart';
import '../../auth/providers/auth_provider.dart';
import '../widgets/student_bottom_nav.dart';

class DeadlinesScreen extends StatefulWidget {
  const DeadlinesScreen({super.key});

  @override
  State<DeadlinesScreen> createState() => _DeadlinesScreenState();
}

class _DeadlinesScreenState extends State<DeadlinesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _deadlineRepo = DeadlineRepository();
  final _announcementRepo = AnnouncementRepository();

  List<DeadlineModel> _deadlines = [];
  List<AnnouncementModel> _announcements = [];
  bool _loading = true;
  String _deadlineFilter = 'All';

  static const _deadlineFilters = ['All', 'Urgent', 'This Week', 'Later'];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final profile = context.read<AuthProvider>().profile!;
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _deadlineRepo.getAll(branch: profile.branch, year: profile.year),
        _announcementRepo.getPublished(profile.branch, profile.year!),
      ]);
      _deadlines = results[0] as List<DeadlineModel>;
      _announcements = results[1] as List<AnnouncementModel>;
    } catch (e) {
      debugPrint('Deadlines load error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<DeadlineModel> get _filteredDeadlines {
    switch (_deadlineFilter) {
      case 'Urgent': return _deadlines.where((d) => d.isUrgent).toList();
      case 'This Week': return _deadlines.where((d) => d.isThisWeek).toList();
      case 'Later': return _deadlines.where((d) => !d.isUrgent && !d.isThisWeek && !d.isOverdue).toList();
      default: return _deadlines;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Priority Checklist', style: AppTextStyles.h3),
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: const [Tab(text: 'Deadlines'), Tab(text: 'Announcements')],
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildDeadlinesTab(),
          _buildAnnouncementsTab(),
        ],
      ),
      bottomNavigationBar: const StudentBottomNav(currentIndex: 0),
    );
  }

  Widget _buildDeadlinesTab() {
    return Column(
      children: [
        // Filter pills
        SizedBox(
          height: 52,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: _deadlineFilters.length,
            itemBuilder: (_, i) {
              final f = _deadlineFilters[i];
              final selected = _deadlineFilter == f;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(f, style: AppTextStyles.label.copyWith(
                    color: selected ? Colors.white : AppColors.textMuted,
                  )),
                  selected: selected,
                  selectedColor: AppColors.primary,
                  backgroundColor: Colors.transparent,
                  side: BorderSide(color: selected ? AppColors.primary : AppColors.textMuted.withOpacity(0.3)),
                  onSelected: (_) => setState(() => _deadlineFilter = f),
                ),
              );
            },
          ),
        ),
        Expanded(
          child: _loading
              ? const SkeletonListView(count: 4)
              : _filteredDeadlines.isEmpty
                  ? const EmptyState(message: 'No deadlines found', icon: LucideIcons.checkCircle)
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredDeadlines.length,
                        itemBuilder: (_, i) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _DeadlineCard(deadline: _filteredDeadlines[i]),
                        ),
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildAnnouncementsTab() {
    return _loading
        ? const SkeletonListView(count: 4)
        : _announcements.isEmpty
            ? const EmptyState(message: 'No announcements', icon: LucideIcons.megaphone)
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _announcements.length,
                  itemBuilder: (_, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _AnnouncementCard(announcement: _announcements[i]),
                  ),
                ),
              );
  }
}

class _DeadlineCard extends StatefulWidget {
  final DeadlineModel deadline;

  const _DeadlineCard({required this.deadline});

  @override
  State<_DeadlineCard> createState() => _DeadlineCardState();
}

class _DeadlineCardState extends State<_DeadlineCard> {
  bool _expanded = false;

  Color get _borderColor {
    switch (widget.deadline.priority) {
      case 'urgent': return AppColors.danger;
      case 'high': return AppColors.warning;
      case 'medium': return AppColors.accent;
      default: return AppColors.success;
    }
  }

  Color get _chipColor {
    if (widget.deadline.isOverdue) return AppColors.danger;
    if (widget.deadline.isUrgent) return AppColors.danger;
    if (widget.deadline.isThisWeek) return AppColors.warning;
    return AppColors.success;
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.deadline;
    return AppCard(
      padding: EdgeInsets.zero,
      border: Border(left: BorderSide(color: _borderColor, width: 4)),
      borderRadius: 12,
      onTap: () => setState(() => _expanded = !_expanded),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AppBadge(
                  label: d.subjectName,
                  color: AppColors.primary.withOpacity(0.1),
                  textColor: AppColors.primary,
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _chipColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    AppDateUtils.formatCountdown(d.dueDate),
                    style: AppTextStyles.caption.copyWith(color: _chipColor, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(d.title, style: AppTextStyles.bodyMedium),
            const SizedBox(height: 4),
            Row(
              children: [
                AppBadge(
                  label: d.branch,
                  color: AppColors.accent.withOpacity(0.1),
                  textColor: AppColors.accent,
                ),
                const SizedBox(width: 4),
                AppBadge.year(d.year),
              ],
            ),
            if (_expanded && d.description != null) ...[
              const SizedBox(height: 8),
              Text(d.description!, style: AppTextStyles.body.copyWith(color: AppColors.textMuted)),
            ],
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
                  style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
            ],
          ),
          const SizedBox(height: 8),
          Text(a.title, style: AppTextStyles.bodyMedium),
          const SizedBox(height: 4),
          Text(
            a.body,
            style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
            maxLines: _expanded ? null : 3,
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
        ],
      ),
    );
  }
}
