import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class BreachCheckerPage extends StatefulWidget {
  const BreachCheckerPage({super.key});

  @override
  State<BreachCheckerPage> createState() => _BreachCheckerPageState();
}

class _BreachCheckerPageState extends State<BreachCheckerPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  List<dynamic>? _breaches;
  String? _errorMessage;
  bool? _isPwned;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  final Color primaryDark = const Color(0xFF0D0221);
  final Color primaryPurple = const Color(0xFF7B1FA2);
  final Color accentPurple = const Color(0xFFAA00FF);
  final Color lightPurple = const Color(0xFFE040FB);
  final Color cardDark = const Color(0xFF1A1A2E);
  final Color dangerRed = const Color(0xFFFF1744);
  final Color safeGreen = const Color(0xFF00E676);

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _checkBreach() async {
    final input = _emailController.text.trim();
    if (input.isEmpty) {
      setState(() => _errorMessage = "Masukkan email terlebih dahulu.");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _breaches = null;
      _isPwned = null;
    });

    try {
      // Using LeakCheck API (free tier)
      final url = Uri.parse(
          'https://leakcheck.io/api/public?check=${Uri.encodeComponent(input)}');
      final response = await http.get(url, headers: {
        'User-Agent': 'Rangers/2.0',
      }).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final found = data['found'] ?? 0;
          setState(() {
            _isPwned = found > 0;
            _breaches = data['sources'] ?? [];
          });
        } else {
          // Fallback: try haveibeenpwned alternative
          await _checkAlternative(input);
        }
      } else {
        await _checkAlternative(input);
      }
    } catch (e) {
      setState(() => _errorMessage = "Gagal koneksi. Coba lagi.\n$e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkAlternative(String email) async {
    try {
      // Try using a public breach check API
      final url = Uri.parse(
          'https://api.xposedornot.com/v1/check-email/${Uri.encodeComponent(email)}');
      final resp = await http.get(url).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final breachList = data['breaches'] ?? data['BreachMetrics'] ?? [];
        setState(() {
          _isPwned = breachList is List && breachList.isNotEmpty;
          _breaches = breachList is List ? breachList : [];
        });
      } else if (resp.statusCode == 404) {
        setState(() {
          _isPwned = false;
          _breaches = [];
        });
      } else {
        setState(() => _errorMessage = "API tidak merespons. Coba beberapa saat lagi.");
      }
    } catch (e) {
      setState(() => _errorMessage = "Terjadi kesalahan: $e");
    }
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
          "BREACH CHECKER",
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Orbitron',
            fontWeight: FontWeight.bold,
            fontSize: 16,
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
            // Header Shield
            Center(
              child: AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_, __) => Transform.scale(
                  scale: _pulseAnim.value,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primaryPurple.withOpacity(0.15),
                      border: Border.all(color: lightPurple.withOpacity(0.5), width: 2),
                      boxShadow: [
                        BoxShadow(
                            color: lightPurple.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5)
                      ],
                    ),
                    child: Icon(Icons.shield_outlined, color: lightPurple, size: 50),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                "Email Breach Scanner",
                style: TextStyle(
                    color: lightPurple,
                    fontFamily: 'Orbitron',
                    fontSize: 14,
                    letterSpacing: 1.5),
              ),
            ),
            Center(
              child: Text(
                "Cek apakah email kamu bocor di database hacker",
                style: TextStyle(
                    color: Colors.grey.shade500, fontFamily: 'ShareTechMono', fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),

            // Input
            Container(
              decoration: BoxDecoration(
                color: cardDark,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: primaryPurple.withOpacity(0.5)),
                boxShadow: [
                  BoxShadow(color: primaryPurple.withOpacity(0.1), blurRadius: 10)
                ],
              ),
              child: TextField(
                controller: _emailController,
                style: const TextStyle(
                    color: Colors.white, fontFamily: 'ShareTechMono'),
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: "email@contoh.com",
                  hintStyle: TextStyle(
                      color: Colors.grey.shade600, fontFamily: 'ShareTechMono'),
                  prefixIcon: Icon(Icons.email_outlined, color: lightPurple),
                  suffixIcon: _emailController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: Colors.grey.shade500),
                          onPressed: () {
                            _emailController.clear();
                            setState(() {
                              _breaches = null;
                              _isPwned = null;
                              _errorMessage = null;
                            });
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Scan Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _checkBreach,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryPurple,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  elevation: 8,
                  shadowColor: primaryPurple.withOpacity(0.5),
                ),
                child: _isLoading
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: lightPurple, strokeWidth: 2),
                          ),
                          const SizedBox(width: 12),
                          Text("SCANNING...",
                              style: TextStyle(
                                  fontFamily: 'Orbitron',
                                  color: Colors.white,
                                  letterSpacing: 1.5)),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.radar, color: Colors.white),
                          const SizedBox(width: 10),
                          const Text("SCAN BREACH",
                              style: TextStyle(
                                  fontFamily: 'Orbitron',
                                  color: Colors.white,
                                  letterSpacing: 1.5,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),

            // Error
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: dangerRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: dangerRed.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: dangerRed),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(_errorMessage!,
                          style: TextStyle(
                              color: dangerRed,
                              fontFamily: 'ShareTechMono',
                              fontSize: 12)),
                    ),
                  ],
                ),
              ),

            // Result Banner
            if (_isPwned != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _isPwned!
                      ? dangerRed.withOpacity(0.12)
                      : safeGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isPwned! ? dangerRed.withOpacity(0.6) : safeGreen.withOpacity(0.5),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (_isPwned! ? dangerRed : safeGreen).withOpacity(0.2),
                      blurRadius: 15,
                    )
                  ],
                ),
                child: Column(
                  children: [
                    Icon(
                      _isPwned! ? Icons.dangerous : Icons.verified_user,
                      color: _isPwned! ? dangerRed : safeGreen,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _isPwned! ? "⚠ EMAIL BOCOR!" : "✓ AMAN",
                      style: TextStyle(
                        color: _isPwned! ? dangerRed : safeGreen,
                        fontFamily: 'Orbitron',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isPwned!
                          ? "Email ditemukan di ${_breaches?.length ?? 0} database breach!"
                          : "Email tidak ditemukan di database breach manapun.",
                      style: TextStyle(
                          color: Colors.grey.shade400,
                          fontFamily: 'ShareTechMono',
                          fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

            // Breach List
            if (_breaches != null && _breaches!.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                "DITEMUKAN DI:",
                style: TextStyle(
                    color: lightPurple,
                    fontFamily: 'Orbitron',
                    fontSize: 12,
                    letterSpacing: 2),
              ),
              const SizedBox(height: 12),
              ..._breaches!.map((breach) {
                final name = breach is Map
                    ? (breach['name'] ?? breach['Name'] ?? breach.toString())
                    : breach.toString();
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cardDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: dangerRed.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: dangerRed.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.warning_amber_rounded,
                            color: dangerRed, size: 18),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name.toString().toUpperCase(),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Orbitron',
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold),
                            ),
                            if (breach is Map && breach['date'] != null)
                              Text(
                                "Date: ${breach['date']}",
                                style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontFamily: 'ShareTechMono',
                                    fontSize: 11),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.copy, color: Colors.grey.shade500, size: 18),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: name.toString()));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Disalin!"),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              }),
            ],

            // Safety Tips
            if (_isPwned == true) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.tips_and_updates, color: Colors.amber, size: 18),
                        const SizedBox(width: 8),
                        Text("LANGKAH AMAN:",
                            style: TextStyle(
                                color: Colors.amber,
                                fontFamily: 'Orbitron',
                                fontSize: 12,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ...[
                      "🔐 Segera ganti password email kamu",
                      "🔑 Aktifkan Two-Factor Authentication (2FA)",
                      "🚫 Jangan gunakan password yang sama di banyak akun",
                      "📧 Periksa email untuk aktivitas mencurigakan",
                    ].map((tip) => Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(tip,
                              style: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontFamily: 'ShareTechMono',
                                  fontSize: 12)),
                        )),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
