import 'arrow_model.dart';

class PuzzleModel {
  final int cols;
  final int rows;
  final List<ArrowModel> arrows;
  final String shapeName;

  PuzzleModel({
    required this.cols,
    required this.rows,
    required this.arrows,
    this.shapeName = '',
  });

  /// Deep copy with fresh arrow instances.
  PuzzleModel clone() => PuzzleModel(
    cols: cols,
    rows: rows,
    shapeName: shapeName,
    arrows: arrows
        .map(
          (a) => ArrowModel(
            id: a.id,
            col: a.col,
            row: a.row,
            dir: a.dir,
            len: a.len,
          ),
        )
        .toList(),
  );
}
