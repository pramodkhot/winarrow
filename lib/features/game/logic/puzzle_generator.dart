import 'dart:math';
import '../models/arrow_model.dart';
import '../models/puzzle_model.dart';
import 'solvability.dart';

// ── Difficulty config ─────────────────────────────────────────────────────────

class _Tier {
  final int gridSize;
  final int minArrows;
  final int maxArrows;
  final int maxLen;
  const _Tier(this.gridSize, this.minArrows, this.maxArrows, this.maxLen);
}

const _tiers = [
  _Tier(6, 10, 15, 2), // tutorial
  _Tier(8, 18, 26, 3), // easy
  _Tier(10, 30, 48, 4), // medium
  _Tier(12, 50, 80, 5), // hard
];

_Tier _tierForLevel(int level) {
  if (level <= 5) return _tiers[0];
  if (level <= 20) return _tiers[1];
  if (level <= 50) return _tiers[2];
  return _tiers[3];
}

// ── Public API ────────────────────────────────────────────────────────────────

PuzzleModel generatePuzzle(int level) {
  final tier = _tierForLevel(level);
  final seed = level * 7919 + 31337;
  final rng = Random(seed);

  for (int attempt = 0; attempt < 400; attempt++) {
    final puzzle = _tryBuild(tier, rng);
    if (puzzle != null && isSolvable(puzzle)) return puzzle;
  }

  // Fallback: guaranteed trivial puzzle (all arrows immediately free)
  return _trivialFallback(tier, rng);
}

// ── Generator internals ───────────────────────────────────────────────────────

PuzzleModel? _tryBuild(_Tier tier, Random rng) {
  final cols = tier.gridSize;
  final rows = tier.gridSize;
  final targetCount =
      tier.minArrows + rng.nextInt(tier.maxArrows - tier.minArrows + 1);
  final occupied = <int>{}; // col * 1000 + row
  final arrows = <ArrowModel>[];

  for (
    int attempt = 0;
    attempt < 2000 && arrows.length < targetCount;
    attempt++
  ) {
    final dir = ArrowDir.values[rng.nextInt(4)];
    final len = 1 + rng.nextInt(tier.maxLen);
    final (dx, dy) = dir.vector;

    // Compute valid tail positions so the arrow fits inside the grid
    final maxCol = cols - 1 - (dx > 0 ? dx * (len - 1) : 0);
    final minCol = dx < 0 ? -dx * (len - 1) : 0;
    final maxRow = rows - 1 - (dy > 0 ? dy * (len - 1) : 0);
    final minRow = dy < 0 ? -dy * (len - 1) : 0;

    if (maxCol < minCol || maxRow < minRow) continue;

    final col = minCol + rng.nextInt(maxCol - minCol + 1);
    final row = minRow + rng.nextInt(maxRow - minRow + 1);

    // Check for overlap
    bool overlaps = false;
    final cells = <int>[];
    for (int s = 0; s < len; s++) {
      final key = (col + dx * s) * 1000 + (row + dy * s);
      if (occupied.contains(key)) {
        overlaps = true;
        break;
      }
      cells.add(key);
    }
    if (overlaps) continue;

    occupied.addAll(cells);
    arrows.add(
      ArrowModel(id: arrows.length, col: col, row: row, dir: dir, len: len),
    );
  }

  if (arrows.length < tier.minArrows) return null;
  return PuzzleModel(cols: cols, rows: rows, arrows: arrows);
}

PuzzleModel _trivialFallback(_Tier tier, Random rng) {
  final cols = tier.gridSize;
  final rows = tier.gridSize;
  // A small chain: arrows pointing right across the middle rows
  final arrows = <ArrowModel>[];
  int id = 0;
  for (int r = 0; r < rows && arrows.length < tier.minArrows; r++) {
    for (int c = 0; c + 1 < cols && arrows.length < tier.minArrows; c += 2) {
      arrows.add(
        ArrowModel(id: id++, col: c, row: r, dir: ArrowDir.right, len: 1),
      );
    }
  }
  return PuzzleModel(cols: cols, rows: rows, arrows: arrows);
}
