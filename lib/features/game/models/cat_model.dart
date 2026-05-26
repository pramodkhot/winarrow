import 'arrow_model.dart';

enum CatStatus { waiting, escaping, freed }

class CatModel {
  final int col;
  final int row;
  final ArrowDir exitDir;
  CatStatus status;

  CatModel({
    required this.col,
    required this.row,
    required this.exitDir,
    this.status = CatStatus.waiting,
  });
}
