import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../data/repositories/timetable_repository.dart';

class TimetableEditScreen extends StatefulWidget {
  final String id;

  const TimetableEditScreen({super.key, required this.id});

  @override
  State<TimetableEditScreen> createState() => _TimetableEditScreenState();
}

class _TimetableEditScreenState extends State<TimetableEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _repo = TimetableRepository();

  String _branch = AppConstants.branches.first;
  int _year = 1;
  DateTime _effectiveDate = DateTime.now();
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final entries = await _repo.getAll();
      final entry = entries.firstWhere((e) => e.id == widget.id);
      _titleCtrl.text = entry.title;
      _descCtrl.text = entry.description ?? '';
      _branch = entry.branch;
      _year = entry.year;
      _effectiveDate = entry.effectiveDate;
    } catch (e) {
      debugPrint('Edit load error: $e');
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
        'branch': _branch,
        'year': _year,
        'effective_date': _effectiveDate.toIso8601String().split('T')[0],
      });
      if (mounted) {
        AppSnackBar.success(context, 'Timetable updated successfully');
        context.go('/admin/content');
      }
    } catch (e) {
      if (mounted) AppSnackBar.error(context, 'Update failed: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _effectiveDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _effectiveDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Edit Timetable', style: AppTextStyles.h3)),
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
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Effective Date',
                      controller: TextEditingController(text: _effectiveDate.toIso8601String().split('T')[0]),
                      readOnly: true,
                      onTap: _pickDate,
                      prefix: const Icon(LucideIcons.calendar, size: 18),
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
