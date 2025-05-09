import 'package:intl/intl.dart';

/// Bir sohbet oturumunu temsil eden model
class ChatConversation {
  final int? id;
  final int userId; // YENİ: Konuşmanın sahibi olan kullanıcının kimliği
  final String title; // Sohbet başlığı/adı
  final DateTime createdAt;
  final DateTime? lastMessageAt;

  ChatConversation({
    this.id,
    required this.userId, // YENİ
    required this.title,
    required this.createdAt,
    this.lastMessageAt,
  });

  // Map'ten nesne oluşturma
  factory ChatConversation.fromMap(Map<String, dynamic> map) {
    return ChatConversation(
      id: map['id'],
      userId: map['userId'], // YENİ
      title: map['title'] ?? 'Yeni Sohbet',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      lastMessageAt: map['lastMessageAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastMessageAt'])
          : null,
    );
  }

  // Nesneyi Map'e dönüştürme
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId, // YENİ
      'title': title,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastMessageAt': lastMessageAt?.millisecondsSinceEpoch,
    };
  }

  // Nesneyi değiştirerek yeni bir kopya oluşturma
  ChatConversation copyWith({
    int? id,
    int? userId, // YENİ
    String? title,
    DateTime? createdAt,
    DateTime? lastMessageAt,
  }) {
    return ChatConversation(
      id: id ?? this.id,
      userId: userId ?? this.userId, // YENİ
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
    );
  }

  // Formatlı tarih gösterimi
  String get formattedDate {
    return DateFormat('dd MMM yyyy HH:mm', 'tr_TR').format(createdAt);
  }

  String get formattedLastMessageTime {
    if (lastMessageAt == null) return '';
    return DateFormat('dd MMM HH:mm', 'tr_TR').format(lastMessageAt!);
  }
}

/// Bir sohbet mesajını temsil eden model
class ChatMessage {
  final int? id;
  final int conversationId;
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    this.id,
    required this.conversationId,
    required this.text,
    required this.isUser,
    required this.timestamp,
  });

  // ChatMessage için copyWith metodu
  ChatMessage copyWith({
    int? id,
    int? conversationId,
    String? text,
    bool? isUser,
    DateTime? timestamp,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  // Map'ten nesne oluşturma
  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'],
      conversationId: map['conversationId'],
      text: map['text'],
      isUser: map['isUser'] == 1,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
    );
  }

  // Nesneyi Map'e dönüştürme
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'conversationId': conversationId,
      'text': text,
      'isUser': isUser ? 1 : 0,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  // Formatlı zaman gösterimi
  String get formattedTime {
    return DateFormat('HH:mm', 'tr_TR').format(timestamp);
  }
}
