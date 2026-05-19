import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/delete_confirm_dialog.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../data/models/knowledge_doc_model.dart';
import '../../../data/repositories/knowledge_repository.dart';
import '../../../data/services/gemini_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../widgets/admin_bottom_nav.dart';

class KnowledgeBaseScreen extends StatefulWidget {
  const KnowledgeBaseScreen({super.key});

  @override
  State<KnowledgeBaseScreen> createState() => _KnowledgeBaseScreenState();
}

class _KnowledgeBaseScreenState extends State<KnowledgeBaseScreen> {
  final _repo = KnowledgeRepository();
  final _gemini = GeminiService();
  List<KnowledgeDocModel> _docs = [];
  bool _loading = true;
  String _categoryFilter = 'all';

  static const _categories = ['all', 'notes', 'policy', 'faq', 'event', 'other'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _docs = await _repo.getAll(category: _categoryFilter == 'all' ? null : _categoryFilter);
    } catch (e) {
      debugPrint('KB load error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _delete(KnowledgeDocModel doc) async {
    final confirmed = await showDeleteConfirmDialog(context, 'knowledge base entry');
    if (!confirmed) return;

    setState(() => _docs.removeWhere((d) => d.id == doc.id));
    await _repo.delete(doc.id);
    if (mounted) AppSnackBar.success(context, 'Entry deleted');
  }

  void _showAddDialog() {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    String category = 'faq';
    String? branch;
    int? year;
    bool adding = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            Future<void> save() async {
              if (titleCtrl.text.trim().isEmpty || contentCtrl.text.trim().isEmpty) return;
              setSheetState(() => adding = true);

              final admin = context.read<AuthProvider>().profile!;
              final content = contentCtrl.text.trim();

              try {
                final embedding = await _gemini.embedText(content);
                final doc = await _repo.insert({
                  'title': titleCtrl.text.trim(),
                  'content': content,
                  'category': category,
                  'branch': branch,
                  'year': year,
                  'added_by': admin.id,
                });
                await _repo.updateEmbedding(doc.id, embedding);

                if (mounted) {
                  Navigator.pop(ctx);
                  AppSnackBar.success(context, '✅ Knowledge entry added and vectorized');
                  _load();
                }
              } catch (e) {
                if (mounted) AppSnackBar.error(context, 'Failed: $e');
              } finally {
                setSheetState(() => adding = false);
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
                top: 24,
                left: 24,
                right: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Add Knowledge Entry', style: AppTextStyles.h3),
                      IconButton(icon: const Icon(LucideIcons.x), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  AppTextField(label: 'Title', controller: titleCtrl, hint: 'Short descriptive title'),
                  const SizedBox(height: 12),
                  AppTextField(label: 'Content', controller: contentCtrl, hint: 'Full content to vectorize...', maxLines: 4),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: category,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: _categories.where((c) => c != 'all').map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (v) => setSheetState(() => category = v!),
                  ),
                  const SizedBox(height: 16),
                  AppButton(
                    label: 'Add & Vectorize',
                    onPressed: save,
                    isLoading: adding,
                    width: double.infinity,
                    icon: LucideIcons.sparkles,
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Knowledge Base (${_docs.length})', style: AppTextStyles.h3),
      ),
      body: Column(
        children: [
          // Category filter
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: _categories.map((c) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(c.toUpperCase(), style: AppTextStyles.caption.copyWith(
                    color: _categoryFilter == c ? Colors.white : AppColors.textMuted,
                  )),
                  selected: _categoryFilter == c,
                  selectedColor: AppColors.primary,
                  backgroundColor: Colors.transparent,
                  side: BorderSide(color: _categoryFilter == c ? AppColors.primary : AppColors.textMuted.withOpacity(0.3)),
                  onSelected: (_) {
                    setState(() => _categoryFilter = c);
                    _load();
                  },
                ),
              )).toList(),
            ),
          ),
          Expanded(
            child: _loading
                ? const SkeletonListView(count: 5)
                : _docs.isEmpty
                    ? const EmptyState(
                        message: 'Knowledge base is empty',
                        submessage: 'Add entries to power the AI assistant',
                        icon: LucideIcons.database,
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _docs.length,
                          itemBuilder: (_, i) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _KbDocCard(
                              doc: _docs[i],
                              onDelete: () => _delete(_docs[i]),
                            ),
                          ),
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: _showAddDialog,
        child: const Icon(LucideIcons.plus, color: Colors.white),
      ),
    );
  }
}

class _KbDocCard extends StatefulWidget {
  final KnowledgeDocModel doc;
  final VoidCallback onDelete;

  const _KbDocCard({required this.doc, required this.onDelete});

  @override
  State<_KbDocCard> createState() => _KbDocCardState();
}

class _KbDocCardState extends State<_KbDocCard> {
  bool _expanded = false;

  String get _categoryColor {
    switch (widget.doc.category) {
      case 'policy': return '#EF4444';
      case 'faq': return '#8B5CF6';
      case 'event': return '#F59E0B';
      case 'notes': return '#EF4444';
      default: return '#6B7280';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppBadge(
                label: widget.doc.category?.toUpperCase() ?? 'GENERAL',
                color: AppColors.accent.withOpacity(0.12),
                textColor: AppColors.accent,
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(LucideIcons.trash2, size: 16, color: AppColors.danger),
                onPressed: widget.onDelete,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(widget.doc.title, style: AppTextStyles.bodyMedium),
          if (_expanded) ...[
            const SizedBox(height: 8),
            Text(widget.doc.content, style: AppTextStyles.body.copyWith(color: AppColors.textMuted)),
            if (widget.doc.branch != null) ...[
              const SizedBox(height: 4),
              AppBadge.branch(widget.doc.branch!),
            ],
          ] else ...[
            Text(
              widget.doc.content,
              style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
