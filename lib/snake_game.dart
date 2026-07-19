import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum Direction { up, down, left, right }
enum GameState { idle, playing, paused, gameOver }

class SnakeGamePage extends StatefulWidget {
  const SnakeGamePage({super.key});

  @override
  State<SnakeGamePage> createState() => _SnakeGamePageState();
}

class _SnakeGamePageState extends State<SnakeGamePage> {
  static const int gridSize = 20;
  static const int cellCount = gridSize * gridSize;

  List<int> snake = [45, 44, 43];
  int food = 100;
  Direction direction = Direction.right;
  Direction nextDirection = Direction.right;
  GameState gameState = GameState.idle;
  Timer? _timer;
  int score = 0;
  int highScore = 0;
  int speed = 200;

  final Color primaryDark = const Color(0xFF0D0221);
  final Color primaryPurple = const Color(0xFF7B1FA2);
  final Color accentPurple = const Color(0xFFAA00FF);
  final Color lightPurple = const Color(0xFFE040FB);
  final Color snakeColor = const Color(0xFF00E676);
  final Color foodColor = const Color(0xFFFF1744);
  final Color headColor = const Color(0xFF69FF47);

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startGame() {
    snake = [45, 44, 43];
    direction = Direction.right;
    nextDirection = Direction.right;
    score = 0;
    speed = 200;
    _spawnFood();
    setState(() => gameState = GameState.playing);
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(Duration(milliseconds: speed), (_) => _update());
  }

  void _spawnFood() {
    final rng = Random();
    do {
      food = rng.nextInt(cellCount);
    } while (snake.contains(food));
  }

  void _update() {
    if (gameState != GameState.playing) return;
    direction = nextDirection;

    final head = snake.first;
    int newHead;

    switch (direction) {
      case Direction.up:
        newHead = head - gridSize;
        if (newHead < 0) { _gameOver(); return; }
        break;
      case Direction.down:
        newHead = head + gridSize;
        if (newHead >= cellCount) { _gameOver(); return; }
        break;
      case Direction.left:
        if (head % gridSize == 0) { _gameOver(); return; }
        newHead = head - 1;
        break;
      case Direction.right:
        if (head % gridSize == gridSize - 1) { _gameOver(); return; }
        newHead = head + 1;
        break;
    }

    if (snake.contains(newHead)) { _gameOver(); return; }

    setState(() {
      snake.insert(0, newHead);
      if (newHead == food) {
        score += 10;
        if (score > highScore) highScore = score;
        _spawnFood();
        if (score % 50 == 0 && speed > 80) {
          speed -= 20;
          _startTimer();
        }
      } else {
        snake.removeLast();
      }
    });
  }

  void _gameOver() {
    _timer?.cancel();
    if (score > highScore) highScore = score;
    setState(() => gameState = GameState.gameOver);
  }

  void _changeDirection(Direction d) {
    if (d == Direction.up && direction == Direction.down) return;
    if (d == Direction.down && direction == Direction.up) return;
    if (d == Direction.left && direction == Direction.right) return;
    if (d == Direction.right && direction == Direction.left) return;
    nextDirection = d;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "SNAKE GAME",
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Orbitron',
            fontWeight: FontWeight.bold,
            fontSize: 16,
            shadows: [Shadow(color: snakeColor.withOpacity(0.8), blurRadius: 10)],
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryPurple.withOpacity(0.4), Colors.transparent],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Score bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildScoreBox("SCORE", score.toString(), snakeColor),
                if (gameState == GameState.playing)
                  GestureDetector(
                    onTap: () {
                      if (gameState == GameState.playing) {
                        _timer?.cancel();
                        setState(() => gameState = GameState.paused);
                      } else if (gameState == GameState.paused) {
                        setState(() => gameState = GameState.playing);
                        _startTimer();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: primaryPurple.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: lightPurple.withOpacity(0.4)),
                      ),
                      child: Icon(
                        gameState == GameState.paused
                            ? Icons.play_arrow
                            : Icons.pause,
                        color: lightPurple,
                      ),
                    ),
                  ),
                _buildScoreBox("BEST", highScore.toString(), lightPurple),
              ],
            ),
          ),

          // Game grid
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: AspectRatio(
                aspectRatio: 1,
                child: GestureDetector(
                  onVerticalDragUpdate: (d) {
                    if (d.delta.dy < -5) _changeDirection(Direction.up);
                    if (d.delta.dy > 5) _changeDirection(Direction.down);
                  },
                  onHorizontalDragUpdate: (d) {
                    if (d.delta.dx < -5) _changeDirection(Direction.left);
                    if (d.delta.dx > 5) _changeDirection(Direction.right);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A0A1A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: primaryPurple.withOpacity(0.5)),
                      boxShadow: [
                        BoxShadow(
                            color: primaryPurple.withOpacity(0.3),
                            blurRadius: 15,
                            spreadRadius: 2)
                      ],
                    ),
                    child: Stack(
                      children: [
                        GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: gridSize,
                          ),
                          itemCount: cellCount,
                          itemBuilder: (_, idx) {
                            Color cellColor = Colors.transparent;
                            if (snake.isNotEmpty && idx == snake.first) {
                              cellColor = headColor;
                            } else if (snake.contains(idx)) {
                              final pos = snake.indexOf(idx);
                              final ratio = 1 - (pos / snake.length * 0.6);
                              cellColor = snakeColor.withOpacity(ratio);
                            } else if (idx == food) {
                              cellColor = foodColor;
                            }
                            return Container(
                              margin: const EdgeInsets.all(0.5),
                              decoration: BoxDecoration(
                                color: cellColor,
                                borderRadius: BorderRadius.circular(2),
                                boxShadow: idx == food
                                    ? [
                                        BoxShadow(
                                            color: foodColor.withOpacity(0.6),
                                            blurRadius: 6)
                                      ]
                                    : snake.isNotEmpty && idx == snake.first
                                        ? [
                                            BoxShadow(
                                                color: headColor.withOpacity(0.6),
                                                blurRadius: 4)
                                          ]
                                        : null,
                              ),
                            );
                          },
                        ),
                        // Overlay states
                        if (gameState == GameState.idle ||
                            gameState == GameState.gameOver ||
                            gameState == GameState.paused)
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.75),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (gameState == GameState.gameOver) ...[
                                    Text("GAME OVER",
                                        style: TextStyle(
                                            color: foodColor,
                                            fontFamily: 'Orbitron',
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 8),
                                    Text("Score: $score",
                                        style: TextStyle(
                                            color: snakeColor,
                                            fontFamily: 'Orbitron',
                                            fontSize: 16)),
                                    const SizedBox(height: 20),
                                  ] else if (gameState == GameState.paused) ...[
                                    Text("PAUSED",
                                        style: TextStyle(
                                            color: lightPurple,
                                            fontFamily: 'Orbitron',
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 20),
                                  ] else ...[
                                    Icon(Icons.sports_esports,
                                        color: snakeColor, size: 60),
                                    const SizedBox(height: 12),
                                    Text("SNAKE",
                                        style: TextStyle(
                                            color: snakeColor,
                                            fontFamily: 'Orbitron',
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 20),
                                  ],
                                  GestureDetector(
                                    onTap: gameState == GameState.paused
                                        ? () {
                                            setState(() =>
                                                gameState = GameState.playing);
                                            _startTimer();
                                          }
                                        : _startGame,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 32, vertical: 14),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            primaryPurple,
                                            accentPurple
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(30),
                                        boxShadow: [
                                          BoxShadow(
                                              color: primaryPurple
                                                  .withOpacity(0.5),
                                              blurRadius: 15)
                                        ],
                                      ),
                                      child: Text(
                                        gameState == GameState.paused
                                            ? "LANJUT"
                                            : gameState == GameState.gameOver
                                                ? "MAIN LAGI"
                                                : "MULAI",
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontFamily: 'Orbitron',
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // D-pad controls
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildControlBtn(Icons.keyboard_arrow_up, Direction.up),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildControlBtn(Icons.keyboard_arrow_left, Direction.left),
                    const SizedBox(width: 60),
                    _buildControlBtn(Icons.keyboard_arrow_right, Direction.right),
                  ],
                ),
                _buildControlBtn(Icons.keyboard_arrow_down, Direction.down),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreBox(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(label,
              style: TextStyle(
                  color: color.withOpacity(0.7),
                  fontFamily: 'ShareTechMono',
                  fontSize: 10)),
          Text(value,
              style: TextStyle(
                  color: color,
                  fontFamily: 'Orbitron',
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildControlBtn(IconData icon, Direction dir) {
    return GestureDetector(
      onTap: () => _changeDirection(dir),
      child: Container(
        width: 60,
        height: 60,
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: primaryPurple.withOpacity(0.3),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: lightPurple.withOpacity(0.4)),
          boxShadow: [
            BoxShadow(
                color: primaryPurple.withOpacity(0.2),
                blurRadius: 8,
                spreadRadius: 1)
          ],
        ),
        child: Icon(icon, color: lightPurple, size: 28),
      ),
    );
  }
}
