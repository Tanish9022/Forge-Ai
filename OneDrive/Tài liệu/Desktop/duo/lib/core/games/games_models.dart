class GameState {
  const GameState({
    required this.id,
    required this.coupleId,
    required this.game,
    required this.state,
    this.currentTurn,
    this.scores,
    required this.updatedAt,
  });

  final String id;
  final String coupleId;
  final String game;
  final Map<String, dynamic> state;
  final String? currentTurn;
  final Map<String, dynamic>? scores;
  final DateTime updatedAt;

  factory GameState.fromJson(Map<String, dynamic> json) {
    return GameState(
      id: json['id'] as String? ?? '',
      coupleId: json['couple_id'] as String? ?? '',
      game: json['game'] as String? ?? '',
      state: json['state'] as Map<String, dynamic>? ?? {},
      currentTurn: json['current_turn'] as String?,
      scores: json['scores'] as Map<String, dynamic>?,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String).toLocal()
          : DateTime.now(),
    );
  }
}
