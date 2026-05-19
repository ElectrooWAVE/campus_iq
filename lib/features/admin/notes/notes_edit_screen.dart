import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../data/repositories/notes_repository.dart';

class NotesEditScreen extends StatefulWidget {
  final String id;

  const NotesEditScreen({super.key, required this.id});

  @override
  State<NotesEditScreen> createState() => _NotesEditScreenState();
}

class _NotesEditScreenState extends State<NotesEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final _repo = NotesRepository();

  String _branch = AppConstants.branches.first;
  int _year = 1;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final notes = await _repo.getAll();
      final note = notes.firstWhere((n) => n.id == widget.id);
      _titleCtrl.text = note.title;
      _descCtrl.text = note.description ?? '';
      _subjectCtrl.text = note.subjectName;
      _branch = note.branch;
      _year = note.year;
    } catch (e) {
      debugPrint('NotesEdit load error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await _repo.update(widget.id, {
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        'subject_name': _subjectCtrl.text.trim(),
        'branch': _branch,
        'year': _year,
      });
      if (mounted) {
        AppSnackBar.success(context, 'PDF note updated successfully');
        context.go('/admin/content');
      }
    } catch (e) {
      if (mounted) AppSnackBar.error(context, 'Update failed: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Edit PDF Note', style: AppTextStyles.h3)),
      body: _loading
          ? const SkeletonListView(count: 4)
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    AppTextField(
                      label: 'Title',
                      controller: _titleCtrl,
                      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Subject',
                      controller: _subjectCtrl,
                      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Description',
                      controller: _descCtrl,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Branch', style: AppTextStyles.label.copyWith(color: AppColors.textMuted)),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                value: _branch,
                                decoration: const InputDecoration(),
                                items: AppConstants.branches
                                    .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                                    .toList(),
                                onChanged: (v) => setState(() => _branch = v!),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Year', style: AppTextStyles.label.copyWith(color: AppColors.textMuted)),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<int>(
                                value: _year,
                                decoration: const InputDecoration(),
                                items: [1, 2, 3, 4]
                                    .map((y) => DropdownMenuItem(value: y, child: Text('Year $y')))
                                    .toList(),
                                onChanged: (v) => setState(() => _year = v!),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    AppButton(
                      label: 'Save Changes',
                      onPressed: _save,
                      isLoading: _saving,
                      width: double.infinity,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
