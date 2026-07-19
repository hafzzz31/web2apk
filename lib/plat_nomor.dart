import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PlatNomorPage extends StatefulWidget {
  const PlatNomorPage({super.key});

  @override
  State<PlatNomorPage> createState() => _PlatNomorPageState();
}

class _PlatNomorPageState extends State<PlatNomorPage> {
  final TextEditingController _platCtrl = TextEditingController();
  Map<String, String>? _result;
  String? _error;

  final Color primaryDark = const Color(0xFF0D0221);
  final Color primaryPurple = const Color(0xFF7B1FA2);
  final Color accentPurple = const Color(0xFFAA00FF);
  final Color lightPurple = const Color(0xFFE040FB);
  final Color cardDark = const Color(0xFF1A1A2E);

  final Map<String, Map<String, String>> _platData = {
    'A': {'wilayah': 'Banten', 'detail': 'Serang, Cilegon, Lebak, Pandeglang, Tangerang (Kab/Kota)'},
    'AA': {'wilayah': 'Jawa Tengah', 'detail': 'Kedu: Magelang, Temanggung, Wonosobo, Purworejo, Kebumen'},
    'AB': {'wilayah': 'DI Yogyakarta', 'detail': 'Bantul, Gunung Kidul, Kulon Progo, Sleman'},
    'AD': {'wilayah': 'Jawa Tengah', 'detail': 'Solo, Boyolali, Sukoharjo, Karanganyar, Wonogiri, Sragen, Klaten'},
    'AE': {'wilayah': 'Jawa Timur', 'detail': 'Madiun, Ponorogo, Magetan, Ngawi, Pacitan'},
    'AG': {'wilayah': 'Jawa Timur', 'detail': 'Kediri, Blitar, Tulungagung, Nganjuk, Trenggalek'},
    'B': {'wilayah': 'DKI Jakarta & Sekitarnya', 'detail': 'Jakarta, Tangerang Selatan, Bekasi, Depok'},
    'BA': {'wilayah': 'Sumatera Barat', 'detail': 'Seluruh Provinsi Sumatera Barat'},
    'BB': {'wilayah': 'Sumatera Utara', 'detail': 'Tapanuli, Nias'},
    'BD': {'wilayah': 'Bengkulu', 'detail': 'Seluruh Provinsi Bengkulu'},
    'BE': {'wilayah': 'Lampung', 'detail': 'Seluruh Provinsi Lampung'},
    'BG': {'wilayah': 'Sumatera Selatan', 'detail': 'Musi Banyuasin, Sekayu'},
    'BH': {'wilayah': 'Jambi', 'detail': 'Seluruh Provinsi Jambi'},
    'BK': {'wilayah': 'Sumatera Utara', 'detail': 'Medan, Deli Serdang, Serdang Bedagai'},
    'BL': {'wilayah': 'Aceh', 'detail': 'Seluruh Provinsi Aceh'},
    'BM': {'wilayah': 'Riau', 'detail': 'Seluruh Provinsi Riau'},
    'BN': {'wilayah': 'Bangka Belitung', 'detail': 'Seluruh Provinsi Bangka Belitung'},
    'BP': {'wilayah': 'Kepulauan Riau', 'detail': 'Batam, Tanjung Pinang, Natuna, Lingga, Karimun'},
    'BV': {'wilayah': 'Sumatera Selatan', 'detail': 'Palembang'},
    'D': {'wilayah': 'Jawa Barat', 'detail': 'Bandung Kota, Bandung Kabupaten, Cimahi'},
    'DA': {'wilayah': 'Kalimantan Selatan', 'detail': 'Seluruh Provinsi Kalimantan Selatan'},
    'DB': {'wilayah': 'Sulawesi Utara', 'detail': 'Manado, Kotamobagu, Bolaang Mongondow'},
    'DC': {'wilayah': 'Sulawesi Barat', 'detail': 'Seluruh Provinsi Sulawesi Barat'},
    'DD': {'wilayah': 'Sulawesi Selatan', 'detail': 'Bone, Sinjai, Bulukumba, Bantaeng'},
    'DE': {'wilayah': 'Maluku', 'detail': 'Seluruh Provinsi Maluku'},
    'DG': {'wilayah': 'Sulawesi Selatan', 'detail': 'Gowa, Takalar, Jeneponto'},
    'DH': {'wilayah': 'NTT', 'detail': 'Kupang'},
    'DK': {'wilayah': 'Bali', 'detail': 'Seluruh Provinsi Bali'},
    'DL': {'wilayah': 'Sulawesi Utara', 'detail': 'Sitaro, Sangihe, Talaud'},
    'DM': {'wilayah': 'Gorontalo', 'detail': 'Seluruh Provinsi Gorontalo'},
    'DN': {'wilayah': 'Sulawesi Tengah', 'detail': 'Seluruh Provinsi Sulawesi Tengah'},
    'DP': {'wilayah': 'Sulawesi Selatan', 'detail': 'Kepulauan Selayar'},
    'DT': {'wilayah': 'Sulawesi Tenggara', 'detail': 'Seluruh Provinsi Sulawesi Tenggara'},
    'DW': {'wilayah': 'Sulawesi Selatan', 'detail': 'Makassar'},
    'E': {'wilayah': 'Jawa Barat', 'detail': 'Cirebon, Indramayu, Majalengka, Kuningan'},
    'EA': {'wilayah': 'NTB', 'detail': 'Sumbawa'},
    'EB': {'wilayah': 'NTT', 'detail': 'Flores, Ende, Manggarai'},
    'ED': {'wilayah': 'NTT', 'detail': 'Sumba'},
    'F': {'wilayah': 'Jawa Barat', 'detail': 'Bogor, Cianjur, Sukabumi'},
    'G': {'wilayah': 'Jawa Tengah', 'detail': 'Pekalongan, Batang, Pemalang, Tegal, Brebes'},
    'H': {'wilayah': 'Jawa Tengah', 'detail': 'Semarang, Kendal, Demak, Grobogan, Salatiga'},
    'K': {'wilayah': 'Jawa Tengah', 'detail': 'Pati, Kudus, Jepara, Rembang, Blora'},
    'KB': {'wilayah': 'Kalimantan Barat', 'detail': 'Seluruh Provinsi Kalimantan Barat'},
    'KH': {'wilayah': 'Kalimantan Tengah', 'detail': 'Seluruh Provinsi Kalimantan Tengah'},
    'KT': {'wilayah': 'Kalimantan Timur', 'detail': 'Seluruh Provinsi Kalimantan Timur'},
    'KU': {'wilayah': 'Kalimantan Utara', 'detail': 'Seluruh Provinsi Kalimantan Utara'},
    'L': {'wilayah': 'Jawa Timur', 'detail': 'Surabaya'},
    'M': {'wilayah': 'Jawa Timur', 'detail': 'Madura: Bangkalan, Sampang, Pamekasan, Sumenep'},
    'N': {'wilayah': 'Jawa Timur', 'detail': 'Malang, Batu, Lumajang, Pasuruan'},
    'P': {'wilayah': 'Jawa Timur', 'detail': 'Besuki: Situbondo, Bondowoso, Banyuwangi, Jember'},
    'PA': {'wilayah': 'Papua', 'detail': 'Seluruh Provinsi Papua'},
    'PB': {'wilayah': 'Papua Barat', 'detail': 'Seluruh Provinsi Papua Barat'},
    'R': {'wilayah': 'Jawa Tengah', 'detail': 'Banyumas: Purwokerto, Cilacap, Banjarnegara, Purbalingga'},
    'S': {'wilayah': 'Jawa Timur', 'detail': 'Bojonegoro, Tuban, Lamongan'},
    'T': {'wilayah': 'Jawa Barat', 'detail': 'Karawang, Purwakarta, Subang'},
    'W': {'wilayah': 'Jawa Timur', 'detail': 'Sidoarjo, Gresik'},
    'Z': {'wilayah': 'Jawa Barat', 'detail': 'Garut, Tasikmalaya, Ciamis, Pangandaran'},
    'D': {'wilayah': 'Jawa Barat', 'detail': 'Bandung'},
    'DR': {'wilayah': 'NTB', 'detail': 'Lombok'},
  };

  void _check() {
    final raw = _platCtrl.text.trim().toUpperCase().replaceAll(' ', '');
    if (raw.isEmpty) {
      setState(() => _error = "Masukkan nomor plat.");
      return;
    }

    // Extract letter prefix
    final match = RegExp(r'^([A-Z]{1,3})').firstMatch(raw);
    if (match == null) {
      setState(() { _error = "Format plat tidak valid."; _result = null; });
      return;
    }
    final prefix = match.group(1)!;

    // Try longest match first
    Map<String, String>? found;
    if (prefix.length >= 2 && _platData.containsKey(prefix.substring(0, 2))) {
      found = _platData[prefix.substring(0, 2)];
    } else if (_platData.containsKey(prefix.substring(0, 1))) {
      found = _platData[prefix.substring(0, 1)];
    }

    if (found == null) {
      setState(() { _error = "Kode plat '$prefix' tidak ditemukan."; _result = null; });
      return;
    }

    // Vehicle type from suffix
    final suffix = raw.substring(prefix.length);
    final numMatch = RegExp(r'\d+').firstMatch(suffix);
    final letterSuffix = suffix.replaceAll(RegExp(r'\d'), '').trim();
    
    String type = 'Tidak diketahui';
    if (letterSuffix.isEmpty) {
      type = 'Kendaraan Umum / Tanpa kode';
    } else if (['Z'].contains(letterSuffix)) {
      type = 'Kendaraan Listrik';
    } else if (int.tryParse(numMatch?.group(0) ?? '') != null) {
      final num = int.parse(numMatch!.group(0)!);
      if (num <= 1999) type = 'Mobil Penumpang';
      else if (num <= 2999) type = 'Sepeda Motor';
      else if (num <= 4999) type = 'Mobil Penumpang';
      else if (num <= 6999) type = 'Bus';
      else if (num <= 8999) type = 'Truk / Kendaraan Niaga';
      else type = 'Kendaraan Khusus';
    }

    setState(() {
      _error = null;
      _result = {
        'Plat': raw,
        'Kode Daerah': found!.containsKey('wilayah') ? prefix : prefix.substring(0, 1),
        'Wilayah': found['wilayah']!,
        'Daerah Detail': found['detail']!,
        'Jenis Kendaraan': type,
        'Nomor Polisi': numMatch?.group(0) ?? '-',
        'Kode Akhir': letterSuffix.isNotEmpty ? letterSuffix : '-',
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "CEK PLAT NOMOR",
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Orbitron',
            fontWeight: FontWeight.bold,
            fontSize: 16,
            shadows: [Shadow(color: lightPurple.withOpacity(0.8), blurRadius: 10)],
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryPurple.withOpacity(0.4), Colors.transparent],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryPurple.withOpacity(0.15),
                  border: Border.all(color: lightPurple.withOpacity(0.5), width: 2),
                ),
                child: Icon(Icons.directions_car, color: lightPurple, size: 40),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Cek asal daerah plat kendaraan Indonesia",
              style: TextStyle(
                  color: Colors.grey.shade500,
                  fontFamily: 'ShareTechMono',
                  fontSize: 12),
            ),
            const SizedBox(height: 24),

            Container(
              decoration: BoxDecoration(
                color: cardDark,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: primaryPurple.withOpacity(0.5)),
              ),
              child: TextField(
                controller: _platCtrl,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Orbitron',
                  fontSize: 20,
                  letterSpacing: 4,
                  fontWeight: FontWeight.bold,
                ),
                textCapitalization: TextCapitalization.characters,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: "B 1234 XY",
                  hintStyle: TextStyle(
                    color: Colors.grey.shade600,
                    fontFamily: 'Orbitron',
                    fontSize: 20,
                    letterSpacing: 4,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(20),
                ),
              ),
            ),
            const SizedBox(height: 14),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _check,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryPurple,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search, color: Colors.white),
                    SizedBox(width: 10),
                    Text("CEK PLAT",
                        style: TextStyle(
                            fontFamily: 'Orbitron',
                            color: Colors.white,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Text(_error!,
                    style: const TextStyle(
                        color: Colors.red, fontFamily: 'ShareTechMono')),
              ),
            ],

            if (_result != null) ...[
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryPurple.withOpacity(0.3),
                      accentPurple.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: lightPurple.withOpacity(0.4)),
                ),
                child: Column(
                  children: [
                    // Plat display
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.black, width: 3),
                      ),
                      child: Text(
                        _result!['Plat']!,
                        style: const TextStyle(
                          color: Colors.black,
                          fontFamily: 'Orbitron',
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 6,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _result!['Wilayah']!,
                      style: TextStyle(
                          color: lightPurple,
                          fontFamily: 'Orbitron',
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _result!['Daerah Detail']!,
                      style: TextStyle(
                          color: Colors.grey.shade400,
                          fontFamily: 'ShareTechMono',
                          fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                    const Divider(color: Colors.white12, height: 24),
                    ...[
                      ['Jenis', _result!['Jenis Kendaraan']!],
                      ['No. Polisi', _result!['Nomor Polisi']!],
                      ['Kode Akhir', _result!['Kode Akhir']!],
                    ].map((row) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 90,
                                child: Text(row[0],
                                    style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontFamily: 'ShareTechMono',
                                        fontSize: 12)),
                              ),
                              Text(": ${row[1]}",
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontFamily: 'ShareTechMono',
                                      fontSize: 12)),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
