import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../data/models/saved_answer_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../widgets/student_bottom_nav.dart';

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  final _client = Supabase.instance.client;
  List<SavedAnswerModel> _savedAnswers = [];
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
      final data = await _client
          .from('saved_answers')
          .select()
          .eq('student_id', profile.id)
          .order('saved_at', ascending: false);
      _savedAnswers = (data as List).map((e) => SavedAnswerModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Profile load error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteSavedAnswer(String id) async {
    await _client.from('saved_answers').delete().eq('id', id);
    setState(() => _savedAnswers.removeWhere((a) => a.id == id));
  }

  Future<void> _logout() async {
    await context.read<AuthProvider>().logout();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AuthProvider>().profile;
    if (profile == null) return const SizedBox.shrink();

    final initials = profile.fullName
        .split(' ')
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();

    return Scaffold(
      appBar: AppBar(title: Text('My Profile', style: AppTextStyles.h3)),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Avatar + info
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.primary.withOpacity(0.15),
                    backgroundImage: profile.avatarUrl != null
                        ? NetworkImage(profile.avatarUrl!) as ImageProvider
                        : null,
                    child: profile.avatarUrl == null
                        ? Text(initials,
                            style: AppTextStyles.h2.copyWith(color: AppColors.primary))
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(profile.fullName, style: AppTextStyles.h2),
                  const SizedBox(height: 4),
                  Text(profile.email,
                      style: AppTextStyles.body.copyWith(color: AppColors.textMuted)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AppBadge.branch(profile.branch),
                      const SizedBox(width: 8),
                      if (profile.year != null) AppBadge.year(profile.year!),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 32),

            // Saved Answers
            Text('Saved Answers', style: AppTextStyles.h3),
            const SizedBox(height: 12),
            if (_loading)
              ...List.generate(2, (_) => const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: SkeletonCard(),
              ))
            else if (_savedAnswers.isEmpty)
              const EmptyState(
                message: 'No saved answers yet',
                submessage: 'Bookmark chatbot answers to see them here',
                icon: LucideIcons.bookmark,
              )
            else
              ..._savedAnswers.map((a) => _SavedAnswerCard(
                answer: a,
                onDelete: () => _deleteSavedAnswer(a.id),
              )),

            const Divider(height: 32),

            // Logout
            AppButton(
              label: 'Logout',
              onPressed: _logout,
              isDanger: true,
              isOutlined: true,
              width: double.infinity,
              icon: LucideIcons.logOut,
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: const StudentBottomNav(currentIndex: 4),
    );
  }
}

class _SavedAnswerCard extends StatefulWidget {
  final SavedAnswerModel answer;
  final VoidCallback onDelete;

  const _SavedAnswerCard({required this.answer, required this.onDelete});

  @override
  State<_SavedAnswerCard> createState() => _SavedAnswerCardState();
}

class _SavedAnswerCardState extends State<_SavedAnswerCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        onTap: () => setState(() => _expanded = !_expanded),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(widget.answer.question, style: AppTextStyles.bodyMedium),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.trash2, size: 16, color: AppColors.danger),
                  onPressed: widget.onDelete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            if (_expanded) ...[
              const SizedBox(height: 8),
              Text(
                widget.answer.answer,
                style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
