//JANGAN LU MALING
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SholatToolsPage extends StatefulWidget {
  const SholatToolsPage({super.key});
  @override
  State<SholatToolsPage> createState() => _SholatToolsPageState();
}

class _SholatToolsPageState extends State<SholatToolsPage> {
  final Color bgDark = const Color(0xFF0D0221);
  final Color primaryPurple = const Color(0xFF7B1FA2);
  final Color accentPurple = const Color(0xFFEA80FC);
  final Color accentGreen = const Color(0xFF43A047);
  final Color cardGlass = Colors.white12;
  final Color borderGlass = Colors.white24;

  Map<String, String> jadwal = {};
  bool isLoadingJadwal = false;
  int tasbihCount = 0;
  double kiblatDegree = 0;

  @override
  void initState() {
    super.initState();
    fetchJadwalSholat();
    hitungKiblat(-6.200000, 106.816666);
  }

  Future<void> fetchJadwalSholat() async {
    setState(() => isLoadingJadwal = true);
    final now = DateTime.now();
    final url = Uri.parse(
        "https://api.myquran.com/v2/sholat/jadwal/1301/${now.year}/${now.month}/${now.day}");
    try {
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final jadwalApi = data["data"]["jadwal"];
        setState(() {
          jadwal = {
            "Subuh": jadwalApi["subuh"],
            "Dzuhur": jadwalApi["dzuhur"],
            "Ashar": jadwalApi["ashar"],
            "Maghrib": jadwalApi["maghrib"],
            "Isya": jadwalApi["isya"],
          };
        });
      }
    } catch (_) {}
    setState(() => isLoadingJadwal = false);
  }

  void hitungKiblat(double lat, double lon) {
    const kaabaLat = 21.4225;
    const kaabaLon = 39.8262;
    final dLon = (kaabaLon - lon) * pi / 180;
    final y = sin(dLon);
    final x = cos(lat * pi / 180) * tan(kaabaLat * pi / 180) - sin(lat * pi / 180) * cos(dLon);
    final bearing = atan2(y, x) * 180 / pi;
    kiblatDegree = (bearing + 360) % 360;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        title: Text('🕌 Islamic Tools', style: TextStyle(
          fontFamily: 'Orbitron', color: accentPurple, fontWeight: FontWeight.bold,
        )),
        backgroundColor: bgDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [bgDark, primaryPurple.withOpacity(0.1), bgDark],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _sectionTitle("📅 Jadwal Sholat"),
            isLoadingJadwal
                ? Center(child: CircularProgressIndicator(color: accentPurple))
                : Column(children: jadwal.entries.map((e) => _jadwalCard(e.key, e.value)).toList()),
            const SizedBox(height: 24),
            _sectionTitle("🧭 Arah Kiblat"),
            _infoCard("Derajat Kiblat", "${kiblatDegree.toStringAsFixed(2)}°", Icons.explore),
            const SizedBox(height: 24),
            _sectionTitle("📿 Tasbih Digital"),
            _tasbihWidget(),
            const SizedBox(height: 24),
            _sectionTitle("🔔 Pengingat Sholat"),
            _infoCard("Status", "Aktif - Notifikasi Tersedia", Icons.notifications_active),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(title, style: TextStyle(
        color: accentPurple, fontSize: 16,
        fontWeight: FontWeight.bold, fontFamily: 'Orbitron',
      )),
    );
  }

  Widget _jadwalCard(String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cardGlass,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accentGreen.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.access_time, color: accentGreen, size: 18),
          const SizedBox(width: 12),
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          const Spacer(),
          Text(value, style: TextStyle(color: accentGreen, fontFamily: 'ShareTechMono', fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _infoCard(String title, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cardGlass,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accentPurple.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: accentPurple, size: 20),
          const SizedBox(width: 12),
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          const Spacer(),
          Text(value, style: TextStyle(color: accentPurple, fontFamily: 'ShareTechMono')),
        ],
      ),
    );
  }

  Widget _tasbihWidget() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardGlass,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentGreen.withOpacity(0.4)),
        boxShadow: [BoxShadow(color: accentGreen.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          Text("$tasbihCount", style: TextStyle(
            fontSize: 64, color: accentGreen,
            fontWeight: FontWeight.bold, fontFamily: 'ShareTechMono',
          )),
          const SizedBox(height: 8),
          Text("SubhanAllah", style: TextStyle(color: accentGreen.withOpacity(0.7), fontSize: 14)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => tasbihCount++),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [accentGreen, const Color(0xFF2E7D32)]),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Center(child: Text("+ Tambah",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15))),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => setState(() => tasbihCount = 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.red.withOpacity(0.4)),
                  ),
                  child: const Text("Reset",
                    style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
