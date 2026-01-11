import 'package:flutter/material.dart';
import '../../core/services/ai_service.dart';

class CitizenAiScreen extends StatefulWidget {
  const CitizenAiScreen({super.key});

  @override
  State<CitizenAiScreen> createState() => _CitizenAiScreenState();
}

class _CitizenAiScreenState extends State<CitizenAiScreen> {
  final List<_ChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _messages.add(
      const _ChatMessage(
        isUser: false,
        text:
            "I can explain report lifecycle, points, and status meanings. "
            "AI suggestions are informational only.",
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() {
      _sending = true;
      _error = null;
      _messages.add(_ChatMessage(isUser: true, text: text));
    });
    _controller.clear();
    _scrollToBottom();

    try {
      final reply = await AiService.sendMessage(
        message: text,
        context: "citizen_help",
      );
      setState(() {
        _messages.add(_ChatMessage(isUser: false, text: reply));
      });
    } catch (_) {
      setState(() {
        _error = "AI service is temporarily unavailable.";
      });
    } finally {
      setState(() {
        _sending = false;
      });
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Citizen AI Assistant"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          if (_error != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              color: scheme.errorContainer,
              child: Text(
                _error!,
                style: textTheme.bodySmall?.copyWith(
                  color: scheme.onErrorContainer,
                ),
              ),
            ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              itemCount: _messages.length + (_sending ? 1 : 0),
              itemBuilder: (context, index) {
                if (_sending && index == _messages.length) {
                  return _TypingIndicator(
                    color: scheme.primary,
                  );
                }
                final message = _messages[index];
                return _ChatBubble(message: message);
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              decoration: BoxDecoration(
                color: scheme.surface,
                border: Border(
                  top: BorderSide(color: scheme.outlineVariant),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: "Ask about reports and points",
                        filled: true,
                        fillColor: scheme.surfaceVariant,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      style: textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 46,
                    width: 46,
                    child: ElevatedButton(
                      onPressed: _sending ? null : _sendMessage,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        backgroundColor: scheme.primary,
                      ),
                      child: _sending
                          ? SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: scheme.onPrimary,
                              ),
                            )
                          : Icon(Icons.send, color: scheme.onPrimary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final bool isUser;
  final String text;

  const _ChatMessage({required this.isUser, required this.text});
}

class _ChatBubble extends StatelessWidget {
  final _ChatMessage message;

  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final alignment =
        message.isUser ? Alignment.centerRight : Alignment.centerLeft;
    final bubbleColor = message.isUser
        ? scheme.primaryContainer
        : scheme.surfaceVariant;
    final textColor = message.isUser
        ? scheme.onPrimaryContainer
        : scheme.onSurfaceVariant;

    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          message.text,
          style: textTheme.bodyMedium?.copyWith(color: textColor),
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  final Color color;

  const _TypingIndicator({required this.color});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: color,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              "AI is typing...",
              style: textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
