import 'dart:math';
import 'package:flutter/material.dart';

class Game2048Page extends StatefulWidget {
  const Game2048Page({super.key});

  @override
  State<Game2048Page> createState() => _Game2048PageState();
}

class _Game2048PageState extends State<Game2048Page> {
  static const int size = 4;
  List<List<int>> board = List.generate(size, (_) => List.filled(size, 0));
  int score = 0;
  int bestScore = 0;
  bool gameOver = false;
  bool won = false;

  final Color primaryDark = const Color(0xFF0D0221);
  final Color primaryPurple = const Color(0xFF7B1FA2);
  final Color lightPurple = const Color(0xFFE040FB);
  final Color cardDark = const Color(0xFF1A1A2E);

  final Map<int, Color> tileColors = {
    0: const Color(0xFF1A1A2E),
    2: const Color(0xFF2D2B55),
    4: const Color(0xFF3D2B6B),
    8: const Color(0xFF6A1B9A),
    16: const Color(0xFF7B1FA2),
    32: const Color(0xFF8E24AA),
    64: const Color(0xFF9C27B0),
    128: const Color(0xFFAA00FF),
    256: const Color(0xFFCC00FF),
    512: const Color(0xFFE040FB),
    1024: const Color(0xFFEA80FC),
    2048: const Color(0xFFFFD700),
  };

  @override
  void initState() {
    super.initState();
    _newGame();
  }

  void _newGame() {
    board = List.generate(size, (_) => List.filled(size, 0));
    score = 0;
    gameOver = false;
    won = false;
    _addRandom();
    _addRandom();
    setState(() {});
  }

  void _addRandom() {
    final empties = <List<int>>[];
    for (int r = 0; r < size; r++)
      for (int c = 0; c < size; c++)
        if (board[r][c] == 0) empties.add([r, c]);
    if (empties.isEmpty) return;
    final pos = empties[Random().nextInt(empties.length)];
    board[pos[0]][pos[1]] = Random().nextInt(10) < 9 ? 2 : 4;
  }

  List<int> _merge(List<int> row) {
    List<int> filtered = row.where((v) => v != 0).toList();
    for (int i = 0; i < filtered.length - 1; i++) {
      if (filtered[i] == filtered[i + 1]) {
        filtered[i] *= 2;
        score += filtered[i];
        if (score > bestScore) bestScore = score;
        if (filtered[i] == 2048) won = true;
        filtered[i + 1] = 0;
      }
    }
    filtered = filtered.where((v) => v != 0).toList();
    while (filtered.length < size) filtered.add(0);
    return filtered;
  }

  bool _move(String dir) {
    final prev = board.map((r) => List<int>.from(r)).toList();
    for (int r = 0; r < size; r++) {
      List<int> row;
      switch (dir) {
        case 'left':
          row = _merge(board[r]);
          board[r] = row;
          break;
        case 'right':
          row = _merge(board[r].reversed.toList()).reversed.toList();
          board[r] = row;
          break;
        case 'up':
          List<int> col = List.generate(size, (i) => board[i][r]);
          col = _merge(col);
          for (int i = 0; i < size; i++) board[i][r] = col[i];
          break;
        case 'down':
          List<int> col = List.generate(size, (i) => board[i][r]).reversed.toList();
          col = _merge(col).reversed.toList();
          for (int i = 0; i < size; i++) board[i][r] = col[i];
          break;
      }
    }
    bool changed = false;
    for (int r = 0; r < size; r++)
      for (int c = 0; c < size; c++)
        if (board[r][c] != prev[r][c]) changed = true;
    return changed;
  }

  bool _isGameOver() {
    for (int r = 0; r < size; r++)
      for (int c = 0; c < size; c++) {
        if (board[r][c] == 0) return false;
        if (r < size - 1 && board[r][c] == board[r + 1][c]) return false;
        if (c < size - 1 && board[r][c] == board[r][c + 1]) return false;
      }
    return true;
  }

  void _handleSwipe(String dir) {
    if (gameOver) return;
    final changed = _move(dir);
    if (changed) {
      _addRandom();
      if (_isGameOver()) gameOver = true;
    }
    setState(() {});
  }

  Color _tileColor(int val) => tileColors[val] ?? const Color(0xFFFFD700);

  Color _textColor(int val) {
    if (val == 0) return Colors.transparent;
    if (val <= 4) return Colors.white54;
    return Colors.white;
  }

  String _tileText(int val) => val == 0 ? '' : val.toString();

  double _fontSize(int val) {
    if (val >= 1024) return 16;
    if (val >= 128) return 20;
    return 24;
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
        title: Text("2048",
            style: TextStyle(
              color: Colors.white, fontFamily: 'Orbitron',
              fontWeight: FontWeight.bold, fontSize: 22,
              shadows: [Shadow(color: const Color(0xFFFFD700).withOpacity(0.8), blurRadius: 10)],
            )),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: lightPurple),
            onPressed: () => setState(_newGame),
          ),
        ],
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryPurple.withOpacity(0.4), Colors.transparent],
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Score
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _scoreBox("SCORE", score, lightPurple),
                _scoreBox("BEST", bestScore, const Color(0xFFFFD700)),
              ],
            ),
          ),

          // Board
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GestureDetector(
                  onVerticalDragEnd: (d) {
                    if (d.primaryVelocity! < -200) _handleSwipe('up');
                    if (d.primaryVelocity! > 200) _handleSwipe('down');
                  },
                  onHorizontalDragEnd: (d) {
                    if (d.primaryVelocity! < -200) _handleSwipe('left');
                    if (d.primaryVelocity! > 200) _handleSwipe('right');
                  },
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A0A1A),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: primaryPurple.withOpacity(0.5)),
                        boxShadow: [BoxShadow(color: primaryPurple.withOpacity(0.3), blurRadius: 20)],
                      ),
                      child: Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: GridView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: size, crossAxisSpacing: 8, mainAxisSpacing: 8,
                              ),
                              itemCount: size * size,
                              itemBuilder: (_, idx) {
                                final r = idx ~/ size, c = idx % size;
                                final val = board[r][c];
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 100),
                                  decoration: BoxDecoration(
                                    color: _tileColor(val),
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: val > 0 ? [BoxShadow(color: _tileColor(val).withOpacity(0.5), blurRadius: 8)] : null,
                                  ),
                                  child: Center(
                                    child: Text(
                                      _tileText(val),
                                      style: TextStyle(
                                        color: _textColor(val),
                                        fontFamily: 'Orbitron',
                                        fontSize: _fontSize(val),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          if (gameOver || won)
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.75),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      won ? "🎉 2048!" : "GAME OVER",
                                      style: TextStyle(
                                        color: won ? const Color(0xFFFFD700) : const Color(0xFFFF1744),
                                        fontFamily: 'Orbitron', fontSize: 28, fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text("Score: $score", style: TextStyle(color: lightPurple, fontFamily: 'Orbitron', fontSize: 16)),
                                    const SizedBox(height: 20),
                                    GestureDetector(
                                      onTap: () => setState(_newGame),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(colors: [primaryPurple, const Color(0xFFAA00FF)]),
                                          borderRadius: BorderRadius.circular(30),
                                        ),
                                        child: const Text("MAIN LAGI", style: TextStyle(
                                            color: Colors.white, fontFamily: 'Orbitron',
                                            fontSize: 16, fontWeight: FontWeight.bold)),
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
          ),

          // D-pad
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              _dpad(Icons.keyboard_arrow_up, 'up'),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _dpad(Icons.keyboard_arrow_left, 'left'),
                const SizedBox(width: 60),
                _dpad(Icons.keyboard_arrow_right, 'right'),
              ]),
              _dpad(Icons.keyboard_arrow_down, 'down'),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _scoreBox(String label, int val, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Column(children: [
      Text(label, style: TextStyle(color: color.withOpacity(0.7), fontFamily: 'ShareTechMono', fontSize: 10)),
      Text(val.toString(), style: TextStyle(color: color, fontFamily: 'Orbitron', fontSize: 20, fontWeight: FontWeight.bold)),
    ]),
  );

  Widget _dpad(IconData icon, String dir) => GestureDetector(
    onTap: () => _handleSwipe(dir),
    child: Container(
      width: 56, height: 56, margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: primaryPurple.withOpacity(0.3), borderRadius: BorderRadius.circular(12),
        border: Border.all(color: lightPurple.withOpacity(0.4)),
      ),
      child: Icon(icon, color: lightPurple, size: 26),
    ),
  );
}
