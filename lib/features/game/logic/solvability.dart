import 'dart:collection';
import '../models/puzzle_model.dart';
import 'freedom_checker.dart';

/// BFS over the freed-arrow bitmask space.
/// Returns true if there exists at least one tap order that frees all arrows.
/// Supports up to 30 arrows per puzzle.
bool isSolvable(PuzzleModel puzzle) {
  final n = puzzle.arrows.length;
  if (n == 0) return true;
  assert(n <= 30, 'Puzzle has too many arrows for bitmask BFS ($n)');

  final fullMask = (1 << n) - 1;
  final queue = Queue<int>()..add(0);
  final visited = <int>{0};

  while (queue.isNotEmpty) {
    final mask = queue.removeFirst();
    if (mask == fullMask) return true;

    for (int i = 0; i < n; i++) {
      if ((mask >> i) & 1 == 1) continue; // already freed

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
