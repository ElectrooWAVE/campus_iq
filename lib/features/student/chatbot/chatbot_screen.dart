import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../data/services/gemini_service.dart';
import '../../../data/services/groq_service.dart';
import '../../../data/services/rag_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../widgets/student_bottom_nav.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _ragService = RagService();
  final _groqService = GroqService();
  final _client = Supabase.instance.client;

  List<_ChatMessage> _messages = [];
  bool _isTyping = false;
  String? _conversationId;
  List<Map<String, String>> _history = [];

  static const _quickChips = [
    "What's my timetable this week?",
    'What assignments are due?',
    'What are the college rules?',
    'Tell me about upcoming exams',
  ];

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _clearChat() {
    setState(() {
      _messages = [];
      _history = [];
      _conversationId = null;
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    final cleaned = text.trim().replaceAll(RegExp(r'<[^>]*>'), '');
    if (cleaned.isEmpty || cleaned.length > 500) return;

    final auth = context.read<AuthProvider>();
    final profile = auth.profile!;

    setState(() {
      _messages.add(_ChatMessage(text: cleaned, isUser: true));
      _isTyping = true;
      _inputCtrl.clear();
    });
    _scrollToBottom();

    try {
      // RAG: embed → pgvector
      final context_ = await _ragService.retrieveContext(
        query: cleaned,
        branch: profile.branch,
        year: profile.year!,
      );

      String aiResponse;
      if (context_ == null) {
        // Fallback — 0 results, skip Groq
        aiResponse = "I don't have that information. Please contact your ${profile.branch} department office directly.";
      } else {
        aiResponse = await _groqService.chatWithGroq(cleaned, context_, _history);
      }

      final userMsg = {'role': 'user', 'content': cleaned};
      final aiMsg = {'role': 'assistant', 'content': aiResponse};
      _history.add(userMsg);
      _history.add(aiMsg);

      setState(() {
        _messages.add(_ChatMessage(
          text: aiResponse,
          isUser: false,
          showBookmark: true,
          onBookmark: () => _saveAnswer(cleaned, aiResponse, profile.id),
        ));
        _isTyping = false;
      });

      // Save conversation
      await _saveConversation(profile.id, userMsg, aiMsg);
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _messages.add(const _ChatMessage(
          text: "I'm having trouble right now. Try again in a moment.",
          isUser: false,
        ));
        _isTyping = false;
      });
    }
  }

  Future<void> _saveConversation(
    String studentId,
    Map<String, String> userMsg,
    Map<String, String> aiMsg,
  ) async {
    try {
      if (_conversationId == null) {
        final result = await _client.from('chatbot_conversations').insert({
          'student_id': studentId,
          'messages': [userMsg, aiMsg],
        }).select().single();
        _conversationId = result['id'] as String;
      } else {
        final existing = await _client
            .from('chatbot_conversations')
            .select('messages')
            .eq('id', _conversationId!)
            .single();
        final msgs = List<dynamic>.from(existing['messages'] as List)
          ..add(userMsg)
          ..add(aiMsg);
        await _client.from('chatbot_conversations').update({
          'messages': msgs,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', _conversationId!);
      }
    } catch (e) {
      debugPrint('Save conversation error: $e');
    }
  }

  Future<void> _saveAnswer(String question, String answer, String studentId) async {
    try {
      await _client.from('saved_answers').insert({
        'student_id': studentId,
        'question': question,
        'answer': answer,
        'saved_at': DateTime.now().toIso8601String(),
      });
      if (mounted) AppSnackBar.success(context, '✅ Answer saved to your profile');
    } catch (e) {
      if (mounted) AppSnackBar.error(context, 'Could not save answer');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('CampusIQ Assistant', style: AppTextStyles.h3),
            Text(
              'Answers only from verified college information',
              style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.rotateCcw),
            tooltip: 'Clear chat',
            onPressed: _clearChat,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length + (_isTyping ? 1 : 0),
                    itemBuilder: (_, i) {
                      if (_isTyping && i == _messages.length) {
                        return const _TypingIndicator();
                      }
                      return _messages[i];
                    },
                  ),
          ),
          _buildInputBar(isDark),
        ],
      ),
      bottomNavigationBar: const StudentBottomNav(currentIndex: 2),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.secondary],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(LucideIcons.bot, color: Colors.white, size: 32),
        ),
        const SizedBox(height: 16),
        Text('Ask me anything about campus', style: AppTextStyles.h3),
        const SizedBox(height: 8),
        Text(
          'I only answer from verified college data',
          style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: _quickChips.map((chip) => ActionChip(
              label: Text(chip, style: AppTextStyles.label.copyWith(color: AppColors.primary)),
              backgroundColor: AppColors.primary.withOpacity(0.08),
              onPressed: () => _sendMessage(chip),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              side: BorderSide(color: AppColors.primary.withOpacity(0.2)),
            )).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildInputBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputCtrl,
              maxLength: 500,
              maxLines: null,
              style: AppTextStyles.body,
              decoration: InputDecoration(
                hintText: 'Ask a question...',
                counterText: '',
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
              ),
              onSubmitted: _sendMessage,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _sendMessage(_inputCtrl.text),
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.send, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage extends StatelessWidget {
  final String text;
  final bool isUser;
  final bool showBookmark;
  final VoidCallback? onBookmark;

  const _ChatMessage({
    required this.text,
    required this.isUser,
    this.showBookmark = false,
    this.onBookmark,
  });

  @override
  Widget build(BuildContext context) {
    if (isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12, left: 48),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(4),
            ),
          ),
          child: Text(text, style: AppTextStyles.body.copyWith(color: Colors.white)),
        ),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(right: 8, bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Center(
              child: Text('AI', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
            ),
          ),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 12, right: 48),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkSurface
                        : AppColors.surface,
                    border: const Border(
                      left: BorderSide(color: AppColors.secondary, width: 3),
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(18),
                      bottomLeft: Radius.circular(18),
                      bottomRight: Radius.circular(18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(text, style: AppTextStyles.body),
                      if (showBookmark) ...[
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: onBookmark,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(LucideIcons.bookmark, size: 14, color: AppColors.textMuted),
                              const SizedBox(width: 4),
                              Text('Save', style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (i) {
      final ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      );
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (mounted) ctrl.repeat(reverse: true);
      });
      return ctrl;
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, left: 40),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.darkSurface
              : AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            return AnimatedBuilder(
              animation: _controllers[i],
              builder: (_, __) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: 8,
                height: 8 + _controllers[i].value * 6,
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
