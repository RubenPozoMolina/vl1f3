import 'package:flutter/material.dart';
import 'environment_manager.dart';
import 'cell.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'vl1f3 - Artificial Life Ecosystem',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'vl1f3 - Virtual Ecosystem'),
    );
  }
}

class EnvironmentVisualization extends StatelessWidget {
  final EnvironmentManager environmentManager;

  const EnvironmentVisualization({
    super.key,
    required this.environmentManager,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: environmentManager.width,
          childAspectRatio: 1.0,
        ),
        itemCount: environmentManager.width * environmentManager.height,
        itemBuilder: (context, index) {
          final x = index % environmentManager.width;
          final y = index ~/ environmentManager.width;
          final cell = environmentManager.getCellAt(x, y);

          return Container(
            margin: const EdgeInsets.all(0.5),
            decoration: BoxDecoration(
              color: _getCellColor(cell),
              borderRadius: BorderRadius.circular(2.0),
              border: Border.all(
                color: Colors.grey.shade300,
                width: 0.5,
              ),
            ),
            child: _getCellContent(cell),
          );
        },
      ),
    );
  }

  Color _getCellColor(Cell cell) {
    if (cell.hasOrganism) {
      // Color based on organism energy
      final energy = cell.organism!.energy;
      if (energy > 100) return Colors.red.shade400;
      if (energy > 75) return Colors.orange.shade400;
      if (energy > 50) return Colors.yellow.shade400;
      return Colors.pink.shade300;
    } else if (cell.hasFood) {
      return Colors.green.shade300;
    } else {
      return Colors.grey.shade100;
    }
  }

  Widget? _getCellContent(Cell cell) {
    if (cell.hasOrganism) {
      return Center(
        child: Container(
          width: cell.organism!.size * 2,
          height: cell.organism!.size * 2,
          decoration: const BoxDecoration(
            color: Colors.black54,
            shape: BoxShape.circle,
          ),
        ),
      );
    } else if (cell.hasFood) {
      return const Center(
        child: Icon(
          Icons.grain,
          size: 8,
          color: Colors.green,
        ),
      );
    }
    return null;
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late EnvironmentManager _environmentManager;

  @override
  void initState() {
    super.initState();
    _environmentManager = EnvironmentManager(
      width: 50,
      height: 50,
      onStateChanged: () {
        if (mounted) setState(() {});
      },
    );
  }

  @override
  void dispose() {
    _environmentManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Row(
        children: [
          // Environment area - 60% of screen width
          Expanded(
            flex: 60,
            child: Container(
              margin: const EdgeInsets.all(16.0),
              child: AspectRatio(
                aspectRatio: 1.0, // Makes it a square
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    border: Border.all(
                      color: Colors.green.shade400,
                      width: 2.0,
                    ),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: EnvironmentVisualization(
                    environmentManager: _environmentManager,
                  ),
                ),
              ),
            ),
          ),
          // Toolbar area - 40% of screen width
          Expanded(
            flex: 40,
            child: Container(
              margin: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border.all(
                  color: Colors.grey.shade300,
                  width: 1.0,
                ),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8.0),
                        topRight: Radius.circular(8.0),
                      ),
                    ),
                    child: const Text(
                      'Toolbar',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _environmentManager.state == SimulationState.stopped
                                ? () => _environmentManager.startSimulation()
                                : _environmentManager.state == SimulationState.paused
                                    ? () => _environmentManager.resumeSimulation()
                                    : () => _environmentManager.pauseSimulation(),
                            icon: Icon(_environmentManager.state == SimulationState.running 
                                ? Icons.pause 
                                : Icons.play_arrow),
                            label: Text(_environmentManager.state == SimulationState.running
                                ? 'Pause'
                                : _environmentManager.state == SimulationState.paused
                                    ? 'Resume'
                                    : 'Start Simulation'),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () => _environmentManager.resetEnvironment(),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reset'),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Controls',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text('Speed: ${_environmentManager.simulationSpeed.toStringAsFixed(1)}x'),
                          Slider(
                            value: _environmentManager.simulationSpeed,
                            min: 0.1,
                            max: 5.0,
                            divisions: 49,
                            onChanged: (value) => _environmentManager.setSimulationSpeed(value),
                          ),
                          Text('Population: ${_environmentManager.populationCount}'),
                          Text('Generation: ${_environmentManager.generation}'),
                          Text('State: ${_environmentManager.state.name}'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
