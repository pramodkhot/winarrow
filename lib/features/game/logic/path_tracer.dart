import '../models/cell.dart';
import '../models/arrow_direction.dart';

class TraceResult {
  final List<List<CellState>> states;
  final bool solved;

  const TraceResult({required this.states, required this.solved});
}

/// Follows the directed arrows from (startRow, startCol) until the path
/// reaches the exit, hits a wall, or loops back to a visited cell.
TraceResult tracePath({
  required List<List<Cell>> grid,
  required int startRow,
  required int startCol,
  required int exitRow,
  required int exitCol,
}) {
  final rows = grid.length;
  final cols = grid[0].length;
  final states = List.generate(
    rows,
    (r) => List.generate(cols, (c) => CellState.idle),
  );

  int r = startRow, c = startCol;
  final visited = <(int, int)>{};

  while (true) {
    if (visited.contains((r, c))) {
      // Loop — mark current as dead end
      states[r][c] = CellState.deadEnd;
      break;
    }
    visited.add((r, c));
    states[r][c] = CellState.traced;

    if (r == exitRow && c == exitCol) {
      return TraceResult(states: states, solved: true);
    }

    final dir = grid[r][c].direction;
    final (dr, dc) = dir.delta;
    final nr = r + dr;
    final nc = c + dc;

    if (nr < 0 || nr >= rows || nc < 0 || nc >= cols) {
      // Walked off the edge
      states[r][c] = CellState.deadEnd;
      break;
    }

    r = nr;
    c = nc;
  }

  return TraceResult(states: states, solved: false);
}
