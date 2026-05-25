import 'arrow_direction.dart';

enum CellState { idle, traced, deadEnd }

class Cell {
  final int row;
  final int col;
  ArrowDirection direction;
  CellState state;
  final bool isStart;
  final bool isExit;

  Cell({
    required this.row,
    required this.col,
    required this.direction,
    this.state = CellState.idle,
    this.isStart = false,
    this.isExit = false,
  });

  Cell copyWith({ArrowDirection? direction, CellState? state}) => Cell(
    row: row,
    col: col,
    direction: direction ?? this.direction,
    state: state ?? this.state,
    isStart: isStart,
    isExit: isExit,
  );
}
