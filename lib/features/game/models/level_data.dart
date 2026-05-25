import 'arrow_direction.dart';

class LevelData {
  final int level;
  final int rows;
  final int cols;
  final int startRow;
  final int startCol;
  final int exitRow;
  final int exitCol;
  // Flat list of directions, row-major order
  final List<ArrowDirection> grid;

  const LevelData({
    required this.level,
    required this.rows,
    required this.cols,
    required this.startRow,
    required this.startCol,
    required this.exitRow,
    required this.exitCol,
    required this.grid,
  });
}

// ── Hand-crafted levels ───────────────────────────────────────────────────────

const _u = ArrowDirection.up;
const _r = ArrowDirection.right;
const _d = ArrowDirection.down;
const _l = ArrowDirection.left;

final List<LevelData> kLevels = [
  // Level 1 — 4×4, very easy
  LevelData(
    level: 1,
    rows: 4,
    cols: 4,
    startRow: 0,
    startCol: 0,
    exitRow: 3,
    exitCol: 3,
    grid: [_r, _r, _d, _d, _u, _r, _d, _d, _u, _u, _r, _d, _u, _u, _r, _r],
  ),
  // Level 2 — 4×4
  LevelData(
    level: 2,
    rows: 4,
    cols: 4,
    startRow: 0,
    startCol: 0,
    exitRow: 3,
    exitCol: 3,
    grid: [_r, _d, _l, _d, _u, _r, _u, _d, _u, _d, _l, _l, _u, _r, _r, _u],
  ),
  // Level 3 — 5×5
  LevelData(
    level: 3,
    rows: 5,
    cols: 5,
    startRow: 0,
    startCol: 0,
    exitRow: 4,
    exitCol: 4,
    grid: [
      _r,
      _r,
      _d,
      _l,
      _d,
      _u,
      _r,
      _d,
      _u,
      _d,
      _u,
      _d,
      _l,
      _l,
      _d,
      _u,
      _r,
      _u,
      _r,
      _d,
      _u,
      _u,
      _r,
      _r,
      _r,
    ],
  ),
  // Level 4 — 5×5
  LevelData(
    level: 4,
    rows: 5,
    cols: 5,
    startRow: 0,
    startCol: 2,
    exitRow: 4,
    exitCol: 2,
    grid: [
      _r,
      _r,
      _d,
      _l,
      _l,
      _u,
      _r,
      _d,
      _l,
      _u,
      _u,
      _r,
      _d,
      _l,
      _u,
      _u,
      _r,
      _d,
      _l,
      _u,
      _u,
      _r,
      _r,
      _r,
      _u,
    ],
  ),
  // Level 5 — 5×5
  LevelData(
    level: 5,
    rows: 5,
    cols: 5,
    startRow: 0,
    startCol: 0,
    exitRow: 4,
    exitCol: 4,
    grid: [
      _d,
      _l,
      _l,
      _l,
      _d,
      _r,
      _r,
      _u,
      _r,
      _d,
      _d,
      _l,
      _l,
      _u,
      _d,
      _r,
      _u,
      _r,
      _r,
      _d,
      _u,
      _r,
      _r,
      _r,
      _r,
    ],
  ),
];
