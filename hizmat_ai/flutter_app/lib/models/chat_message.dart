enum MessageRole { user, ai }

class ChatMessage {
  final String id;
  final MessageRole role;
  final String text;
  final DateTime timestamp;
  final List<String>? providerIds;

  const ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.timestamp,
    this.providerIds,
  });
}
