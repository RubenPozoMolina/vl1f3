import 'organism.dart';

class Cell {
  final int x;
  final int y;
  Organism? organism;
  Food? food;

  Cell({required this.x, required this.y, this.organism, this.food});

  bool get isEmpty => organism == null && food == null;
  bool get hasOrganism => organism != null;
  bool get hasFood => food != null;

  void reset() {
    organism = null;
    food = null;
  }
}

class Food {
  int? x;
  int? y;
  double energy;

  Food({
    this.x,
    this.y,
    required this.energy,
  });

  @override
  String toString() => 'Food(pos: ($x,$y), energy: ${energy.toStringAsFixed(1)})';
}
