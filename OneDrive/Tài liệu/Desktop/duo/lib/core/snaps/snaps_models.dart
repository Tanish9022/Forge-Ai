class Snap {
  const Snap({
    required this.id,
    required this.coupleId,
    required this.storageRef,
    required this.senderId,
    this.duration,
    required this.viewed,
    required this.savedBy,
    this.deletedAt,
    required this.createdAt,
    this.expiresAt,
  });

  final String id;
  final String coupleId;
  final String storageRef;
  final String senderId;
  final int? duration;
  final bool viewed;
  final List<String> savedBy;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final DateTime? expiresAt;

  factory Snap.fromJson(Map<String, dynamic> json) {
    return Snap(
      id: json['id'] as String,
      coupleId: json['coupleId'] as String,
      storageRef: json['storageRef'] as String,
      senderId: json['senderId'] as String,
      duration: json['duration'] as int?,
      viewed: json['viewed'] as bool,
      savedBy: ((json['savedBy'] as List<dynamic>?) ?? [])
          .map((id) => id.toString())
          .toList(),
      deletedAt: json['deletedAt'] != null
          ? DateTime.parse(json['deletedAt'] as String).toLocal()
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String).toLocal()
          : null,
    );
  }
}

class SnapFeed {
  const SnapFeed({
    required this.snaps,
    required this.streakCount,
  });

  final List<Snap> snaps;
  final int streakCount;
}
