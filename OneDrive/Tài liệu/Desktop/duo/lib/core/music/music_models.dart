class MusicSession {
  const MusicSession({
    this.trackId,
    this.trackTitle,
    this.trackArtist,
    required this.isPlaying,
    required this.position,
    required this.updatedAt,
    this.updatedBy,
    required this.queue,
  });

  final String? trackId;
  final String? trackTitle;
  final String? trackArtist;
  final bool isPlaying;
  final double position; // position in seconds
  final DateTime updatedAt;
  final String? updatedBy;
  final List<dynamic> queue;

  factory MusicSession.fromJson(Map<String, dynamic> json) {
    return MusicSession(
      trackId: json['track_id'] as String?,
      trackTitle: json['track_title'] as String?,
      trackArtist: json['track_artist'] as String?,
      isPlaying: json['is_playing'] as bool? ?? false,
      position: (json['position'] as num?)?.toDouble() ?? 0.0,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String).toLocal()
          : DateTime.now(),
      updatedBy: json['updated_by'] as String?,
      queue: json['queue'] as List<dynamic>? ?? [],
    );
  }
}

class YouTubeTrack {
  const YouTubeTrack({
    required this.videoId,
    required this.title,
    required this.channelTitle,
    this.thumbnailUrl,
  });

  final String videoId;
  final String title;
  final String channelTitle;
  final String? thumbnailUrl;

  factory YouTubeTrack.fromJson(Map<String, dynamic> json) {
    return YouTubeTrack(
      videoId: json['videoId'] as String,
      title: json['title'] as String,
      channelTitle: json['channelTitle'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String?,
    );
  }
}
