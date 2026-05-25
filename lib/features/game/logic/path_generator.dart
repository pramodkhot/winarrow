import 'dart:math';
import '../models/difficulty.dart';
import '../models/puzzle.dart';

class PathGenerator {
  static Puzzle generate(Difficulty difficulty, {int? seed}) {
    final rng = seed != null ? Random(seed) : Random();
    final n = difficulty.gridSize;
    final minLen = difficulty.minSegments;
    final maxLen = difficulty.maxSegments;

    // Retry until a valid path is produced (should almost always succeed first try)
    for (int attempt = 0; attempt < 100; attempt++) {
      final path = _tryGenerate(n, n, minLen, maxLen, rng);
      if (path != null) return Puzzle(rows: n, cols: n, path: path);
    }

    // Fallback: guaranteed short diagonal-ish path
    return Puzzle(rows: n, cols: n, path: _fallback(n));
  }

  // ── Internals ─────────────────────────────────────────────────────────────

  static List<(int, int)>? _tryGenerate(
    int rows,
    int cols,
    int minLen,
    int maxLen,
    Random rng,
  ) {
    // Collect all edge dots as candidates for start
    final edges = <(int, int)>[];
    for (int c = 0; c < cols; c++) {
      edges.add((0, c));
      edges.add((rows - 1, c));
    }
    for (int r = 1; r < rows - 1; r++) {
      edges.add((r, 0));
      edges.add((r, cols - 1));
    }
    edges.shuffle(rng);

    final start = edges.first;
    final visited = List.generate(rows, (_) => List.filled(cols, false));
    visited[start.$1][start.$2] = true;

    final path = <(int, int)>[start];
    return _walk(
      visited,
      start.$1,
      start.$2,
      rows,
      cols,
      minLen,
      maxLen,
      rng,
      path,
    );
  }

  static List<(int, int)>? _walk(
    List<List<bool>> visited,
    int r,
    int c,
    int rows,
    int cols,
    int minLen,
    int maxLen,
    Random rng,
    List<(int, int)> path,
  ) {
    if (path.length > maxLen) return path.length >= minLen ? path : null;
    // Occasionally stop early once minimum length is reached
    if (path.length >= minLen && rng.nextDouble() < 0.2) return path;

    const dirs = [(-1, 0), (0, 1), (1, 0), (0, -1)];
    final shuffled = List.of(dirs)..shuffle(rng);

    for (final (dr, dc) in shuffled) {
      final nr = r + dr;
      final nc = c + dc;
      if (nr < 0 || nr >= rows || nc < 0 || nc >= cols) continue;
      if (visited[nr][nc]) continue;

      visited[nr][nc] = true;
      path.add((nr, nc));
      final result = _walk(
        visited,
        nr,
        nc,
        rows,
        cols,
        minLen,
        maxLen,
        rng,
        path,
      );
      if (result != null) return result;
      path.removeLast();
      visited[nr][nc] = false;
    }

    return path.length >= minLen ? path : null;
  }

  static List<(int, int)> _fallback(int n) {
    final path = <(int, int)>[];
    for (int i = 0; i < n; i++) {
      path.add((0, i));
    }
    for (int i = 1; i < n; i++) {
      path.add((i, n - 1));
    }
    return path;
  }
}
