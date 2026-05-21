import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageSender {
  worker,
  customer,
  system;

  static MessageSender fromString(String value) {
    switch (value) {
      case 'worker':
        return MessageSender.worker;
      case 'customer':
        return MessageSender.customer;
      case 'system':
        return MessageSender.system;
      default:
        return MessageSender.customer;
    }
  }

  String toFirestoreString() {
    switch (this) {
      case MessageSender.worker:
        return 'worker';
      case MessageSender.customer:
        return 'customer';
      case MessageSender.system:
        return 'system';
    }
  }
}

class ChatMessage {
  final String id;
  final MessageSender sender;
  final String text;
  final String translatedText;
  final DateTime sentAt;
  final bool read;

  const ChatMessage({
    required this.id,
    required this.sender,
    required this.text,
    this.translatedText = '',
    required this.sentAt,
    this.read = false,
  });

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      id: doc.id,
      sender: MessageSender.fromString(d['sender'] as String? ?? ''),
      text: d['text'] as String? ?? '',
      translatedText: d['translated_text'] as String? ?? '',
      sentAt: d['sent_at'] is Timestamp
          ? (d['sent_at'] as Timestamp).toDate()
          : DateTime.now(),
      read: d['read'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'sender': sender.toFirestoreString(),
        'text': text,
        'translated_text': translatedText,
        'sent_at': Timestamp.fromDate(sentAt),
        'read': read,
      };
}
