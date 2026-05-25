import 'dart:collection';
import '../models/arrow_model.dart';
import '../models/puzzle_model.dart';
import 'freedom_checker.dart';

/// Checks solvability.
/// For ≤30 arrows: full BFS over bitmask state space (exact).
/// For >30 arrows: greedy fixed-point simulation (complete for this puzzle type
/// because freeing an arrow never blocks a previously-freeable arrow).
bool isSolvable(PuzzleModel puzzle) {
  final n = puzzle.arrows.length;
  if (n == 0) return true;
  if (n <= 30) return _bfsSolvable(puzzle);
  return _greedySolvable(puzzle);
}

bool _bfsSolvable(PuzzleModel puzzle) {
  final n = puzzle.arrows.length;
  final fullMask = (1 << n) - 1;
  final queue = Queue<int>()..add(0);
  final visited = <int>{0};

  while (queue.isNotEmpty) {
    final mask = queue.removeFirst();
    if (mask == fullMask) return true;

    for (int i = 0; i < n; i++) {
      if ((mask >> i) & 1 == 1) continue;
      if (canFree(
        puzzle.arrows[i],
        puzzle.arrows,
        puzzle.cols,
        puzzle.rows,
        freedMask: mask,
      )) {
        final next = mask | (1 << i);
        if (visited.add(next)) {
          queue.add(next);
        }
      }
    }
  }
  return false;
}

/// Repeatedly free any currently-freeable arrow until nothing moves.
/// Monotonic: freed arrows only help, never hurt, so this is complete.
bool _greedySolvable(PuzzleModel puzzle) {
  final freed = List<bool>.filled(puzzle.arrows.length, false);
  int freedCount = 0;
  int prevCount = -1;

  while (freedCount != prevCount) {
    prevCount = freedCount;
    for (int i = 0; i < puzzle.arrows.length; i++) {
      if (freed[i]) continue;
      if (_canFreeWithBools(
        puzzle.arrows[i],
        puzzle.arrows,
        freed,
        puzzle.cols,
        puzzle.rows,
      )) {
        freed[i] = true;
        freedCount++;
      }
    }
  }
  return freedCount == puzzle.arrows.length;
}

bool _canFreeWithBools(
  ArrowModel arrow,
  List<ArrowModel> all,
  List<bool> freed,
  int cols,
  int rows,
) {
  final occupied = <int>{};
  for (int i = 0; i < all.length; i++) {
    if (freed[i] || all[i].id == arrow.id) continue;
    for (final (c, r) in all[i].cells) {
      occupied.add(c * 1000 + r);
    }
  }
  final (dx, dy) = arrow.headDir.vector;
  int c = arrow.headCol + dx;
  int r = arrow.headRow + dy;
  while (c >= 0 && c < cols && r >= 0 && r < rows) {
    if (occupied.contains(c * 1000 + r)) return false;
    c += dx;
    r += dy;
  }
  return true;
}
