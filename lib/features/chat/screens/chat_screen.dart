import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/bloc/auth_bloc.dart';

class ChatMessage {
  final String content;
  final bool isUser;
  final DateTime time;

  ChatMessage({required this.content, required this.isUser, required this.time});
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final List<Map<String, String>> _history = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final response = await context.read<ApiClient>().getChatHistory();
      final List<dynamic> saved = response.data['messages'] ?? [];

      if (saved.isEmpty) {
        _showWelcomeMessage();
        return;
      }

      setState(() {
        for (final m in saved) {
          final isUser = m['role'] == 'user';
          _messages.add(ChatMessage(
            content: m['content'] as String,
            isUser: isUser,
            time: DateTime.tryParse(m['createdAt'] ?? '') ?? DateTime.now(),
          ));
          _history.add({'role': m['role'] as String, 'content': m['content'] as String});
        }
      });
      _scrollToBottom();
    } catch (_) {
      // Historique indisponible (hors ligne, erreur réseau...) — on démarre
      // simplement une nouvelle conversation plutôt que de bloquer l'écran.
      _showWelcomeMessage();
    }
  }

  void _showWelcomeMessage() {
    setState(() {
      _messages.add(ChatMessage(
        content: '👋 Salut ! Je suis ScholarBot, ton assistant bourses.\n\nDis-moi ton objectif (pays, niveau, domaine) et je te guide directement.',
        isUser: false,
        time: DateTime.now(),
      ));
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    _controller.clear();

    setState(() {
      _messages.add(ChatMessage(content: text, isUser: true, time: DateTime.now()));
      _isLoading = true;
    });
    _scrollToBottom();

    _history.add({'role': 'user', 'content': text});

    try {
      final authState = context.read<AuthBloc>().state;
      Map<String, dynamic>? userProfile;
      if (authState is AuthAuthenticatedState) {
        userProfile = authState.user;
      }

      final response = await context.read<ApiClient>().sendChatMessage(
        messages: _history,
        userProfile: userProfile,
      );

      final botMessage = response.data['message'] as String;
      _history.add({'role': 'assistant', 'content': botMessage});

      setState(() {
        _messages.add(ChatMessage(content: botMessage, isUser: false, time: DateTime.now()));
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          content: 'Désolé, une erreur est survenue. Réessayez.',
          isUser: false,
          time: DateTime.now(),
        ));
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ScholarBot',
                  style: TextStyle(
                      fontSize: AppTheme.fsBodyLg,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary),
                ),
                Row(
                  children: [
                    Container(width: 7, height: 7, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    const Text(
                      'En ligne',
                      style: TextStyle(
                          fontSize: AppTheme.fsBodySm,
                          color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.textSecondary),
            onPressed: () {
              setState(() {
                _messages.clear();
                _history.clear();
                _messages.add(ChatMessage(
                  content: '👋 Salut ! Je suis ScholarBot, ton assistant bourses.\n\nDis-moi ton objectif (pays, niveau, domaine) et je te guide directement.',
                  isUser: false,
                  time: DateTime.now(),
                ));
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (_, i) {
                if (i == _messages.length && _isLoading) {
                  return _TypingIndicator();
                }
                return _MessageBubble(message: _messages[i]);
              },
            ),
          ),

          // Quick suggestions (si peu de messages)
          if (_messages.length <= 2)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  _QuickSuggestion('🎯 Trouver une bourse', () {
                    _controller.text = 'Aide-moi à trouver des bourses adaptées à mon profil.';
                    _sendMessage();
                  }),
                  _QuickSuggestion('🎓 Bourses Master', () {
                    _controller.text = 'Quelles bourses sont disponibles pour un Master ?';
                    _sendMessage();
                  }),
                  _QuickSuggestion('🌍 Bourses par pays', () {
                    _controller.text = 'Quelles bourses ciblent les étudiants de mon pays ? Donne-moi les plus pertinentes.';
                    _sendMessage();
                  }),
                  _QuickSuggestion('📝 Lettre de motivation', () {
                    _controller.text = 'Comment rédiger une bonne lettre de motivation ?';
                    _sendMessage();
                  }),
                  _QuickSuggestion('📅 Deadlines proches', () {
                    _controller.text = 'Quelles sont les deadlines les plus proches à ne pas rater ?';
                    _sendMessage();
                  }),
                ],
              ),
            ),

          // Input
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            decoration: const BoxDecoration(
              color: AppTheme.surface,
              border: Border(top: BorderSide(color: AppTheme.border, width: 1.5)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    maxLines: 3,
                    minLines: 1,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: InputDecoration(
                      hintText: 'Posez votre question...',
                      filled: true,
                      fillColor: AppTheme.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
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

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 30, height: 30,
              decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? AppTheme.primary : AppTheme.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                border: isUser ? null : Border.all(color: AppTheme.border, width: 1.5),
              ),
              child: Text(
                message.content,
                style: TextStyle(
                  color: isUser ? Colors.white : AppTheme.textPrimary,
                  fontSize: AppTheme.fsBodyMd,
                  height: 1.5,
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18), topRight: Radius.circular(18), bottomRight: Radius.circular(18), bottomLeft: Radius.circular(4),
              ),
              border: Border.all(color: AppTheme.border, width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) => _Dot(delay: i * 200)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  final int delay;
  const _Dot({required this.delay});

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        width: 8, height: 8,
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.3 + (_anim.value * 0.7)),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _QuickSuggestion extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _QuickSuggestion(this.label, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.border, width: 1.5),
        ),
        child: Text(
          label,
          style: const TextStyle(
              fontSize: AppTheme.fsBodySm,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary),
        ),
      ),
    );
  }
}
