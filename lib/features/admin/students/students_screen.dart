import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../data/models/profile_model.dart';
import '../widgets/admin_bottom_nav.dart';

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  final _client = Supabase.instance.client;
  List<ProfileModel> _students = [];
  List<ProfileModel> _filtered = [];
  bool _loading = true;
  String _search = '';
  String? _branchFilter;
  int? _yearFilter;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _client
          .from('profiles')
          .select()
          .eq('role', 'student')
          .order('full_name');
      _students = (data as List).map((e) => ProfileModel.fromJson(e)).toList();
      _applyFilters();
    } catch (e) {
      debugPrint('Students load error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyFilters() {
    _filtered = _students.where((s) {
      final matchSearch = _search.isEmpty ||
          s.fullName.toLowerCase().contains(_search.toLowerCase()) ||
          s.email.toLowerCase().contains(_search.toLowerCase());
      final matchBranch = _branchFilter == null || s.branch == _branchFilter;
      final matchYear = _yearFilter == null || s.year == _yearFilter;
      return matchSearch && matchBranch && matchYear;
    }).toList();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Students (${_filtered.length})', style: AppTextStyles.h3),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by name or email...',
                prefixIcon: const Icon(LucideIcons.search, size: 18),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                filled: true,
              ),
              onChanged: (v) {
                _search = v;
                _applyFilters();
              },
            ),
          ),
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                _FilterChip(
                  label: 'All Branches',
                  selected: _branchFilter == null,
                  onTap: () {
                    _branchFilter = null;
                    _applyFilters();
                  },
                ),
                ...['Computer Science', 'Information Technology', 'Electronics', 'Mechanical', 'Civil', 'Electrical'].map((b) => _FilterChip(
                  label: b,
                  selected: _branchFilter == b,
                  onTap: () {
                    _branchFilter = _branchFilter == b ? null : b;
                    _applyFilters();
                  },
                )),
              ],
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _FilterChip(
                  label: 'All Years',
                  selected: _yearFilter == null,
                  onTap: () {
                    _yearFilter = null;
                    _applyFilters();
                  },
                ),
                ...List.generate(4, (i) => _FilterChip(
                  label: 'Year ${i + 1}',
                  selected: _yearFilter == i + 1,
                  onTap: () {
                    _yearFilter = _yearFilter == i + 1 ? null : i + 1;
                    _applyFilters();
                  },
                )),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const SkeletonListView(count: 6)
                : _filtered.isEmpty
                    ? const EmptyState(
                        message: 'No students found',
                        icon: LucideIcons.users,
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _StudentCard(student: _filtered[i]),
                          ),
                        ),
                      ),
          ),
        ],
      ),
      bottomNavigationBar: const AdminBottomNav(currentIndex: 2),
    );
  }
}

class _StudentCard extends StatelessWidget {
  final ProfileModel student;

  const _StudentCard({required this.student});

  @override
  Widget build(BuildContext context) {
    final initials = student.fullName
        .split(' ')
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();

    return AppCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primary.withOpacity(0.15),
            backgroundImage: student.avatarUrl != null ? NetworkImage(student.avatarUrl!) : null,
            child: student.avatarUrl == null
                ? Text(initials, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary))
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(student.fullName, style: AppTextStyles.bodyMedium),
                Text(student.email, style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    AppBadge.branch(student.branch),
                    const SizedBox(width: 4),
                    if (student.year != null) AppBadge.year(student.year!),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label, style: AppTextStyles.caption.copyWith(
          color: selected ? Colors.white : AppColors.textMuted,
        )),
        selected: selected,
        selectedColor: AppColors.primary,
        backgroundColor: Colors.transparent,
        side: BorderSide(color: selected ? AppColors.primary : AppColors.textMuted.withOpacity(0.3)),
        onSelected: (_) => onTap(),
      ),
    );
  }
}
