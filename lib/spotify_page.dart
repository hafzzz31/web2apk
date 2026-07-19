import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';

// ════════════════════════════════════════════════════════
//  SPOTIFY PAGE — Free Music via iTunes Search API
//  Stream preview 30 detik resmi dari Apple/iTunes (gratis)
// ════════════════════════════════════════════════════════

class SpotifyPage extends StatefulWidget {
  const SpotifyPage({super.key});
  @override
  State<SpotifyPage> createState() => _SpotifyPageState();
}

class _SpotifyPageState extends State<SpotifyPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchCtrl = TextEditingController();
  final AudioPlayer _audioPlayer = AudioPlayer();

  List<dynamic> _tracks = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  String _error = '';

  // Player state
  Map<String, dynamic>? _currentTrack;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  late AnimationController _albumArtCtrl;

  final Color bgDark        = const Color(0xFF0F1115);
  final Color cardBg        = const Color(0xFF1C1F26);
  final Color primaryPurple = const Color(0xFFC0C0C0);
  final Color accentPurple  = const Color(0xFFE5E5E5);
  final Color borderGlass   = const Color(0x33FFFFFF);

  // Popular searches default
  final List<String> _defaultTerms = [
    'pop hits 2024', 'indonesia', 'lofi chill', 'kpop', 'anime ost',
  ];
  int _defaultIndex = 0;

  @override
  void initState() {
    super.initState();
    _albumArtCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 10))..repeat();

    _audioPlayer.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });
    _audioPlayer.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _isPlaying = state == PlayerState.playing);
    });
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) setState(() { _isPlaying = false; _position = Duration.zero; });
    });

    _fetchDefault();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _albumArtCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchDefault() async {
    final term = _defaultTerms[_defaultIndex % _defaultTerms.length];
    await _searchMusic(term, isDefault: true);
  }

  Future<void> _searchMusic(String query, {bool isDefault = false}) async {
    if (query.trim().isEmpty) return;
    setState(() { _isLoading = true; _error = ''; if (!isDefault) _hasSearched = true; });

    try {
      final encoded = Uri.encodeQueryComponent(query.trim());
      final res = await http.get(Uri.parse(
        'https://itunes.apple.com/search?term=$encoded&media=music&limit=30&country=ID',
      )).timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final results = (data['results'] as List)
            .where((t) => t['previewUrl'] != null && t['previewUrl'].toString().isNotEmpty)
            .toList();
        setState(() { _tracks = results; if (isDefault) _hasSearched = false; });
      } else {
        setState(() => _error = 'Gagal memuat musik (${res.statusCode})');
      }
    } catch (e) {
      setState(() => _error = 'Cek koneksi internet kamu.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _playTrack(Map<String, dynamic> track) async {
    final previewUrl = track['previewUrl'];
    if (previewUrl == null || previewUrl.toString().isEmpty) return;

    if (_currentTrack?['trackId'] == track['trackId'] && _isPlaying) {
      await _audioPlayer.pause();
      return;
    }

    setState(() { _currentTrack = track; _position = Duration.zero; });
    await _audioPlayer.stop();
    await _audioPlayer.play(UrlSource(previewUrl));
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        backgroundColor: const Color(0xFF130530),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [primaryPurple, accentPurple]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.music_note_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('HoxtenMusic',
                style: TextStyle(color: Colors.white, fontSize: 16,
                    fontWeight: FontWeight.bold, fontFamily: 'Orbitron')),
            Text('Preview 30 detik • iTunes',
                style: TextStyle(color: accentPurple, fontSize: 9,
                    fontFamily: 'ShareTechMono')),
          ]),
        ]),
      ),
      body: Column(children: [
        // ── SEARCH BAR ──────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
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
                  onSubmitted: (v) => _searchMusic(v),
                  decoration: InputDecoration(
                    hintText: 'Cari lagu, artis...',
                    hintStyle: TextStyle(color: Colors.white30),
                    prefixIcon: Icon(Icons.search, color: accentPurple, size: 20),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.white38, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              _fetchDefault();
                              setState(() => _hasSearched = false);
                            })
                        : null,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _searchMusic(_searchCtrl.text),
              child: Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [primaryPurple, accentPurple]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.search, color: Colors.white, size: 20),
              ),
            ),
          ]),
        ),

        // ── QUICK TAGS ──────────────────────────────────
        if (!_hasSearched)
          SizedBox(
            height: 38,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: _defaultTerms.length,
              itemBuilder: (ctx, i) => GestureDetector(
                onTap: () {
                  _searchCtrl.text = _defaultTerms[i];
                  _searchMusic(_defaultTerms[i]);
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 8, top: 4, bottom: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: primaryPurple.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: accentPurple.withOpacity(0.35)),
                  ),
                  child: Text(_defaultTerms[i],
                      style: TextStyle(color: accentPurple, fontSize: 11)),
                ),
              ),
            ),
          ),

        // ── TRACK LIST ──────────────────────────────────
        Expanded(
          child: _isLoading
              ? Center(child: CircularProgressIndicator(color: accentPurple))
              : _error.isNotEmpty
                  ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.wifi_off_rounded, color: Colors.white38, size: 48),
                      const SizedBox(height: 12),
                      Text(_error, style: const TextStyle(color: Colors.white54)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchDefault,
                        style: ElevatedButton.styleFrom(backgroundColor: primaryPurple),
                        child: const Text('Coba Lagi'),
                      ),
                    ]))
                  : _tracks.isEmpty
                      ? Center(child: Text('Tidak ada hasil.',
                          style: TextStyle(color: Colors.white38)))
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.only(
                              left: 14, right: 14, top: 8,
                              bottom: _currentTrack != null ? 170 : 14),
                          itemCount: _tracks.length,
                          itemBuilder: (ctx, i) => _buildTrackTile(_tracks[i]),
                        ),
        ),

        // ── MINI PLAYER ─────────────────────────────────
        if (_currentTrack != null) _buildMiniPlayer(),
      ]),
    );
  }

  Widget _buildTrackTile(Map<String, dynamic> track) {
    final isActive = _currentTrack?['trackId'] == track['trackId'];
    final artUrl   = track['artworkUrl100'] ?? '';

    return GestureDetector(
      onTap: () => _playTrack(track),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isActive ? primaryPurple.withOpacity(0.25) : cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive ? accentPurple.withOpacity(0.6) : accentPurple.withOpacity(0.15),
            width: isActive ? 1.5 : 1,
          ),
          boxShadow: isActive ? [BoxShadow(
              color: accentPurple.withOpacity(0.15), blurRadius: 10)] : [],
        ),
        child: Row(children: [
          // Album art
          Stack(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: artUrl.isNotEmpty
                  ? Image.network(artUrl, width: 50, height: 50, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 50, height: 50,
                        color: primaryPurple.withOpacity(0.3),
                        child: Icon(Icons.music_note, color: accentPurple),
                      ))
                  : Container(
                      width: 50, height: 50,
                      color: primaryPurple.withOpacity(0.3),
                      child: Icon(Icons.music_note, color: accentPurple)),
            ),
            if (isActive && _isPlaying)
              Positioned.fill(child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  color: Colors.black54,
                  child: Icon(Icons.pause_rounded, color: Colors.white, size: 24),
                ),
              )),
          ]),
          const SizedBox(width: 12),
          // Track info
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(track['trackName'] ?? 'Unknown',
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.white.withOpacity(0.9),
                  fontSize: 13, fontWeight: FontWeight.bold,
                ),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 3),
            Text(track['artistName'] ?? '',
                style: TextStyle(color: Colors.white54, fontSize: 11),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ])),
          // Play indicator / duration
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            if (isActive && _isPlaying)
              Icon(Icons.equalizer_rounded, color: accentPurple, size: 20)
            else
              Icon(Icons.play_circle_fill_rounded,
                  color: isActive ? accentPurple : Colors.white24, size: 22),
            const SizedBox(height: 4),
            Text('30s', style: TextStyle(color: Colors.white24, fontSize: 9,
                fontFamily: 'ShareTechMono')),
          ]),
        ]),
      ),
    );
  }

  Widget _buildMiniPlayer() {
    final track  = _currentTrack!;
    final artUrl = track['artworkUrl100'] ?? '';
    final pct    = _duration.inMilliseconds > 0
        ? _position.inMilliseconds / _duration.inMilliseconds
        : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF130530),
        border: Border(top: BorderSide(color: accentPurple.withOpacity(0.3))),
        boxShadow: [BoxShadow(
            color: primaryPurple.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        top: false,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Progress bar
          LinearProgressIndicator(
            value: pct.clamp(0.0, 1.0),
            backgroundColor: Colors.white10,
            valueColor: AlwaysStoppedAnimation<Color>(accentPurple),
            minHeight: 3,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: Row(children: [
              // Album art spinning
              RotationTransition(
                turns: _isPlaying ? _albumArtCtrl : const AlwaysStoppedAnimation(0),
                child: ClipOval(child: artUrl.isNotEmpty
                    ? Image.network(artUrl, width: 48, height: 48, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 48, height: 48,
                          color: primaryPurple.withOpacity(0.4),
                          child: Icon(Icons.music_note, color: accentPurple)))
                    : Container(
                        width: 48, height: 48,
                        color: primaryPurple.withOpacity(0.4),
                        child: Icon(Icons.music_note, color: accentPurple))),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(track['trackName'] ?? '',
                    style: const TextStyle(color: Colors.white, fontSize: 13,
                        fontWeight: FontWeight.bold),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(track['artistName'] ?? '',
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text('${_formatDuration(_position)} / ${_formatDuration(_duration)}',
                    style: TextStyle(color: accentPurple, fontSize: 10,
                        fontFamily: 'ShareTechMono')),
              ])),
              // Controls
              Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(
                  icon: Icon(Icons.replay_10_rounded, color: Colors.white70, size: 26),
                  onPressed: () async {
                    final newPos = _position - const Duration(seconds: 10);
                    await _audioPlayer.seek(newPos < Duration.zero ? Duration.zero : newPos);
                  },
                ),
                GestureDetector(
                  onTap: () async {
                    if (_isPlaying) {
                      await _audioPlayer.pause();
                    } else {
                      await _audioPlayer.resume();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [primaryPurple, accentPurple]),
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(
                          color: accentPurple.withOpacity(0.4), blurRadius: 10)],
                    ),
                    child: Icon(_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: Colors.white, size: 26),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.forward_10_rounded, color: Colors.white70, size: 26),
                  onPressed: () async {
                    final newPos = _position + const Duration(seconds: 10);
                    await _audioPlayer.seek(newPos > _duration ? _duration : newPos);
                  },
                ),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}
