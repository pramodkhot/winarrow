import 'dart:collection';
import '../models/arrow_model.dart';
import '../models/puzzle_model.dart';
import 'freedom_checker.dart';

/// Checks solvability.
/// For ≤30 arrows: full BFS over bitmask state space (exact).
/// For >30 arrows: repeated greedy simulation (heuristic — fast, not exhaustive).
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

/// Greedy simulation: repeatedly free any currently-freeable arrow until none
/// remain or we're stuck. Run multiple passes to account for ordering effects.
bool _greedySolvable(PuzzleModel puzzle) {
  final freed = List<bool>.filled(puzzle.arrows.length, false);
  int prevFreedCount = -1;
  int freedCount = 0;

  while (freedCount != prevFreedCount) {
    prevFreedCount = freedCount;
    for (int i = 0; i < puzzle.arrows.length; i++) {
      if (freed[i]) continue;
      // Build a freedMask from the freed list (only for canFree call)
      if (_canFreeWithBoolList(
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

bool _canFreeWithBoolList(
  ArrowModel arrow,
  List<ArrowModel> allArrows,
  List<bool> freed,
  int cols,
  int rows,
) {
  final occupied = <int>{};
  for (int i = 0; i < allArrows.length; i++) {
    if (freed[i] || allArrows[i].id == arrow.id) continue;
    final a = allArrows[i];
    if (a.status == ArrowStatus.freed || a.status == ArrowStatus.animating) {
      continue;
    }
    for (final cell in a.cells) {
      occupied.add(cell.$1 * 1000 + cell.$2);
    }
  }

  final (dx, dy) = arrow.dir.vector;
  int c = arrow.headCol + dx;
  int r = arrow.headRow + dy;
  while (c >= 0 && c < cols && r >= 0 && r < rows) {
    if (occupied.contains(c * 1000 + r)) return false;
    c += dx;
    r += dy;
  }
  return true;
}
