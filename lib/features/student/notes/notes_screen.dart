import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../data/models/pdf_note_model.dart';
import '../../../data/repositories/notes_repository.dart';
import '../../auth/providers/auth_provider.dart';
import '../widgets/student_bottom_nav.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final _repo = NotesRepository();
  List<PdfNoteModel> _notes = [];
  List<String> _subjects = [];
  String _selectedSubject = 'All';
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
      _notes = await _repo.getByBranchYear(profile.branch, profile.year!);
      _subjects = ['All', ..._notes.map((n) => n.subjectName).toSet().toList()];
    } catch (e) {
      debugPrint('Notes load error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<PdfNoteModel> get _filtered {
    if (_selectedSubject == 'All') return _notes;
    return _notes.where((n) => n.subjectName == _selectedSubject).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Study Notes', style: AppTextStyles.h3)),
      body: Column(
        children: [
          // Subject filter pills
          if (_subjects.isNotEmpty)
            SizedBox(
              height: 48,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _subjects.length,
                itemBuilder: (_, i) {
                  final s = _subjects[i];
                  final selected = _selectedSubject == s;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(s, style: AppTextStyles.label.copyWith(
                        color: selected ? Colors.white : AppColors.textMuted,
                      )),
                      selected: selected,
                      selectedColor: AppColors.primary,
                      backgroundColor: Colors.transparent,
                      side: BorderSide(
                        color: selected ? AppColors.primary : AppColors.textMuted.withOpacity(0.3),
                      ),
                      onSelected: (_) => setState(() => _selectedSubject = s),
                    ),
                  );
                },
              ),
            ),
          Expanded(
            child: _loading
                ? const SkeletonListView(count: 4)
                : _filtered.isEmpty
                    ? const EmptyState(
                        message: 'No notes uploaded yet',
                        icon: LucideIcons.fileText,
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.75,
                          ),
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) => _NoteCard(note: _filtered[i]),
                        ),
                      ),
          ),
        ],
      ),
      bottomNavigationBar: const StudentBottomNav(currentIndex: 3),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final PdfNoteModel note;

  const _NoteCard({required this.note});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.danger.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(LucideIcons.fileText, color: AppColors.danger, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            note.title,
            style: AppTextStyles.bodyMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          AppBadge(
            label: note.subjectName,
            color: AppColors.primary.withOpacity(0.1),
            textColor: AppColors.primary,
          ),
          const SizedBox(height: 4),
          Text(
            AppDateUtils.formatDate(note.createdAt),
            style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _openPdf(context, note),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              child: const Text('Open'),
            ),
          ),
        ],
      ),
    );
  }

  void _openPdf(BuildContext context, PdfNoteModel note) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text(note.title, style: AppTextStyles.h3)),
          body: SfPdfViewer.network(note.fileUrl),
        ),
      ),
    );
  }
}
