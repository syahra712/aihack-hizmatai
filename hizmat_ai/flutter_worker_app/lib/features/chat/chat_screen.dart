import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../core/extensions.dart';
import '../../core/theme.dart';
import '../../models/chat_message.dart';
import '../../providers/providers.dart';
import '../../services/firestore_service.dart';

// ---------------------------------------------------------------------------
// Chat Screen
// ---------------------------------------------------------------------------

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.bookingRef});

  final String bookingRef;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSending = false;

  // Urdu quick replies with context labels
  static const List<_QuickReply> _quickReplies = [
    _QuickReply(urdu: 'آ رہا ہوں', label: 'On my way'),
    _QuickReply(urdu: 'پہنچ گیا', label: "I've arrived"),
    _QuickReply(urdu: 'کام شروع کر رہا ہوں', label: 'Starting work'),
    _QuickReply(urdu: 'مکمل ہو گیا', label: 'Done'),
    _QuickReply(urdu: 'سامان چاہیے', label: 'Need materials'),
    _QuickReply(urdu: 'تھوڑا وقت لگے گا', label: 'Will take more time'),
  ];

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
    final text = _textController.text.trim();
    if (text.isEmpty || _isSending) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isSending = true);
    _textController.clear();

    final message = ChatMessage(
      id: '',
      sender: MessageSender.worker,
      text: text,
      sentAt: DateTime.now(),
    );

    try {
      await ref
          .read(firestoreServiceProvider)
          .sendMessage(widget.bookingRef, message);
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Failed to send message', isError: true);
        _textController.text = text;
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatAsync = ref.watch(
      _chatStreamProvider(widget.bookingRef),
    );

    // Derive customer name from the booking doc
    final customerName = ref
            .watch(workerProfileProvider)
            .valueOrNull
            ?.name ??
        'Customer'; // fallback; parent widget may pass via extra

    return Scaffold(
      backgroundColor: WorkerColors.background,
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: WorkerColors.accentLight,
              child: Text(
                customerName.isNotEmpty
                    ? customerName[0].toUpperCase()
                    : 'C',
                style: context.textTheme.titleSmall
                    ?.copyWith(color: WorkerColors.accent),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Active Job Chat',
                    style: context.textTheme.titleMedium,
                  ),
                  Text(
                    '#${widget.bookingRef}',
                    style: context.textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Booking ref chip
            Container(
              margin: const EdgeInsets.only(right: 12),
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: WorkerColors.accentLight,
                borderRadius:
                    BorderRadius.circular(WorkerSizes.chipRadius),
              ),
              child: Text(
                widget.bookingRef.length > 8
                    ? widget.bookingRef.substring(0, 8)
                    : widget.bookingRef,
                style: context.textTheme.labelSmall?.copyWith(
                  color: WorkerColors.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: chatAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text(
                  'Could not load messages',
                  style: context.textTheme.bodyMedium
                      ?.copyWith(color: WorkerColors.error),
                ),
              ),
              data: (messages) {
                WidgetsBinding.instance
                    .addPostFrameCallback((_) => _scrollToBottom());
                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      'No messages yet.\nSend a quick reply below.',
                      textAlign: TextAlign.center,
                      style: context.textTheme.bodyMedium
                          ?.copyWith(color: WorkerColors.textMuted),
                    ),
                  );
                }
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    return _MessageBubble(message: messages[index]);
                  },
                );
              },
            ),
          ),
          // Bottom input area
          _ChatInputArea(
            controller: _textController,
            quickReplies: _quickReplies,
            isSending: _isSending,
            onSend: _sendMessage,
            onQuickReply: (text) {
              _textController.text = text;
              _textController.selection = TextSelection.fromPosition(
                TextPosition(offset: text.length),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Chat stream provider (family)
// ---------------------------------------------------------------------------

final _chatStreamProvider =
    StreamProvider.family<List<ChatMessage>, String>((ref, bookingRef) {
  return ref.read(firestoreServiceProvider).chatStream(bookingRef);
});

// ---------------------------------------------------------------------------
// Message bubble
// ---------------------------------------------------------------------------

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isWorker = message.sender == MessageSender.worker;
    final isSystem = message.sender == MessageSender.system;
    final timeStr = DateFormat('hh:mm a').format(message.sentAt);

    if (isSystem) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: WorkerColors.divider,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              message.text,
              style: context.textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
                color: WorkerColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: isWorker ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: isWorker
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width * 0.72,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isWorker
                      ? WorkerColors.accent
                      : const Color(0xFFEEEFF4),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isWorker ? 16 : 4),
                    bottomRight: Radius.circular(isWorker ? 4 : 16),
                  ),
                ),
                child: Text(
                  message.text,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: isWorker ? Colors.white : WorkerColors.text,
                    height: 1.4,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              timeStr,
              style: context.textTheme.labelSmall
                  ?.copyWith(color: WorkerColors.textLight),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Quick reply data
// ---------------------------------------------------------------------------

class _QuickReply {
  const _QuickReply({required this.urdu, required this.label});

  final String urdu;
  final String label;
}

// ---------------------------------------------------------------------------
// Chat input area
// ---------------------------------------------------------------------------

class _ChatInputArea extends StatelessWidget {
  const _ChatInputArea({
    required this.controller,
    required this.quickReplies,
    required this.isSending,
    required this.onSend,
    required this.onQuickReply,
  });

  final TextEditingController controller;
  final List<_QuickReply> quickReplies;
  final bool isSending;
  final VoidCallback onSend;
  final void Function(String) onQuickReply;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: WorkerColors.surface,
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Quick reply chips
            SizedBox(
              height: 52,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                itemCount: quickReplies.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final qr = quickReplies[index];
                  return GestureDetector(
                    onTap: () => onQuickReply(qr.urdu),
                    child: Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 0),
                      decoration: BoxDecoration(
                        color: WorkerColors.accentLight,
                        borderRadius:
                            BorderRadius.circular(WorkerSizes.chipRadius),
                        border: Border.all(
                          color: WorkerColors.accent.withOpacity(0.3),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        qr.urdu,
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: WorkerColors.accentDark,
                          fontWeight: FontWeight.w500,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(height: 1),
            // Text field + send button
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      minLines: 1,
                      maxLines: 4,
                      textDirection: TextDirection.ltr,
                      style: context.textTheme.bodyMedium,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: context.textTheme.bodyMedium
                            ?.copyWith(color: WorkerColors.textLight),
                        filled: true,
                        fillColor: WorkerColors.background,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => onSend(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: WorkerColors.accent,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: isSending ? null : onSend,
                      child: Container(
                        width: WorkerSizes.minTouchTarget,
                        height: WorkerSizes.minTouchTarget,
                        alignment: Alignment.center,
                        child: isSending
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send_rounded,
                                color: Colors.white, size: 22),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
