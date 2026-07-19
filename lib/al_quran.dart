import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;


class AppColors {
  static const Color background = Color(0xFF121212); // Dark grey background
  static const Color softRed = Color(0xFFB0B0B0); // Silver utama
  static const Color softRedGlow = Color(0x40B0B0B0); // Glow effect dengan silver
  static const Color card = Color(0xFF1E1E1E); // Card color abu-abu gelap
  static const Color text = Color(0xFFF5F5F5); // Putih terang (untuk teks)
  static const Color softRedLight = Color(0xFFE0E0E0); // Silver lebih terang/kilau
  static const Color softRedDark = Color(0xFF757575); // Silver lebih gelap
}


class Ayat {
  final int nomor;
  final String arab;
  final String arti;

  Ayat({
    required this.nomor,
    required this.arab,
    required this.arti,
  });
}

class Surat {
  final int nomor;
  final String nama;
  final String latin;
  final List<Ayat> ayat;

  Surat({
    required this.nomor,
    required this.nama,
    required this.latin,
    required this.ayat,
  });
}


class AlQuranPage extends StatefulWidget {
  const AlQuranPage({super.key});

  @override
  State<AlQuranPage> createState() => _AlQuranPageState();
}

class _AlQuranPageState extends State<AlQuranPage> {
  bool loading = true;
  List<Surat> suratList = [];

  @override
  void initState() {
    super.initState();
    _loadQuran();
  }


  Future<void> _loadQuran() async {
    try {
      final arabRes = await http.get(
        Uri.parse('https://api.alquran.cloud/v1/quran/quran-uthmani'),
      );
      final indoRes = await http.get(
        Uri.parse('https://api.alquran.cloud/v1/quran/id.indonesian'),
      );

      final arabData = jsonDecode(arabRes.body);
      final indoData = jsonDecode(indoRes.body);

      final List arabSurah = arabData['data']['surahs'];
      final List indoSurah = indoData['data']['surahs'];

      List<Surat> result = [];

      for (int i = 0; i < arabSurah.length; i++) {
        final List arabAyat = arabSurah[i]['ayahs'];
        final List indoAyat = indoSurah[i]['ayahs'];

        List<Ayat> ayatList = [];

        for (int j = 0; j < arabAyat.length; j++) {
          ayatList.add(
            Ayat(
              nomor: arabAyat[j]['numberInSurah'],
              arab: arabAyat[j]['text'],
              arti: indoAyat[j]['text'],
            ),
          );
        }

        result.add(
          Surat(
            nomor: arabSurah[i]['number'],
            nama: arabSurah[i]['name'],
            latin: arabSurah[i]['englishName'],
            ayat: ayatList,
          ),
        );
      }

      setState(() {
        suratList = result;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'AL-QUR\'AN',
          style: TextStyle(
            fontFamily: 'Orbitron',
            letterSpacing: 2,
            color: AppColors.softRed, // Diubah ke soft red
          ),
        ),
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.softRed, // Diubah ke soft red
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: suratList.length,
              itemBuilder: (context, index) {
                return _suratCard(suratList[index]);
              },
            ),
    );
  }


  Widget _suratCard(Surat surat) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.softRedLight), // Diubah ke soft red light
        boxShadow: [
          BoxShadow(
            color: AppColors.softRedGlow, // Diubah ke soft red glow
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ExpansionTile(
        iconColor: AppColors.softRed, // Diubah ke soft red
        collapsedIconColor: AppColors.softRedLight, // Diubah ke soft red light
        collapsedTextColor: AppColors.softRedLight, // Diubah ke soft red light
        textColor: AppColors.softRed, // Diubah ke soft red
        title: Text(
          '${surat.nomor}. ${surat.latin}',
          style: const TextStyle(
            fontFamily: 'Orbitron',
            color: AppColors.softRed, // Diubah ke soft red
            letterSpacing: 1.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          surat.nama,
          textAlign: TextAlign.right,
          style: const TextStyle(
            fontSize: 18,
            color: AppColors.text,
          ),
        ),
        children: surat.ayat.map(_ayatTile).toList(),
      ),
    );
  }


  Widget _ayatTile(Ayat ayat) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.softRedDark.withOpacity(0.2), // Diubah ke soft red dark
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Ayat ${ayat.nomor}',
              style: const TextStyle(
                fontFamily: 'Orbitron',
                color: AppColors.softRedLight, // Diubah ke soft red light
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            ayat.arab,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 24,
              height: 1.9,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.softRedDark.withOpacity(0.1), // Diubah ke soft red dark
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.softRedLight.withOpacity(0.3), // Diubah ke soft red light
              ),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                ayat.arti,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.softRedLight, // Diubah ke soft red light
                  height: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Divider(
            color: AppColors.softRedLight.withOpacity(0.3), // Diubah ke soft red light
            thickness: 1,
          ),
        ],
      ),
    );
  }
}