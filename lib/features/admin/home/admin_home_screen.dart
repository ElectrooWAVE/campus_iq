import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../auth/providers/auth_provider.dart';
import '../widgets/admin_bottom_nav.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final _client = Supabase.instance.client;

  int _students = 0;
  int _activeDeadlines = 0;
  int _weeklyAnnouncements = 0;
  int _pdfNotes = 0;
  List<Map<String, dynamic>> _recentActivity = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final now = DateTime.now();
      final sevenDaysAgo = now.subtract(const Duration(days: 7)).toIso8601String();

      final results = await Future.wait([
        _client.from('profiles').select().eq('role', 'student'),
        _client.from('deadlines').select().gte('due_date', now.toIso8601String()),
        _client.from('announcements').select().gte('created_at', sevenDaysAgo),
        _client.from('pdf_notes').select(),
      ]);

      _students = (results[0] as List).length;
      _activeDeadlines = (results[1] as List).length;
      _weeklyAnnouncements = (results[2] as List).length;
      _pdfNotes = (results[3] as List).length;

      // Recent activity
      final announcements = await _client
          .from('announcements')
          .select('id, title, created_at')
          .order('created_at', ascending: false)
          .limit(4);
      final deadlines = await _client
          .from('deadlines')
          .select('id, title, created_at')
          .order('created_at', ascending: false)
          .limit(3);
      final notes = await _client
          .from('pdf_notes')
          .select('id, title, created_at')
          .order('created_at', ascending: false)
          .limit(3);

      final all = [
        ...(announcements as List).map((e) => {...(e as Map<String, dynamic>), 'type': 'announcement'}),
        ...(deadlines as List).map((e) => {...(e as Map<String, dynamic>), 'type': 'deadline'}),
        ...(notes as List).map((e) => {...(e as Map<String, dynamic>), 'type': 'pdf'}),
      ];
      all.sort((a, b) => DateTime.parse(b['created_at']).compareTo(DateTime.parse(a['created_at'])));
      _recentActivity = all.take(10).toList();
    } catch (e) {
      debugPrint('Admin home load error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AuthProvider>().profile;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Admin Dashboard', style: AppTextStyles.h3),
            if (profile != null)
              Text(profile.fullName,
                  style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.logOut),
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Stat cards
            Text('Overview', style: AppTextStyles.h3),
            const SizedBox(height: 12),
            _loading
                ? GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.4,
                    children: List.generate(4, (_) => const SkeletonLoader(width: double.infinity, height: 100, borderRadius: 16)),
                  )
                : GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.4,
                    children: [
                      _StatCard(value: '$_students', label: 'Total Students', icon: LucideIcons.users, color: AppColors.primary),
                      _StatCard(value: '$_activeDeadlines', label: 'Active Deadlines', icon: LucideIcons.clock, color: AppColors.warning),
                      _StatCard(value: '$_weeklyAnnouncements', label: 'This Week', icon: LucideIcons.megaphone, color: AppColors.success),
                      _StatCard(value: '$_pdfNotes', label: 'PDF Notes', icon: LucideIcons.fileText, color: AppColors.danger),
                    ],
                  ),

            const SizedBox(height: 24),

            // Quick actions
            Text('Quick Actions', style: AppTextStyles.h3),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.2,
              children: [
                _QuickAction(icon: LucideIcons.megaphone, label: 'Post Announcement', color: AppColors.success, onTap: () => context.go('/admin/announcements/create')),
                _QuickAction(icon: LucideIcons.calendar, label: 'Upload Timetable', color: AppColors.primary, onTap: () => context.go('/admin/timetable/upload')),
                _QuickAction(icon: LucideIcons.fileText, label: 'Upload PDF Notes', color: AppColors.danger, onTap: () => context.go('/admin/notes/upload')),
                _QuickAction(icon: LucideIcons.clock, label: 'Add Deadline', color: AppColors.warning, onTap: () => context.go('/admin/deadlines/create')),
              ],
            ),

            const SizedBox(height: 24),

            // Recent activity
            Text('Recent Activity', style: AppTextStyles.h3),
            const SizedBox(height: 12),
            if (_loading)
              ...List.generate(4, (_) => const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: SkeletonCard(),
              ))
            else if (_recentActivity.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: Text('No recent activity')),
              )
            else
              ..._recentActivity.map((item) => _ActivityItem(item: item)),

            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: const AdminBottomNav(currentIndex: 0),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _StatCard({required this.value, required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 22),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: AppTextStyles.h1.copyWith(color: color, fontSize: 26)),
              Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: AppTextStyles.label, maxLines: 2)),
        ],
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final Map<String, dynamic> item;

  const _ActivityItem({required this.item});

  (IconData, Color) get _typeInfo {
    switch (item['type']) {
      case 'announcement': return (LucideIcons.megaphone, AppColors.success);
      case 'deadline': return (LucideIcons.clock, AppColors.warning);
      case 'pdf': return (LucideIcons.fileText, AppColors.danger);
      default: return (LucideIcons.activity, AppColors.textMuted);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _typeInfo;
    final createdAt = DateTime.tryParse(item['created_at'] ?? '') ?? DateTime.now();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['title'] ?? '', style: AppTextStyles.bodyMedium),
                  Text(AppDateUtils.formatRelative(createdAt),
                      style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
