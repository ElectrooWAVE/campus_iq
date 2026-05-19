import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../data/repositories/deadline_repository.dart';
import '../../../data/repositories/notification_repository.dart';
import '../../auth/providers/auth_provider.dart';

class CreateDeadlineScreen extends StatefulWidget {
  const CreateDeadlineScreen({super.key});

  @override
  State<CreateDeadlineScreen> createState() => _CreateDeadlineScreenState();
}

class _CreateDeadlineScreenState extends State<CreateDeadlineScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _repo = DeadlineRepository();
  final _client = Supabase.instance.client;

  String _branch = AppConstants.branches.first;
  int _year = 1;
  String _priority = 'medium';
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));
  bool _loading = false;

  static const _priorities = ['low', 'medium', 'high', 'urgent'];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _subjectCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dueDate),
    );
    setState(() {
      _dueDate = picked.copyWith(
        hour: time?.hour ?? 23,
        minute: time?.minute ?? 59,
      );
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final admin = context.read<AuthProvider>().profile!;
      final deadline = await _repo.insert({
        'title': _titleCtrl.text.trim(),
        'subject_name': _subjectCtrl.text.trim(),
        'description': _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        'due_date': _dueDate.toIso8601String(),
        'branch': _branch,
        'year': _year,
        'priority': _priority,
        'created_by': admin.id,
      });

      // Notify students
      await _notifyStudents(deadline.id, _titleCtrl.text.trim(), _dueDate);

      if (mounted) {
        AppSnackBar.success(context, '✅ Deadline added!');
        context.go('/admin/content');
      }
    } catch (e) {
      if (mounted) AppSnackBar.error(context, 'Failed to create: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _notifyStudents(String id, String title, DateTime dueDate) async {
    try {
      final students = await _client.from('profiles').select('id').eq('role', 'student').eq('branch', _branch).eq('year', _year);
      final notifs = (students as List).map((s) => {
        'user_id': s['id'],
        'title': 'New Deadline: $title',
        'body': 'Due: ${dueDate.toIso8601String().split('T')[0]}',
        'type': 'deadline',
        'priority': _priority,
        'reference_id': id,
        'reference_type': 'deadline',
        'is_read': false,
      }).toList();
      if (notifs.isNotEmpty) {
        await _client.from('notifications').insert(notifs);
      }
    } catch (e) {
      debugPrint('Deadline notify error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Deadline', style: AppTextStyles.h3),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.canPop() ? context.pop() : context.go('/admin/content'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppTextField(
                label: 'Task / Assignment Title',
                hint: 'e.g. Mini Project Submission',
                controller: _titleCtrl,
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Subject Name',
                hint: 'e.g. Software Engineering',
                controller: _subjectCtrl,
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Details (optional)',
                hint: 'Additional instructions...',
                controller: _descCtrl,
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Due Date
              AppTextField(
                label: 'Due Date & Time',
                hint: 'Select deadline',
                controller: TextEditingController(text: _dueDate.toIso8601String().replaceAll('T', ' ').substring(0, 16)),
                readOnly: true,
                onTap: _pickDate,
                prefix: const Icon(LucideIcons.clock, size: 18),
              ),
              const SizedBox(height: 16),

              // Branch + Year
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
                          isExpanded: true,
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

              // Priority
              Text('Priority', style: AppTextStyles.label.copyWith(color: AppColors.textMuted)),
              const SizedBox(height: 8),
              Row(
                children: _priorities.map((p) {
                  final selected = _priority == p;
                  final colors = {
                    'low': AppColors.success,
                    'medium': AppColors.accent,
                    'high': AppColors.warning,
                    'urgent': AppColors.danger,
                  };
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _priority = p),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: selected ? colors[p]!.withOpacity(0.15) : Colors.transparent,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: selected ? colors[p]! : AppColors.textMuted.withOpacity(0.3),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              p.toUpperCase(),
                              style: AppTextStyles.caption.copyWith(
                                color: selected ? colors[p] : AppColors.textMuted,
                                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 32),
              AppButton(
                label: 'Add Deadline',
                onPressed: _submit,
                isLoading: _loading,
                width: double.infinity,
                icon: LucideIcons.plusCircle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
