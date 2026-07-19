import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PasswordGeneratorPage extends StatefulWidget {
  const PasswordGeneratorPage({super.key});

  @override
  State<PasswordGeneratorPage> createState() => _PasswordGeneratorPageState();
}

class _PasswordGeneratorPageState extends State<PasswordGeneratorPage> {
  int _length = 16;
  bool _useUpper = true;
  bool _useLower = true;
  bool _useNumbers = true;
  bool _useSymbols = true;
  String _generated = '';
  final List<String> _history = [];

  final Color primaryDark = const Color(0xFF0D0221);
  final Color primaryPurple = const Color(0xFF7B1FA2);
  final Color accentPurple = const Color(0xFFAA00FF);
  final Color lightPurple = const Color(0xFFE040FB);
  final Color cardDark = const Color(0xFF1A1A2E);
  final Color safeGreen = const Color(0xFF00E676);

  @override
  void initState() {
    super.initState();
    _generate();
  }

  void _generate() {
    const upper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const lower = 'abcdefghijklmnopqrstuvwxyz';
    const numbers = '0123456789';
    const symbols = '!@#\$%^&*()_+-=[]{}|;:,.<>?';

    String chars = '';
    if (_useUpper) chars += upper;
    if (_useLower) chars += lower;
    if (_useNumbers) chars += numbers;
    if (_useSymbols) chars += symbols;

    if (chars.isEmpty) {
      setState(() => _generated = 'Pilih setidaknya 1 karakter!');
      return;
    }

    final rng = Random.secure();
    final pwd = List.generate(_length, (_) => chars[rng.nextInt(chars.length)]).join();
    setState(() {
      _generated = pwd;
      if (_history.length >= 10) _history.removeAt(0);
      _history.add(pwd);
    });
  }

  int _getStrength() {
    if (_generated.isEmpty || _generated.contains(' ')) return 0;
    int score = 0;
    if (_generated.length >= 12) score++;
    if (_generated.length >= 16) score++;
    if (RegExp(r'[A-Z]').hasMatch(_generated)) score++;
    if (RegExp(r'[a-z]').hasMatch(_generated)) score++;
    if (RegExp(r'[0-9]').hasMatch(_generated)) score++;
    if (RegExp(r'[!@#\$%^&*]').hasMatch(_generated)) score++;
    return score;
  }

  String _strengthLabel(int s) {
    if (s <= 2) return 'LEMAH';
    if (s <= 4) return 'SEDANG';
    return 'KUAT';
  }

  Color _strengthColor(int s) {
    if (s <= 2) return const Color(0xFFFF1744);
    if (s <= 4) return const Color(0xFFFFD600);
    return safeGreen;
  }

  @override
  Widget build(BuildContext context) {
    final strength = _getStrength();
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
          "PASSWORD GENERATOR",
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Orbitron',
            fontWeight: FontWeight.bold,
            fontSize: 14,
            shadows: [Shadow(color: lightPurple.withOpacity(0.8), blurRadius: 10)],
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Generated Password Display
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: primaryPurple.withOpacity(0.5)),
                boxShadow: [
                  BoxShadow(
                      color: primaryPurple.withOpacity(0.2),
                      blurRadius: 15,
                      spreadRadius: 2)
                ],
              ),
              child: Column(
                children: [
                  SelectableText(
                    _generated,
                    style: TextStyle(
                      color: lightPurple,
                      fontFamily: 'ShareTechMono',
                      fontSize: _length > 20 ? 14 : 18,
                      letterSpacing: 2,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  // Strength bar
                  Row(
                    children: [
                      Text("STRENGTH:",
                          style: TextStyle(
                              color: Colors.grey.shade500,
                              fontFamily: 'ShareTechMono',
                              fontSize: 11)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: strength / 6,
                            backgroundColor: Colors.white10,
                            color: _strengthColor(strength),
                            minHeight: 8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _strengthLabel(strength),
                        style: TextStyle(
                          color: _strengthColor(strength),
                          fontFamily: 'Orbitron',
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: _generated));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text("Password disalin!"),
                                backgroundColor: primaryPurple,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                          },
                          icon: const Icon(Icons.copy, size: 16),
                          label: const Text("COPY",
                              style: TextStyle(fontFamily: 'Orbitron')),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryPurple.withOpacity(0.5),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _generate,
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text("BARU",
                              style: TextStyle(fontFamily: 'Orbitron')),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentPurple,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Length Slider
            Text("PANJANG: $_length karakter",
                style: TextStyle(
                    color: lightPurple,
                    fontFamily: 'Orbitron',
                    fontSize: 12,
                    letterSpacing: 1)),
            Slider(
              value: _length.toDouble(),
              min: 8,
              max: 64,
              divisions: 56,
              activeColor: lightPurple,
              inactiveColor: primaryPurple.withOpacity(0.3),
              thumbColor: lightPurple,
              onChanged: (v) => setState(() => _length = v.round()),
            ),
            const SizedBox(height: 16),

            // Options
            Text("KARAKTER:",
                style: TextStyle(
                    color: lightPurple,
                    fontFamily: 'Orbitron',
                    fontSize: 12,
                    letterSpacing: 1)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _buildToggle("A-Z BESAR", _useUpper,
                    (v) => setState(() => _useUpper = v)),
                _buildToggle("a-z kecil", _useLower,
                    (v) => setState(() => _useLower = v)),
                _buildToggle("0-9 Angka", _useNumbers,
                    (v) => setState(() => _useNumbers = v)),
                _buildToggle("!@# Simbol", _useSymbols,
                    (v) => setState(() => _useSymbols = v)),
              ],
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _generate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryPurple,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  elevation: 8,
                  shadowColor: primaryPurple.withOpacity(0.5),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.auto_fix_high, color: Colors.white),
                    SizedBox(width: 10),
                    Text("GENERATE PASSWORD",
                        style: TextStyle(
                            fontFamily: 'Orbitron',
                            color: Colors.white,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),

            // History
            if (_history.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text("RIWAYAT (${_history.length})",
                  style: TextStyle(
                      color: lightPurple,
                      fontFamily: 'Orbitron',
                      fontSize: 12,
                      letterSpacing: 1)),
              const SizedBox(height: 12),
              ..._history.reversed.map((pwd) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: cardDark,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: primaryPurple.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(pwd,
                              style: const TextStyle(
                                  color: Colors.white70,
                                  fontFamily: 'ShareTechMono',
                                  fontSize: 12),
                              overflow: TextOverflow.ellipsis),
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: Icon(Icons.copy,
                              color: Colors.grey.shade500, size: 18),
                          onPressed: () =>
                              Clipboard.setData(ClipboardData(text: pwd)),
                        ),
                      ],
                    ),
                  )),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildToggle(String label, bool value, Function(bool) onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: value ? primaryPurple.withOpacity(0.4) : cardDark,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: value ? lightPurple.withOpacity(0.6) : Colors.white12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              value ? Icons.check_box : Icons.check_box_outline_blank,
              color: value ? lightPurple : Colors.grey.shade600,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    color: value ? Colors.white : Colors.grey.shade500,
                    fontFamily: 'ShareTechMono',
                    fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
