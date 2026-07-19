import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'fa_icon_ext.dart';

const _baseUrl = 'http://hoxtenhafz.jscloud.my.id:2001';

// ─── Palette ──────────────────────────────────────────────────────────────
class _C {
  static const bg         = Color(0xFF020305);
  static const surface    = Color(0xFF0A0F1C);
  static const card       = Color(0xFF141B2D);
  static const cardHover  = Color(0xFF1E293B);
  static const border     = Color(0xFF334155);
  static const borderLit  = Color(0xFF475569);
  static const silverBase = Color(0xFF94A3B8);
  static const silverMid  = Color(0xFFCBD5E1);
  static const silverLit  = Color(0xFFF1F5F9);
  static const silverFrost = Color(0xFFE2E8F0);
  static const green      = Color(0xFF22C55E);
  static const greenDim   = Color(0xFF16A34A);
  static const red        = Color(0xFFEF4444);
  static const text       = Color(0xFFE2EDF9);
  static const textSub    = Color(0xFF94A3B8);
  static const textDim    = Color(0xFF64748B);

  static const LinearGradient silverGrad = LinearGradient(
    colors: [silverBase, silverMid, silverLit],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient deepGrad = LinearGradient(
    colors: [Color(0xFF0A0F1C), Color(0xFF020305)],
    begin: Alignment.topCenter, end: Alignment.bottomCenter,
  );
}

Color _roleColor(String role) {
  switch (role.toLowerCase()) {
    case 'owner':     return const Color(0xFFF59E0B);
    case 'admin':     return const Color(0xFFEF4444);
    case 'moderator': return const Color(0xFF22C55E);
    case 'partner':   return const Color(0xFF3B82F6);
    case 'vip':       return const Color(0xFFA855F7);
    case 'reseller':  return const Color(0xFF22C55E);
    default:          return _C.silverLit;
  }
}

class HomePage extends StatefulWidget {
  final String username;
  final String password;
  final String sessionKey;
  final List<Map<String, dynamic>> listBug;
  final String role;
  final String expiredDate;

  const HomePage({
    super.key,
    required this.username,
    required this.password,
    required this.sessionKey,
    required this.listBug,
    required this.role,
    required this.expiredDate,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final targetCtrl = TextEditingController();
  final PageController _bugPageCtrl = PageController(viewportFraction: 0.78);

  String selectedBugId = '';
  String _bugMode    = 'number';
  String _senderType = 'private';
  bool   _isSending  = false;
  String? _responseMsg;

  List<String> _globalSenders    = [];
  bool         _isLoadingSenders = false;

  late AnimationController _entranceCtrl;
  late AnimationController _sendBtnCtrl;
  late AnimationController _resultCtrl;
  late AnimationController _waveCtrl;
  late Animation<double> _entrance;
  late Animation<double> _sendPulse;
  late Animation<double> _sendGlow;
  late Animation<double> _resultFade;
  late Animation<Offset> _resultSlide;

  // ─── Video untuk Hoxen ────────────────────────────────────────────────
  late VideoPlayerController _hoxenVideoCtrl;
  ChewieController? _hoxenChewieCtrl;
  bool _hoxenReady = false;

  bool get canAccessGlobalSender {
    final r = widget.role.toLowerCase();
    return r == 'admin' || r == 'moderator' || r == 'tk' || r == 'owner' || r == 'partner' || r == 'reseller' || r == 'member' || r == 'developer';
  }

  @override
  void initState() {
    super.initState();
    if (widget.listBug.isNotEmpty) {
      selectedBugId = widget.listBug[0]['bug_id'];
    }

    _entranceCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1200),
    );
    _entrance = CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOutQuart);

    _sendBtnCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _sendPulse = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _sendBtnCtrl, curve: Curves.easeInOut),
    );
    _sendGlow = Tween<double>(begin: 0.15, end: 0.5).animate(
      CurvedAnimation(parent: _sendBtnCtrl, curve: Curves.easeInOut),
    );

    _resultCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 400),
    );
    _resultFade = CurvedAnimation(parent: _resultCtrl, curve: Curves.easeOut);
    _resultSlide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(
      CurvedAnimation(parent: _resultCtrl, curve: Curves.easeOutCubic),
    );

    _waveCtrl = AnimationController(
      vsync: this, duration: const Duration(seconds: 3),
    )..repeat();

    _entranceCtrl.forward();
    _loadGlobalSenders();

    // ─── Inisialisasi video hoxen ──────────────────────────────────────
    _hoxenVideoCtrl = VideoPlayerController.asset('assets/videos/rdvsp.mp4');
    _hoxenVideoCtrl.initialize().then((_) {
      if (!mounted) return;
      _hoxenVideoCtrl.setLooping(true);
      _hoxenVideoCtrl.setVolume(0);
      _hoxenVideoCtrl.play();
      setState(() {
        _hoxenReady = true;
        _hoxenChewieCtrl = ChewieController(
          videoPlayerController: _hoxenVideoCtrl,
          autoPlay: true,
          looping: true,
          showControls: false,
        );
      });
    }).catchError((_) {
      if (mounted) setState(() => _hoxenReady = false);
    });
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _sendBtnCtrl.dispose();
    _resultCtrl.dispose();
    _waveCtrl.dispose();
    targetCtrl.dispose();
    _bugPageCtrl.dispose();
    _hoxenVideoCtrl.dispose();
    _hoxenChewieCtrl?.dispose();
    super.dispose();
  }

  Future<void> _loadGlobalSenders() async {
    setState(() => _isLoadingSenders = true);
    try {
      final res = await http.get(Uri.parse(
        '$_baseUrl/getActiveSenders?key=${widget.sessionKey}',
      )).timeout(const Duration(seconds: 10));
      final data = jsonDecode(res.body);
      if (data['valid'] == true && data['senders'] != null) {
        if (mounted) setState(() => _globalSenders = List<String>.from(data['senders']));
      } else {
        if (mounted) setState(() => _globalSenders = []);
      }
    } catch (_) {
      if (mounted) setState(() => _globalSenders = []);
    } finally {
      if (mounted) setState(() => _isLoadingSenders = false);
    }
  }

  Future<void> _sendBug() async {
    final rawInput = targetCtrl.text.trim();
    final key = widget.sessionKey;

    if (_bugMode == 'number') {
      if (formatPhone(rawInput) == null) {
        _showAlert('Nomor Tidak Valid', 'Gunakan format internasional.\nContoh: +62812xxxxxxxx');
        return;
      }
    } else {
      if (!isValidGroupLink(rawInput)) {
        _showAlert('Link Tidak Valid',
            'Masukkan link grup WhatsApp yang valid.\nContoh: https://chat.whatsapp.com/XXX');
        return;
      }
    }

    if (_senderType == 'global' && !canAccessGlobalSender) {
      _showAlert('Akses Ditolak', 'Sender Global hanya untuk Admin!');
      return;
    }

    if (selectedBugId.isEmpty) {
      _showAlert('Pilih Bug', 'Silakan pilih bug terlebih dahulu.');
      return;
    }

    setState(() { _isSending = true; _responseMsg = null; });
    _resultCtrl.reset();

    try {
      final encodedTarget = Uri.encodeComponent(rawInput);
      final url = Uri.parse(
        '$_baseUrl/sendBug'
        '?key=$key'
        '&target=$encodedTarget'
        '&bug=$selectedBugId'
        '${_senderType == 'global' ? '&senderMode=global' : ''}',
      );

      final res = await http.get(url).timeout(const Duration(seconds: 15));
      final data = jsonDecode(res.body);

      if (data['valid'] == false) {
        _setResponse('error', 'Session key tidak valid. Silakan login ulang.');
      } else if (data['cooldown'] == true) {
        final wait = data['wait'] ?? 0;
        _setResponse('warning', 'Cooldown aktif! Tunggu $wait detik lagi.');
      } else if (data['sended'] == true) {
        final label = _bugMode == 'group' ? 'grup target' : rawInput;
        final role = data['role'] ?? widget.role;
        _setResponse('success', 'Bug berhasil dikirim ke $label! [$role]');
        targetCtrl.clear();
      } else {
        _setResponse('error', 'Gagal mengirim. Server sedang maintenance.');
      }
    } on Exception catch (e) {
      if (e.toString().contains('TimeoutException')) {
        _setResponse('error', 'Request timeout. Periksa koneksi internet.');
      } else {
        _setResponse('error', 'Koneksi error. Periksa jaringan dan coba lagi.');
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _setResponse(String type, String msg) {
    if (!mounted) return;
    setState(() => _responseMsg = '$type|$msg');
    _resultCtrl.forward(from: 0);
  }

  String? formatPhone(String s) {
    final c = s.replaceAll(RegExp(r'[^\d+]'), '');
    return (c.startsWith('+') && c.length >= 8) ? c : null;
  }

  bool isValidGroupLink(String s) =>
      s.startsWith('https://') && s.contains('chat.whatsapp.com');

  void _showAlert(String title, String msg) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (_, anim, __, child) => ScaleTransition(
        scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
        child: FadeTransition(opacity: anim, child: child),
      ),
      pageBuilder: (ctx, _, __) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        child: Container(
          decoration: BoxDecoration(
            color: _C.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _C.silverBase.withOpacity(0.3), width: 1),
            boxShadow: [BoxShadow(color: _C.silverBase.withOpacity(0.1), blurRadius: 40)],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _C.silverBase.withOpacity(0.1),
                border: Border.all(color: _C.silverBase.withOpacity(0.3)),
              ),
              child: const Icon(Icons.warning_amber_rounded, color: _C.silverBase, size: 24),
            ),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(color: _C.text, fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(msg, textAlign: TextAlign.center,
                style: const TextStyle(color: _C.textSub, fontSize: 13, height: 1.5)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: _GradBtn(label: 'OK', fullWidth: true, onTap: () => Navigator.pop(ctx)),
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── BACKGROUND GAMBAR ────────────────────────────────
          Positioned.fill(
            child: _buildBackgroundImage(),
          ),

          // ── DARK OVERLAY ──────────────────────────────────────
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.75),
                    Colors.black.withOpacity(0.82),
                    Colors.black.withOpacity(0.92),
                  ],
                ),
              ),
            ),
          ),

          // ── SCANLINE EFFECT ──────────────────────────────────
          Positioned.fill(
            child: _buildScanlineOverlay(),
          ),

          // ── MAIN CONTENT ──────────────────────────────────────
          SafeArea(
            child: FadeTransition(
              opacity: _entrance,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 34),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 14),
                    _buildVideoCard(),          // ← VIDEO CARD SEKARANG DI SINI
                    const SizedBox(height: 14),
                    _buildAttackSequenceCard(),
                    const SizedBox(height: 18),
                    _buildSenderCard(),
                    const SizedBox(height: 18),
                    _buildBugCarousel(),
                    const SizedBox(height: 18),
                    if (_responseMsg != null) _buildResultBanner(),
                    const SizedBox(height: 12),
                    _buildLaunchButton(),
                    const SizedBox(height: 18),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── BACKGROUND IMAGE ──────────────────────────────────────────────────
  Widget _buildBackgroundImage() {
    return Image.asset(
      'assets/images/hoxten.jpg',
      fit: BoxFit.cover,
    );
  }

  // ── SCANLINE OVERLAY ──────────────────────────────────────────────────
  Widget _buildScanlineOverlay() {
    return IgnorePointer(
      child: Opacity(
        opacity: 0.03,
        child: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/logo.png'),
              repeat: ImageRepeat.repeat,
            ),
          ),
        ),
      ),
    );
  }

  // ── HEADER ────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    final rColor = _roleColor(widget.role);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.border.withOpacity(0.6), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: rColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: rColor.withOpacity(0.5), width: 1.5),
                ),
                child: Icon(Icons.person_rounded, color: rColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.username,
                      style: const TextStyle(
                        color: _C.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildTag(widget.role.toUpperCase(), rColor),
                        const SizedBox(width: 8),
                        _buildTag('SECURE', _C.green),
                        const SizedBox(width: 8),
                        _buildTag('', _C.silverBase),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _C.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _C.green.withOpacity(0.3), width: 0.8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5, height: 5,
                      decoration: const BoxDecoration(color: _C.green, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 5),
                    const Text('ONLINE', style: TextStyle(color: _C.green, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.access_time_rounded, color: _C.textDim, size: 11),
              const SizedBox(width: 4),
              Text(
                'EXPIRED: ${widget.expiredDate}',
                style: const TextStyle(color: _C.textDim, fontSize: 11, letterSpacing: 0.5),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withOpacity(0.3), width: 0.6),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: 0.8),
      ),
    );
  }

  // ── VIDEO CARD (HOXEN) ──────────────────────────────────────────────
  Widget _buildVideoCard() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.border.withOpacity(0.5), width: 0.8),
        boxShadow: [BoxShadow(color: _C.silverBase.withOpacity(0.05), blurRadius: 12)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: _hoxenReady && _hoxenChewieCtrl != null
            ? Chewie(controller: _hoxenChewieCtrl!)
            : const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _DotsLoader(),
                    SizedBox(height: 8),
                    Text(
                      'Memuat video...',
                      style: TextStyle(color: _C.textDim, fontSize: 12, letterSpacing: 0.5),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  // ── ATTACK SEQUENCE CARD ──────────────────────────────────────────────
  Widget _buildAttackSequenceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.border.withOpacity(0.5), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(
                  color: _C.red,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: _C.red.withOpacity(0.5), blurRadius: 6)],
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'ATTACK SEQUENCE',
                style: TextStyle(
                  color: _C.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Divider(color: _C.border.withOpacity(0.4), height: 16),

          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _C.border.withOpacity(0.4), width: 0.5),
            ),
            child: Row(
              children: [
                _buildModeChip('NUMBER', _bugMode == 'number', () {
                  setState(() { _bugMode = 'number'; targetCtrl.clear(); });
                }),
                _buildModeChip('GROUP', _bugMode == 'group', () {
                  setState(() { _bugMode = 'group'; targetCtrl.clear(); });
                }),
              ],
            ),
          ),

          const SizedBox(height: 16),

          _buildFieldLabel('TARGET'),
          const SizedBox(height: 6),

          Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _C.border.withOpacity(0.5), width: 0.8),
            ),
            child: TextField(
              controller: targetCtrl,
              keyboardType: _bugMode == 'number' ? TextInputType.phone : TextInputType.url,
              style: const TextStyle(color: _C.text, fontSize: 14, fontWeight: FontWeight.w600),
              cursorColor: _C.silverLit,
              decoration: InputDecoration(
                hintText: _bugMode == 'number'
                    ? 'destination phone number'
                    : 'group link destination',
                hintStyle: TextStyle(color: _C.textDim.withOpacity(0.6), fontSize: 12),
                prefixIcon: Icon(
                  _bugMode == 'number' ? Icons.phone_android_rounded : Icons.link_rounded,
                  color: _C.textDim,
                  size: 18,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              ),
            ),
          ),

          const SizedBox(height: 14),

          Text(
            targetCtrl.text.isEmpty ? 'awaiting target input' : 'target: ${targetCtrl.text}',
            style: TextStyle(
              color: targetCtrl.text.isEmpty ? _C.textDim.withOpacity(0.5) : _C.green.withOpacity(0.7),
              fontSize: 10,
              letterSpacing: 0.5,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeChip(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: active ? _C.silverBase.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: active ? Border.all(color: _C.silverBase.withOpacity(0.4), width: 0.8) : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: active ? _C.silverLit : _C.textDim,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String text) {
    return Row(
      children: [
        Container(
          width: 3, height: 12,
          decoration: BoxDecoration(
            color: _C.red,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            color: _C.textSub,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  // ── SENDER CARD ───────────────────────────────────────────────────────
  Widget _buildSenderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.border.withOpacity(0.5), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(
                  color: _C.silverBase,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: _C.silverBase.withOpacity(0.3), blurRadius: 4)],
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'SENDER TYPE',
                style: TextStyle(
                  color: _C.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Divider(color: _C.border.withOpacity(0.4), height: 16),

          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _senderType = 'private'),
                  child: _buildTransmitOption(
                    label: 'PRIVATE',
                    icon: FontAwesomeIcons.userSecret.toIcon(),
                    active: _senderType == 'private',
                    subtitle: 'My Session',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (!canAccessGlobalSender) {
                      _showAlert('Locked', 'Fitur ini khusus Developer/Admin.');
                      return;
                    }
                    setState(() => _senderType = 'global');
                    _loadGlobalSenders();
                  },
                  child: _buildTransmitOption(
                    label: 'GLOBAL',
                    icon: FontAwesomeIcons.globe.toIcon(),
                    active: _senderType == 'global',
                    subtitle: _isLoadingSenders
                        ? '...'
                        : '${_globalSenders.length} Active',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransmitOption({
    required String label,
    required IconData icon,
    required bool active,
    required String subtitle,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: active ? _C.silverBase.withOpacity(0.1) : Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: active ? _C.silverBase.withOpacity(0.4) : _C.border.withOpacity(0.3),
          width: active ? 1 : 0.5,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: active ? _C.silverLit : _C.textDim, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: active ? _C.silverLit : _C.textDim,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (active)
            Container(
              width: 16, height: 16,
              decoration: BoxDecoration(
                color: _C.green,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: _C.green.withOpacity(0.4), blurRadius: 4)],
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 10),
            )
          else
            Container(
              width: 16, height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _C.textDim.withOpacity(0.4), width: 1),
              ),
            ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: _C.textDim, fontSize: 9, letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }

  // ── BUG CAROUSEL ──────────────────────────────────────────────────────
  Widget _buildBugCarousel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.border.withOpacity(0.5), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(
                  color: _C.red,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: _C.red.withOpacity(0.5), blurRadius: 6)],
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'PAYLOAD',
                style: TextStyle(
                  color: _C.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Divider(color: _C.border.withOpacity(0.4), height: 16),

          if (widget.listBug.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text('NO PAYLOAD AVAILABLE', style: TextStyle(color: _C.textDim, fontSize: 11, letterSpacing: 1)),
              ),
            )
          else
            SizedBox(
              height: 110,
              child: PageView.builder(
                controller: _bugPageCtrl,
                itemCount: widget.listBug.length,
                onPageChanged: (index) {
                  setState(() {
                    selectedBugId = widget.listBug[index]['bug_id'];
                  });
                },
                itemBuilder: (context, index) {
                  final bug = widget.listBug[index];
                  final isSelected = bug['bug_id'] == selectedBugId;
                  return _buildBugCard(bug, isSelected, index);
                },
              ),
            ),

          const SizedBox(height: 10),

          if (widget.listBug.length > 1)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.listBug.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: widget.listBug[i]['bug_id'] == selectedBugId ? 18 : 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: widget.listBug[i]['bug_id'] == selectedBugId
                        ? _C.silverLit
                        : _C.textDim.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBugCard(Map<String, dynamic> bug, bool isSelected, int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSelected ? _C.silverBase.withOpacity(0.08) : Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? _C.silverBase.withOpacity(0.5) : _C.border.withOpacity(0.3),
          width: isSelected ? 1.2 : 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              if (isSelected)
                Container(
                  width: 18, height: 18,
                  decoration: BoxDecoration(
                    color: _C.green,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: _C.green.withOpacity(0.4), blurRadius: 4)],
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 11),
                )
              else
                Container(
                  width: 18, height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: _C.textDim.withOpacity(0.4), width: 1),
                  ),
                ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  bug['bug_name'] ?? 'Unknown',
                  style: TextStyle(
                    color: isSelected ? _C.silverLit : _C.textSub,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'ID: ${bug['bug_id'] ?? '-'}',
            style: TextStyle(
              color: _C.textDim.withOpacity(0.6),
              fontSize: 10,
              letterSpacing: 0.5,
            ),
          ),
          if (isSelected)
            const SizedBox(height: 6),
          if (isSelected)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _C.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: _C.green.withOpacity(0.3), width: 0.5),
              ),
              child: const Text(
                'SELECTED',
                style: TextStyle(color: _C.green, fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: 1),
              ),
            ),
        ],
      ),
    );
  }

  // ── LAUNCH ATTACK BUTTON ──────────────────────────────────────────────
  Widget _buildLaunchButton() {
    return AnimatedBuilder(
      animation: _sendBtnCtrl,
      builder: (_, __) => GestureDetector(
        onTap: _isSending ? null : _sendBug,
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: _C.silverGrad,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: _C.silverMid.withOpacity(_isSending ? 0.15 : _sendGlow.value),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (_isSending)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: AnimatedBuilder(
                      animation: _waveCtrl,
                      builder: (_, __) => CustomPaint(
                        painter: _WavePainter(_waveCtrl.value),
                        size: const Size(double.infinity, 56),
                      ),
                    ),
                  ),
                ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _isSending
                    ? const SizedBox(
                        key: ValueKey('loading'),
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.black87),
                      )
                    : const Row(
                        key: ValueKey('send'),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.send_rounded, color: Colors.black87, size: 22),
                          SizedBox(width: 10),
                          Text(
                            'LAUNCH ATTACK',
                            style: TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── RESULT BANNER ─────────────────────────────────────────────────────
  Widget _buildResultBanner() {
    if (_responseMsg == null) return const SizedBox();
    final parts = _responseMsg!.split('|');
    final type = parts[0];
    final msg = parts.length > 1 ? parts[1] : '';

    Color color;
    IconData icon;
    switch (type) {
      case 'success':
        color = _C.green;
        icon = Icons.check_circle_rounded;
        break;
      case 'warning':
        color = _C.silverBase;
        icon = Icons.warning_rounded;
        break;
      default:
        color = _C.red;
        icon = Icons.error_rounded;
    }

    return FadeTransition(
      opacity: _resultFade,
      child: SlideTransition(
        position: _resultSlide,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.4), width: 0.8),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  msg,
                  style: const TextStyle(color: _C.text, fontSize: 12, fontWeight: FontWeight.w600, height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── SUPPORTING WIDGETS ──────────────────────────────────────────────────

class _WavePainter extends CustomPainter {
  final double t;
  _WavePainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.15)..style = PaintingStyle.fill;
    final path = Path();
    path.moveTo(0, size.height);
    for (double x = 0; x <= size.width; x++) {
      final y = size.height * 0.5 +
          math.sin((x / size.width * 4 * math.pi) + (t * math.pi * 2)) * size.height * 0.2;
      path.lineTo(x, y);
    }
    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_WavePainter old) => old.t != t;
}

class _DotsLoader extends StatefulWidget {
  const _DotsLoader();

  @override
  State<_DotsLoader> createState() => _DotsLoaderState();
}

class _DotsLoaderState extends State<_DotsLoader> with SingleTickerProviderStateMixin {
  late AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          final t = ((_c.value - i / 3) % 1.0).clamp(0.0, 1.0);
          final s = math.sin(t * math.pi);
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Transform.scale(
              scale: 0.5 + s * 0.5,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _C.silverMid.withOpacity(0.4 + s * 0.6),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _GradBtn extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final bool fullWidth;
  const _GradBtn({required this.label, required this.onTap, this.fullWidth = false});

  @override
  State<_GradBtn> createState() => _GradBtnState();
}

class _GradBtnState extends State<_GradBtn> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) {
        setState(() => _down = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _down = false),
      child: AnimatedScale(
        scale: _down ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          height: 48,
          width: widget.fullWidth ? double.infinity : null,
          decoration: BoxDecoration(
            gradient: _C.silverGrad,
            borderRadius: BorderRadius.circular(14),
            boxShadow: _down
                ? []
                : [
                    BoxShadow(
                      color: _C.silverMid.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Center(
            child: Text(
              widget.label,
              style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w800, fontSize: 15),
            ),
          ),
        ),
      ),
    );
  }
}