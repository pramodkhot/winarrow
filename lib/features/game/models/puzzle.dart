class Puzzle {
  final int rows;
  final int cols;

  // Ordered list of (row, col) dot positions from start → end.
  // path.length - 1 segments total.
  final List<(int, int)> path;

  const Puzzle({required this.rows, required this.cols, required this.path});

  int get segmentCount => path.length - 1;
  (int, int) get startDot => path.first;
  (int, int) get endDot => path.last;
}
