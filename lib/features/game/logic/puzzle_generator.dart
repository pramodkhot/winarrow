import 'dart:math';
import '../models/arrow_model.dart';
import '../models/cat_model.dart';
import '../models/puzzle_model.dart';
import 'solvability.dart';

// ── Difficulty config ─────────────────────────────────────────────────────────

class _Tier {
  final int gridSize;
  final int minArrows;
  final int maxArrows;
  final int minLen; // min snake body length (cells)
  final int maxLen; // max snake body length (cells)
  const _Tier(
    this.gridSize,
    this.minArrows,
    this.maxArrows,
    this.minLen,
    this.maxLen,
  );
}

// Larger grids = smaller cells = dots packed tightly like reference game.
// Short snake bodies (2–5) + high arrow counts = densely filled board.
const _tiers = [
  _Tier(12, 22, 32, 2, 4), // tutorial : 12×12 = 144 cells
  _Tier(14, 34, 48, 2, 5), // easy     : 14×14 = 196 cells
  _Tier(16, 50, 68, 2, 5), // medium   : 16×16 = 256 cells
  _Tier(18, 70, 90, 2, 5), // hard     : 18×18 = 324 cells
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
  final withCat = level % 10 == 0 && level > 0;

  for (int attempt = 0; attempt < 400; attempt++) {
    final puzzle = _tryBuild(tier, rng);
    if (puzzle != null && isSolvable(puzzle)) {
      return withCat ? _addCat(puzzle, rng) : puzzle;
    }
  }
  final fallback = _trivialFallback(tier);
  return withCat ? _addCat(fallback, rng) : fallback;
}

// ── Generator internals ───────────────────────────────────────────────────────

PuzzleModel? _tryBuild(_Tier tier, Random rng) {
  final cols = tier.gridSize;
  final rows = tier.gridSize;
  final targetCount =
      tier.minArrows + rng.nextInt(tier.maxArrows - tier.minArrows + 1);
  final occupied = <int>{}; // cells claimed by placed arrows
  final arrows = <ArrowModel>[];

  for (
    int attempt = 0;
    attempt < 4000 && arrows.length < targetCount;
    attempt++
  ) {
    final startCol = rng.nextInt(cols);
    final startRow = rng.nextInt(rows);
    if (occupied.contains(startCol * 1000 + startRow)) continue;

    final targetLen = tier.minLen + rng.nextInt(tier.maxLen - tier.minLen + 1);
    final path = _buildSnakePath(
      startCol,
      startRow,
      rng,
      cols,
      rows,
      targetLen,
      occupied,
    );
    if (path.length < 2) continue;

    final headDir = _stepDir(path[path.length - 2], path.last);
    for (final (c, r) in path) {
      occupied.add(c * 1000 + r);
    }
    arrows.add(ArrowModel(id: arrows.length, path: path, headDir: headDir));
  }

  if (arrows.length < tier.minArrows) return null;
  return PuzzleModel(cols: cols, rows: rows, arrows: arrows);
}

/// Grow a snake path starting at (startCol, startRow).
/// Checks [occupied] (other arrows) AND self-cells to avoid overlap.
/// Prefers continuing in the same direction 65 % of the time for longer runs.
List<(int, int)> _buildSnakePath(
  int startCol,
  int startRow,
  Random rng,
  int cols,
  int rows,
  int targetLen,
  Set<int> occupied,
) {
  final path = <(int, int)>[(startCol, startRow)];
  final self = <int>{startCol * 1000 + startRow};
  ArrowDir? lastDir;

  while (path.length < targetLen) {
    final (curC, curR) = path.last;

    // Candidate directions: shuffle all, then optionally bias towards lastDir.
    final shuffled = ArrowDir.values.toList()..shuffle(rng);
    if (lastDir != null && rng.nextDouble() < 0.65) {
      shuffled.remove(lastDir);
      shuffled.insert(0, lastDir);
    }

    bool extended = false;
    for (final d in shuffled) {
      final (dx, dy) = d.vector;
      final nc = curC + dx;
      final nr = curR + dy;
      final key = nc * 1000 + nr;
      if (nc >= 0 &&
          nc < cols &&
          nr >= 0 &&
          nr < rows &&
          !occupied.contains(key) &&
          !self.contains(key)) {
        path.add((nc, nr));
        self.add(key);
        lastDir = d;
        extended = true;
        break;
      }
    }
    if (!extended) break; // stuck — return what we have
  }
  return path;
}

ArrowDir _stepDir((int, int) from, (int, int) to) {
  final dx = to.$1 - from.$1;
  final dy = to.$2 - from.$2;
  if (dx == 1) return ArrowDir.right;
  if (dx == -1) return ArrowDir.left;
  if (dy == 1) return ArrowDir.down;
  return ArrowDir.up;
}

PuzzleModel _trivialFallback(_Tier tier) {
  final cols = tier.gridSize;
  final rows = tier.gridSize;
  final arrows = <ArrowModel>[];
  int id = 0;
  for (int r = 0; r < rows && arrows.length < tier.minArrows; r++) {
    for (int c = 0; c + 1 < cols && arrows.length < tier.minArrows; c += 2) {
      arrows.add(
        ArrowModel(
          id: id++,
          path: [(c, r), (c + 1, r)],
          headDir: ArrowDir.right,
        ),
      );
    }
  }
  return PuzzleModel(cols: cols, rows: rows, arrows: arrows);
}

// ── Cat rescue placement ──────────────────────────────────────────────────────

/// Places a cat at the board center and ensures its exit path is initially blocked.
PuzzleModel _addCat(PuzzleModel puzzle, Random rng) {
  final cc = puzzle.cols ~/ 2;
  final cr = puzzle.rows ~/ 2;
  final exitDir = ArrowDir.values[rng.nextInt(4)];

  // Remove arrow cells overlapping the cat's cell, re-index IDs.
  final filtered = puzzle.arrows
      .where((a) => !a.cells.any((c) => c.$1 == cc && c.$2 == cr))
      .toList();
  final arrows = [
    for (int i = 0; i < filtered.length; i++)
      ArrowModel(id: i, path: filtered[i].path, headDir: filtered[i].headDir),
  ];

  // Check whether the cat's exit path is already blocked.
  final occupied = {
    for (final a in arrows)
      for (final cell in a.cells) cell.$1 * 1000 + cell.$2,
  };
  final (dx, dy) = exitDir.vector;
  bool blocked = false;
  {
    int c = cc + dx;
    int r = cr + dy;
    while (c >= 0 && c < puzzle.cols && r >= 0 && r < puzzle.rows) {
      if (occupied.contains(c * 1000 + r)) {
        blocked = true;
        break;
      }
      c += dx;
      r += dy;
    }
  }

  // If exit path is clear, insert a 2-cell blocking arrow.
  if (!blocked) {
    final bc = cc + dx;
    final br = cr + dy;
    final perpDir = dx != 0 ? ArrowDir.down : ArrowDir.right;
    final (px, py) = perpDir.vector;
    final bc2 = bc + px;
    final br2 = br + py;
    if (bc >= 0 &&
        bc < puzzle.cols &&
        br >= 0 &&
        br < puzzle.rows &&
        bc2 >= 0 &&
        bc2 < puzzle.cols &&
        br2 >= 0 &&
        br2 < puzzle.rows &&
        !occupied.contains(bc * 1000 + br) &&
        !occupied.contains(bc2 * 1000 + br2)) {
      arrows.add(
        ArrowModel(
          id: arrows.length,
          path: [(bc, br), (bc2, br2)],
          headDir: perpDir,
        ),
      );
    }
  }

  return PuzzleModel(
    cols: puzzle.cols,
    rows: puzzle.rows,
    arrows: arrows,
    cat: CatModel(col: cc, row: cr, exitDir: exitDir),
  );
}
