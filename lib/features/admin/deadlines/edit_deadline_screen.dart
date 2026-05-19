import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../data/repositories/deadline_repository.dart';

class EditDeadlineScreen extends StatefulWidget {
  final String id;
  const EditDeadlineScreen({super.key, required this.id});

  @override
  State<EditDeadlineScreen> createState() => _EditDeadlineScreenState();
}

class _EditDeadlineScreenState extends State<EditDeadlineScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _repo = DeadlineRepository();

  String _branch = AppConstants.branches.first;
  int _year = 1;
  String _priority = 'medium';
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));
  bool _loading = true;
  bool _saving = false;

  static const _priorities = ['low', 'medium', 'high', 'urgent'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final deadlines = await _repo.getAll();
      final d = deadlines.firstWhere((x) => x.id == widget.id);
      _titleCtrl.text = d.title;
      _subjectCtrl.text = d.subjectName;
      _descCtrl.text = d.description ?? '';
      _branch = d.branch;
      _year = d.year;
      _priority = d.priority;
      _dueDate = d.dueDate;
    } catch (e) {
      debugPrint('EditDeadline load error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await _repo.update(widget.id, {
        'title': _titleCtrl.text.trim(),
        'subject_name': _subjectCtrl.text.trim(),
        'description': _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        'due_date': _dueDate.toIso8601String(),
        'branch': _branch,
        'year': _year,
        'priority': _priority,
      });
      if (mounted) {
        AppSnackBar.success(context, 'Deadline updated');
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
      appBar: AppBar(title: Text('Edit Deadline', style: AppTextStyles.h3)),
      body: _loading
          ? const SkeletonListView(count: 4)
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppTextField(label: 'Title', controller: _titleCtrl, validator: (v) => (v == null || v.isEmpty) ? 'Required' : null),
                    const SizedBox(height: 16),
                    AppTextField(label: 'Subject', controller: _subjectCtrl, validator: (v) => (v == null || v.isEmpty) ? 'Required' : null),
                    const SizedBox(height: 16),
                    AppTextField(label: 'Description', controller: _descCtrl, maxLines: 3),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Due Date',
                      controller: TextEditingController(text: _dueDate.toIso8601String().split('T')[0]),
                      readOnly: true,
                      onTap: _pickDate,
                      prefix: const Icon(LucideIcons.clock, size: 18),
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
                                items: AppConstants.branches.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
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
                                items: [1, 2, 3, 4].map((y) => DropdownMenuItem(value: y, child: Text('Year $y'))).toList(),
                                onChanged: (v) => setState(() => _year = v!),
                              ),
                            ],
                          ),
                        ),
                      ],
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
                              label: Text(p.toUpperCase(), style: AppTextStyles.caption.copyWith(
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
                    const SizedBox(height: 32),
                    AppButton(label: 'Save Changes', onPressed: _save, isLoading: _saving, width: double.infinity),
                  ],
                ),
              ),
            ),
    );
  }
}
