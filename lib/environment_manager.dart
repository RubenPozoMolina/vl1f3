import 'dart:math';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'cell.dart';
import 'organism.dart';

enum SimulationState { stopped, running, paused }

class EnvironmentManager {
  static const int defaultWidth = 100;
  static const int defaultHeight = 100;

  final int width;
  final int height;
  final List<List<Cell>> _grid;
  final List<Organism> _organisms;
  final Random _random;

  SimulationState _state;
  int _generation;
  double _simulationSpeed;
  Timer? _simulationTimer;

  // Callback for UI updates
  VoidCallback? onStateChanged;

  EnvironmentManager({
    this.width = defaultWidth,
    this.height = defaultHeight,
    this.onStateChanged,
  }) : _grid = List.generate(
         height,
         (y) => List.generate(
           width,
           (x) => Cell(x: x, y: y),
         ),
       ),
       _organisms = [],
       _random = Random(),
       _state = SimulationState.stopped,
       _generation = 0,
       _simulationSpeed = 1.0;

  // Getters
  SimulationState get state => _state;
  int get generation => _generation;
  double get simulationSpeed => _simulationSpeed;
  int get populationCount => _organisms.length;
  List<Organism> get organisms => List.unmodifiable(_organisms);

  // Environment control methods
  void startSimulation() {
    if (_state != SimulationState.running) {
      _state = SimulationState.running;
      if (_organisms.isEmpty) {
        _initializeEnvironment();
      }
      _startSimulationTimer();
      _notifyStateChanged();
    }
  }

  void pauseSimulation() {
    if (_state == SimulationState.running) {
      _state = SimulationState.paused;
      _simulationTimer?.cancel();
      _notifyStateChanged();
    }
  }

  void resumeSimulation() {
    if (_state == SimulationState.paused) {
      _state = SimulationState.running;
      _startSimulationTimer();
      _notifyStateChanged();
    }
  }

  void stopSimulation() {
    _state = SimulationState.stopped;
    _simulationTimer?.cancel();
    _notifyStateChanged();
  }

  void resetEnvironment() {
    _simulationTimer?.cancel();
    _state = SimulationState.stopped;
    _generation = 0;
    _organisms.clear();
    _clearGrid();
    _notifyStateChanged();
  }

  void setSimulationSpeed(double speed) {
    _simulationSpeed = speed.clamp(0.1, 5.0);
    if (_state == SimulationState.running) {
      _startSimulationTimer();
    }
    _notifyStateChanged();
  }

  void dispose() {
    _simulationTimer?.cancel();
  }

  // Get cell at position for rendering
  Cell getCellAt(int x, int y) {
    if (_isValidPosition(x, y)) {
      return _grid[y][x];
    }
    return Cell(x: x, y: y);
  }

  // Get environment statistics
  Map<String, dynamic> getStatistics() {
    return {
      'population': populationCount,
      'generation': generation,
      'state': state.name,
      'speed': simulationSpeed,
      'totalFood': _getTotalFood(),
      'averageEnergy': _getAverageEnergy(),
    };
  }

  // Private methods
  void _startSimulationTimer() {
    _simulationTimer?.cancel();
    final intervalMs = (1000 / (_simulationSpeed * 10)).round();
    _simulationTimer = Timer.periodic(
      Duration(milliseconds: intervalMs),
      (timer) => _updateSimulation(),
    );
  }

  void _notifyStateChanged() {
    onStateChanged?.call();
  }

  void _initializeEnvironment() {
    _clearGrid();
    _organisms.clear();

    // Add initial organisms
    for (int i = 0; i < 20; i++) {
      _addRandomOrganism();
    }

    // Add food sources
    for (int i = 0; i < 50; i++) {
      _addRandomFood();
    }
  }

  void _clearGrid() {
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        _grid[y][x].reset();
      }
    }
  }

  void _addRandomOrganism() {
    int x = _random.nextInt(width);
    int y = _random.nextInt(height);

    if (_grid[y][x].isEmpty) {
      var organism = Organism(
        x: x,
        y: y,
        energy: 100.0,
        speed: _random.nextDouble() * 2 + 0.5,
        size: _random.nextDouble() * 3 + 1,
      );

      _organisms.add(organism);
      _grid[y][x].organism = organism;
    }
  }

  void _addRandomFood() {
    int x = _random.nextInt(width);
    int y = _random.nextInt(height);

    if (_grid[y][x].food == null) {
      _grid[y][x].food = Food(energy: _random.nextDouble() * 50 + 10);
    }
  }

  void _updateSimulation() {
    if (_state != SimulationState.running) return;

    // Update organisms
    var organismsToRemove = <Organism>[];
    var organismsToAdd = <Organism>[];

    // Create a copy of the list to avoid concurrent modification
    var currentOrganisms = List<Organism>.from(_organisms);

    for (var organism in currentOrganisms) {
      _updateOrganism(organism, organismsToAdd);

      if (organism.energy <= 0) {
        organismsToRemove.add(organism);
        _grid[organism.y][organism.x].organism = null;
      }
    }

    // Remove dead organisms
    for (var organism in organismsToRemove) {
      _organisms.remove(organism);
    }

    // Add new organisms from reproduction
    for (var organism in organismsToAdd) {
      _organisms.add(organism);
    }

    // Add new food periodically
    if (_random.nextDouble() < 0.1) {
      _addRandomFood();
    }

    // Check for generation advancement
    if (_organisms.length < 5) {
      _advanceGeneration();
    }

    _notifyStateChanged();
  }

  void _updateOrganism(Organism organism, List<Organism> organismsToAdd) {
    // Consume energy for being alive
    organism.energy -= 0.5;

    // Look for food nearby
    var nearbyFood = _findNearbyFood(organism);
    if (nearbyFood != null) {
      organism.energy += nearbyFood.energy;
      _grid[nearbyFood.y!][nearbyFood.x!].food = null;
    } else {
      // Move randomly if no food nearby
      _moveOrganismRandomly(organism);
    }

    // Reproduction if enough energy
    if (organism.energy > 150 && _random.nextDouble() < 0.05) {
      _reproduceOrganism(organism, organismsToAdd);
    }
  }

  Food? _findNearbyFood(Organism organism) {
    for (int dy = -2; dy <= 2; dy++) {
      for (int dx = -2; dx <= 2; dx++) {
        int newX = organism.x + dx;
        int newY = organism.y + dy;

        if (_isValidPosition(newX, newY)) {
          var food = _grid[newY][newX].food;
          if (food != null) {
            food.x = newX;
            food.y = newY;
            return food;
          }
        }
      }
    }
    return null;
  }

  void _moveOrganismRandomly(Organism organism) {
    int newX = organism.x + _random.nextInt(3) - 1;
    int newY = organism.y + _random.nextInt(3) - 1;

    if (_isValidPosition(newX, newY) && _grid[newY][newX].organism == null) {
      _grid[organism.y][organism.x].organism = null;
      organism.x = newX;
      organism.y = newY;
      _grid[newY][newX].organism = organism;
    }
  }

  void _reproduceOrganism(Organism parent, List<Organism> organismsToAdd) {
    // Find nearby empty cell
    for (int dy = -1; dy <= 1; dy++) {
      for (int dx = -1; dx <= 1; dx++) {
        if (dx == 0 && dy == 0) continue;

        int newX = parent.x + dx;
        int newY = parent.y + dy;

        if (_isValidPosition(newX, newY) && _grid[newY][newX].isEmpty) {
          parent.energy -= 50; // Cost of reproduction

          var child = Organism(
            x: newX,
            y: newY,
            energy: 50.0,
            speed: parent.speed + (_random.nextDouble() - 0.5) * 0.2,
            size: parent.size + (_random.nextDouble() - 0.5) * 0.3,
          );

          organismsToAdd.add(child);
          _grid[newY][newX].organism = child;
          return;
        }
      }
    }
  }

  void _advanceGeneration() {
    _generation++;
    _initializeEnvironment();
  }

  bool _isValidPosition(int x, int y) {
    return x >= 0 && x < width && y >= 0 && y < height;
  }

  int _getTotalFood() {
    int count = 0;
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        if (_grid[y][x].hasFood) count++;
      }
    }
    return count;
  }

  double _getAverageEnergy() {
    if (_organisms.isEmpty) return 0.0;
    double total = _organisms.fold<double>(0.0, (sum, org) => sum + org.energy);
    return total / _organisms.length;
  }
}
