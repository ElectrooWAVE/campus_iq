import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../data/repositories/knowledge_repository.dart';
import '../../../data/repositories/notes_repository.dart';
import '../../../data/services/gemini_service.dart';
import '../../../data/services/storage_service.dart';
import '../../auth/providers/auth_provider.dart';

class NotesUploadScreen extends StatefulWidget {
  const NotesUploadScreen({super.key});

  @override
  State<NotesUploadScreen> createState() => _NotesUploadScreenState();
}

class _NotesUploadScreenState extends State<NotesUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final _repo = NotesRepository();
  final _kbRepo = KnowledgeRepository();
  final _storage = StorageService();
  final _gemini = GeminiService();

  String _branch = AppConstants.branches.first;
  int _year = 1;
  Uint8List? _pdfBytes;
  String? _pdfName;
  bool _loading = false;
  String _status = '';

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _subjectCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    setState(() {
      _pdfBytes = file.bytes;
      _pdfName = file.name;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pdfBytes == null) {
      AppSnackBar.error(context, 'Please select a PDF file');
      return;
    }

    setState(() { _loading = true; _status = 'Uploading PDF...'; });

    try {
      final admin = context.read<AuthProvider>().profile!;

      final result = await _storage.uploadPdf(admin.branch, _pdfBytes!, _pdfName!);

      setState(() => _status = 'Saving to database...');

      final note = await _repo.insert({
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        'file_url': result['url'],
        'storage_path': result['path'],
        'file_name': _pdfName,
        'subject_name': _subjectCtrl.text.trim(),
        'branch': _branch,
        'year': _year,
        'uploaded_by': admin.id,
      });

      // Vectorize for RAG
      setState(() => _status = 'Vectorizing for AI assistant...');
      final kbContent = 'Subject: ${_subjectCtrl.text.trim()}\n'
          'Title: ${_titleCtrl.text.trim()}\n'
          '${_descCtrl.text.trim().isNotEmpty ? "Description: ${_descCtrl.text.trim()}\n" : ""}'
          'Branch: $_branch\nYear: $_year';

      final embedding = await _gemini.embedText(kbContent);

      await _kbRepo.insert({
        'title': _titleCtrl.text.trim(),
        'content': kbContent,
        'category': 'notes',
        'source_id': note.id,
        'source_type': 'pdf_note',
        'branch': _branch,
        'year': _year,
        'added_by': admin.id,
      });

      await _kbRepo.updateEmbedding(note.id, embedding);

      if (mounted) {
        AppSnackBar.success(context, '✅ PDF uploaded and vectorized for AI assistant!');
        context.go('/admin/content');
      }
    } catch (e) {
      if (mounted) AppSnackBar.error(context, 'Upload failed: $e');
    } finally {
      if (mounted) setState(() { _loading = false; _status = ''; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Upload PDF Notes', style: AppTextStyles.h3),
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
                label: 'Note Title',
                hint: 'e.g. Discrete Mathematics — Chapter 3',
                controller: _titleCtrl,
                validator: (v) => (v == null || v.isEmpty) ? 'Title is required' : null,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Subject Name',
                hint: 'e.g. Discrete Mathematics',
                controller: _subjectCtrl,
                validator: (v) => (v == null || v.isEmpty) ? 'Subject is required' : null,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Description (optional)',
                hint: 'Brief overview of what this PDF covers',
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
              const SizedBox(height: 24),

              // PDF picker
              GestureDetector(
                onTap: _pickPdf,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _pdfBytes != null ? AppColors.danger : AppColors.textMuted.withOpacity(0.3),
                      width: _pdfBytes != null ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _pdfBytes != null ? LucideIcons.fileCheck : LucideIcons.filePlus,
                        size: 36,
                        color: _pdfBytes != null ? AppColors.danger : AppColors.textMuted,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _pdfName ?? 'Tap to select PDF',
                        style: AppTextStyles.body.copyWith(
                          color: _pdfBytes != null ? AppColors.textPrimary : AppColors.textMuted,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),

              if (_status.isNotEmpty) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Text(_status, style: AppTextStyles.body.copyWith(color: AppColors.primary)),
                  ],
                ),
              ],

              const SizedBox(height: 32),
              AppButton(
                label: 'Upload & Vectorize',
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
