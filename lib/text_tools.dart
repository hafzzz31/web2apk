import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TextToolsPage extends StatefulWidget {
  const TextToolsPage({super.key});

  @override
  State<TextToolsPage> createState() => _TextToolsPageState();
}

class _TextToolsPageState extends State<TextToolsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _inputCtrl = TextEditingController();
  String _output = '';

  final Color primaryDark = const Color(0xFF0D0221);
  final Color primaryPurple = const Color(0xFF7B1FA2);
  final Color accentPurple = const Color(0xFFAA00FF);
  final Color lightPurple = const Color(0xFFE040FB);
  final Color cardDark = const Color(0xFF1A1A2E);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _inputCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _inputCtrl.dispose();
    super.dispose();
  }

  String get text => _inputCtrl.text;

  // Stats
  int get wordCount =>
      text.trim().isEmpty ? 0 : text.trim().split(RegExp(r'\s+')).length;
  int get charCount => text.length;
  int get charNoSpace => text.replaceAll(' ', '').length;
  int get lineCount =>
      text.isEmpty ? 0 : text.split('\n').length;
  int get sentenceCount =>
      text.isEmpty ? 0 : text.split(RegExp(r'[.!?]+')).where((s) => s.trim().isNotEmpty).length;

  // Case converters
  void _toUpper() => setState(() => _output = text.toUpperCase());
  void _toLower() => setState(() => _output = text.toLowerCase());
  void _toTitle() => setState(() => _output = text.split(' ')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
      .join(' '));
  void _toSentence() {
    final sentences = text.split(RegExp(r'(?<=[.!?])\s+'));
    setState(() => _output = sentences
        .map((s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1).toLowerCase()}')
        .join(' '));
  }
  void _toAlternate() {
    var result = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      result.write(i % 2 == 0 ? text[i].toUpperCase() : text[i].toLowerCase());
    }
    setState(() => _output = result.toString());
  }
  void _reverse() => setState(() => _output = text.split('').reversed.join(''));
  void _reverseWords() => setState(() => _output = text.split(' ').reversed.join(' '));
  void _removeSpaces() => setState(() => _output = text.replaceAll(RegExp(r'\s+'), ' ').trim());
  void _removeLines() => setState(() => _output = text.split('\n').where((l) => l.trim().isNotEmpty).join('\n'));

  String _generateLorem([int words = 50]) {
    const loremWords = [
      'lorem', 'ipsum', 'dolor', 'sit', 'amet', 'consectetur',
      'adipiscing', 'elit', 'sed', 'do', 'eiusmod', 'tempor', 'incididunt',
      'ut', 'labore', 'et', 'dolore', 'magna', 'aliqua', 'enim', 'ad',
      'minim', 'veniam', 'quis', 'nostrud', 'exercitation', 'ullamco',
      'laboris', 'nisi', 'aliquip', 'ex', 'ea', 'commodo', 'consequat',
      'duis', 'aute', 'irure', 'in', 'reprehenderit', 'voluptate',
      'velit', 'esse', 'cillum', 'fugiat', 'nulla', 'pariatur', 'excepteur',
      'sint', 'occaecat', 'cupidatat', 'non', 'proident', 'sunt', 'culpa',
      'qui', 'officia', 'deserunt', 'mollit', 'anim', 'id', 'est', 'laborum',
    ];
    final rng = Random();
    return List.generate(words, (_) => loremWords[rng.nextInt(loremWords.length)])
        .join(' ')
        .replaceFirstMapped(RegExp(r'^.'), (m) => m[0]!.toUpperCase()) + '.';
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
          "TEXT TOOLS",
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Orbitron',
            fontWeight: FontWeight.bold,
            fontSize: 16,
            shadows: [Shadow(color: lightPurple.withOpacity(0.8), blurRadius: 10)],
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: lightPurple,
          unselectedLabelColor: Colors.grey,
          indicatorColor: lightPurple,
          isScrollable: true,
          labelStyle: const TextStyle(fontFamily: 'Orbitron', fontSize: 10),
          tabs: const [
            Tab(text: "STATS"),
            Tab(text: "CASE"),
            Tab(text: "TRANSFORM"),
            Tab(text: "LOREM"),
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
      body: Column(
        children: [
          // Input
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Container(
              decoration: BoxDecoration(
                color: cardDark,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: primaryPurple.withOpacity(0.5)),
              ),
              child: TextField(
                controller: _inputCtrl,
                maxLines: 4,
                style: const TextStyle(
                    color: Colors.white, fontFamily: 'ShareTechMono', fontSize: 13),
                decoration: InputDecoration(
                  hintText: "Ketik atau tempel teks di sini...",
                  hintStyle: TextStyle(
                      color: Colors.grey.shade600, fontFamily: 'ShareTechMono'),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
            ),
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // STATS
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.6,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _statCard("KATA", wordCount.toString(), Icons.text_fields),
                          _statCard("KARAKTER", charCount.toString(), Icons.abc),
                          _statCard("TANPA SPASI", charNoSpace.toString(), Icons.space_bar),
                          _statCard("BARIS", lineCount.toString(), Icons.format_list_numbered),
                          _statCard("KALIMAT", sentenceCount.toString(), Icons.format_quote),
                          _statCard("PARAGRAF",
                              text.isEmpty ? '0' : text.split(RegExp(r'\n\n+')).where((p) => p.trim().isNotEmpty).length.toString(),
                              Icons.segment),
                        ],
                      ),
                    ],
                  ),
                ),

                // CASE
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _actionChip("UPPERCASE", _toUpper),
                          _actionChip("lowercase", _toLower),
                          _actionChip("Title Case", _toTitle),
                          _actionChip("Sentence case", _toSentence),
                          _actionChip("AlTeRnAtE", _toAlternate),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _outputBox(),
                    ],
                  ),
                ),

                // TRANSFORM
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _actionChip("Balik Teks", _reverse),
                          _actionChip("Balik Kata", _reverseWords),
                          _actionChip("Hapus Spasi", _removeSpaces),
                          _actionChip("Hapus Baris Kosong", _removeLines),
                          _actionChip("Trim Semua", () => setState(() => _output = text.trim())),
                          _actionChip("Remove Numbers", () => setState(() => _output = text.replaceAll(RegExp(r'\d'), ''))),
                          _actionChip("Only Numbers", () => setState(() => _output = text.replaceAll(RegExp(r'\D'), ''))),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _outputBox(),
                    ],
                  ),
                ),

                // LOREM
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text("Generate Lorem Ipsum",
                          style: TextStyle(
                              color: lightPurple,
                              fontFamily: 'Orbitron',
                              fontSize: 12)),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _actionChip("25 Kata", () => setState(() => _output = _generateLorem(25))),
                          _actionChip("50 Kata", () => setState(() => _output = _generateLorem(50))),
                          _actionChip("100 Kata", () => setState(() => _output = _generateLorem(100))),
                          _actionChip("200 Kata", () => setState(() => _output = _generateLorem(200))),
                          _actionChip("500 Kata", () => setState(() => _output = _generateLorem(500))),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _outputBox(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: primaryPurple.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: lightPurple, size: 14),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      color: Colors.grey.shade500,
                      fontFamily: 'ShareTechMono',
                      fontSize: 10)),
            ],
          ),
          Text(value,
              style: TextStyle(
                  color: lightPurple,
                  fontFamily: 'Orbitron',
                  fontSize: 24,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _actionChip(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: primaryPurple.withOpacity(0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: lightPurple.withOpacity(0.4)),
        ),
        child: Text(label,
            style: const TextStyle(
                color: Colors.white,
                fontFamily: 'ShareTechMono',
                fontSize: 12)),
      ),
    );
  }

  Widget _outputBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: lightPurple.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("HASIL",
                  style: TextStyle(
                      color: lightPurple,
                      fontFamily: 'ShareTechMono',
                      fontSize: 11)),
              if (_output.isNotEmpty)
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        _inputCtrl.text = _output;
                        setState(() => _output = '');
                      },
                      child: Text("→ INPUT",
                          style: TextStyle(
                              color: Colors.grey.shade500,
                              fontFamily: 'ShareTechMono',
                              fontSize: 10)),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () =>
                          Clipboard.setData(ClipboardData(text: _output)),
                      child: Text("COPY",
                          style: TextStyle(
                              color: lightPurple,
                              fontFamily: 'ShareTechMono',
                              fontSize: 10)),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 8),
          SelectableText(
            _output.isEmpty ? "// output akan muncul di sini" : _output,
            style: TextStyle(
              color: _output.isEmpty ? Colors.grey.shade700 : Colors.white,
              fontFamily: 'ShareTechMono',
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
