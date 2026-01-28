class GameStats {
  final int score;
  final int fishCount;
  final int storyCount;
  final int timestamp;

  GameStats({
    required this.score,
    required this.fishCount,
    required this.storyCount,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'score': score,
      'fishCount': fishCount,
      'storyCount': storyCount,
      'timestamp': timestamp,
    };
  }

  factory GameStats.fromJson(Map<String, dynamic> json) {
    return GameStats(
      score: json['score'] ?? 0,
      fishCount: json['fishCount'] ?? 0,
      storyCount: json['storyCount'] ?? 0,
      timestamp: json['timestamp'] ?? 0,
    );
  }
}
