import 'dart:ui';
import 'package:flutter/material.dart';
import 'manage_server.dart';
import 'wifi_internal.dart';
import 'wifi_external.dart';
import 'ddos_panel.dart';
import 'nik_check.dart';
import 'tiktok_page.dart';
import 'instagram_page.dart';
import 'qr_gen.dart';
import 'domain_page.dart';
import 'spam_ngl.dart';
import 'riwayat_page.dart';
import 'breach_checker.dart';
import 'web_scanner.dart';
import 'ip_geo.dart';
import 'password_generator.dart';
import 'encoder_tools.dart';
import 'phone_lookup.dart';
import 'snake_game.dart';
import 'game_2048.dart';
import 'text_tools.dart';
import 'fake_identity.dart';
import 'plat_nomor.dart';
import 'converter_page.dart';
import 'url_shortener.dart';
import 'typosquat_checker.dart';
import 'speed_test.dart';
import 'whois_page.dart';
import 'hoxten_controller.dart';

class ToolsPage extends StatelessWidget {
  final String sessionKey;
  final String userRole;
  final List<Map<String, dynamic>> listDoos;

  const ToolsPage({
    super.key,
    required this.sessionKey,
    required this.userRole,
    required this.listDoos,
  });

  // ===== SILVER / DARK COLOR PALETTE =====
  static const Color primaryDark   = Color(0xFF000000); // Hitam Pekat
  static const Color cardDark      = Color(0xFF121212); // Abu Sangat Gelap
  static const Color cardDark2     = Color(0xFF1A1A1A); // Abu Gelap
  static const Color primarySilver = Color(0xFF424242); // Silver Utama
  static const Color accentSilver  = Color(0xFFE0E0E0); // Silver Terang
  static const Color lightSilver   = Color(0xFFBDBDBD); // Silver Muda
  static const Color primaryWhite  = Colors.white;
  static const Color accentGrey    = Color(0xFF9E9E9E);

  // Tool counts per category
  static const Map<String, int> _toolCounts = {
    'DDoS Tools': 2,
    'Network': 3,
    'OSINT': 5,
    'Downloader': 2,
    'Utilities': 5,
    'Security': 7,
    'Games': 2,
    'Converter': 8,
    'Quick Access': 3,
  };

  @override
  Widget build(BuildContext context) {
    final totalTools = _toolCounts.values.fold(0, (a, b) => a + b);
    return Scaffold(
      backgroundColor: primaryDark,
      body: SafeArea(
        child: Column(
          children: [
            // ── HEADER ───────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    primarySilver.withOpacity(0.55), // Silver Gradient
                    accentSilver.withOpacity(0.3),
                    cardDark2,
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
                border: Border(
                  bottom: BorderSide(color: lightSilver.withOpacity(0.25), width: 1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: primarySilver.withOpacity(0.35),
                    blurRadius: 20, offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Icon box
                  Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [primarySilver, accentSilver],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: accentSilver.withOpacity(0.4),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.tune_rounded, color: Colors.black, size: 28), // Icon Hitam
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Tools Dashboard",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontFamily: 'Orbitron',
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Security & OSINT Suite",
                          style: TextStyle(
                            color: lightSilver.withOpacity(0.85),
                            fontSize: 12,
                            fontFamily: 'ShareTechMono',
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Badge total tools
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: lightSilver.withOpacity(0.5), width: 1),
                    ),
                    child: Text(
                      "$totalTools tools",
                      style: const TextStyle(
                        color: lightSilver,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'ShareTechMono',
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── CATEGORY GRID ────────────────────────────────
            Expanded(
              child: GridView.count(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 1.05,
                children: [
                  _buildToolCard(
                    icon: Icons.flash_on_rounded,
                    title: "DDoS Tools",
                    subtitle: "Attack & Server",
                    accentColor: const Color(0xFFFF1744),
                    onTap: () => _showDDoSTools(context),
                  ),
                  _buildToolCard(
                    icon: Icons.wifi_tethering_rounded,
                    title: "Network",
                    subtitle: "WiFi & Spam",
                    accentColor: const Color(0xFFFFAB00),
                    onTap: () => _showNetworkTools(context),
                  ),
                  _buildToolCard(
                    icon: Icons.manage_search_rounded,
                    title: "OSINT",
                    subtitle: "Investigation",
                    accentColor: accentSilver, // Silver
                    onTap: () => _showOSINTTools(context),
                  ),
                  _buildToolCard(
                    icon: Icons.cloud_download_rounded,
                    title: "Downloader",
                    subtitle: "Social Media",
                    accentColor: const Color(0xFF00E5FF),
                    onTap: () => _showDownloaderTools(context),
                  ),
                  _buildToolCard(
                    icon: Icons.handyman_rounded,
                    title: "Utilities",
                    subtitle: "Extra Tools",
                    accentColor: const Color(0xFF69FF47),
                    onTap: () => _showUtilityTools(context),
                  ),
                  _buildToolCard(
                    icon: Icons.shield_rounded,
                    title: "Security",
                    subtitle: "Breach & Scan",
                    accentColor: const Color(0xFFFF6D00),
                    onTap: () => _showSecurityTools(context),
                  ),
                  _buildToolCard(
                    icon: Icons.sports_esports_rounded,
                    title: "Games",
                    subtitle: "Mini Games",
                    accentColor: const Color(0xFFFFD600),
                    onTap: () => _showGames(context),
                  ),
                  _buildToolCard(
                    icon: Icons.transform_rounded,
                    title: "Converter",
                    subtitle: "Text & Units",
                    accentColor: lightSilver, // Silver
                    onTap: () => _showConverterTools(context),
                  ),
                  _buildToolCard(
                    icon: Icons.rocket_launch_rounded,
                    title: "Quick Access",
                    subtitle: "Favorites & History",
                    accentColor: const Color(0xFF40C4FF),
                    onTap: () => _showQuickAccess(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    final count = _toolCounts[title] ?? 0;
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutBack,
      builder: (context, double scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: cardDark,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: accentColor.withOpacity(0.25), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: accentColor.withOpacity(0.12),
                blurRadius: 14, offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Subtle glow top-left
              Positioned(
                top: -20, left: -20,
                child: Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accentColor.withOpacity(0.07),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row: icon box + count badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: accentColor.withOpacity(0.35), width:1),
                          ),
                          child: Icon(icon, color: accentColor, size: 24),
                        ),
                        Container(
                          width: 28, height: 28,
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: accentColor.withOpacity(0.5), width: 1),
                          ),
                          child: Center(
                            child: Text(
                              "$count",
                              style: TextStyle(
                                color: accentColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'ShareTechMono',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Title
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontFamily: 'Orbitron',
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height:3),
                    // Subtitle
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                        fontFamily: 'ShareTechMono',
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Accent line bottom
                    Container(
                      height: 3,
                      width: 36,
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withOpacity(0.5),
                            blurRadius: 6,
                          ),
                        ],
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

  void _showQuickAccess(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: cardDark,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          border: Border.all(color: primarySilver.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(color: primarySilver.withOpacity(0.2), blurRadius: 20, spreadRadius: 5),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [primarySilver, accentSilver], begin: Alignment.centerLeft, end: Alignment.centerRight),
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
              ),
              child: Row(
                children: [
                  Icon(Icons.rocket_launch, color: Colors.black), // Icon Hitam
                  const SizedBox(width: 12),
                  Text("Quick Access", style: TextStyle(color: Colors.black, fontSize: 20, fontFamily: 'Orbitron', fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildToolOption(
                      icon: Icons.history_rounded,
                      label: "Riwayat Aktivitas",
                      color: lightSilver,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => RiwayatPage(sessionKey: sessionKey, role: userRole)));
                      },
                    ),
                    _buildToolOption(icon: Icons.star, label: "Favorites (Coming Soon)", color: lightSilver, onTap: () => _showComingSoon(context)),
                    _buildToolOption(icon: Icons.settings, label: "Settings (Coming Soon)", color: lightSilver, onTap: () => _showComingSoon(context)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDDoSTools(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: cardDark,
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
          border: Border.all(color: primarySilver.withOpacity(0.3)),
          boxShadow: [BoxShadow(color: primarySilver.withOpacity(0.2), blurRadius: 20, spreadRadius: 5)],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [primarySilver, accentSilver], begin: Alignment.centerLeft, end: Alignment.centerRight),
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
              ),
              child: Row(children: [
                Icon(Icons.flash_on, color: Colors.black),
                const SizedBox(width: 12),
                Text("DDoS Tools", style: TextStyle(color: Colors.black, fontSize: 20, fontFamily: 'Orbitron', fontWeight: FontWeight.bold)),
              ]),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildToolOption(
                      icon: Icons.flash_on, label: "Attack Panel", color: lightSilver,
                      onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => AttackPanel(sessionKey: sessionKey, listDoos: listDoos))); },
                    ),
                    _buildToolOption(
                      icon: Icons.dns, label: "Manage Server", color: lightSilver,
                      onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => ManageServerPage(keyToken: sessionKey))); },
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

  void _showNetworkTools(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: cardDark,
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
          border: Border.all(color: primarySilver.withOpacity(0.3)),
          boxShadow: [BoxShadow(color: primarySilver.withOpacity(0.2), blurRadius: 20, spreadRadius: 5)],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [primarySilver, accentSilver], begin: Alignment.centerLeft, end: Alignment.centerRight),
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
              ),
              child: Row(children: [
                Icon(Icons.wifi, color: Colors.black),
                const SizedBox(width: 12),
                Text("Network Tools", style: TextStyle(color: Colors.black, fontSize: 20, fontFamily: 'Orbitron', fontWeight: FontWeight.bold)),
              ]),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildToolOption(icon: Icons.newspaper_outlined, label: "Spam NGL", color: lightSilver,
                        onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const NglPage())); }),
                    _buildToolOption(icon: Icons.wifi_off, label: "WiFi Killer (Internal)", color: lightSilver,
                        onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const WifiKillerPage())); }),
                    if (userRole == "vip" || userRole == "owner")
                      _buildToolOption(icon: Icons.router, label: "WiFi Killer (External)", color: lightSilver,
                          onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => WifiInternalPage(sessionKey: sessionKey))); }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOSINTTools(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: cardDark,
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
          border: Border.all(color: primarySilver.withOpacity(0.3)),
          boxShadow: [BoxShadow(color: primarySilver.withOpacity(0.2), blurRadius: 20, spreadRadius: 5)],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [primarySilver, accentSilver], begin: Alignment.centerLeft, end: Alignment.centerRight),
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
              ),
              child: Row(children: [
                Icon(Icons.search, color: Colors.black),
                const SizedBox(width: 12),
                Text("OSINT Tools", style: TextStyle(color: Colors.black, fontSize: 20, fontFamily: 'Orbitron', fontWeight: FontWeight.bold)),
              ]),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildToolOption(icon: Icons.badge, label: "NIK Detail", color: lightSilver,
                        onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const NikCheckerPage())); }),
                    _buildToolOption(icon: Icons.domain, label: "Domain OSINT", color: lightSilver,
                        onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const DomainOsintPage())); }),
                    _buildToolOption(icon: Icons.phone_android, label: "Phone Lookup", color: lightSilver,
                        onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const PhoneLookupPage())); }),
                    _buildToolOption(icon: Icons.manage_search, label: "WHOIS Lookup", color: lightSilver,
                        onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const WhoisPage())); }),
                    _buildToolOption(icon: Icons.find_replace, label: "Typosquat Checker", color: lightSilver,
                        onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const TyposquatPage())); }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDownloaderTools(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: cardDark,
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
          border: Border.all(color: primarySilver.withOpacity(0.3)),
          boxShadow: [BoxShadow(color: primarySilver.withOpacity(0.2), blurRadius: 20, spreadRadius: 5)],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [primarySilver, accentSilver], begin: Alignment.centerLeft, end: Alignment.centerRight),
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
              ),
              child: Row(children: [
                Icon(Icons.download, color: Colors.black),
                const SizedBox(width: 12),
                Text("Media Downloader", style: TextStyle(color: Colors.black, fontSize: 20, fontFamily: 'Orbitron', fontWeight: FontWeight.bold)),
              ]),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildToolOption(icon: Icons.video_library, label: "TikTok Downloader", color: lightSilver,
                        onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const TiktokDownloaderPage())); }),
                    _buildToolOption(icon: Icons.camera_alt, label: "Instagram Downloader", color: lightSilver,
                        onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const InstagramDownloaderPage())); }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showUtilityTools(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: cardDark,
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
          border: Border.all(color: primarySilver.withOpacity(0.3)),
          boxShadow: [BoxShadow(color: primarySilver.withOpacity(0.2), blurRadius: 20, spreadRadius: 5)],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [primarySilver, accentSilver], begin: Alignment.centerLeft, end: Alignment.centerRight),
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
              ),
              child: Row(children: [
                Icon(Icons.build, color: Colors.black),
                const SizedBox(width: 12),
                Text("Utility Tools", style: TextStyle(color: Colors.black, fontSize: 20, fontFamily: 'Orbitron', fontWeight: FontWeight.bold)),
              ]),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildToolOption(icon: Icons.qr_code, label: "QR Generator", color: lightSilver,
                        onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const QrGeneratorPage())); }),
                    _buildToolOption(icon: Icons.public, label: "IP Geolocation", color: lightSilver,
                        onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const IpGeoPage())); }),
                    _buildToolOption(icon: Icons.speed, label: "Speed Test", color: lightSilver,
                        onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const SpeedTestPage())); }),
                    _buildToolOption(icon: Icons.password, label: "Password Generator", color: lightSilver,
                        onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const PasswordGeneratorPage())); }),
                    _buildToolOption(icon: Icons.link, label: "URL Shortener", color: lightSilver,
                        onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const UrlShortenerPage())); }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      color: cardDark,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: primarySilver.withOpacity(0.3)), // Border Silver
      ),
      elevation:4,
      shadowColor: primarySilver.withOpacity(0.2),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: primarySilver.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(color: primarySilver.withOpacity(0.3)),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(label, style: TextStyle(color: primaryWhite, fontFamily: 'Orbitron', fontWeight: FontWeight.w500)),
        trailing: Container(
          padding: EdgeInsets.all(4),
          decoration: BoxDecoration(color: primarySilver.withOpacity(0.2), shape: BoxShape.circle),
          child: Icon(Icons.arrow_forward_ios, color: color, size: 14),
        ),
        onTap: onTap,
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.hourglass_top, color: primaryWhite),
            SizedBox(width: 8),
            Text('Feature Coming Soon!', style: TextStyle(fontFamily: 'Orbitron', fontWeight: FontWeight.bold, color: primaryWhite)),
          ],
        ),
        backgroundColor: primarySilver, // Silver SnackBar
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Widget _buildSheet(BuildContext context, String title, IconData icon, List<Widget> options) {
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
      decoration: BoxDecoration(
        color: cardDark,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
        border: Border.all(color: primarySilver.withOpacity(0.3)),
        boxShadow: [BoxShadow(color: primarySilver.withOpacity(0.2), blurRadius: 20, spreadRadius: 5)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [primarySilver, accentSilver], begin: Alignment.centerLeft, end: Alignment.centerRight),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
            ),
            child: Row(children: [
              Icon(icon, color: Colors.black),
              const SizedBox(width: 12),
              Text(title, style: TextStyle(color: Colors.black, fontSize: 20, fontFamily: 'Orbitron', fontWeight: FontWeight.bold)),
            ]),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(children: options),
            ),
          ),
        ],
      ),
    );
  }

  void _showSecurityTools(BuildContext context) {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent, isScrollControlled: true,
      builder: (ctx) => _buildSheet(ctx, "Security Tools", Icons.shield, [
        _buildToolOption(icon: Icons.radar, label: "Breach Checker", color: accentSilver,
            onTap: () { Navigator.pop(ctx); Navigator.push(ctx, MaterialPageRoute(builder: (_) => const BreachCheckerPage())); }),
        _buildToolOption(icon: Icons.scanner, label: "Web Scanner", color: lightSilver,
            onTap: () { Navigator.pop(ctx); Navigator.push(ctx, MaterialPageRoute(builder: (_) => const WebScannerPage())); }),
        _buildToolOption(icon: Icons.public, label: "IP Geolocation", color: lightSilver,
            onTap: () { Navigator.pop(ctx); Navigator.push(ctx, MaterialPageRoute(builder: (_) => const IpGeoPage())); }),
        _buildToolOption(icon: Icons.find_replace, label: "Typosquat Checker", color: const Color(0xFFFFD600),
            onTap: () { Navigator.pop(ctx); Navigator.push(ctx, MaterialPageRoute(builder: (_) => const TyposquatPage())); }),
        _buildToolOption(icon: Icons.manage_search, label: "WHOIS Lookup", color: const Color(0xFF00FF41),
            onTap: () { Navigator.pop(ctx); Navigator.push(ctx, MaterialPageRoute(builder: (_) => const WhoisPage())); }),
        _buildToolOption(icon: Icons.speed, label: "Speed Test", color: lightSilver,
            onTap: () { Navigator.pop(ctx); Navigator.push(ctx, MaterialPageRoute(builder: (_) => const SpeedTestPage())); }),
        _buildToolOption(icon: Icons.admin_panel_settings, label: "Hoxten RAT Controller", color: const Color(0xFF00E5FF),
            onTap: () { Navigator.pop(ctx); Navigator.push(ctx, MaterialPageRoute(builder: (_) => const HoxtenRatPage())); }),
      ]),
    );
  }

  void _showGames(BuildContext context) {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent, isScrollControlled: true,
      builder: (ctx) => _buildSheet(ctx, "Mini Games", Icons.sports_esports, [
        _buildToolOption(icon: Icons.sports_esports, label: "Snake Game 🐍", color: primarySilver,
            onTap: () { Navigator.pop(ctx); Navigator.push(ctx, MaterialPageRoute(builder: (_) => const SnakeGamePage())); }),
        _buildToolOption(icon: Icons.grid_4x4, label: "2048 Game", color: const Color(0xFFFFD700),
            onTap: () { Navigator.pop(ctx); Navigator.push(ctx, MaterialPageRoute(builder: (_) => const Game2048Page())); }),
      ]),
    );
  }

  void _showConverterTools(BuildContext context) {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent, isScrollControlled: true,
      builder: (ctx) => _buildSheet(ctx, "Converter & Tools", Icons.transform, [
        _buildToolOption(icon: Icons.currency_exchange, label: "Mata Uang & Satuan", color: lightSilver,
            onTap: () { Navigator.pop(ctx); Navigator.push(ctx, MaterialPageRoute(builder: (_) => const ConverterPage())); }),
        _buildToolOption(icon: Icons.text_fields, label: "Text Tools", color: lightSilver,
            onTap: () { Navigator.pop(ctx); Navigator.push(ctx, MaterialPageRoute(builder: (_) => const TextToolsPage())); }),
        _buildToolOption(icon: Icons.lock, label: "Encoder / Hash", color: const Color(0xFF00FF41),
            onTap: () { Navigator.pop(ctx); Navigator.push(ctx, MaterialPageRoute(builder: (_) => const EncoderToolsPage())); }),
        _buildToolOption(icon: Icons.password, label: "Password Generator", color: lightSilver,
            onTap: () { Navigator.pop(ctx); Navigator.push(ctx, MaterialPageRoute(builder: (_) => const PasswordGeneratorPage())); }),
        _buildToolOption(icon: Icons.link, label: "URL Shortener", color: lightSilver,
            onTap: () { Navigator.pop(ctx); Navigator.push(ctx, MaterialPageRoute(builder: (_) => const UrlShortenerPage())); }),
        _buildToolOption(icon: Icons.person_add, label: "Fake Identity Generator", color: accentSilver,
            onTap: () { Navigator.pop(ctx); Navigator.push(ctx, MaterialPageRoute(builder: (_) => const FakeIdentityPage())); }),
        _buildToolOption(icon: Icons.phone_android, label: "Phone Lookup", color: lightSilver,
            onTap: () { Navigator.pop(ctx); Navigator.push(ctx, MaterialPageRoute(builder: (_) => const PhoneLookupPage())); }),
        _buildToolOption(icon: Icons.directions_car, label: "Cek Plat Nomor", color: Colors.amber,
            onTap: () { Navigator.pop(ctx); Navigator.push(ctx, MaterialPageRoute(builder: (_) => const PlatNomorPage())); }),
      ]),
    );
  }
}