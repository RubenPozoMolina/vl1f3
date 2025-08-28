class Organism {
  int x;
  int y;
  double energy;
  double speed;
  double size;
  final int id;
  static int _nextId = 0;

  Organism({
    required this.x,
    required this.y,
    required this.energy,
    required this.speed,
    required this.size,
  }) : id = _nextId++;

  @override
  String toString() => 'Organism(id: $id, pos: ($x,$y), energy: ${energy.toStringAsFixed(1)})';
}
