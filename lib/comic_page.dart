import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// ════════════════════════════════════════════════════════
//  COMIC PAGE — MangaDex API (Stabil & Cepat)
//  Dioptimasi agar gambar muncul dan tidak error
// ════════════════════════════════════════════════════════

class ComicPage extends StatefulWidget {
  const ComicPage({super.key});
  @override
  State<ComicPage> createState() => _ComicPageState();
}

class _ComicPageState extends State<ComicPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchCtrl = TextEditingController();
  late TabController _tabCtrl;

  List<dynamic> _popularList = [];
  List<dynamic> _searchList  = [];
  bool _isLoadingPopular = false;
  bool _isLoadingSearch  = false;
  bool _hasSearched = false;
  String _errorPopular = '';
  String _errorSearch  = '';

  final Color bgDark        = const Color(0xFF080A0D);
  final Color cardBg        = const Color(0xFF14181F);
  final Color primaryPurple = const Color(0xFFB8BEC9);
  final Color accentPurple  = const Color(0xFFF5F7FA);

  static const _headers = {
    'User-Agent': 'Hoxten/1.0',
    'Accept': 'application/json',
  };

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _fetchPopular();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── FETCH POPULAR via MangaDex ────────────────────────
  Future<void> _fetchPopular() async {
    setState(() { _isLoadingPopular = true; _errorPopular = ''; });
    try {
      // Urutkan berdasarkan Follows (paling populer)
      final res = await http.get(
        Uri.parse('https://api.mangadex.org/manga?limit=24&order[followedCount]=desc&includes[]=cover_art'),
        headers: _headers,
      ).timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() => _popularList = data['data'] ?? []);
      } else {
        setState(() => _errorPopular = 'Gagal memuat (${res.statusCode})');
      }
    } catch (e) {
      setState(() => _errorPopular = 'Cek koneksi internet kamu.');
    } finally {
      setState(() => _isLoadingPopular = false);
    }
  }

  // ── SEARCH via MangaDex ──────────────────────────────
  Future<void> _searchManga(String query) async {
    if (query.trim().isEmpty) return;
    setState(() {
      _isLoadingSearch = true;
      _errorSearch = '';
      _hasSearched = true;
    });
    _tabCtrl.animateTo(1);
    try {
      final encoded = Uri.encodeQueryComponent(query.trim());
      final res = await http.get(
        Uri.parse('https://api.mangadex.org/manga?title=$encoded&limit=24&includes[]=cover_art'),
        headers: _headers,
      ).timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() => _searchList = data['data'] ?? []);
      } else {
        setState(() => _errorSearch = 'Gagal mencari manga.');
      }
    } catch (e) {
      setState(() => _errorSearch = 'Cek koneksi internet kamu.');
    } finally {
      setState(() => _isLoadingSearch = false);
    }
  }

  // ── Helper untuk ambil Cover ─────────────────────────
  String _getCover(Map item) {
    final relationships = item['relationships'] as List? ?? [];
    for (final rel in relationships) {
      if (rel['type'] == 'cover_art') {
        final fileName = rel['attributes']?['fileName'] ?? '';
        if (fileName.isNotEmpty) {
          return 'https://uploads.mangadex.org/covers/${item['id']}/$fileName.512.jpg';
        }
      }
    }
    return '';
  }

  String _getTitle(Map item) {
    final attr = item['attributes']?['title'] ?? {};
    return attr['en'] ?? attr.values.firstOrNull ?? 'Unknown';
  }

  String _getStatus(Map item) {
    final status = item['attributes']?['status'] ?? '';
    if (status == 'ongoing') return 'ON';
    if (status == 'completed') return 'END';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        backgroundColor: const Color(0xFF130530),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Comic',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold,
                fontFamily: 'Orbitron', fontSize: 16)),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: accentPurple,
          labelColor: accentPurple,
          unselectedLabelColor: Colors.white38,
          labelStyle: const TextStyle(fontFamily: 'ShareTechMono', fontSize: 12),
          tabs: const [Tab(text: 'POPULER'), Tab(text: 'PENCARIAN')],
        ),
      ),
      body: Column(children: [
        // ── SEARCH BAR ──────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
          child: Row(children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: accentPurple.withOpacity(0.35)),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  onSubmitted: _searchManga,
                  decoration: InputDecoration(
                    hintText: 'Cari manga / manhwa...',
                    hintStyle: TextStyle(color: Colors.white30),
                    prefixIcon: Icon(Icons.search, color: accentPurple, size: 20),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.white38, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() { _hasSearched = false; _searchList = []; });
                              _tabCtrl.animateTo(0);
                            })
                        : null,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _searchManga(_searchCtrl.text),
              child: Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryPurple, accentPurple]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.search, color: Colors.white, size: 20),
              ),
            ),
          ]),
        ),

        // ── TAB CONTENT ─────────────────────────────────
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: [
              // Tab 0: Populer
              _buildGrid(
                list: _popularList,
                isLoading: _isLoadingPopular,
                error: _errorPopular,
                onRetry: _fetchPopular,
              ),
              // Tab 1: Pencarian
              _hasSearched
                  ? _buildGrid(
                      list: _searchList,
                      isLoading: _isLoadingSearch,
                      error: _errorSearch,
                      onRetry: () => _searchManga(_searchCtrl.text),
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search, color: Colors.white24, size: 56),
                          const SizedBox(height: 12),
                          Text('Ketik judul manga di atas',
                              style: TextStyle(color: Colors.white38, fontSize: 13)),
                        ],
                      ),
                    ),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _buildGrid({
    required List list,
    required bool isLoading,
    required String error,
    required VoidCallback onRetry,
  }) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator(color: accentPurple));
    }
    if (error.isNotEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.wifi_off_rounded, color: Colors.white38, size: 48),
        const SizedBox(height: 12),
        Text(error, style: const TextStyle(color: Colors.white54, fontSize: 13)),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: onRetry,
          style: ElevatedButton.styleFrom(backgroundColor: primaryPurple,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          child: const Text('Coba Lagi'),
        ),
      ]));
    }
    if (list.isEmpty) {
      return Center(child: Text('Tidak ada hasil.',
          style: TextStyle(color: Colors.white38)));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(14),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.62,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: list.length,
      itemBuilder: (ctx, i) => _buildCard(list[i]),
    );
  }

  Widget _buildCard(Map item) {
    final title  = _getTitle(item);
    final cover  = _getCover(item);
    final status = _getStatus(item);
    final desc   = item['attributes']?['description']?['en'] ?? '';

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => _MangaDetailPage(item: item))),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accentPurple.withOpacity(0.2)),
          boxShadow: [BoxShadow(
              color: primaryPurple.withOpacity(0.15),
              blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Cover
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: cover.isNotEmpty
                  ? Image.network(cover,
                      width: double.infinity, fit: BoxFit.cover,
                      headers: const {'Referer': 'https://mangadex.org'}, // WAJIB!
                      errorBuilder: (_, __, ___) => _placeholder())
                  : _placeholder(),
            ),
          ),
          // Info
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: const TextStyle(color: Colors.white,
                      fontSize: 12, fontWeight: FontWeight.bold),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Row(children: [
                if (desc.isNotEmpty)
                  Expanded(child: Text(desc,
                      style: TextStyle(color: Colors.white38, fontSize: 9),
                      maxLines: 1, overflow: TextOverflow.ellipsis)),
                const Spacer(),
                if (status.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: status == 'ON'
                          ? Colors.green.withOpacity(0.15)
                          : primaryPurple.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: status == 'ON'
                            ? Colors.greenAccent : accentPurple,
                        fontSize: 9, fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _placeholder() => Container(
    color: primaryPurple.withOpacity(0.2),
    child: Center(child: Icon(Icons.menu_book_rounded, color: accentPurple, size: 36)),
  );
}

// ════════════════════════════════════════════════════════
//  MANGA DETAIL PAGE
// ════════════════════════════════════════════════════════
class _MangaDetailPage extends StatefulWidget {
  final Map item;
  const _MangaDetailPage({required this.item});
  @override
  State<_MangaDetailPage> createState() => _MangaDetailPageState();
}

class _MangaDetailPageState extends State<_MangaDetailPage> {
  List<dynamic> _chapters = [];
  bool _isLoading = true;
  String _error = '';

  final Color bgDark        = const Color(0xFF080A0D);
  final Color cardBg        = const Color(0xFF14181F);
  final Color primaryPurple = const Color(0xFFB8BEC9);
  final Color accentPurple  = const Color(0xFFF5F7FA);

  static const _headers = {
    'User-Agent': 'Hoxten/1.0',
    'Accept': 'application/json',
  };

  @override
  void initState() {
    super.initState();
    _fetchChapters();
  }

  Future<void> _fetchChapters() async {
    setState(() { _isLoading = true; _error = ''; });
    final mangaId = widget.item['id'];
    try {
      final res = await http.get(
        Uri.parse('https://api.mangadex.org/manga/$mangaId/feed'
            '?limit=100&translatedLanguage[]=en&translatedLanguage[]=id'
            '&order[chapter]=asc'),
        headers: _headers,
      ).timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() { _chapters = data['data'] ?? []; });
      } else {
        setState(() { _error = 'Gagal memuat chapter.'; });
      }
    } catch (_) {
      setState(() { _error = 'Gagal memuat chapter.'; });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _getCover() {
    final relationships = widget.item['relationships'] as List? ?? [];
    for (final rel in relationships) {
      if (rel['type'] == 'cover_art') {
        final fileName = rel['attributes']?['fileName'] ?? '';
        if (fileName.isNotEmpty) {
          return 'https://uploads.mangadex.org/covers/${widget.item['id']}/$fileName.512.jpg';
        }
      }
    }
    return '';
  }

  String _getTitle() {
    final attr = widget.item['attributes']?['title'] ?? {};
    return attr['en'] ?? attr.values.firstOrNull ?? 'Unknown';
  }

  @override
  Widget build(BuildContext context) {
    final title  = _getTitle();
    final cover  = _getCover();
    final desc   = widget.item['attributes']?['description']?['en'] ?? 'Tidak ada deskripsi.';
    final status = widget.item['attributes']?['status'] ?? '-';
    final tags   = (widget.item['attributes']?['tags'] as List? ?? [])
        .map((t) => t['attributes']?['name']?['en'] ?? '').where((s) => s.isNotEmpty).take(5).toList();

    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        backgroundColor: const Color(0xFF130530),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(title,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold,
                fontSize: 14, fontFamily: 'Orbitron'),
            overflow: TextOverflow.ellipsis),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── HEADER ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: cover.isNotEmpty
                    ? Image.network(cover, width: 110, height: 160, fit: BoxFit.cover,
                        headers: const {'Referer': 'https://mangadex.org'},
                        errorBuilder: (_, __, ___) => Container(
                          width: 110, height: 160,
                          color: primaryPurple.withOpacity(0.2),
                          child: Icon(Icons.menu_book_rounded, color: accentPurple, size: 40),
                        ))
                    : Container(width: 110, height: 160,
                        color: primaryPurple.withOpacity(0.2),
                        child: Icon(Icons.menu_book_rounded, color: accentPurple, size: 40)),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(
                    color: Colors.white, fontSize: 14,
                    fontWeight: FontWeight.bold, fontFamily: 'Orbitron')),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: status == 'ongoing'
                        ? Colors.green.withOpacity(0.15) : primaryPurple.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(status == 'ongoing' ? 'ONGOING' : status.toUpperCase(),
                      style: TextStyle(
                        color: status == 'ongoing' ? Colors.greenAccent : accentPurple,
                        fontSize: 10, fontWeight: FontWeight.bold,
                      )),
                ),
                const SizedBox(height: 8),
                Wrap(spacing: 6, runSpacing: 6, children: tags.map((g) =>
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: primaryPurple.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: accentPurple.withOpacity(0.3)),
                    ),
                    child: Text(g, style: TextStyle(color: accentPurple, fontSize: 10)),
                  )).toList()),
                const SizedBox(height: 8),
                Text(desc,
                    style: const TextStyle(color: Colors.white54, fontSize: 11, height: 1.5),
                    maxLines: 5, overflow: TextOverflow.ellipsis),
              ])),
            ]),
          ),

          // ── CHAPTERS ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              Container(width: 4, height: 16,
                  decoration: BoxDecoration(
                      color: accentPurple, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 8),
              const Text('Daftar Chapter',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold,
                      fontFamily: 'Orbitron', fontSize: 13)),
              const Spacer(),
              Text('${_chapters.length} ch',
                  style: TextStyle(color: accentPurple, fontSize: 11,
                      fontFamily: 'ShareTechMono')),
            ]),
          ),
          const SizedBox(height: 10),

          _isLoading
              ? Center(child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: CircularProgressIndicator(color: accentPurple)))
              : _error.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: Center(child: Text(_error,
                          style: TextStyle(color: Colors.white38))))
                  : _chapters.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(24),
                          child: Center(child: Text('Chapter belum tersedia di database.',
                              style: TextStyle(color: Colors.white38, fontSize: 12))))
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          itemCount: _chapters.length,
                          itemBuilder: (ctx, i) {
                            final ch   = _chapters[i];
                            final attr = ch['attributes'];
                            final num  = attr?['chapter'] ?? '?';
                            final ctitle = attr?['title'] ?? '';
                            final lang  = attr?['translatedLanguage'] ?? '';
                            return GestureDetector(
                              onTap: () => Navigator.push(context, MaterialPageRoute(
                                  builder: (_) => _ChapterReaderPage(chapterId: ch['id']))),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: cardBg,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: accentPurple.withOpacity(0.2)),
                                ),
                                child: Row(children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: primaryPurple.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text('Ch. $num',
                                        style: TextStyle(
                                            color: accentPurple, fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'ShareTechMono')),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(child: Text(
                                    ctitle.isNotEmpty ? ctitle : 'Chapter $num',
                                    style: const TextStyle(color: Colors.white, fontSize: 13),
                                    overflow: TextOverflow.ellipsis,
                                  )),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.white10,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(lang.toUpperCase(),
                                        style: TextStyle(color: Colors.white38, fontSize: 9)),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(Icons.arrow_forward_ios,
                                      color: accentPurple, size: 13),
                                ]),
                              ),
                            );
                          }),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════
//  CHAPTER READER PAGE
// ════════════════════════════════════════════════════════
class _ChapterReaderPage extends StatefulWidget {
  final String chapterId;
  const _ChapterReaderPage({required this.chapterId});
  @override
  State<_ChapterReaderPage> createState() => _ChapterReaderPageState();
}

class _ChapterReaderPageState extends State<_ChapterReaderPage> {
  List<String> _pages = [];
  bool _isLoading = true;
  String _error   = '';
  bool _showBar   = true;

  final Color accentPurple = const Color(0xFFEA80FC);

  @override
  void initState() {
    super.initState();
    _fetchPages();
  }

  Future<void> _fetchPages() async {
    setState(() { _isLoading = true; _error = ''; });
    try {
      final res = await http.get(
        Uri.parse('https://api.mangadex.org/at-home/server/${widget.chapterId}'),
        headers: {'User-Agent': 'Hoxten/1.0'},
      ).timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        final data  = jsonDecode(res.body);
        final base  = data['baseUrl'];
        final hash  = data['chapter']?['hash'];
        final pages = List<String>.from(data['chapter']?['data'] ?? []);
        setState(() => _pages = pages.map((p) => '$base/data/$hash/$p').toList());
      } else {
        setState(() => _error = 'Gagal memuat halaman (${res.statusCode})');
      }
    } catch (e) {
      setState(() => _error = 'Gagal memuat halaman.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _showBar
          ? AppBar(
              backgroundColor: Colors.black87,
              iconTheme: const IconThemeData(color: Colors.white),
              title: Text('${_pages.length} halaman',
                  style: TextStyle(color: accentPurple, fontSize: 13,
                      fontFamily: 'ShareTechMono')),
            )
          : null,
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: accentPurple))
          : _error.isNotEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.error_outline, color: Colors.white38, size: 48),
                  const SizedBox(height: 12),
                  Text(_error, style: const TextStyle(color: Colors.white54)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _fetchPages,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7B1FA2),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                    child: const Text('Coba Lagi'),
                  ),
                ]))
              : GestureDetector(
                  onTap: () => setState(() => _showBar = !_showBar),
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: _pages.length,
                    itemBuilder: (ctx, i) => Image.network(
                      _pages[i],
                      fit: BoxFit.fitWidth,
                      width: double.infinity,
                      headers: const {'Referer': 'https://mangadex.org'}, // WAJIB!
                      loadingBuilder: (ctx, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          height: 200,
                          alignment: Alignment.center,
                          child: CircularProgressIndicator(
                            color: accentPurple,
                            value: progress.expectedTotalBytes != null
                                ? progress.cumulativeBytesLoaded /
                                    progress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                      errorBuilder: (_, __, ___) => Container(
                        height: 80,
                        color: Colors.grey.shade900,
                        child: const Icon(Icons.broken_image, color: Colors.white38),
                      ),
                    ),
                  ),
                ),
    );
  }
}