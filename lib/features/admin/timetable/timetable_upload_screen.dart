import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../data/repositories/timetable_repository.dart';
import '../../../data/services/storage_service.dart';
import '../../auth/providers/auth_provider.dart';

class TimetableUploadScreen extends StatefulWidget {
  const TimetableUploadScreen({super.key});

  @override
  State<TimetableUploadScreen> createState() => _TimetableUploadScreenState();
}

class _TimetableUploadScreenState extends State<TimetableUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _repo = TimetableRepository();
  final _storage = StorageService();
  final _picker = ImagePicker();

  String _branch = AppConstants.branches.first;
  int _year = 1;
  DateTime _effectiveDate = DateTime.now();
  Uint8List? _imageBytes;
  String? _imageExtension;
  bool _loading = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    final ext = picked.path.split('.').last.toLowerCase();
    setState(() {
      _imageBytes = bytes;
      _imageExtension = ext == 'jpg' ? 'jpeg' : ext;
    });
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageBytes == null) {
      AppSnackBar.error(context, 'Please select a timetable image');
      return;
    }

    setState(() => _loading = true);
    try {
      final admin = context.read<AuthProvider>().profile!;
      final result = await _storage.uploadImage(
        'timetable-images',
        admin.branch,
        _imageBytes!,
        _imageExtension!,
      );

      await _repo.insert({
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        'image_url': result['url'],
        'storage_path': result['path'],
        'branch': _branch,
        'year': _year,
        'effective_date': _effectiveDate.toIso8601String().split('T')[0],
        'posted_by': admin.id,
      });

      if (mounted) {
        AppSnackBar.success(context, 'Timetable uploaded successfully!');
        context.go('/admin/content');
      }
    } catch (e) {
      if (mounted) AppSnackBar.error(context, 'Upload failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Upload Timetable', style: AppTextStyles.h3),
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
                label: 'Timetable Title',
                hint: 'e.g. CSE 3rd Year — Mon–Sat',
                controller: _titleCtrl,
                validator: (v) => (v == null || v.isEmpty) ? 'Title is required' : null,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Description (optional)',
                hint: 'Any notes about this timetable',
                controller: _descCtrl,
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Branch and Year
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
                              .map((b) => DropdownMenuItem(value: b, child: Text(b, style: AppTextStyles.body)))
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

              // Date picker
              AppTextField(
                label: 'Effective Date',
                hint: 'Pick a date',
                controller: TextEditingController(text: _effectiveDate.toIso8601String().split('T')[0]),
                readOnly: true,
                onTap: _pickDate,
                prefix: const Icon(LucideIcons.calendar, size: 18),
              ),
              const SizedBox(height: 24),

              // Image picker
              Text('Timetable Image', style: AppTextStyles.label.copyWith(color: AppColors.textMuted)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickImage,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  height: 180,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _imageBytes != null ? AppColors.primary : AppColors.textMuted.withOpacity(0.3),
                      width: _imageBytes != null ? 2 : 1,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: _imageBytes != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.memory(_imageBytes!, fit: BoxFit.cover),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.imagePlus, size: 36, color: AppColors.primary.withOpacity(0.6)),
                            const SizedBox(height: 8),
                            Text('Tap to select image from gallery', style: AppTextStyles.body.copyWith(color: AppColors.textMuted)),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 32),
              AppButton(
                label: 'Upload Timetable',
                onPressed: _submit,
                isLoading: _loading,
                width: double.infinity,
                icon: LucideIcons.upload,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
