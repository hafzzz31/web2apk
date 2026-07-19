import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:video_player/video_player.dart';
import 'fa_icon_ext.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  
  // Video Player Controller
  late VideoPlayerController _videoController;

  // ─── PALETTE: FUTURE STEEL ───────────────────────────────────
  static const Color bgDeep = Color(0xFF050505);
  static const Color surface = Color(0xFF0F1014);
  static const Color silver = Color(0xFFB0B8C4);
  static const Color silverLight = Color(0xFFE2E8F0);
  static const Color accent = Color(0xFF38BDF8); // Sky Blue Accent
  static const Color glass = Color(0x121A1D24);
  static const Color border = Color(0x1FFFFFFF);

  @override
  void initState() {
    super.initState();
    
    // Inisialisasi Video
    _videoController = VideoPlayerController.asset('assets/videos/banner.mp4')
      ..initialize().then((_) {
        setState(() {});
        _videoController.setLooping(true);
        _videoController.play();
      }).catchError((e) {
        debugPrint("Error loading video: $e");
      });

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _videoController.dispose();
    super.dispose();
  }

  Future<void> _openUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  // ─── PRICE CATALOG DIALOG ────────────────────────────────────────
  void _showPriceCatalog() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF121212),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: silver.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.6),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  border: Border(
                    bottom: BorderSide(color: border, width: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.diamond_outlined, color: accent, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        "PRICING PLAN",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Icon(Icons.close, color: silver, size: 20),
                    ),
                  ],
                ),
              ),
              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Member 1 Bulan (Abu-abu, Ikon User)
                      const _PriceCard(
                        title: "MEMBER",
                        price: "25k",
                        duration: "1 Bulan",
                        icon: Icons.person_outline,
                        color: Color(0xFF90A4AE), // Blue Grey
                        isHighlight: true,
                      ),
                      const SizedBox(height: 12),
                      // Member Permanent (Putih Krem, Ikon User Star)
                      const _PriceCard(
                        title: "MEMBER",
                        price: "50k",
                        duration: "Permanent",
                        icon: Icons.star_outline_rounded,
                        color: Color(0xFFCFD8DC), // Lighter Silver/White
                        isHighlight: true,
                      ),
                      const SizedBox(height: 12),
                      // Reseller (Oranye, Ikon Toko)
                      const _PriceCard(
                        title: "RESELLER",
                        price: "100k",
                        duration: "Permanent",
                        icon: Icons.storefront_outlined,
                        color: Color(0xFFFF9800), // Orange
                        isHighlight: true,
                      ),
                      const SizedBox(height: 12),
                      // Partner (Ungu, Ikon Handshake)
                      const _PriceCard(
                        title: "PARTNER",
                        price: "200k",
                        duration: "Permanent",
                        icon: Icons.handshake_outlined,
                        color: Color(0xFFAB47BC), // Purple
                        isHighlight: true,
                      ),
                      const SizedBox(height: 12),
                      // TK (Hijau, Ikon Verified)
                      const _PriceCard(
                        title: "TK",
                        price: "300k",
                        duration: "Permanent",
                        icon: Icons.verified_user_outlined,
                        color: Color(0xFF66BB6A), // Green
                        isHighlight: true,
                      ),
                      const SizedBox(height: 12),
                      // Moderator (Emas/Kuning, Ikon Gavel)
                      const _PriceCard(
                        title: "MODERATOR",
                        price: "400k",
                        duration: "Permanent",
                        icon: Icons.gavel_outlined,
                        color: Color(0xFFFFCA28), // Amber/Gold
                        isHighlight: true,
                      ),
                      const SizedBox(height: 12),
                      // Admin (Merah, Ikon Shield)
                      const _PriceCard(
                        title: "OWNER",
                        price: "600k",
                        duration: "Permanent",
                        icon: Icons.admin_panel_settings_outlined,
                        color: Color(0xFFEF5350), // Red
                        isHighlight: true,
                      ),
                      const SizedBox(height: 24),
                      _ContactButton(
                        icon: FontAwesomeIcons.telegram.toIcon(),
                        label: "Chat Admin for Order",
                        url: "https://t.me/hafz_reals",
                        color: Colors.blueAccent,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDeep,
      // Menggunakan Stack untuk menumpuk Video dan UI (Teks/Tombol)
      body: Stack(
        children: [
          // ─── BACKGROUND VIDEO LAYER ────────────────────────────
          Positioned.fill(
            child: _videoController.value.isInitialized
                ? VideoPlayer(_videoController)
                : Container(color: bgDeep),
          ),
          
          // ─── DARK OVERLAY AGAR TEKS TERBACA ────────────────────
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    bgDeep.withOpacity(0.85),
                    bgDeep.withOpacity(0.4),
                    bgDeep.withOpacity(0.95),
                  ],
                ),
              ),
            ),
          ),

          // ─── UI CONTENT LAYER (FULL SCREEN TANPA SCROLL) ──────
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                // Diganti Column agar memenuhi layar secara penuh (Full Screen)
                child: Column(
                  children: [
                    // ── HEADER ────────────────────────────────────
                  // (Bagian Hoxten V.5 sudah dihapus sesuai permintaan)
                    const Spacer(flex: 1), // DIUBAH: Flex diturunkan dari 2 ke 1 agar posisi naik
                    // ── LOGO (POSISI TENGAH, DI ATAS WELCOME BACK) ─
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: silver.withOpacity(0.4), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 15,
                            spreadRadius: 2,
                          )
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/logo.jpg',
                          width: 80, // Ukuran diperbesar agar proporsional
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 80,
                            height: 80,
                            color: surface,
                            child: const Icon(Icons.image, color: silver, size: 40),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── TITLE SECTION (CENTERED) ─────────────────
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Colors.white, silver],
                      ).createShader(bounds),
                      child: const Text(
                        "WELCOME BACK",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.1,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Premium tools for your digital needs.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: silver.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                    
                    const SizedBox(height: 24),

                    // ── FEATURES GRID ────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: _FeatureChip(
                                icon: Icons.flash_on_rounded, label: "Fast"),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _FeatureChip(
                                icon: Icons.security_rounded, label: "Safe"),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _FeatureChip(
                                icon: Icons.support_agent_rounded, label: "24/7"),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── SOCIAL CONTACT ───────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: _ContactButton(
                              icon: FontAwesomeIcons.telegram.toIcon(),
                              label: "Telegram",
                              url: "https://t.me/hafz_reals",
                              color: silver,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ContactButton(
                              icon: FontAwesomeIcons.tiktok.toIcon(),
                              label: "TikTok",
                              url: "https://www.tiktok.com/@Hafzz_111",
                              color: silverLight,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),
                    
                    // ── CREDITS ──────────────────────────────────
                    Center(
                      child: Text(
                        "Powered by @hafz_reals",
                        style: TextStyle(
                          color: silver.withOpacity(0.4),
                          fontSize: 10,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ─── ACTION BUTTONS ──────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: OutlinedButton.icon(
                              onPressed: _showPriceCatalog,
                              icon: const Icon(Icons.shopping_bag_outlined,
                                  size: 18, color: silver),
                              label: const Text("Check Pricing"),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: silverLight,
                                side: BorderSide(color: border),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              onPressed: () => Navigator.pushNamed(context, "/login"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: silverLight,
                                foregroundColor: Colors.black,
                                elevation: 0,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text("Sign In Now",
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.5)),
                                  SizedBox(width: 8),
                                  Icon(Icons.arrow_forward_rounded, size: 18),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                   const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── WIDGET COMPONENTS ──────────────────────────────────────────────

  Widget _FeatureChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: glass,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          Icon(icon, color: silverLight, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
                color: silver.withOpacity(0.9),
                fontSize: 11,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _ContactButton({
    required IconData icon,
    required String label,
    required String url,
    required Color color,
  }) {
    return InkWell(
      onTap: () => _openUrl(url),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── SUB WIDGETS: DIALOG COMPONENTS ───────────────────────────────────────
class _PriceCard extends StatelessWidget {
  final String title;
  final String price;
  final String duration;
  final IconData icon;
  final Color color;
  final bool isHighlight;

  const _PriceCard({
    required this.title,
    required this.price,
    required this.duration,
    required this.icon,
    required this.color,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isHighlight ? color.withOpacity(0.1) : const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHighlight ? color : Colors.white.withOpacity(0.1),
          width: isHighlight ? 1.5 : 0.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  duration,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Text(
            "Rp$price",
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}