import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../data/repositories/announcement_repository.dart';
import '../../../data/repositories/notification_repository.dart';
import '../../../data/services/storage_service.dart';
import '../../auth/providers/auth_provider.dart';

class CreateAnnouncementScreen extends StatefulWidget {
  const CreateAnnouncementScreen({super.key});

  @override
  State<CreateAnnouncementScreen> createState() => _CreateAnnouncementScreenState();
}

class _CreateAnnouncementScreenState extends State<CreateAnnouncementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  final _repo = AnnouncementRepository();
  final _notifRepo = NotificationRepository();
  final _storage = StorageService();
  final _client = Supabase.instance.client;
  final _picker = ImagePicker();

  String _priority = 'general';
  String? _branch;
  int? _year;
  bool _allStudents = true;
  bool _isPublished = true;
  Uint8List? _imageBytes;
  String? _imageExt;
  bool _loading = false;

  static const _priorities = ['general', 'important', 'urgent'];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() {
      _imageBytes = bytes;
      _imageExt = picked.path.split('.').last == 'jpg' ? 'jpeg' : picked.path.split('.').last;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_allStudents && _branch == null) {
      AppSnackBar.error(context, 'Please select a target branch');
      return;
    }

    setState(() => _loading = true);
    try {
      final admin = context.read<AuthProvider>().profile!;

      String? imageUrl;
      String? storagePath;

      if (_imageBytes != null) {
        final result = await _storage.uploadImage(
          'announcement-images',
          'announcements',
          _imageBytes!,
          _imageExt!,
        );
        imageUrl = result['url'];
        storagePath = result['path'];
      }

      final announcement = await _repo.insert({
        'title': _titleCtrl.text.trim(),
        'body': _bodyCtrl.text.trim(),
        'image_url': imageUrl,
        'storage_path': storagePath,
        'priority': _priority,
        'branch': _allStudents ? null : _branch,
        'year': _allStudents ? null : _year,
        'is_published': _isPublished,
        'created_by': admin.id,
      });

      // Send notifications if published
      if (_isPublished) {
        await _notifyStudents(announcement.id, _titleCtrl.text.trim(), _bodyCtrl.text.trim());
      }

      if (mounted) {
        AppSnackBar.success(context, '✅ Announcement posted!');
        context.go('/admin/content');
      }
    } catch (e) {
      if (mounted) AppSnackBar.error(context, 'Failed to post: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _notifyStudents(String id, String title, String body) async {
    try {
      // Get matching students
      var query = _client.from('profiles').select('id').eq('role', 'student');
      if (!_allStudents && _branch != null) {
        query = query.eq('branch', _branch!) as dynamic;
        if (_year != null) query = query.eq('year', _year!) as dynamic;
      }
      final students = await query;

      // Bulk insert notifications
      final notifs = (students as List).map((s) => {
        'user_id': s['id'],
        'title': 'New Announcement: $title',
        'body': body,
        'type': 'announcement',
        'priority': _priority,
        'reference_id': id,
        'reference_type': 'announcement',
        'is_read': false,
      }).toList();

      if (notifs.isNotEmpty) {
        await _client.from('notifications').insert(notifs);
      }
    } catch (e) {
      debugPrint('Notification insert error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Post Announcement', style: AppTextStyles.h3),
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
                label: 'Title',
                hint: 'Brief, descriptive headline',
                controller: _titleCtrl,
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Message Body',
                hint: 'Full details of the announcement...',
                controller: _bodyCtrl,
                maxLines: 5,
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // Priority
              Text('Priority', style: AppTextStyles.label.copyWith(color: AppColors.textMuted)),
              const SizedBox(height: 8),
              Row(
                children: _priorities.map((p) {
                  final selected = _priority == p;
                  final colors = {
                    'general': AppColors.textMuted,
                    'important': AppColors.warning,
                    'urgent': AppColors.danger,
                  };
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _priority = p),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: selected ? colors[p]!.withOpacity(0.12) : Colors.transparent,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: selected ? colors[p]! : AppColors.textMuted.withOpacity(0.3),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              p.toUpperCase(),
                              style: AppTextStyles.label.copyWith(
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

              const SizedBox(height: 16),

              // Audience toggle
              SwitchListTile(
                value: _allStudents,
                onChanged: (v) => setState(() => _allStudents = v),
                title: Text('Broadcast to All Students', style: AppTextStyles.bodyMedium),
                subtitle: Text(
                  _allStudents ? 'All students will receive this' : 'Target specific branch/year',
                  style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
                ),
                activeColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
              ),

              if (!_allStudents) ...[
                const SizedBox(height: 12),
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
                            hint: const Text('Select'),
                            decoration: const InputDecoration(),
                            isExpanded: true,
                            items: AppConstants.branches
                                .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                                .toList(),
                            onChanged: (v) => setState(() => _branch = v),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Year (opt.)', style: AppTextStyles.label.copyWith(color: AppColors.textMuted)),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<int>(
                            value: _year,
                            hint: const Text('All'),
                            decoration: const InputDecoration(),
                            items: [1, 2, 3, 4]
                                .map((y) => DropdownMenuItem(value: y, child: Text('Year $y')))
                                .toList(),
                            onChanged: (v) => setState(() => _year = v),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 16),

              // Optional image
              Text('Image (optional)', style: AppTextStyles.label.copyWith(color: AppColors.textMuted)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity,
                  height: 140,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.textMuted.withOpacity(0.3)),
                  ),
                  child: _imageBytes != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.memory(_imageBytes!, fit: BoxFit.cover),
                        )
                      : const Center(
                          child: Icon(LucideIcons.imagePlus, size: 36, color: AppColors.textMuted),
                        ),
                ),
              ),

              const SizedBox(height: 16),
              SwitchListTile(
                value: _isPublished,
                onChanged: (v) => setState(() => _isPublished = v),
                title: Text('Publish Immediately', style: AppTextStyles.bodyMedium),
                activeColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
              ),

              const SizedBox(height: 32),
              AppButton(
                label: 'Post Announcement',
                onPressed: _submit,
                isLoading: _loading,
                width: double.infinity,
                icon: LucideIcons.megaphone,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
