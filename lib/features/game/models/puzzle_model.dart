import 'arrow_model.dart';
import 'cat_model.dart';

class PuzzleModel {
  final int cols;
  final int rows;
  final List<ArrowModel> arrows;
  final String shapeName;
  final CatModel? cat;

  PuzzleModel({
    required this.cols,
    required this.rows,
    required this.arrows,
    this.shapeName = '',
    this.cat,
  });

  bool get isCatLevel => cat != null;

  PuzzleModel clone() => PuzzleModel(
    cols: cols,
    rows: rows,
    shapeName: shapeName,
    cat: cat != null
        ? CatModel(col: cat!.col, row: cat!.row, exitDir: cat!.exitDir)
        : null,
    arrows: arrows
        .map(
          (a) =>
              ArrowModel(id: a.id, path: List.of(a.path), headDir: a.headDir),
        )
        .toList(),
  );
}
