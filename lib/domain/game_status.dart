// Game status enum for multiplayer games
enum GameStatus {
  waiting,
  playing,
  finished;

  String toJson() => name;

  static GameStatus fromJson(String json) {
    return GameStatus.values.firstWhere(
      (status) => status.name == json,
      orElse: () => GameStatus.waiting,
    );
  }
}
