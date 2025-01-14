import 'package:flutter/material.dart'; // Core Flutter library for UI
import 'package:esense_flutter/esense.dart'; // eSense package for Bluetooth earable integration
import 'package:permission_handler/permission_handler.dart'; // Permission handler for runtime permission requests
import 'dart:async'; // For using Timer and asynchronous programming
import 'dart:math' as math; // For mathematical functions

void main() {
  runApp(const MyApp()); // entry point of the application
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ESense Balance Ball', // Application title
      theme: ThemeData(
        primarySwatch: Colors.blue, // Default theme color
        brightness: Brightness.dark, // Dark theme
      ),
      home: const ESensePage(), // Starting page of the app
    );
  }
}

class ESensePage extends StatefulWidget {
  const ESensePage({super.key});

  @override
  ESensePageState createState() => ESensePageState(); // State management for ESensePage
}

class ESensePageState extends State<ESensePage> with TickerProviderStateMixin {
  final String deviceName = 'eSense-0114';
  bool _connected = false;
  String _connectionStatus = 'Disconnected'; // Display message for connection status
  late final ESenseManager eSenseManager; // Manager for eSense device communication

  // Ball position and game state
  double _ballX = 0.0; // X-coordinate of the ball
  double _ballY = 0.0; // Y-coordinate of the ball
  int _score = 0; // Player's score
  bool _isPlaying = false; // Game state
  Timer? _gameTimer; // Timer for game updates
  Timer? _countdownTimer; // Timer for countdown
  int _timeLeft = 90; // Game duration in seconds
  List<Offset> _targets = []; // List of target positions
  final double _ballSize = 20.0; // Diameter of the ball
  final double _targetSize = 30.0; // Diameter of each target

  late AnimationController _connectAnimController; // Animation for connection status

  @override
  void initState() {
    super.initState();
    eSenseManager = ESenseManager(deviceName); // Initialize eSenseManager with device name
    _connectAnimController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    // Request permissions and connect to eSense device
    requestBluetoothPermissions().then((_) {
      _connectToESense();
    });
  }

  // Request necessary Bluetooth and location permissions
  Future<void> requestBluetoothPermissions() async {
    if (await Permission.bluetoothScan.isDenied) {
      await Permission.bluetoothScan.request();
    }
    if (await Permission.bluetoothConnect.isDenied) {
      await Permission.bluetoothConnect.request();
    }
    if (await Permission.locationWhenInUse.isDenied) {
      await Permission.locationWhenInUse.request();
    }

    if (await Permission.location.isDenied) {
      await Permission.location.request();
    }
  }

  // Attempt to connect to the eSense device  
  Future<void> _connectToESense() async {
    setState(() => _connectionStatus = 'Connecting...');
    eSenseManager.connectionEvents.listen((event) {
      setState(() {
        _connected = event.type == ConnectionType.connected;
        _connectionStatus = _connected ? 'Connected' : 'Disconnected';
      });

      if (_connected) {
        _onESenseConnected(); // Start listening to sensor data
      }
    });

    // Retry connection if not immediately successful
    while (!_connected) {
      try {
        bool success = await eSenseManager.connect();
        if (!success) {
          setState(() => _connectionStatus = 'Connection Failed. Retrying...');
          await Future.delayed(const Duration(seconds: 3));
        } else {
          break;
        }
      } catch (e) {
        setState(() => _connectionStatus = 'Error: ${e.toString()}');
      }
    }
  }

  // Start listening for sensor events once connected
  void _onESenseConnected() {
    eSenseManager.setSamplingRate(10).then((_) {
      eSenseManager.sensorEvents.listen((event) {
        if (event.gyro != null) {

          // Update ball position
          setState(() {
            // Map X and Y gyroscope data to ball movement
            _ballX += event.gyro![0] / 1000;
            _ballY += event.gyro![1] / 1000;

            double zInfluence = event.gyro![2] / 1000;
            _ballX += zInfluence * 0.1; // Adjust based on Z-axis, if relevant
          });
          // Call updateBallPosition to ensure the ball stays within bounds
          updateBallPosition();
        }
      });
    });
  }

  // Constrain the ball's movement to the playfield
  void updateBallPosition() {
    double playfieldWidth = 300; // Playfield width (from the container size)
    double playfieldHeight = 300; // Playfield height (from the container size)
    double ballRadius = _ballSize / 2;

    // Prevent ball from going out of bounds (playfield boundaries)
    if (_ballX - ballRadius < -playfieldWidth / 2) {
      _ballX = -playfieldWidth / 2 +
          ballRadius; // Adjust position to prevent going out
    } else if (_ballX + ballRadius > playfieldWidth / 2) {
      _ballX = playfieldWidth / 2 -
          ballRadius; // Adjust position to prevent going out
    }

    if (_ballY - ballRadius < -playfieldHeight / 2) {
      _ballY = -playfieldHeight / 2 +
          ballRadius; // Adjust position to prevent going out
    } else if (_ballY + ballRadius > playfieldHeight / 2) {
      _ballY = playfieldHeight / 2 -
          ballRadius; // Adjust position to prevent going out
    }

    setState(() {});
  }

  void _startGame() {
    setState(() {
      _isPlaying = true;
      _score = 0;
      _targets = [];
      _ballX = 0.0;
      _ballY = 0.0;
      _timeLeft = 90; // Start with 90 seconds (1 minute 30 seconds)
    });
    _addNewTarget();

    // Start the game timer (updates game state every 50ms)
    _gameTimer = Timer.periodic(const Duration(milliseconds: 50), _updateGame);

    // Start the countdown timer for 3 minutes
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft <= 0) {
        // Time is up, stop the game
        timer.cancel();
        setState(() {
          _isPlaying = false;
          _gameTimer?.cancel(); // Stop the game state updates
        });
        _showGameOverDialog(); // Show the game over dialog
      } else {
        setState(() {
          _timeLeft--; // Decrease time left by 1 second
        });
      }
    });
  }

  // Display game over dialog
  void _showGameOverDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Game Over'),
          content: Text('Your final score is: $_score'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _resetGame();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Reset the game state
  void _resetGame() {
    setState(() {
      _score = 0;
      _ballX = 0.0;
      _ballY = 0.0;
      _timeLeft = 90;
      _targets.clear();
      _isPlaying = false;
    });
  }
  
  // Add a new target at a random position
  void _addNewTarget() {
    final random = math.Random();
    double x = random.nextDouble() * 300 - 150;
    double y = random.nextDouble() * 300 - 150;
    setState(() => _targets.add(Offset(x, y)));
  }

 // Update game state
  void _updateGame(Timer timer) {
    if (!_isPlaying) return;

    for (int i = _targets.length - 1; i >= 0; i--) {
      if (_checkCollision(_targets[i])) {
        setState(() {
          _targets.removeAt(i);
          _score += 10;
          _addNewTarget();
        });
      }
    }
  }

  // Check for collisions with targets
  bool _checkCollision(Offset target) {
    final distance = math.sqrt(
      math.pow(_ballX - target.dx, 2) + math.pow(_ballY - target.dy, 2),
    );
    return distance < (_ballSize + _targetSize) / 2;
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _countdownTimer?.cancel();
    _connectAnimController.dispose();
    eSenseManager.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ESense Balance Ball'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Score: $_score | Time Left: ${_timeLeft ~/ 60}:${(_timeLeft % 60).toString().padLeft(2, '0')}',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _connectAnimController,
            builder: (context, child) {
              return Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _connected
                        ? Colors.green.withOpacity(_connectAnimController.value)
                        : Colors.red.withOpacity(_connectAnimController.value),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _connectionStatus,
                  style: TextStyle(
                    color: _connected ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          Center(
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Stack(
                children: [
                  ..._targets.map((target) => Positioned(
                        left: target.dx + 150 - _targetSize / 2,
                        top: target.dy + 150 - _targetSize / 2,
                        child: Container(
                          width: _targetSize,
                          height: _targetSize,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                      )),
                  Positioned(
                    left: _ballX + 150 - _ballSize / 2,
                    top: _ballY + 150 - _ballSize / 2,
                    child: Container(
                      width: _ballSize,
                      height: _ballSize,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(2, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: _connected ? _connectToESense : null,
                icon: const Icon(Icons.refresh),
                label: const Text('Reconnect'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _connected
                    ? () {
                        if (_isPlaying) {
                          setState(() {
                            _resetGame();
                          });
                        } else {
                          _startGame();
                        }
                      }
                    : null,
                icon: Icon(_isPlaying ? Icons.restart_alt_rounded : Icons.play_arrow),
                label: Text(_isPlaying ? 'Restart Game' : 'Start Game'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isPlaying ? Colors.red : Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Place the earphone on flat surface and move the earphone to move the red ball and collect the green targets!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
