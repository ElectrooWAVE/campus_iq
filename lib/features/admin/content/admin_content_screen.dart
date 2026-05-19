import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/delete_confirm_dialog.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../data/models/announcement_model.dart';
import '../../../data/models/deadline_model.dart';
import '../../../data/models/pdf_note_model.dart';
import '../../../data/models/timetable_model.dart';
import '../../../data/repositories/announcement_repository.dart';
import '../../../data/repositories/deadline_repository.dart';
import '../../../data/repositories/knowledge_repository.dart';
import '../../../data/repositories/notes_repository.dart';
import '../../../data/repositories/notification_repository.dart';
import '../../../data/repositories/timetable_repository.dart';
import '../../../data/services/storage_service.dart';
import '../widgets/admin_bottom_nav.dart';

class AdminContentScreen extends StatefulWidget {
  const AdminContentScreen({super.key});

  @override
  State<AdminContentScreen> createState() => _AdminContentScreenState();
}

class _AdminContentScreenState extends State<AdminContentScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Content Management', style: AppTextStyles.h3),
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: const [
            Tab(text: 'Timetable'),
            Tab(text: 'PDF Notes'),
            Tab(text: 'Announce.'),
          ],
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          labelStyle: AppTextStyles.label,
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: const [
          _TimetableTab(),
          _PdfNotesTab(),
          _AnnouncementsTab(),
        ],
      ),
      bottomNavigationBar: const AdminBottomNav(currentIndex: 1),
    );
  }
}

// ─────────────── TIMETABLE TAB ───────────────
class _TimetableTab extends StatefulWidget {
  const _TimetableTab();

  @override
  State<_TimetableTab> createState() => _TimetableTabState();
}

class _TimetableTabState extends State<_TimetableTab> {
  final _repo = TimetableRepository();
  final _storage = StorageService();
  List<TimetableModel> _entries = [];
  bool _loading = true;
  int? _yearFilter;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _entries = await _repo.getAll(year: _yearFilter);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _delete(TimetableModel entry) async {
    final confirmed = await showDeleteConfirmDialog(context, 'timetable entry');
    if (!confirmed) return;

    // Optimistic remove
    setState(() => _entries.removeWhere((e) => e.id == entry.id));

    await _storage.deleteFile('timetable-images', entry.storagePath);
    await _repo.delete(entry.id);
    if (mounted) AppSnackBar.success(context, 'Timetable deleted successfully');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _YearFilterBar(
            selected: _yearFilter,
            onSelect: (y) {
              setState(() => _yearFilter = y);
              _load();
            },
          ),
          Expanded(
            child: _loading
                ? const SkeletonListView(count: 4)
                : _entries.isEmpty
                    ? const EmptyState(message: 'No timetables yet', icon: LucideIcons.calendar)
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _entries.length,
                          itemBuilder: (_, i) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _TimetableListCard(
                              entry: _entries[i],
                              onEdit: () => context.go('/admin/timetable/edit/${_entries[i].id}'),
                              onDelete: () => _delete(_entries[i]),
                            ),
                          ),
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => context.go('/admin/timetable/upload'),
        child: const Icon(LucideIcons.plus, color: Colors.white),
      ),
    );
  }
}

class _TimetableListCard extends StatelessWidget {
  final TimetableModel entry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TimetableListCard({required this.entry, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: entry.imageUrl,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              placeholder: (_, __) => const SkeletonLoader(width: 60, height: 60, borderRadius: 8),
              errorWidget: (_, __, ___) => Container(
                width: 60, height: 60, color: AppColors.background,
                child: const Icon(LucideIcons.image, size: 24),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.title, style: AppTextStyles.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 4,
                  children: [
                    AppBadge.branch(entry.branch),
                    AppBadge.year(entry.year),
                    AppBadge(
                      label: AppDateUtils.formatDate(entry.effectiveDate),
                      color: AppColors.textMuted.withOpacity(0.1),
                      textColor: AppColors.textMuted,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(icon: const Icon(LucideIcons.pencil, color: AppColors.primary, size: 18), onPressed: onEdit),
              IconButton(icon: const Icon(LucideIcons.trash2, color: AppColors.danger, size: 18), onPressed: onDelete),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────── PDF NOTES TAB ───────────────
class _PdfNotesTab extends StatefulWidget {
  const _PdfNotesTab();

  @override
  State<_PdfNotesTab> createState() => _PdfNotesTabState();
}

class _PdfNotesTabState extends State<_PdfNotesTab> {
  final _repo = NotesRepository();
  final _storage = StorageService();
  final _kbRepo = KnowledgeRepository();
  final _notifRepo = NotificationRepository();
  List<PdfNoteModel> _notes = [];
  bool _loading = true;
  int? _yearFilter;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _notes = await _repo.getAll(year: _yearFilter);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _delete(PdfNoteModel note) async {
    final confirmed = await showDeleteConfirmDialog(context, 'PDF note');
    if (!confirmed) return;

    setState(() => _notes.removeWhere((n) => n.id == note.id));

    await _storage.deleteFile('pdf-notes', note.storagePath);
    await _kbRepo.deleteBySourceId(note.id, 'pdf_note');
    await _repo.delete(note.id);

    if (mounted) AppSnackBar.success(context, 'PDF note and knowledge base entry deleted');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _YearFilterBar(
            selected: _yearFilter,
            onSelect: (y) {
              setState(() => _yearFilter = y);
              _load();
            },
          ),
          Expanded(
            child: _loading
                ? const SkeletonListView(count: 4)
                : _notes.isEmpty
                    ? const EmptyState(message: 'No PDF notes yet', icon: LucideIcons.fileText)
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _notes.length,
                          itemBuilder: (_, i) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _PdfNoteListCard(
                              note: _notes[i],
                              onEdit: () => context.go('/admin/notes/edit/${_notes[i].id}'),
                              onDelete: () => _delete(_notes[i]),
                            ),
                          ),
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => context.go('/admin/notes/upload'),
        child: const Icon(LucideIcons.plus, color: Colors.white),
      ),
    );
  }
}

class _PdfNoteListCard extends StatelessWidget {
  final PdfNoteModel note;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PdfNoteListCard({required this.note, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          const Icon(LucideIcons.fileText, color: AppColors.danger, size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(note.title, style: AppTextStyles.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 4,
                  children: [
                    AppBadge(label: note.subjectName, color: AppColors.accent.withOpacity(0.1), textColor: AppColors.accent),
                    AppBadge.branch(note.branch),
                    AppBadge.year(note.year),
                  ],
                ),
                Text(note.fileName, style: AppTextStyles.caption.copyWith(color: AppColors.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(icon: const Icon(LucideIcons.pencil, color: AppColors.primary, size: 18), onPressed: onEdit),
              IconButton(icon: const Icon(LucideIcons.trash2, color: AppColors.danger, size: 18), onPressed: onDelete),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────── ANNOUNCEMENTS TAB ───────────────
class _AnnouncementsTab extends StatefulWidget {
  const _AnnouncementsTab();

  @override
  State<_AnnouncementsTab> createState() => _AnnouncementsTabState();
}

class _AnnouncementsTabState extends State<_AnnouncementsTab>
    with SingleTickerProviderStateMixin {
  late TabController _innerTab;
  final _announcementRepo = AnnouncementRepository();
  final _deadlineRepo = DeadlineRepository();
  final _storage = StorageService();
  final _notifRepo = NotificationRepository();

  List<AnnouncementModel> _announcements = [];
  List<DeadlineModel> _deadlines = [];
  bool _loading = true;
  int? _deadlineYearFilter;

  @override
  void initState() {
    super.initState();
    _innerTab = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _innerTab.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _announcementRepo.getAll(),
        _deadlineRepo.getAll(year: _deadlineYearFilter),
      ]);
      _announcements = results[0] as List<AnnouncementModel>;
      _deadlines = results[1] as List<DeadlineModel>;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteAnnouncement(AnnouncementModel a) async {
    final confirmed = await showDeleteConfirmDialog(context, 'announcement');
    if (!confirmed) return;

    setState(() => _announcements.removeWhere((x) => x.id == a.id));

    if (a.storagePath != null) {
      await _storage.deleteFile('announcement-images', a.storagePath!);
    }
    await _notifRepo.deleteByReferenceId(a.id);
    await _announcementRepo.delete(a.id);

    if (mounted) AppSnackBar.success(context, 'Announcement deleted');
  }

  Future<void> _deleteDeadline(DeadlineModel d) async {
    final confirmed = await showDeleteConfirmDialog(context, 'deadline');
    if (!confirmed) return;

    setState(() => _deadlines.removeWhere((x) => x.id == d.id));

    await _notifRepo.deleteByReferenceId(d.id);
    await _deadlineRepo.delete(d.id);

    if (mounted) AppSnackBar.success(context, 'Deadline deleted');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _innerTab,
          tabs: const [Tab(text: 'Announcements'), Tab(text: 'Deadlines')],
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          labelStyle: AppTextStyles.label,
        ),
        Expanded(
          child: TabBarView(
            controller: _innerTab,
            children: [
              // Announcements
              Scaffold(
                body: _loading
                    ? const SkeletonListView(count: 4)
                    : _announcements.isEmpty
                        ? const EmptyState(message: 'No announcements', icon: LucideIcons.megaphone)
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _announcements.length,
                              itemBuilder: (_, i) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _AnnouncementListCard(
                                  announcement: _announcements[i],
                                  onEdit: () => context.go('/admin/announcements/edit/${_announcements[i].id}'),
                                  onDelete: () => _deleteAnnouncement(_announcements[i]),
                                  onTogglePublish: () async {
                                    final a = _announcements[i];
                                    await _announcementRepo.togglePublish(a.id, !a.isPublished);
                                    await _load();
                                  },
                                ),
                              ),
                            ),
                          ),
                floatingActionButton: FloatingActionButton(
                  backgroundColor: AppColors.primary,
                  onPressed: () => context.go('/admin/announcements/create'),
                  child: const Icon(LucideIcons.plus, color: Colors.white),
                ),
              ),
              // Deadlines
              Scaffold(
                body: Column(
                  children: [
                    _YearFilterBar(
                      selected: _deadlineYearFilter,
                      onSelect: (y) {
                        setState(() => _deadlineYearFilter = y);
                        _load();
                      },
                    ),
                    Expanded(
                      child: _loading
                          ? const SkeletonListView(count: 4)
                          : _deadlines.isEmpty
                              ? const EmptyState(message: 'No deadlines', icon: LucideIcons.clock)
                              : RefreshIndicator(
                                  onRefresh: _load,
                                  child: ListView.builder(
                                    padding: const EdgeInsets.all(16),
                                    itemCount: _deadlines.length,
                                    itemBuilder: (_, i) => Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: _DeadlineListCard(
                                        deadline: _deadlines[i],
                                        onEdit: () => context.go('/admin/deadlines/edit/${_deadlines[i].id}'),
                                        onDelete: () => _deleteDeadline(_deadlines[i]),
                                      ),
                                    ),
                                  ),
                                ),
                    ),
                  ],
                ),
                floatingActionButton: FloatingActionButton(
                  backgroundColor: AppColors.primary,
                  onPressed: () => context.go('/admin/deadlines/create'),
                  child: const Icon(LucideIcons.plus, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AnnouncementListCard extends StatelessWidget {
  final AnnouncementModel announcement;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTogglePublish;

  const _AnnouncementListCard({
    required this.announcement,
    required this.onEdit,
    required this.onDelete,
    required this.onTogglePublish,
  });

  @override
  Widget build(BuildContext context) {
    final a = announcement;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppBadge.priority(a.priority),
              const Spacer(),
              if (a.imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: CachedNetworkImage(
                    imageUrl: a.imageUrl!,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(a.title, style: AppTextStyles.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(a.body, style: AppTextStyles.caption.copyWith(color: AppColors.textMuted), maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(
            a.branch != null ? '${a.branch} — ${a.year != null ? "Year ${a.year}" : "All Years"}' : 'All Students',
            style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton.icon(
                icon: const Icon(LucideIcons.pencil, size: 14),
                label: const Text('Edit'),
                onPressed: onEdit,
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              ),
              TextButton.icon(
                icon: const Icon(LucideIcons.trash2, size: 14),
                label: const Text('Delete'),
                onPressed: onDelete,
                style: TextButton.styleFrom(foregroundColor: AppColors.danger),
              ),
              if (!a.isPublished)
                TextButton(
                  onPressed: onTogglePublish,
                  child: const Text('Publish'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DeadlineListCard extends StatelessWidget {
  final DeadlineModel deadline;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _DeadlineListCard({required this.deadline, required this.onEdit, required this.onDelete});

  Color get _borderColor {
    switch (deadline.priority) {
      case 'urgent': return AppColors.danger;
      case 'high': return AppColors.warning;
      case 'medium': return AppColors.accent;
      default: return AppColors.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      border: Border(left: BorderSide(color: _borderColor, width: 4)),
      borderRadius: 12,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(deadline.title, style: AppTextStyles.bodyMedium),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    children: [
                      AppBadge(label: deadline.subjectName, color: AppColors.primary.withOpacity(0.1), textColor: AppColors.primary),
                      AppBadge.branch(deadline.branch),
                      AppBadge.year(deadline.year),
                    ],
                  ),
                  Text(AppDateUtils.formatCountdown(deadline.dueDate),
                      style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(icon: const Icon(LucideIcons.pencil, color: AppColors.primary, size: 18), onPressed: onEdit),
                IconButton(icon: const Icon(LucideIcons.trash2, color: AppColors.danger, size: 18), onPressed: onDelete),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────── SHARED: Year Filter Bar ───────────────
class _YearFilterBar extends StatelessWidget {
  final int? selected;
  final void Function(int?) onSelect;

  const _YearFilterBar({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _FilterChip(label: 'All', selected: selected == null, onTap: () => onSelect(null)),
          ...List.generate(4, (i) => _FilterChip(
            label: '${i + 1}${_suffix(i + 1)} Year',
            selected: selected == i + 1,
            onTap: () => onSelect(i + 1),
          )),
        ],
      ),
    );
  }

  String _suffix(int y) {
    if (y == 1) return 'st';
    if (y == 2) return 'nd';
    if (y == 3) return 'rd';
    return 'th';
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label, style: AppTextStyles.label.copyWith(
          color: selected ? Colors.white : AppColors.textMuted,
        )),
        selected: selected,
        selectedColor: AppColors.primary,
        backgroundColor: Colors.transparent,
        side: BorderSide(color: selected ? AppColors.primary : AppColors.textMuted.withOpacity(0.3)),
        onSelected: (_) => onTap(),
      ),
    );
  }
}
