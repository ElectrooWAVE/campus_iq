import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../data/repositories/announcement_repository.dart';

class EditAnnouncementScreen extends StatefulWidget {
  final String id;
  const EditAnnouncementScreen({super.key, required this.id});

  @override
  State<EditAnnouncementScreen> createState() => _EditAnnouncementScreenState();
}

class _EditAnnouncementScreenState extends State<EditAnnouncementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  final _repo = AnnouncementRepository();

  String _priority = 'general';
  String? _branch;
  int? _year;
  bool _allStudents = true;
  bool _isPublished = true;
  bool _loading = true;
  bool _saving = false;

  static const _priorities = ['general', 'important', 'urgent'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final all = await _repo.getAll();
      final a = all.firstWhere((x) => x.id == widget.id);
      _titleCtrl.text = a.title;
      _bodyCtrl.text = a.body;
      _priority = a.priority;
      _branch = a.branch;
      _year = a.year;
      _allStudents = a.branch == null;
      _isPublished = a.isPublished;
    } catch (e) {
      debugPrint('EditAnnouncement load error: $e');
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
        'body': _bodyCtrl.text.trim(),
        'priority': _priority,
        'branch': _allStudents ? null : _branch,
        'year': _allStudents ? null : _year,
        'is_published': _isPublished,
      });
      if (mounted) {
        AppSnackBar.success(context, 'Announcement updated');
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
      appBar: AppBar(title: Text('Edit Announcement', style: AppTextStyles.h3)),
      body: _loading
          ? const SkeletonListView(count: 4)
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppTextField(
                      label: 'Title',
                      controller: _titleCtrl,
                      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Body',
                      controller: _bodyCtrl,
                      maxLines: 5,
                      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    Text('Priority', style: AppTextStyles.label.copyWith(color: AppColors.textMuted)),
                    const SizedBox(height: 8),
                    Row(
                      children: _priorities.map((p) {
                        final selected = _priority == p;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(p.toUpperCase(), style: AppTextStyles.label.copyWith(
                                color: selected ? Colors.white : AppColors.textMuted,
                              )),
                              selected: selected,
                              selectedColor: AppColors.primary,
                              backgroundColor: Colors.transparent,
                              onSelected: (_) => setState(() => _priority = p),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      value: _allStudents,
                      onChanged: (v) => setState(() => _allStudents = v),
                      title: Text('All Students', style: AppTextStyles.bodyMedium),
                      activeColor: AppColors.primary,
                      contentPadding: EdgeInsets.zero,
                    ),
                    if (!_allStudents) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _branch,
                              hint: const Text('Branch'),
                              decoration: const InputDecoration(),
                              items: AppConstants.branches
                                  .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                                  .toList(),
                              onChanged: (v) => setState(() => _branch = v),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              value: _year,
                              hint: const Text('Year'),
                              decoration: const InputDecoration(),
                              items: [1, 2, 3, 4]
                                  .map((y) => DropdownMenuItem(value: y, child: Text('Year $y')))
                                  .toList(),
                              onChanged: (v) => setState(() => _year = v),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    SwitchListTile(
                      value: _isPublished,
                      onChanged: (v) => setState(() => _isPublished = v),
                      title: Text('Published', style: AppTextStyles.bodyMedium),
                      activeColor: AppColors.primary,
                      contentPadding: EdgeInsets.zero,
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
