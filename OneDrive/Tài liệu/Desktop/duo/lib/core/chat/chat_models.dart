class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.coupleId,
    required this.type,
    required this.senderId,
    required this.status,
    this.replyTo,
    required this.reactions,
    required this.isDeleted,
    required this.createdAt,
    required this.decryptedContent,
  });

  final String id;
  final String coupleId;
  final String type;
  final String senderId;
  final String status;
  final String? replyTo;
  final Map<String, dynamic> reactions;
  final bool isDeleted;
  final DateTime createdAt;
  final String decryptedContent;

  ChatMessage copyWith({
    String? status,
    Map<String, dynamic>? reactions,
    bool? isDeleted,
    String? decryptedContent,
  }) {
    return ChatMessage(
      id: id,
      coupleId: coupleId,
      type: type,
      senderId: senderId,
      status: status ?? this.status,
      replyTo: replyTo,
      reactions: reactions ?? this.reactions,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt,
      decryptedContent: decryptedContent ?? this.decryptedContent,
    );
  }
}
