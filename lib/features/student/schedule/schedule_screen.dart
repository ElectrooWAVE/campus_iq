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
import '../../../core/widgets/image_viewer.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../data/models/timetable_model.dart';
import '../../../data/repositories/timetable_repository.dart';
import '../../auth/providers/auth_provider.dart';
import '../widgets/student_bottom_nav.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final _repo = TimetableRepository();
  List<TimetableModel> _entries = [];
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
      _entries = await _repo.getByBranchYear(profile.branch, profile.year!);
    } catch (e) {
      debugPrint('Schedule load error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AuthProvider>().profile;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Timetable — ${profile?.branch ?? ''} ${profile?.year ?? ''}${_yearSuffix(profile?.year ?? 0)} Year',
          style: AppTextStyles.h3,
        ),
      ),
      body: _loading
          ? const SkeletonListView(count: 3)
          : _entries.isEmpty
              ? const EmptyState(
                  message: 'No timetable posted yet',
                  submessage: 'Check back when your admin uploads one',
                  icon: LucideIcons.calendar,
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _entries.length,
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _TimetableCard(entry: _entries[i]),
                    ),
                  ),
                ),
      bottomNavigationBar: const StudentBottomNav(currentIndex: 1),
    );
  }

  String _yearSuffix(int y) {
    if (y == 1) return 'st';
    if (y == 2) return 'nd';
    if (y == 3) return 'rd';
    return 'th';
  }
}

class _TimetableCard extends StatelessWidget {
  final TimetableModel entry;

  const _TimetableCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(child: Text(entry.title, style: AppTextStyles.bodyMedium)),
                AppBadge(
                  label: AppDateUtils.formatDate(entry.effectiveDate),
                  color: AppColors.primary.withOpacity(0.1),
                  textColor: AppColors.primary,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => ImageViewer.show(context, entry.imageUrl),
            child: Hero(
              tag: entry.id,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                child: CachedNetworkImage(
                  imageUrl: entry.imageUrl,
                  width: double.infinity,
                  fit: BoxFit.fitWidth,
                  placeholder: (_, __) => const SkeletonLoader(width: double.infinity, height: 200, borderRadius: 0),
                  errorWidget: (_, __, ___) => Container(
                    height: 200,
                    color: AppColors.background,
                    child: const Center(child: Icon(LucideIcons.image, size: 48)),
                  ),
                ),
              ),
            ),
          ),
          if (entry.description != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                entry.description!,
                style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
              ),
            ),
        ],
      ),
    );
  }
}
