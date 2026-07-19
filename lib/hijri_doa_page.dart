import 'package:flutter/material.dart';

// ════════════════════════════════════════════════════════
//  HIJRI DOA PAGE — Kalender Hijriah + Doa Harian
//  Tanpa API, semua data built-in
// ════════════════════════════════════════════════════════

class HijriDoaPage extends StatefulWidget {
  const HijriDoaPage({super.key});
  @override
  State<HijriDoaPage> createState() => _HijriDoaPageState();
}

class _HijriDoaPageState extends State<HijriDoaPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  final Color bgDark        = const Color(0xFF0D0221);
  final Color cardBg        = const Color(0xFF1A0A2E);
  final Color primaryPurple = const Color(0xFF7B1FA2);
  final Color accentPurple  = const Color(0xFFEA80FC);
  final Color accentGreen   = const Color(0xFF43A047);

  // ── HIJRI CONVERSION ──────────────────────────────────
  Map<String, dynamic> _getHijriDate(DateTime gregorian) {
    int gYear = gregorian.year;
    int gMonth = gregorian.month;
    int gDay = gregorian.day;

    // Algoritma konversi Gregorian → Hijriah (Umm al-Qura approximation)
    int jd = _gregorianToJD(gYear, gMonth, gDay);
    return _jdToHijri(jd);
  }

  int _gregorianToJD(int y, int m, int d) {
    if (m <= 2) { y -= 1; m += 12; }
    int a = (y / 100).floor();
    int b = 2 - a + (a / 4).floor();
    return (365.25 * (y + 4716)).floor() +
        (30.6001 * (m + 1)).floor() + d + b - 1524;
  }

  Map<String, dynamic> _jdToHijri(int jd) {
    int l = jd - 1948440 + 10632;
    int n = ((l - 1) / 10631).floor();
    l = l - 10631 * n + 354;
    int j = (((10985 - l) / 5316).floor()) * (((50 * l) / 17719).floor()) +
        ((l / 5670).floor()) * (((43 * l) / 15238).floor());
    l = l - (((30 - j) / 15).floor()) * (((17719 * j) / 50).floor()) -
        ((j / 16).floor()) * (((15238 * j) / 43).floor()) + 29;
    int month = (24 * l / 709).floor();
    int day   = l - (709 * month / 24).floor();
    int year  = 30 * n + j - 30;
    return {'year': year, 'month': month, 'day': day};
  }

  final List<String> _hijriMonths = [
    'Muharram', 'Shafar', 'Rabi\'ul Awwal', 'Rabi\'ul Akhir',
    'Jumadil Awwal', 'Jumadil Akhir', 'Rajab', 'Sya\'ban',
    'Ramadhan', 'Syawal', 'Dzulqa\'dah', 'Dzulhijjah',
  ];

  final List<String> _hijriDays = [
    'Ahad', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'
  ];

  // ── DOA DATA ──────────────────────────────────────────
  final List<Map<String, String>> _doaList = [
    {
      'title': 'Doa Bangun Tidur',
      'arabic': 'اَلْحَمْدُ لِلَّهِ الَّذِيْ أَحْيَانَا بَعْدَ مَا أَمَاتَنَا وَإِلَيْهِ النُّشُوْرُ',
      'latin': 'Alhamdulillahilladzi ahyaanaa ba\'da maa amaatanaa wa ilaihin nusyuur.',
      'arti': 'Segala puji bagi Allah yang telah menghidupkan kami setelah mematikan kami, dan kepada-Nya lah kebangkitan.',
    },
    {
      'title': 'Doa Sebelum Tidur',
      'arabic': 'بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا',
      'latin': 'Bismikallahumma amuutu wa ahyaa.',
      'arti': 'Dengan nama-Mu ya Allah, aku mati dan aku hidup.',
    },
    {
      'title': 'Doa Sebelum Makan',
      'arabic': 'اَللَّهُمَّ بَارِكْ لَنَا فِيْمَا رَزَقْتَنَا وَقِنَا عَذَابَ النَّارِ',
      'latin': 'Allahumma baarik lanaa fiimaa razaqtanaa wa qinaa \'adzaaban naar.',
      'arti': 'Ya Allah, berkahilah kami dalam rezeki yang telah Engkau berikan kepada kami, dan peliharalah kami dari siksa api neraka.',
    },
    {
      'title': 'Doa Sesudah Makan',
      'arabic': 'اَلْحَمْدُ لِلَّهِ الَّذِيْ أَطْعَمَنَا وَسَقَانَا وَجَعَلَنَا مِنَ الْمُسْلِمِيْنَ',
      'latin': 'Alhamdulillahilladzi ath\'amanaa wa saqaanaa wa ja\'alanaa minal muslimiin.',
      'arti': 'Segala puji bagi Allah yang telah memberi kami makan dan minum, serta menjadikan kami termasuk orang-orang Islam.',
    },
    {
      'title': 'Doa Masuk Masjid',
      'arabic': 'اَللَّهُمَّ افْتَحْ لِيْ أَبْوَابَ رَحْمَتِكَ',
      'latin': 'Allahummaftah lii abwaaba rahmatik.',
      'arti': 'Ya Allah, bukakanlah untukku pintu-pintu rahmat-Mu.',
    },
    {
      'title': 'Doa Keluar Masjid',
      'arabic': 'اَللَّهُمَّ إِنِّيْ أَسْأَلُكَ مِنْ فَضْلِكَ',
      'latin': 'Allahumma innii as\'aluka min fadhlika.',
      'arti': 'Ya Allah, sesungguhnya aku memohon kepada-Mu dari karunia-Mu.',
    },
    {
      'title': 'Doa Masuk Rumah',
      'arabic': 'اَللَّهُمَّ إِنِّيْ أَسْأَلُكَ خَيْرَ الْمَوْلِجِ وَخَيْرَ الْمَخْرَجِ',
      'latin': 'Allahumma innii as\'aluka khairal mawlaji wa khairal makhraji.',
      'arti': 'Ya Allah, aku memohon kepada-Mu kebaikan waktu masuk dan kebaikan waktu keluar.',
    },
    {
      'title': 'Doa Keluar Rumah',
      'arabic': 'بِسْمِ اللهِ تَوَكَّلْتُ عَلَى اللهِ وَلَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللهِ',
      'latin': 'Bismillahi tawakkaltu \'alallahi wa laa hawla wa laa quwwata illaa billaah.',
      'arti': 'Dengan nama Allah, aku bertawakkal kepada Allah. Tiada daya dan kekuatan kecuali dengan pertolongan Allah.',
    },
    {
      'title': 'Doa Masuk Kamar Mandi',
      'arabic': 'اَللَّهُمَّ إِنِّيْ أَعُوْذُ بِكَ مِنَ الْخُبُثِ وَالْخَبَائِثِ',
      'latin': 'Allahumma innii a\'udzubika minal khubutsi wal khabaa\'its.',
      'arti': 'Ya Allah, aku berlindung kepada-Mu dari setan laki-laki dan setan perempuan.',
    },
    {
      'title': 'Doa Keluar Kamar Mandi',
      'arabic': 'غُفْرَانَكَ',
      'latin': 'Ghufraanak.',
      'arti': 'Aku memohon ampunan-Mu.',
    },
    {
      'title': 'Doa Naik Kendaraan',
      'arabic': 'سُبْحَانَ الَّذِيْ سَخَّرَ لَنَا هَذَا وَمَا كُنَّا لَهُ مُقْرِنِيْنَ وَإِنَّا إِلَى رَبِّنَا لَمُنْقَلِبُوْنَ',
      'latin': 'Subhaanalladzii sakhkhara lanaa haadzaa wa maa kunnaa lahu muqriniin, wa innaa ilaa rabbinaa lamunqalibuun.',
      'arti': 'Maha Suci Allah yang telah menundukkan kendaraan ini bagi kami, padahal sebelumnya kami tidak mampu menguasainya. Dan sesungguhnya kami akan kembali kepada Rabb kami.',
    },
    {
      'title': 'Doa Ketika Bercermin',
      'arabic': 'اَللَّهُمَّ حَسَّنْتَ خَلْقِيْ فَحَسِّنْ خُلُقِيْ',
      'latin': 'Allahumma hassanta khalqii fahassin khuluqii.',
      'arti': 'Ya Allah, Engkau telah memperindah penciptaanku, maka indahkanlah akhlakku.',
    },
    {
      'title': 'Doa Memohon Ilmu',
      'arabic': 'رَبِّ زِدْنِيْ عِلْمًا',
      'latin': 'Rabbii zidnii \'ilmaa.',
      'arti': 'Ya Rabb-ku, tambahkanlah ilmu kepadaku.',
    },
    {
      'title': 'Doa Agar Dimudahkan Urusan',
      'arabic': 'اَللَّهُمَّ لَا سَهْلَ إِلَّا مَا جَعَلْتَهُ سَهْلًا وَأَنْتَ تَجْعَلُ الْحَزْنَ إِذَا شِئْتَ سَهْلًا',
      'latin': 'Allahumma laa sahla illaa maa ja\'altahu sahlaa, wa anta taj\'alul hazna idzaa syi\'ta sahlaa.',
      'arti': 'Ya Allah, tidak ada kemudahan kecuali yang Engkau mudahkan, dan Engkau menjadikan kesedihan itu mudah jika Engkau menghendaki.',
    },
    {
      'title': 'Doa Qunut',
      'arabic': 'اَللَّهُمَّ اهْدِنِيْ فِيْمَنْ هَدَيْتَ وَعَافِنِيْ فِيْمَنْ عَافَيْتَ وَتَوَلَّنِيْ فِيْمَنْ تَوَلَّيْتَ',
      'latin': 'Allahummahdini fiiman hadayt, wa \'aafinii fiiman \'aafayt, wa tawallaniii fiiman tawallayt.',
      'arti': 'Ya Allah, berilah aku petunjuk sebagaimana orang-orang yang telah Engkau beri petunjuk...',
    },
    {
      'title': 'Doa Setelah Sholat',
      'arabic': 'أَسْتَغْفِرُ اللهَ، أَسْتَغْفِرُ اللهَ، أَسْتَغْفِرُ اللهَ',
      'latin': 'Astaghfirullaah (3x).',
      'arti': 'Aku memohon ampunan kepada Allah (3x).',
    },
    {
      'title': 'Doa Mohon Perlindungan',
      'arabic': 'أَعُوْذُ بِكَلِمَاتِ اللهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ',
      'latin': 'A\'uudzu bikalimaatillaahit taammaati min syarri maa khalaq.',
      'arti': 'Aku berlindung dengan kalimat-kalimat Allah yang sempurna dari kejahatan makhluk yang Dia ciptakan.',
    },
    {
      'title': 'Doa Hujan Turun',
      'arabic': 'اَللَّهُمَّ صَيِّبًا نَافِعًا',
      'latin': 'Allahumma shayyiban naafi\'aa.',
      'arti': 'Ya Allah, turunkanlah hujan yang bermanfaat.',
    },
    {
      'title': 'Doa Mendengar Petir',
      'arabic': 'سُبْحَانَ الَّذِيْ يُسَبِّحُ الرَّعْدُ بِحَمْدِهِ',
      'latin': 'Subhaanalladzii yusabbihur ra\'du bihamdih.',
      'arti': 'Maha Suci Allah yang petir bertasbih memuji-Nya.',
    },
    {
      'title': 'Doa untuk Orang Tua',
      'arabic': 'رَبِّ اغْفِرْ لِيْ وَلِوَالِدَيَّ وَارْحَمْهُمَا كَمَا رَبَّيَانِيْ صَغِيْرًا',
      'latin': 'Rabbighfir lii wa liwaalidayya warhamhumaa kamaa rabbayaanii shaghiiraa.',
      'arti': 'Ya Tuhanku, ampunilah aku dan kedua orang tuaku, sayangilah mereka sebagaimana mereka menyayangiku waktu kecil.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now   = DateTime.now();
    final hijri = _getHijriDate(now);
    final hDay  = _hijriDays[now.weekday % 7];
    final hDate = '${hijri['day']} ${_hijriMonths[(hijri['month'] as int) - 1]} ${hijri['year']} H';

    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        backgroundColor: const Color(0xFF130530),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Islam',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold,
                fontFamily: 'Orbitron', fontSize: 16)),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: accentPurple,
          labelColor: accentPurple,
          unselectedLabelColor: Colors.white38,
          labelStyle: const TextStyle(fontFamily: 'ShareTechMono', fontSize: 12),
          tabs: const [Tab(text: 'KALENDER HIJRIAH'), Tab(text: 'DOA HARIAN')],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          // ── TAB 1: KALENDER HIJRIAH ──────────────────
          _buildHijriTab(now, hijri, hDay, hDate),
          // ── TAB 2: DOA HARIAN ────────────────────────
          _buildDoaTab(),
        ],
      ),
    );
  }

  Widget _buildHijriTab(DateTime now, Map hijri, String hDay, String hDate) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        // ── KARTU TANGGAL HIJRIAH HARI INI ──────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color(0xFF1B5E20), accentGreen.withOpacity(0.7)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(
                color: accentGreen.withOpacity(0.3), blurRadius: 20,
                offset: const Offset(0, 8))],
          ),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.mosque_rounded, color: Colors.white70, size: 18),
              const SizedBox(width: 8),
              Text('KALENDER HIJRIAH',
                  style: TextStyle(color: Colors.white70, fontSize: 11,
                      fontFamily: 'Orbitron', letterSpacing: 1.5)),
            ]),
            const SizedBox(height: 16),
            Text('${hijri['day']}',
                style: const TextStyle(color: Colors.white, fontSize: 64,
                    fontWeight: FontWeight.w900, fontFamily: 'Orbitron')),
            Text(_hijriMonths[(hijri['month'] as int) - 1],
                style: const TextStyle(color: Colors.white, fontSize: 22,
                    fontWeight: FontWeight.bold, fontFamily: 'Orbitron')),
            Text('${hijri['year']} H',
                style: TextStyle(color: Colors.white70, fontSize: 15,
                    fontFamily: 'ShareTechMono')),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('$hDay, ${now.day}/${now.month}/${now.year}',
                  style: const TextStyle(color: Colors.white,
                      fontSize: 13, fontFamily: 'ShareTechMono')),
            ),
          ]),
        ),

        const SizedBox(height: 20),

        // ── INFO BULAN HIJRIAH ───────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: accentGreen.withOpacity(0.3)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 4, height: 16,
                  decoration: BoxDecoration(
                      color: accentGreen, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 8),
              const Text('Info Bulan Ini',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold,
                      fontFamily: 'Orbitron', fontSize: 13)),
            ]),
            const SizedBox(height: 14),
            ..._getMonthInfo(hijri['month'] as int).map((info) =>
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(Icons.circle, color: accentGreen, size: 6),
                  const SizedBox(width: 8),
                  Expanded(child: Text(info,
                      style: const TextStyle(color: Colors.white70, fontSize: 12,
                          height: 1.5))),
                ]),
              )),
          ]),
        ),

        const SizedBox(height: 20),

        // ── 12 BULAN HIJRIAH ─────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: accentPurple.withOpacity(0.2)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 4, height: 16,
                  decoration: BoxDecoration(
                      color: accentPurple, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 8),
              const Text('12 Bulan Hijriah',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold,
                      fontFamily: 'Orbitron', fontSize: 13)),
            ]),
            const SizedBox(height: 14),
            ...List.generate(12, (i) {
              final isCurrentMonth = (hijri['month'] as int) == i + 1;
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isCurrentMonth
                      ? accentGreen.withOpacity(0.15)
                      : Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isCurrentMonth
                        ? accentGreen.withOpacity(0.5)
                        : Colors.white.withOpacity(0.05),
                  ),
                ),
                child: Row(children: [
                  Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      color: isCurrentMonth
                          ? accentGreen.withOpacity(0.3)
                          : primaryPurple.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(child: Text('${i + 1}',
                        style: TextStyle(
                          color: isCurrentMonth ? accentGreen : Colors.white54,
                          fontSize: 11, fontWeight: FontWeight.bold,
                          fontFamily: 'ShareTechMono',
                        ))),
                  ),
                  const SizedBox(width: 12),
                  Text(_hijriMonths[i],
                      style: TextStyle(
                        color: isCurrentMonth ? Colors.white : Colors.white70,
                        fontSize: 13,
                        fontWeight: isCurrentMonth ? FontWeight.bold : FontWeight.normal,
                      )),
                  if (isCurrentMonth) ...[
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: accentGreen.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('SEKARANG',
                          style: TextStyle(color: accentGreen, fontSize: 9,
                              fontWeight: FontWeight.bold, fontFamily: 'ShareTechMono')),
                    ),
                  ],
                ]),
              );
            }),
          ]),
        ),
        const SizedBox(height: 20),
      ]),
    );
  }

  List<String> _getMonthInfo(int month) {
    const infos = {
      1: ['Muharram adalah bulan yang dimuliakan Allah SWT.',
          'Puasa Asyura (10 Muharram) menghapus dosa setahun yang lalu.',
          'Disunnahkan berpuasa pada tanggal 9 dan 10 Muharram.'],
      2: ['Shafar berarti "kosong" dalam bahasa Arab.',
          'Bulan yang sering dianggap sial oleh orang Arab jahiliah, namun Islam membantah hal ini.',
          'Tidak ada larangan atau keutamaan khusus di bulan ini.'],
      3: ['Bulan kelahiran Nabi Muhammad SAW (12 Rabiul Awwal).',
          'Umat Islam merayakan Maulid Nabi di bulan ini.',
          'Dianjurkan memperbanyak sholawat kepada Nabi.'],
      4: ['Rabi\'ul Akhir adalah bulan keempat dalam kalender Hijriah.',
          'Tidak ada ibadah khusus yang ditetapkan di bulan ini.',
          'Tetap dianjurkan memperbanyak ibadah dan amalan sholeh.'],
      5: ['Jumadil Awwal adalah bulan kelima dalam kalender Hijriah.',
          'Termasuk dalam musim dingin di wilayah Arab.',
          'Dianjurkan memperbanyak doa dan dzikir.'],
      6: ['Jumadil Akhir adalah bulan keenam dalam kalender Hijriah.',
          'Bulan sebelum Rajab yang mulia.',
          'Persiapkan diri menyambut bulan-bulan mulia.'],
      7: ['Rajab adalah salah satu dari empat bulan haram.',
          'Isra Miraj Nabi Muhammad SAW terjadi pada 27 Rajab.',
          'Dianjurkan memperbanyak puasa dan ibadah di bulan ini.'],
      8: ['Sya\'ban adalah bulan penuh berkah sebelum Ramadhan.',
          'Malam Nisfu Sya\'ban (15 Sya\'ban) adalah malam yang penuh ampunan.',
          'Nabi SAW banyak berpuasa di bulan Sya\'ban.'],
      9: ['Ramadhan adalah bulan yang paling mulia.',
          'Diwajibkan berpuasa selama sebulan penuh.',
          'Al-Qur\'an diturunkan pada bulan Ramadhan.',
          'Terdapat Lailatul Qadar yang lebih baik dari 1000 bulan.'],
      10: ['Syawal adalah bulan kemenangan setelah Ramadhan.',
           'Hari Raya Idul Fitri jatuh pada 1 Syawal.',
           'Disunnahkan puasa 6 hari di bulan Syawal.'],
      11: ['Dzulqa\'dah adalah salah satu dari empat bulan haram.',
           'Bulan persiapan sebelum ibadah haji.',
           'Diharamkan berperang di bulan ini.'],
      12: ['Dzulhijjah adalah bulan haji dan bulan yang sangat mulia.',
           'Hari Raya Idul Adha jatuh pada 10 Dzulhijjah.',
           '10 hari pertama Dzulhijjah adalah hari-hari terbaik dalam setahun.',
           'Disunnahkan puasa Arafah (9 Dzulhijjah) yang menghapus dosa 2 tahun.'],
    };
    return infos[month] ?? ['Tidak ada informasi khusus untuk bulan ini.'];
  }

  Widget _buildDoaTab() {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(14),
      itemCount: _doaList.length,
      itemBuilder: (ctx, i) {
        final doa = _doaList[i];
        return _DoaCard(
          doa: doa,
          cardBg: cardBg,
          accentPurple: accentPurple,
          primaryPurple: primaryPurple,
          accentGreen: accentGreen,
        );
      },
    );
  }
}

// ── DOA CARD WIDGET ───────────────────────────────────
class _DoaCard extends StatefulWidget {
  final Map<String, String> doa;
  final Color cardBg, accentPurple, primaryPurple, accentGreen;
  const _DoaCard({
    required this.doa,
    required this.cardBg,
    required this.accentPurple,
    required this.primaryPurple,
    required this.accentGreen,
  });
  @override
  State<_DoaCard> createState() => _DoaCardState();
}

class _DoaCardState extends State<_DoaCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: widget.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _expanded
                ? widget.accentPurple.withOpacity(0.5)
                : widget.accentPurple.withOpacity(0.15),
          ),
          boxShadow: _expanded
              ? [BoxShadow(color: widget.primaryPurple.withOpacity(0.2),
                  blurRadius: 10)]
              : [],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: widget.accentPurple.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.menu_book_rounded,
                  color: widget.accentPurple, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(widget.doa['title']!,
                style: const TextStyle(color: Colors.white,
                    fontSize: 13, fontWeight: FontWeight.bold))),
            Icon(
              _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: widget.accentPurple, size: 20,
            ),
          ]),

          // Expanded content
          if (_expanded) ...[
            const SizedBox(height: 14),
            // Arabic
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: widget.primaryPurple.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: widget.accentPurple.withOpacity(0.2)),
              ),
              child: Text(widget.doa['arabic']!,
                  textAlign: TextAlign.right,
                  style: const TextStyle(color: Colors.white,
                      fontSize: 18, height: 2.0,
                      fontWeight: FontWeight.w500)),
            ),
            const SizedBox(height: 10),
            // Latin
            Text(widget.doa['latin']!,
                style: TextStyle(color: widget.accentGreen,
                    fontSize: 12, fontStyle: FontStyle.italic, height: 1.5)),
            const SizedBox(height: 6),
            // Arti
            Text(widget.doa['arti']!,
                style: const TextStyle(color: Colors.white60,
                    fontSize: 12, height: 1.5)),
          ],
        ]),
      ),
    );
  }
}
