import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class UrlShortenerPage extends StatefulWidget {
  const UrlShortenerPage({super.key});

  @override
  State<UrlShortenerPage> createState() => _UrlShortenerPageState();
}

class _UrlShortenerPageState extends State<UrlShortenerPage> {
  final TextEditingController _urlCtrl = TextEditingController();
  bool _isLoading = false;
  String? _shortUrl;
  String? _error;
  final List<Map<String, String>> _history = [];

  final Color primaryDark = const Color(0xFF0D0221);
  final Color primaryPurple = const Color(0xFF7B1FA2);
  final Color accentPurple = const Color(0xFFAA00FF);
  final Color lightPurple = const Color(0xFFE040FB);
  final Color cardDark = const Color(0xFF1A1A2E);
  final Color cyanBlue = const Color(0xFF00E5FF);

  Future<void> _shorten() async {
    String url = _urlCtrl.text.trim();
    if (url.isEmpty) {
      setState(() => _error = "Masukkan URL yang ingin diperpendek.");
      return;
    }
    if (!url.startsWith('http')) url = 'https://$url';

    setState(() {
      _isLoading = true;
      _error = null;
      _shortUrl = null;
    });

    try {
      // Try TinyURL API
      final resp = await http.get(
        Uri.parse('https://tinyurl.com/api-create.php?url=${Uri.encodeComponent(url)}'),
      ).timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200 && resp.body.startsWith('http')) {
        setState(() {
          _shortUrl = resp.body.trim();
          _history.insert(0, {'original': url, 'short': _shortUrl!});
          if (_history.length > 20) _history.removeLast();
        });
      } else {
        // Fallback: is.gd
        final resp2 = await http.get(
          Uri.parse('https://is.gd/create.php?format=simple&url=${Uri.encodeComponent(url)}'),
        ).timeout(const Duration(seconds: 10));
        if (resp2.statusCode == 200 && resp2.body.startsWith('http')) {
          setState(() {
            _shortUrl = resp2.body.trim();
            _history.insert(0, {'original': url, 'short': _shortUrl!});
            if (_history.length > 20) _history.removeLast();
          });
        } else {
          setState(() => _error = "Gagal mempersingkat URL. Coba lagi.");
        }
      }
    } catch (e) {
      setState(() => _error = "Koneksi gagal: $e");
    } finally {
      setState(() => _isLoading = false);
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
          "URL SHORTENER",
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Orbitron',
            fontWeight: FontWeight.bold,
            fontSize: 16,
            shadows: [Shadow(color: cyanBlue.withOpacity(0.8), blurRadius: 10)],
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
          children: [
            Center(
              child: Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryPurple.withOpacity(0.15),
                  border: Border.all(color: cyanBlue.withOpacity(0.5), width: 2),
                ),
                child: Icon(Icons.link, color: cyanBlue, size: 40),
              ),
            ),
            const SizedBox(height: 16),
            Text("Persingkat URL panjang jadi pendek",
                style: TextStyle(color: Colors.grey.shade500, fontFamily: 'ShareTechMono', fontSize: 12)),
            const SizedBox(height: 24),

            Container(
              decoration: BoxDecoration(
                color: cardDark,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: primaryPurple.withOpacity(0.5)),
              ),
              child: TextField(
                controller: _urlCtrl,
                style: const TextStyle(color: Colors.white, fontFamily: 'ShareTechMono'),
                decoration: InputDecoration(
                  hintText: "https://url-panjang-banget.com/path/...",
                  hintStyle: TextStyle(color: Colors.grey.shade600, fontFamily: 'ShareTechMono'),
                  prefixIcon: Icon(Icons.language, color: cyanBlue),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 14),

            SizedBox(
              width: double.infinity, height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _shorten,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryPurple,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 8,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.compress, color: Colors.white),
                        SizedBox(width: 10),
                        Text("PERSINGKAT URL", style: TextStyle(
                            fontFamily: 'Orbitron', color: Colors.white,
                            letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                      ]),
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Text(_error!, style: const TextStyle(color: Colors.red, fontFamily: 'ShareTechMono')),
              ),
            ],

            if (_shortUrl != null) ...[
              const SizedBox(height: 20),
              Container(
                width: double.infinity, padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [primaryPurple.withOpacity(0.3), cyanBlue.withOpacity(0.1)]),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cyanBlue.withOpacity(0.4)),
                ),
                child: Column(
                  children: [
                    Text("SHORT URL", style: TextStyle(color: Colors.grey.shade400, fontFamily: 'ShareTechMono', fontSize: 11, letterSpacing: 2)),
                    const SizedBox(height: 12),
                    Text(_shortUrl!, style: TextStyle(color: cyanBlue, fontFamily: 'Orbitron', fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: _shortUrl!));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: const Text("Disalin!"),
                                    backgroundColor: primaryPurple,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                              );
                            },
                            icon: const Icon(Icons.copy, size: 16),
                            label: const Text("COPY", style: TextStyle(fontFamily: 'Orbitron')),
                            style: ElevatedButton.styleFrom(backgroundColor: primaryPurple.withOpacity(0.5), foregroundColor: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => launchUrl(Uri.parse(_shortUrl!)),
                            icon: const Icon(Icons.open_in_new, size: 16),
                            label: const Text("BUKA", style: TextStyle(fontFamily: 'Orbitron')),
                            style: ElevatedButton.styleFrom(backgroundColor: cyanBlue.withOpacity(0.3), foregroundColor: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            if (_history.isNotEmpty) ...[
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerLeft,
                child: Text("RIWAYAT", style: TextStyle(color: lightPurple, fontFamily: 'Orbitron', fontSize: 12, letterSpacing: 1.5)),
              ),
              const SizedBox(height: 12),
              ..._history.map((item) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cardDark, borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: primaryPurple.withOpacity(0.2)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(item['original']!, style: TextStyle(color: Colors.grey.shade500, fontFamily: 'ShareTechMono', fontSize: 11), overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(children: [
                    Expanded(child: Text(item['short']!, style: TextStyle(color: cyanBlue, fontFamily: 'ShareTechMono', fontSize: 13, fontWeight: FontWeight.bold))),
                    IconButton(
                      padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                      icon: Icon(Icons.copy, color: Colors.grey.shade600, size: 16),
                      onPressed: () => Clipboard.setData(ClipboardData(text: item['short']!)),
                    ),
                  ]),
                ]),
              )),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
