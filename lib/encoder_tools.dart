import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EncoderToolsPage extends StatefulWidget {
  const EncoderToolsPage({super.key});

  @override
  State<EncoderToolsPage> createState() => _EncoderToolsPageState();
}

class _EncoderToolsPageState extends State<EncoderToolsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _inputCtrl = TextEditingController();
  String _output = '';
  String _selectedHash = 'MD5';

  final Color primaryDark = const Color(0xFF0D0221);
  final Color primaryPurple = const Color(0xFF7B1FA2);
  final Color accentPurple = const Color(0xFFAA00FF);
  final Color lightPurple = const Color(0xFFE040FB);
  final Color cardDark = const Color(0xFF1A1A2E);
  final Color terminalGreen = const Color(0xFF00FF41);

  final List<String> _hashTypes = ['MD5', 'SHA-1', 'SHA-256', 'SHA-512'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _inputCtrl.dispose();
    super.dispose();
  }

  void _encode() {
    if (_inputCtrl.text.isEmpty) return;
    final bytes = utf8.encode(_inputCtrl.text);
    setState(() => _output = base64.encode(bytes));
  }

  void _decode() {
    if (_inputCtrl.text.isEmpty) return;
    try {
      final decoded = utf8.decode(base64.decode(_inputCtrl.text.trim()));
      setState(() => _output = decoded);
    } catch (e) {
      setState(() => _output = "ERROR: Input bukan Base64 yang valid!");
    }
  }

  void _generateHash() {
    if (_inputCtrl.text.isEmpty) return;
    final bytes = utf8.encode(_inputCtrl.text);
    String result;
    switch (_selectedHash) {
      case 'MD5':
        result = md5.convert(bytes).toString();
        break;
      case 'SHA-1':
        result = sha1.convert(bytes).toString();
        break;
      case 'SHA-256':
        result = sha256.convert(bytes).toString();
        break;
      case 'SHA-512':
        result = sha512.convert(bytes).toString();
        break;
      default:
        result = md5.convert(bytes).toString();
    }
    setState(() => _output = result);
  }

  void _copyOutput() {
    if (_output.isEmpty) return;
    Clipboard.setData(ClipboardData(text: _output));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Disalin!"),
        backgroundColor: primaryPurple,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
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
          "ENCODER / HASH",
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Orbitron',
            fontWeight: FontWeight.bold,
            fontSize: 14,
            shadows: [Shadow(color: terminalGreen.withOpacity(0.8), blurRadius: 10)],
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: lightPurple,
          unselectedLabelColor: Colors.grey,
          indicatorColor: lightPurple,
          labelStyle: const TextStyle(fontFamily: 'Orbitron', fontSize: 11),
          tabs: const [
            Tab(text: "BASE64"),
            Tab(text: "DECODE"),
            Tab(text: "HASH"),
          ],
        ),
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
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Input
            Container(
              decoration: BoxDecoration(
                color: cardDark,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: primaryPurple.withOpacity(0.5)),
              ),
              child: TextField(
                controller: _inputCtrl,
                maxLines: 4,
                style: const TextStyle(
                    color: Colors.white, fontFamily: 'ShareTechMono'),
                decoration: InputDecoration(
                  hintText: "Masukkan teks...",
                  hintStyle: TextStyle(
                      color: Colors.grey.shade600, fontFamily: 'ShareTechMono'),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Tab-specific options + button
            TabBarView(
              controller: _tabController,
              children: [
                // BASE64 Encode
                _buildActionButton("ENCODE BASE64", Icons.lock_outline, _encode),
                // BASE64 Decode
                _buildActionButton("DECODE BASE64", Icons.lock_open, _decode),
                // Hash
                Column(
                  children: [
                    Row(
                      children: _hashTypes.map((type) {
                        final selected = _selectedHash == type;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedHash = type),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: selected
                                    ? primaryPurple.withOpacity(0.5)
                                    : cardDark,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: selected
                                      ? lightPurple.withOpacity(0.6)
                                      : Colors.white12,
                                ),
                              ),
                              child: Text(type,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: selected
                                        ? Colors.white
                                        : Colors.grey.shade500,
                                    fontFamily: 'ShareTechMono',
                                    fontSize: 11,
                                    fontWeight: selected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  )),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    _buildActionButton(
                        "GENERATE HASH", Icons.fingerprint, _generateHash),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Output
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: terminalGreen.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("OUTPUT",
                            style: TextStyle(
                                color: terminalGreen,
                                fontFamily: 'ShareTechMono',
                                fontSize: 11,
                                letterSpacing: 2)),
                        if (_output.isNotEmpty)
                          GestureDetector(
                            onTap: _copyOutput,
                            child: Row(
                              children: [
                                Icon(Icons.copy,
                                    color: terminalGreen, size: 14),
                                const SizedBox(width: 4),
                                Text("COPY",
                                    style: TextStyle(
                                        color: terminalGreen,
                                        fontFamily: 'ShareTechMono',
                                        fontSize: 11)),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const Divider(color: Colors.white10, height: 16),
                    Expanded(
                      child: SingleChildScrollView(
                        child: SelectableText(
                          _output.isEmpty ? "// output akan muncul di sini" : _output,
                          style: TextStyle(
                            color: _output.isEmpty
                                ? Colors.grey.shade700
                                : terminalGreen,
                            fontFamily: 'ShareTechMono',
                            fontSize: 13,
                          ),
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
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryPurple,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 6,
          shadowColor: primaryPurple.withOpacity(0.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Text(label,
                style: const TextStyle(
                    fontFamily: 'Orbitron',
                    color: Colors.white,
                    letterSpacing: 1.2,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
