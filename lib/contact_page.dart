import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'fa_icon_ext.dart';

class ContactPage extends StatefulWidget {
  const ContactPage({super.key});

  @override
  State<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  late VideoPlayerController _videoController;

  // --- TEMA WARNA ---
  static const Color bgDark = Color(0xFF121212);
  static const Color primaryRed = Color(0xFF9E9E9E);
  static const Color accentRed = Color(0xFFE0E0E0);

  // Warna glass effect dengan opacity
  static const Color cardGlass = Color.fromARGB(13, 192, 192, 192);
  static const Color borderGlass = Color.fromARGB(26, 192, 192, 192);

  @override
  void initState() {
    super.initState();
    // Inisialisasi video dari assets
    _videoController = VideoPlayerController.asset('assets/videos/banner.mp4')
      ..initialize().then((_) {
        setState(() {}); // Update UI setelah video siap diputar
        _videoController.setLooping(true); // Agar video berulang terus
        _videoController.play(); // Mulai putar video
      });
  }

  @override
  void dispose() {
    _videoController.dispose(); // Wajib di-dispose agar tidak memory leak
    super.dispose();
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: accentRed),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Customer Service",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      // Menggunakan Stack agar video menjadi lapisan paling belakang
      body: Stack(
        children: [
          // Lapisan 1: Video Background
          Positioned.fill(
            child: _videoController.value.isInitialized
                ? FittedBox(
                    fit: BoxFit.cover, // Membuat video memenuhi layar tanpa distorsi
                    child: SizedBox(
                      width: _videoController.value.size.width,
                      height: _videoController.value.size.height,
                      child: VideoPlayer(_videoController),
                    ),
                  )
                : Container(color: bgDark), // Warna sementara sebelum video loading
          ),
          // Lapisan 2: Overlay Gelap (Agar teks dan tombol tetap terbaca)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.6), // Atur opacity sesuai kebutuhan (0.5 - 0.8)
            ),
          ),
          // Lapisan 3: Konten UI asli kamu
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Header Icon
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: primaryRed.withOpacity(0.2),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: primaryRed.withOpacity(0.4),
                          blurRadius: 20,
                        )
                      ],
                    ),
                    child: const Icon(
                      Icons.support_agent_rounded,
                      size: 60,
                      color: accentRed,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Need Help?",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Contact us through our social media platforms below.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Grid Buttons
                  Column(
                    children: [
                      _buildContactButton(
                        label: "Telegram",
                        icon: FontAwesomeIcons.telegram.toIcon(),
                        color: Colors.blue,
                        url: "https://t.me/hafz_reals",
                      ),
                      const SizedBox(height: 16),
                      _buildContactButton(
                        label: "WhatsApp",
                        icon: FontAwesomeIcons.whatsapp.toIcon(),
                        color: Colors.green,
                        url: "https://wa.me/62",
                      ),
                      const SizedBox(height: 16),
                      _buildContactButton(
                        label: "TikTok",
                        icon: FontAwesomeIcons.tiktok.toIcon(),
                        color: Colors.white,
                        url: "https://www.tiktok.com/@hafzz_111",
                      ),
                      const SizedBox(height: 16),
                      _buildContactButton(
                        label: "Instagram",
                        icon: FontAwesomeIcons.instagram.toIcon(),
                        color: Colors.pinkAccent,
                        url: "https://www.instagram.com/hafzz_store1?igsh=dHlxMGM2dmZ4ZmRu",
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactButton({
    required String label,
    required IconData icon,
    required Color color,
    required String url,
  }) {
    return InkWell(
      onTap: () => _launchUrl(url),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        decoration: BoxDecoration(
          color: cardGlass,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderGlass),
          boxShadow: [
            BoxShadow(
              color: primaryRed.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 20),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white54,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}