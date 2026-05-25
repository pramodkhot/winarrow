import '../models/arrow_model.dart';

/// Returns true if [arrow] can escape off the board edge in its head direction
/// without being blocked by any non-freed arrow in [allArrows].
bool canFree(
  ArrowModel arrow,
  List<ArrowModel> allArrows,
  int cols,
  int rows, {
  int? freedMask,
}) {
  final occupied = <int>{};

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
