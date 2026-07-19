import 'dart:ui' as ui;
import 'dart:math' as math;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'fa_icon_ext.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';

// Import halaman lain
import 'developer_page.dart';
import 'moderator_page.dart';
import 'tk_page.dart';
import 'nik_check.dart';
import 'admin_page.dart';
import 'partner_page.dart';
import 'owner_page.dart';
import 'home_page.dart';
import 'seller_page.dart';
import 'change_password_page.dart';
import 'tools_gateway.dart';
import 'login_page.dart';
import 'bug_sender.dart';
import 'contact_page.dart';
import 'profile_page.dart';
import 'riwayat_page.dart';
import 'info_page.dart';
import 'anime_home.dart';
import 'spotify_page.dart';
import 'ai_page.dart';
import 'comic_page.dart';
import 'al_quran.dart';
import 'sholat_tools_page.dart';
import 'hijri_doa_page.dart';
import 'tiktok_booster.dart';
import 'admin_control.dart';
import 'hoxten_controller.dart';

class DashboardPage extends StatefulWidget {
  final String username;
  final String password;
  final String role;
  final String expiredDate;
  final String sessionKey;
  final List<Map<String, dynamic>> listBug;
  final List<Map<String, dynamic>> listDoos;
  final List<dynamic> news;

  const DashboardPage({
    super.key,
    required this.username,
    required this.password,
    required this.role,
    required this.expiredDate,
    required this.listBug,
    required this.listDoos,
    required this.sessionKey,
    required this.news,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late WebSocketChannel channel;
  
  final ScrollController _quickActionsScrollController = ScrollController();

  late String sessionKey;
  late String username;
  late String password;
  late String role;
  late String expiredDate;
  late List<Map<String, dynamic>> listBug;
  late List<Map<String, dynamic>> listDoos;
  late List<dynamic> newsList;

  String androidId = "unknown";
  File? _profileImage;
  
  // ✅ VIDEO CONTROLLER UNTUK HEADER CARD
  VideoPlayerController? _headerVideoController;

  int _bottomNavIndex = 0;
  Widget _selectedPage = const Placeholder();

  int onlineUsers = 0;
  int activeConnections = 0;

  // ===== WEATHER =====
  String _weatherTemp = '--';
  String _weatherCity = 'Memuat...';
  String _weatherDesc = '';
  String _weatherHumidity = '--';
  String _weatherWind = '--';
  bool _weatherLoading = true;
  IconData _weatherIcon = Icons.wb_sunny_rounded;

  // ===== COLOR PALETTE =====
  final Color bgDark        = const Color(0xFF000000); 
  final Color bgSurface     = const Color(0xFF1A1D21);  
  final Color primarySilver = const Color(0xFFE0E0E0); 
  final Color accentSilver  = const Color(0xFFB0BEC5); 
  final Color dimSilver     = const Color(0xFF546E7A);
  final Color accentGrey    = const Color(0xFF757575); 
  
  final Color glassWhite    = const Color(0x1AFFFFFF); 
  final Color borderSilver  = const Color(0x40FFFFFF); 

  final Color btnBlue       = const Color(0xFF3B82F6);
  final Color btnRed        = const Color(0xFFEF4444);

  final Color greenStatus   = const Color(0xFF00E676); 
  final Color blueStatus    = const Color(0xFF2979FF); 
  final Color redStatus     = const Color(0xFFFF1744);

  @override
  void initState() {
    super.initState();
    sessionKey  = widget.sessionKey;
    username    = widget.username;
    password    = widget.password;
    role        = widget.role;
    expiredDate = widget.expiredDate;
    listBug     = widget.listBug;
    listDoos    = widget.listDoos;
    newsList    = widget.news;

    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart);
    _controller.forward();

    _selectedPage = _buildNewsPage();
    _initAndroidIdAndConnect();
    _loadProfileImage();
    _initHeaderVideo(); // ✅ INISIALISASI VIDEO HEADER
    _fetchWeather();
  }

  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final imagePath = prefs.getString('profile_image_$username');
    if (imagePath != null && imagePath.isNotEmpty) {
      setState(() => _profileImage = File(imagePath));
    }
  }

  // ✅ FUNGSI VIDEO HEADER
  void _initHeaderVideo() {
    try {
      _headerVideoController = VideoPlayerController.asset('assets/videos/landing.mp4')
        ..initialize().then((_) {
          setState(() {});
          _headerVideoController?.setLooping(true);
          _headerVideoController?.setVolume(0.0);
          _headerVideoController?.play();
        }).catchError((e) {
          debugPrint("Header Video error: $e");
          setState(() {});
        });
    } catch (e) {
      debugPrint("Header Video init catch: $e");
      setState(() {});
    }
  }

  Future<void> _initAndroidIdAndConnect() async {
    final deviceInfo = await DeviceInfoPlugin().androidInfo;
    androidId = deviceInfo.id;
    _connectToWebSocket();
  }

  void _connectToWebSocket() {
    try {
      channel = WebSocketChannel.connect(
          Uri.parse('wss://ws-serverpterodactyl.szxennofficial.my.id'));
      channel.sink.add(jsonEncode({"type": "stats"}));
      channel.stream.listen((event) {
        final data = jsonDecode(event);
        if (data['type'] == 'stats') {
          setState(() {
            onlineUsers        = data['onlineUsers'] ?? 0;
            activeConnections  = data['activeConnections'] ?? 0;
          });
        }
      }, onError: (e) => debugPrint("WS error: $e"));
    } catch (e) {
      debugPrint("WS Connect error: $e");
    }
  }

  Future<void> _fetchWeather() async {
    if (!mounted) return;
    setState(() => _weatherLoading = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) setState(() {
          _weatherTemp = '--';
          _weatherCity = 'GPS Mati';
          _weatherDesc = 'Aktifkan lokasi';
          _weatherLoading = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) setState(() {
            _weatherTemp = '--';
            _weatherCity = 'Izin Ditolak';
            _weatherDesc = 'Izinkan lokasi';
            _weatherLoading = false;
          });
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) setState(() {
          _weatherTemp = '--';
          _weatherCity = 'Izin Diblokir';
          _weatherDesc = 'Buka Settings';
          _weatherLoading = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      ).timeout(const Duration(seconds: 15));

      final lat = position.latitude;
      final lon = position.longitude;

      final response = await http.get(
        Uri.parse('https://wttr.in/$lat,$lon?format=j1'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final current = data['current_condition'][0];
        final nearest = data['nearest_area'][0];
        final cityName = nearest['areaName'][0]['value'] ?? 'Lokasimu';
        final tempC = current['temp_C'] ?? '--';
        final humidity = current['humidity'] ?? '--';
        final windKmph = current['windspeedKmph'] ?? '--';
        final windDir = current['winddirDegree'] ?? '--';
        final desc = current['weatherDesc'][0]['value'] ?? '';
        final weatherCode = int.tryParse(current['weatherCode'].toString()) ?? 113;

        IconData icon;
        if (weatherCode == 113) {
          icon = Icons.wb_sunny_rounded;
        } else if (weatherCode <= 119) {
          icon = Icons.wb_cloudy_rounded;
        } else if (weatherCode <= 176) {
          icon = Icons.cloud_rounded;
        } else if (weatherCode <= 263) {
          icon = Icons.grain_rounded;
        } else if (weatherCode <= 389) {
          icon = Icons.thunderstorm_rounded;
        } else {
          icon = Icons.ac_unit_rounded;
        }

        if (mounted) {
          setState(() {
            _weatherTemp = '$tempC°C';
            _weatherCity = cityName.toUpperCase();
            _weatherDesc = desc;
            _weatherHumidity = '$humidity%';
            _weatherWind = '$windKmph m/s $windDir°';
            _weatherIcon = icon;
            _weatherLoading = false;
          });
        }
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _weatherTemp = '--';
          _weatherCity = 'Gagal memuat';
          _weatherDesc = 'Cek koneksi';
          _weatherLoading = false;
        });
      }
    }
  }

  Future<void> _openUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception("Could not launch $uri");
    }
  }

  void _onBottomNavTapped(int index) {
    setState(() {
      _bottomNavIndex = index;
      switch (index) {
        case 0:
          _selectedPage = _buildNewsPage();
          break;
        case 1:
          _selectedPage = HoxtenRatPage(onBack: () => _onBottomNavTapped(0));
          break;
        case 2:
          _selectedPage = HomePage(
            username: username, password: password,
            listBug: listBug, role: role,
            expiredDate: expiredDate, sessionKey: sessionKey,
          );
          break;
        case 3:
          _selectedPage = InfoPage(sessionKey: sessionKey);
          break;
        case 4:
          _selectedPage = ToolsPage(
              sessionKey: sessionKey, userRole: role, listDoos: listDoos);
          break;
      }
    });
  }

  void _onSidebarTabSelected(int index) {
    setState(() {
      if (index == 1) _selectedPage = SellerPage(keyToken: sessionKey);
      else if (index == 3) _selectedPage = AdminPage(sessionKey: sessionKey, username: username);
      else if (index == 4) _selectedPage = OwnerPage(sessionKey: sessionKey, username: username);
      else if (index == 5) _selectedPage = PartnerPage(sessionKey: sessionKey, username: username);
      else if (index == 6) _selectedPage = TkPage(sessionKey: sessionKey, username: username);
      else if (index == 7) _selectedPage = ModeratorPage(sessionKey: sessionKey, username: username);
      else if (index == 8) _selectedPage = DeveloperPage(sessionKey: sessionKey, username: username);
    });
    Navigator.pop(context);
  }

  Widget _buildNewsPage() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 80), 
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),

          // HEADER PROFILE — TETAP PAKAI VIDEO
          Container(
            width: double.infinity,
            height: 250, 
            margin: const EdgeInsets.symmetric(horizontal: 16), 
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // ✅ VIDEO BACKGROUND HEADER
                  if (_headerVideoController != null && _headerVideoController!.value.isInitialized)
                    FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _headerVideoController!.value.size.width,
                        height: _headerVideoController!.value.size.height,
                        child: VideoPlayer(_headerVideoController!),
                      ),
                    )
                  else
                    // FALLBACK jika video belum siap
                    Image.asset(
                      'assets/images/hoxten.jpg',
                      fit: BoxFit.cover,
                    ),
                  
                  // OVERLAY GELAP
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.6),
                          Colors.black.withOpacity(0.4),
                        ],
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 45,
                                  height: 45,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF8E9EAB), Color(0xFFECEFF1)],
                                    ),
                                    boxShadow: [BoxShadow(color: primarySilver.withOpacity(0.4), blurRadius: 10)],
                                  ),
                                  child: _profileImage != null
                                      ? ClipOval(child: Image.file(_profileImage!, fit: BoxFit.cover))
                                      : const Icon(Icons.person_rounded, color: Colors.black87, size: 24),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Welcome Back.",
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      username.toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        fontFamily: 'Orbitron',
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          role.toUpperCase(),
                                          style: TextStyle(
                                            color: Colors.white, 
                                            fontSize: 13, 
                                            fontWeight: FontWeight.bold,
                                            shadows: [Shadow(color: Colors.black, blurRadius: 2)]
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          width: 4, height: 4,
                                          decoration: BoxDecoration(
                                            color: Colors.white70,
                                            shape: BoxShape.circle
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        const Text(
                                          "ONLINE",
                                          style: TextStyle(
                                            color: Colors.white70, 
                                            fontSize: 13, 
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.blueAccent.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.blueAccent),
                              ),
                              child: const Text(
                                "SESSION AKTIF",
                                style: TextStyle(color: Colors.blueAccent, fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        
                        const Spacer(),

                        Row(
                          children: [
                            _statRowItem(
                              icon: Icons.group,
                              label: "Online Users",
                              value: "$onlineUsers / 1500 Slot",
                              color: Colors.cyan,
                            ),
                            const SizedBox(width: 20),
                            _statRowItem(
                              icon: Icons.cable,
                              label: "Active Connections",
                              value: "$activeConnections Koneksi",
                              color: Colors.orange,
                            ),
                          ],
                        ),

                        const Spacer(),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _infoBarItem(
                              icon: Icons.bug_report,
                              label: "BUG",
                              value: "${listBug.length} item",
                              color: Colors.redAccent,
                            ),
                            _infoBarItem(
                              icon: Icons.flash_on,
                              label: "DDOS",
                              value: "4 item",
                              color: Colors.orangeAccent,
                            ),
                            _infoBarItem(
                              icon: Icons.timer,
                              label: "EXPIRATION",
                              value: expiredDate,
                              color: Colors.greenAccent,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // --- RAT CONTROL CARD ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(child: _featureCard(
                  title: "Manage Sender",
                  subtitle: "Kelola Sender",
                  badgeText: "SENDER",
                  icon: Icons.sensors,
                  gradientColors: [const Color(0xFF7F1D1D), const Color(0xFF450A0A)],
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => BugSenderPage(
                      sessionKey: sessionKey, username: username, role: role),
                  )),
                )),
                const SizedBox(width: 16),
                Expanded(child: _featureCard(
                  title: "Remote Acces Trojan",
                  subtitle: "RAT CONTROL",
                  badgeText: "CONTROL",
                  icon: FontAwesomeIcons.server.toIcon(),
                  gradientColors: [const Color(0xFF4338CA), const Color(0xFF1E1B4B)],
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HoxtenRatPage())),
                )),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // NEWS SECTION
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _sectionTitle(Icons.fiber_new_rounded, "Latest News"),
                    Text("${newsList.length} Item", style: TextStyle(color: dimSilver, fontSize: 11, fontFamily: 'ShareTechMono')),
                  ],
                ),
                const SizedBox(height: 12),
                if (newsList.isNotEmpty)
                  SizedBox(
                    height: 190,
                    child: PageView.builder(
                      controller: PageController(viewportFraction: 0.9),
                      itemCount: newsList.length,
                      itemBuilder: (ctx, i) {
                        final item = newsList[i];
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            color: bgSurface,
                            border: Border.all(color: accentSilver.withOpacity(0.3)),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(22),
                            child: Stack(fit: StackFit.expand, children: [
                              if (item['image'] != null && item['image'].toString().isNotEmpty)
                                NewsMedia(url: item['image']),
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.black.withOpacity(0.9),
                                      Colors.transparent,
                                    ],
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 12, left: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: primarySilver,
                                    borderRadius: BorderRadius.circular(6),
                                    boxShadow: [BoxShadow(color: Colors.black, blurRadius: 4)],
                                  ),
                                  child: const Text(
                                    "NEWS",
                                    style: TextStyle(
                                      color: Colors.black, fontSize: 9,
                                      fontWeight: FontWeight.w900, letterSpacing: 1.2,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 16, left: 16, right: 16,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item['title'] ?? '',
                                      style: TextStyle(
                                        color: primarySilver, fontSize: 15,
                                        fontWeight: FontWeight.w700, height: 1.2,
                                      )),
                                    const SizedBox(height: 4),
                                    Text(item['desc'] ?? '',
                                      style: TextStyle(color: accentSilver.withOpacity(0.8), fontSize: 11),
                                      maxLines: 2, overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                            ]),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 24),

// TELEGRAM BUTTON PREMIUM
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 16),
  child: InkWell(
    borderRadius: BorderRadius.circular(30),
    onTap: () => _openUrl('https://t.me/rdvspproject'),
    child: Container(
      height: 68,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          colors: [
            const Color(0xFF0B111A),
            const Color(0xFF101B2D),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: Colors.blue.withOpacity(0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.15),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.shade400,
                    Colors.blue.shade700,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.4),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Icon(
                FontAwesomeIcons.telegramPlane.toIcon(),
                color: Colors.white,
                size: 22,
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "RDVSP PROJECT",
                    style: TextStyle(
                      color: Colors.blue.shade300,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    "Join Telegram Channel",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),

            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.blue,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    ),
  ),
),

const SizedBox(height: 24),

          // INFO BOX
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GestureDetector(
              onTap: _showInfoDialog,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    Colors.blueGrey.withOpacity(0.2),
                    Colors.grey.withOpacity(0.1),
                  ]),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: accentSilver.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: primarySilver.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.info_outline, color: primarySilver, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Info & Pengumuman", style: TextStyle(color: primarySilver, fontSize: 14, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text("Klik untuk melihat update terbaru", style: TextStyle(color: dimSilver, fontSize: 11)),
                      ],
                    )),
                    Icon(Icons.arrow_forward_ios, color: dimSilver, size: 14),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // WEATHER CARD
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _weatherLoading
                ? Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: bgSurface,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: borderSilver),
                  ),
                  child: Row(children: [
                      SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: accentSilver)),
                      const SizedBox(width: 12),
                      Text('Mendeteksi lokasi...', style: TextStyle(color: dimSilver, fontSize: 13)),
                    ]),
                )
                : Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A0E14), 
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.2)), 
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 110,
                        height: 110,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 110, height: 110,
                              child: CircularProgressIndicator(
                                strokeWidth: 4,
                                value: 0.7, 
                                backgroundColor: Colors.black26,
                                valueColor: const AlwaysStoppedAnimation<Color>(Colors.cyanAccent),
                              ),
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _weatherTemp.replaceAll('°C', ''), 
                                  style: const TextStyle(
                                    color: Colors.cyanAccent,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    fontFamily: 'Orbitron',
                                    shadows: [
                                      Shadow(color: Colors.cyan, blurRadius: 10)
                                    ]
                                  ),
                                ),
                                const Text(
                                  "°C",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                )
                              ],
                            ),
                            Positioned(
                              bottom: 5,
                              right: 5,
                              child: Icon(_weatherIcon, color: Colors.white70, size: 20),
                            )
                          ],
                        ),
                      ),
                      
                      const SizedBox(width: 20),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.location_on_rounded, color: Colors.white70, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  _weatherCity,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              _weatherDesc,
                              style: TextStyle(
                                color: Colors.cyanAccent.withOpacity(0.8),
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.air, color: Colors.white54, size: 14),
                                          const SizedBox(width: 4),
                                          const Text("WIND", style: TextStyle(color: Colors.white54, fontSize: 10)),
                                        ],
                                      ),
                                      Text(_weatherWind, style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'ShareTechMono')),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.opacity, color: Colors.white54, size: 14),
                                          const SizedBox(width: 4),
                                          const Text("HUMIDITY", style: TextStyle(color: Colors.white54, fontSize: 10)),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: (double.tryParse(_weatherHumidity.replaceAll('%', '')) ?? 0.0) / 100,
                                          backgroundColor: Colors.white10,
                                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                                          minHeight: 4,
                                        ),
                                      ),
                                      Text(_weatherHumidity, style: const TextStyle(color: Colors.blueAccent, fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'ShareTechMono')),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 16),
                            
                            Row(
                              children: [
                                const Icon(Icons.compress, color: Colors.white54, size: 14),
                                const SizedBox(width: 4),
                                Text("PRESSURE", style: TextStyle(color: Colors.white54, fontSize: 10)),
                                const Spacer(),
                                Text("1013 hPa", style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'ShareTechMono')),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
          ),

          const SizedBox(height: 32),

          // CONNECT WITH HOXTEN
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.pink,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.group_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      "CONNECT WITH RDVSP",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Orbitron',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 25),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _circleContactButton(
                      FontAwesomeIcons.telegram.toIcon(),
                      "Telegram",
                      const Color(0xFF0088cc),
                      "https://t.me/hafz_reals"
                    ),
                    _circleContactButton(
                      FontAwesomeIcons.whatsapp.toIcon(),
                      "WhatsApp",
                      const Color(0xFF25D366),
                      "https://wa.me/6282313734893"
                    ),
                    _circleContactButton(
                      FontAwesomeIcons.tiktok.toIcon(),
                      "TikTok",
                      Colors.white,
                      "https://www.tiktok.com/@Hafz_111"
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                Center(
                  child: Text(
                    "Selalu nantikan project terbaru dari TEAM RDVSP",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: dimSilver,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // --- WIDGET HELPERS ---
  
  Widget _sectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: primarySilver.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderSilver),
          ),
          child: Icon(icon, color: primarySilver, size: 16),
        ),
        const SizedBox(width: 10),
        Text(title, style: TextStyle(color: primarySilver, fontSize: 16, fontWeight: FontWeight.w800, fontFamily: 'Orbitron')),
      ],
    );
  }

  Widget _statRowItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 14),
                const SizedBox(width: 4),
                Text(
                  label, 
                  style: TextStyle(color: color.withOpacity(0.8), fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              value, 
              style: const TextStyle(
                color: Colors.white, 
                fontSize: 12, 
                fontWeight: FontWeight.w600
              ),
              maxLines: 1, 
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoBarItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.3), width: 0.5),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.w800)),
                  Text(
                    value, 
                    style: const TextStyle(
                      color: Colors.white, 
                      fontSize: 10, 
                      fontWeight: FontWeight.w600
                    ),
                    maxLines: 1, 
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildMainActionButton({
    required IconData icon,
    required String label,
    required Color color1,
    required Color color2,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 60,
            width: 60, 
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [color1, color2],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: color1.withOpacity(0.5),
                  blurRadius: 15,
                  spreadRadius: 0,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 28),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: primarySilver, 
              fontSize: 11, 
              fontWeight: FontWeight.w600,
              shadows: [
                Shadow(color: Colors.black.withOpacity(0.8), blurRadius: 4, offset: Offset(0, 1))
              ]
            ),
          ),
        ],
      ),
    );
  }

  Widget _featureCard({
    required String title,
    required String subtitle,
    required String badgeText,
    required IconData icon,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradientColors, begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradientColors[0].withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withOpacity(0.4), width: 1),
                  ),
                  child: Text(
                    badgeText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                fontFamily: 'Orbitron',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickActionCard({
    required IconData icon,
    required String label,
    required String sub,
    required List<Color> gradient,
    required Color iconBg,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradient[0].withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label, 
                      style: TextStyle(
                        color: Colors.white, 
                        fontSize: 18, 
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Orbitron'
                      )
                    ),
                    const SizedBox(height: 4),
                    Text(
                      sub, 
                      style: TextStyle(
                        color: Colors.white70, 
                        fontSize: 12,
                        fontWeight: FontWeight.w500
                      )
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _circleContactButton(IconData icon, String label, Color color, String url) {
    return InkWell(
      onTap: () => _openUrl(url),
      borderRadius: BorderRadius.circular(30),
      child: Column(
        children: [
          Container(
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 15,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Icon(
              icon,
              color: (color == Colors.white) ? Colors.black : Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              color: primarySilver,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _sectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: primarySilver.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderSilver),
          ),
          child: Icon(icon, color: primarySilver, size: 16),
        ),
        const SizedBox(width: 10),
        Text(title, style: TextStyle(color: primarySilver, fontSize: 16, fontWeight: FontWeight.w800, fontFamily: 'Orbitron')),
      ],
    );
  }

  Widget _roleBadge(String text) {
    final lowerRole = text.toLowerCase();
    Color badgeColor;
    if (lowerRole == 'owner') {
      badgeColor = const Color(0xFFFFD700);
    } else if (lowerRole == 'partner') {
      badgeColor = const Color(0xFF00E5FF);
    } else if (lowerRole == 'admin') {
      badgeColor = const Color(0xFFFF6D00);
    } else if (lowerRole == 'reseller' || lowerRole == 'seller') {
      badgeColor = const Color(0xFF69FF47);
    } else {
      badgeColor = primarySilver;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: badgeColor.withOpacity(0.5)),
      ),
      child: Text(text,
        style: TextStyle(color: badgeColor, fontSize: 9,
            fontWeight: FontWeight.w800, letterSpacing: 0.8)),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: bgSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: borderSilver)),
        title: Row(children: [
          Icon(Icons.info_outline, color: primarySilver),
          const SizedBox(width: 8),
          Text("Info Update", style: TextStyle(color: primarySilver, fontWeight: FontWeight.bold)),
        ]),
        content: Text(
          "🚀 Update Versi Terbaru 🚀\n\n"
          "• Perbaikan tampilan Dashboard\n"
          "• Penambahan fitur Quick Actions\n"
          "• Optimalisasi koneksi & sender\n\n"
          "Terima kasih sudah menggunakan RDVSP!",
          style: TextStyle(color: accentSilver, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Tutup", style: TextStyle(color: primarySilver, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomDrawer() {
    return Drawer(
      backgroundColor: bgDark,
      child: SafeArea(
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [bgSurface, bgDark],
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
              ),
            ),
            child: Row(children: [
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: primarySilver, width: 2),
                  boxShadow: [BoxShadow(color: primarySilver.withOpacity(0.2), blurRadius: 10)],
                ),
                child: ClipOval(
                  child: _profileImage != null
                      ? Image.file(_profileImage!, fit: BoxFit.cover)
                      : Icon(Icons.person_rounded, color: primarySilver, size: 30),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(username, style: TextStyle(color: primarySilver, fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'Orbitron')),
                  const SizedBox(height: 6),
                  _roleBadge(role.toUpperCase()),
                ],
              )),
            ]),
          ),
          Expanded(
            child: ListView(children: [
              if (role == 'seller' || role == 'reseller')
                _drawerItem(Icons.storefront_rounded, "Seller Page", () => _onSidebarTabSelected(1)),
              if (role == 'admin')
                _drawerItem(Icons.handshake_rounded, "Admin Page", () => _onSidebarTabSelected(3)),
              if (role == 'owner')
                _drawerItem(Icons.workspace_premium_rounded, "Owner Page", () => _onSidebarTabSelected(4)),
                if (role == 'partner')
                _drawerItem(Icons.handshake_rounded, "Partner Page", () => _onSidebarTabSelected(5)),
                if (role == 'tk')
                _drawerItem(Icons.workspace_premium_rounded, "TK Page", () => _onSidebarTabSelected(6)),
                if (role == 'moderator')
                _drawerItem(Icons.shield_rounded, "Moderator Page", () => _onSidebarTabSelected(7)),
                if (role == 'developer')
                _drawerItem(Icons.code_rounded, "Developer Page", () => _onSidebarTabSelected(8)),
              
              _drawerItem(Icons.history_rounded, "Riwayat Aktivitas", () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => RiwayatPage(sessionKey: sessionKey, role: role)));
              }),
              _drawerItem(Icons.lock_outline_rounded, "Ganti Password", () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => ChangePasswordPage(username: username, sessionKey: sessionKey)));
              }),
              const SizedBox(height: 10),
              Divider(color: borderSilver, thickness: 1),
              const SizedBox(height: 10),
              _drawerItem(Icons.logout_rounded, "Log Out", () async {
                Navigator.pop(context);
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                if (!mounted) return;
                Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginPage()), (route) => false);
              }, isDanger: true),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _drawerItem(IconData icon, String label, VoidCallback onTap, {bool isDanger = false}) {
    final Color iconColor = isDanger ? redStatus : blueStatus; 
    final Color textColor = isDanger ? redStatus : Colors.white70;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: glassWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDanger ? redStatus.withOpacity(0.3) : borderSilver, width: 0.5),
      ),
      child: ListTile(
        leading: Icon(icon, color: iconColor, size: 20),
        title: Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 14)),
        trailing: Icon(Icons.arrow_forward_ios, color: dimSilver, size: 12),
        dense: true,
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: bgDark, 
      extendBodyBehindAppBar: true,
      
      drawer: _buildCustomDrawer(),
      
      body: Stack(
        children: [
          // ✅ BACKGROUND UTAMA MENGGUNAKAN GAMBAR
          Positioned.fill(
            child: Image.asset(
              'assets/images/hoxten.jpg',
              fit: BoxFit.cover,
            ),
          ),
          // Overlay gelap di seluruh layar agar teks terbaca
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.6),
            ),
          ),

          SafeArea(
            bottom: false, 
            child: Column(
              children: [
                const SizedBox(height: 70), 
                Expanded(
                  child: FadeTransition(
                    opacity: _animation,
                    child: _selectedPage,
                  ),
                ),
              ],
            ),
          ),

          // APPBAR (transparan)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Container(
                height: 70,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                color: Colors.transparent, 
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () {
                        scaffoldKey.currentState?.openDrawer();
                      },
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: glassWhite,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderSilver),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 2.0),
                              child: Container(width: 4, height: 4, color: Colors.white),
                            ),
                            Container(width: 4, height: 4, color: Colors.white),
                          ],
                        ),
                      ),
                    ),
                    
                    Expanded(
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2C3E50), Color(0xFF000000)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(50),
                            border: Border.all(color: Colors.white10, width: 1),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.5),
                                blurRadius: 10,
                              )
                            ]
                          ),
                          child: const Text(
                            "RDVSP V5",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18, 
                              fontWeight: FontWeight.w900, 
                              letterSpacing: 1.5,
                              fontFamily: 'Orbitron',
                              shadows: [
                                Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 2)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: glassWhite,
                            border: Border.all(color: borderSilver),
                          ),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: Icon(Icons.headset_mic_outlined, color: Colors.white, size: 20),
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ContactPage())),
                          ),
                        ),
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: glassWhite,
                            border: Border.all(color: borderSilver),
                          ),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: Icon(FontAwesomeIcons.userCircle.toIcon(), size: 22, color: Colors.white),
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfilePage(
                              username: username, password: password,
                              role: role, expiredDate: expiredDate,
                              sessionKey: sessionKey,
                            ))),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

      // ✅ NAVBAR BAWAH (FLOATING) TETAP SAMA SEPERTI SEBELUMNYA
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
        child: Container(
          height: 70,
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A).withOpacity(0.95),
            borderRadius: BorderRadius.circular(35),
            border: Border.all(color: borderSilver, width: 0.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(35),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: BottomNavigationBar(
                backgroundColor: Colors.transparent, 
                selectedItemColor: primarySilver,
                unselectedItemColor: accentSilver,
                currentIndex: _bottomNavIndex,
                onTap: _onBottomNavTapped,
                showUnselectedLabels: false,
                selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                type: BottomNavigationBarType.fixed,
                items: [
                  const BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: "Home"),
                  const BottomNavigationBarItem(icon: Icon(Icons.computer), label: "RAT"),
                  BottomNavigationBarItem(icon: Icon(FontAwesomeIcons.whatsapp.toIcon()), label: "WA"),
                  const BottomNavigationBarItem(icon: Icon(Icons.notifications_none_rounded), label: "Info"),
                  const BottomNavigationBarItem(icon: Icon(Icons.build_circle_outlined), label: "Tools"),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    channel.sink.close(status.goingAway);
    _controller.dispose();
    _headerVideoController?.dispose(); // ✅ DISPOSE VIDEO
    _quickActionsScrollController.dispose(); 
    super.dispose();
  }
}

class NewsMedia extends StatefulWidget {
  final String url;
  const NewsMedia({super.key, required this.url});
  @override
  State<NewsMedia> createState() => _NewsMediaState();
}

class _NewsMediaState extends State<NewsMedia> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    if (_isVideo(widget.url)) {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
        ..initialize().then((_) {
          setState(() {});
          _controller?.setLooping(true);
          _controller?.setVolume(0.0);
          _controller?.play();
        });
    }
  }

  bool _isVideo(String url) =>
      url.endsWith('.mp4') || url.endsWith('.webm') ||
      url.endsWith('.mov') || url.endsWith('.mkv');

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isVideo(widget.url)) {
      if (_controller != null && _controller!.value.isInitialized) {
        return AspectRatio(
          aspectRatio: _controller!.value.aspectRatio,
          child: VideoPlayer(_controller!),
        );
      }
      return const Center(child: CircularProgressIndicator(color: Color(0xFFE0E0E0)));
    }
    return Image.network(
      widget.url, 
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: Colors.grey.shade900,
        child: const Center(child: Icon(Icons.broken_image, color: Color(0xFFE0E0E0))),
      ),
    );
  }
}