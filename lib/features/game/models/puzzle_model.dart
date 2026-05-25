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

  PuzzleModel clone() => PuzzleModel(
    cols: cols,
    rows: rows,
    shapeName: shapeName,
    arrows: arrows
        .map(
          (a) =>
              ArrowModel(id: a.id, path: List.of(a.path), headDir: a.headDir),
        )
        .toList(),
  );
}
