class Note {
  const Note({
    required this.id,
    required this.coupleId,
    required this.authorId,
    required this.encryptedTitle,
    required this.titleIv,
    required this.encryptedContent,
    required this.contentIv,
    required this.color,
    required this.isPinned,
    required this.createdAt,
    required this.updatedAt,
    this.decryptedTitle,
    this.decryptedContent,
  });

  final String id;
  final String coupleId;
  final String authorId;
  final String encryptedTitle;
  final String titleIv;
  final String encryptedContent;
  final String contentIv;
  final String color;
  final bool isPinned;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Ephemeral decrypted state
  final String? decryptedTitle;
  final String? decryptedContent;

  Note copyWithDecrypted({
    String? title,
    String? content,
  }) {
    return Note(
      id: id,
      coupleId: coupleId,
      authorId: authorId,
      encryptedTitle: encryptedTitle,
      titleIv: titleIv,
      encryptedContent: encryptedContent,
      contentIv: contentIv,
      color: color,
      isPinned: isPinned,
      createdAt: createdAt,
      updatedAt: updatedAt,
      decryptedTitle: title ?? decryptedTitle,
      decryptedContent: content ?? decryptedContent,
    );
  }

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'] as String,
      coupleId: json['coupleId'] as String,
      authorId: json['authorId'] as String,
      encryptedTitle: json['encryptedTitle'] as String,
      titleIv: json['titleIv'] as String,
      encryptedContent: json['encryptedContent'] as String,
      contentIv: json['contentIv'] as String,
      color: json['color'] as String? ?? 'rose',
      isPinned: json['isPinned'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
      updatedAt: DateTime.parse(json['updatedAt'] as String).toLocal(),
    );
  }
}
