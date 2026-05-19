import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../widgets/admin_bottom_nav.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final _client = Supabase.instance.client;
  bool _loading = true;

  int _totalStudents = 0;
  int _totalPdf = 0;
  int _totalAnnouncements = 0;
  int _totalDeadlines = 0;
  int _unreadNotifications = 0;
  int _kbDocs = 0;
  Map<String, int> _studentsByBranch = {};
  Map<String, int> _studentsByYear = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final students = await _client.from('profiles').select().eq('role', 'student');
      final studentList = students as List;

      _totalStudents = studentList.length;
      _studentsByBranch = {};
      _studentsByYear = {};

      for (final s in studentList) {
        final branch = s['branch'] as String? ?? 'Unknown';
        final year = s['year'] as int? ?? 0;
        _studentsByBranch[branch] = (_studentsByBranch[branch] ?? 0) + 1;
        _studentsByYear['Year $year'] = (_studentsByYear['Year $year'] ?? 0) + 1;
      }

      final counts = await Future.wait([
        _client.from('pdf_notes').select(),
        _client.from('announcements').select(),
        _client.from('deadlines').select(),
        _client.from('notifications_log').select().eq('is_read', false),
        _client.from('knowledge_base_docs').select(),
      ]);

      _totalPdf = (counts[0] as List).length;
      _totalAnnouncements = (counts[1] as List).length;
      _totalDeadlines = (counts[2] as List).length;
      _unreadNotifications = (counts[3] as List).length;
      _kbDocs = (counts[4] as List).length;
    } catch (e) {
      debugPrint('Analytics load error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Analytics', style: AppTextStyles.h3)),
      body: _loading
          ? const SkeletonListView(count: 6)
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Overview stats
                  Text('Platform Overview', style: AppTextStyles.h3),
                  const SizedBox(height: 12),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.4,
                    children: [
                      _StatCard(value: '$_totalStudents', label: 'Students', icon: LucideIcons.users, color: AppColors.primary),
                      _StatCard(value: '$_totalPdf', label: 'PDF Notes', icon: LucideIcons.fileText, color: AppColors.danger),
                      _StatCard(value: '$_totalAnnouncements', label: 'Announcements', icon: LucideIcons.megaphone, color: AppColors.success),
                      _StatCard(value: '$_totalDeadlines', label: 'Deadlines', icon: LucideIcons.clock, color: AppColors.warning),
                      _StatCard(value: '$_kbDocs', label: 'KB Documents', icon: LucideIcons.database, color: AppColors.secondary),
                      _StatCard(value: '$_unreadNotifications', label: 'Unread Notifs', icon: LucideIcons.bell, color: AppColors.accent),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Students by branch
                  Text('Students by Branch', style: AppTextStyles.h3),
                  const SizedBox(height: 12),
                  ..._studentsByBranch.entries.map((e) => _BarRow(
                    label: e.key,
                    value: e.value,
                    max: _totalStudents,
                    color: AppColors.primary,
                  )),

                  const SizedBox(height: 24),

                  // Students by year
                  Text('Students by Year', style: AppTextStyles.h3),
                  const SizedBox(height: 12),
                  ..._studentsByYear.entries.map((e) => _BarRow(
                    label: e.key,
                    value: e.value,
                    max: _totalStudents,
                    color: AppColors.secondary,
                  )),

                  const SizedBox(height: 80),
                ],
              ),
            ),
      bottomNavigationBar: const AdminBottomNav(currentIndex: 3),
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
          Icon(icon, color: color, size: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: AppTextStyles.h1.copyWith(color: color, fontSize: 24)),
              Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
            ],
          ),
        ],
      ),
    );
  }
}

class _BarRow extends StatelessWidget {
  final String label;
  final int value;
  final int max;
  final Color color;

  const _BarRow({required this.label, required this.value, required this.max, required this.color});

  @override
  Widget build(BuildContext context) {
    final pct = max == 0 ? 0.0 : value / max;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: AppTextStyles.body),
              Text('$value', style: AppTextStyles.bodyMedium),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: pct.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: color.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}
