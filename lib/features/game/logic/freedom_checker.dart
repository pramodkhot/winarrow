import '../models/arrow_model.dart';

/// Returns true if [arrow] can escape off the board edge without being
/// blocked by any non-freed arrow in [allArrows].
///
/// Pass [freedMask] as a bitmask of already-freed arrow ids (by list index)
/// to use during solvability simulation. Pass null for live gameplay (rely
/// on arrow.status instead).
bool canFree(
  ArrowModel arrow,
  List<ArrowModel> allArrows,
  int cols,
  int rows, {
  int? freedMask,
}) {
  // Build occupied-cells set excluding the tested arrow and freed arrows.
  final occupied = <int>{}; // encoded as col * 100 + row

  for (int i = 0; i < allArrows.length; i++) {
    final a = allArrows[i];
    if (a.id == arrow.id) continue;

    final alreadyFreed = freedMask != null
        ? (freedMask >> i) & 1 == 1
        : a.status == ArrowStatus.freed || a.status == ArrowStatus.animating;
    if (alreadyFreed) continue;

    for (final (c, r) in a.cells) {
      occupied.add(c * 1000 + r);
    }
  }

  // Walk from just ahead of the head toward the board edge.
  final (dx, dy) = arrow.dir.vector;
  int c = arrow.headCol + dx;
  int r = arrow.headRow + dy;

  while (c >= 0 && c < cols && r >= 0 && r < rows) {
    if (occupied.contains(c * 1000 + r)) return false; // blocked
    c += dx;
    r += dy;
  }
  return true; // free to escape
}
