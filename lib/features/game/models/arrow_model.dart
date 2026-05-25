enum ArrowDir { right, left, up, down }

extension ArrowDirX on ArrowDir {
  (int dx, int dy) get vector => switch (this) {
    ArrowDir.right => (1, 0),
    ArrowDir.left => (-1, 0),
    ArrowDir.up => (0, -1),
    ArrowDir.down => (0, 1),
  };
}

enum ArrowStatus { locked, freed, flashError, animating }

class ArrowModel {
  final int id;
  final int col; // tail column (0-based from left)
  final int row; // tail row (0-based from top)
  final ArrowDir dir;
  final int len; // 1–5 cells
  ArrowStatus status;

  ArrowModel({
    required this.id,
    required this.col,
    required this.row,
    required this.dir,
    required this.len,
    this.status = ArrowStatus.locked,
  });

  (int, int) get vector => dir.vector;

  int get headCol => col + dir.vector.$1 * (len - 1);
  int get headRow => row + dir.vector.$2 * (len - 1);

  /// All (col, row) cells occupied by this arrow body.
  List<(int, int)> get cells {
    final (dx, dy) = dir.vector;
    return List.generate(len, (s) => (col + dx * s, row + dy * s));
  }

  ArrowModel copyWith({ArrowStatus? status}) => ArrowModel(
    id: id,
    col: col,
    row: row,
    dir: dir,
    len: len,
    status: status ?? this.status,
  );
}
