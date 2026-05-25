enum ArrowDir { right, left, up, down }

extension ArrowDirX on ArrowDir {
  (int, int) get vector => switch (this) {
    ArrowDir.right => (1, 0),
    ArrowDir.left => (-1, 0),
    ArrowDir.up => (0, -1),
    ArrowDir.down => (0, 1),
  };
}

enum ArrowStatus { locked, freed, flashError, animating }

/// A snake-shaped arrow: a winding connected path of grid cells.
/// [path] is ordered tail → head, each entry is (col, row).
/// [headDir] is the direction the head cell exits the board.
class ArrowModel {
  final int id;
  final List<(int, int)> path;
  final ArrowDir headDir;
  ArrowStatus status;

  ArrowModel({
    required this.id,
    required this.path,
    required this.headDir,
    this.status = ArrowStatus.locked,
  });

  (int, int) get head => path.last;
  (int, int) get tail => path.first;
  int get headCol => head.$1;
  int get headRow => head.$2;

  List<(int, int)> get cells => path;
}
