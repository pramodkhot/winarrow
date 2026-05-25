enum Difficulty {
  easy,
  medium,
  hard;

  static Difficulty forLevel(int level) {
    if (level <= 20) return easy;
    if (level <= 50) return medium;
    return hard;
  }

  int get gridSize => switch (this) {
    easy => 6,
    medium => 8,
    hard => 10,
  };

  int get minSegments => switch (this) {
    easy => 8,
    medium => 15,
    hard => 25,
  };

  int get maxSegments => switch (this) {
    easy => 14,
    medium => 24,
    hard => 40,
  };

  String get label => switch (this) {
    easy => 'Easy',
    medium => 'Medium',
    hard => 'Hard',
  };
}
