enum ArrowDirection { up, right, down, left }

extension ArrowDirectionX on ArrowDirection {
  ArrowDirection rotated() {
    const order = [
      ArrowDirection.up,
      ArrowDirection.right,
      ArrowDirection.down,
      ArrowDirection.left,
    ];
    return order[(index + 1) % 4];
  }

  // The cell (row+dr, col+dc) this arrow points toward
  (int dr, int dc) get delta => switch (this) {
    ArrowDirection.up => (-1, 0),
    ArrowDirection.right => (0, 1),
    ArrowDirection.down => (1, 0),
    ArrowDirection.left => (0, -1),
  };

  // Arrow points back into this cell from that direction
  ArrowDirection get opposite => switch (this) {
    ArrowDirection.up => ArrowDirection.down,
    ArrowDirection.right => ArrowDirection.left,
    ArrowDirection.down => ArrowDirection.up,
    ArrowDirection.left => ArrowDirection.right,
  };
}
