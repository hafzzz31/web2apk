import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class PhoneLookupPage extends StatefulWidget {
  const PhoneLookupPage({super.key});

  @override
  State<PhoneLookupPage> createState() => _PhoneLookupPageState();
}

class _PhoneLookupPageState extends State<PhoneLookupPage> {
  final TextEditingController _phoneCtrl = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _result;
  String? _error;

  final Color primaryDark = const Color(0xFF0D0221);
  final Color primaryPurple = const Color(0xFF7B1FA2);
  final Color accentPurple = const Color(0xFFAA00FF);
  final Color lightPurple = const Color(0xFFE040FB);
  final Color cardDark = const Color(0xFF1A1A2E);

  // Prefix data Indonesia
  final Map<String, Map<String, String>> _prefixData = {
    // Telkomsel
    '0811': {'operator': 'Telkomsel', 'type': 'Kartu Halo', 'emoji': '📱'},
    '0812': {'operator': 'Telkomsel', 'type': 'SimPATI', 'emoji': '📱'},
    '0813': {'operator': 'Telkomsel', 'type': 'SimPATI', 'emoji': '📱'},
    '0821': {'operator': 'Telkomsel', 'type': 'AS', 'emoji': '📱'},
    '0822': {'operator': 'Telkomsel', 'type': 'AS', 'emoji': '📱'},
    '0823': {'operator': 'Telkomsel', 'type': 'AS', 'emoji': '📱'},
    '0851': {'operator': 'Telkomsel', 'type': 'AS', 'emoji': '📱'},
    '0852': {'operator': 'Telkomsel', 'type': 'AS', 'emoji': '📱'},
    '0853': {'operator': 'Telkomsel', 'type': 'AS', 'emoji': '📱'},
    // Indosat
    '0814': {'operator': 'Indosat Ooredoo', 'type': 'Matrix', 'emoji': '📲'},
    '0815': {'operator': 'Indosat Ooredoo', 'type': 'Mentari', 'emoji': '📲'},
    '0816': {'operator': 'Indosat Ooredoo', 'type': 'Mentari', 'emoji': '📲'},
    '0855': {'operator': 'Indosat Ooredoo', 'type': 'IM3', 'emoji': '📲'},
    '0856': {'operator': 'Indosat Ooredoo', 'type': 'IM3', 'emoji': '📲'},
    '0857': {'operator': 'Indosat Ooredoo', 'type': 'IM3', 'emoji': '📲'},
    '0858': {'operator': 'Indosat Ooredoo', 'type': 'IM3', 'emoji': '📲'},
    // XL/Axis
    '0817': {'operator': 'XL Axiata', 'type': 'XL', 'emoji': '📡'},
    '0818': {'operator': 'XL Axiata', 'type': 'XL', 'emoji': '📡'},
    '0819': {'operator': 'XL Axiata', 'type': 'XL', 'emoji': '📡'},
    '0859': {'operator': 'XL Axiata', 'type': 'XL', 'emoji': '📡'},
    '0877': {'operator': 'XL Axiata', 'type': 'XL', 'emoji': '📡'},
    '0878': {'operator': 'XL Axiata', 'type': 'XL', 'emoji': '📡'},
    '0879': {'operator': 'XL Axiata', 'type': 'XL', 'emoji': '📡'},
    '0831': {'operator': 'AXIS', 'type': 'AXIS', 'emoji': '📡'},
    '0832': {'operator': 'AXIS', 'type': 'AXIS', 'emoji': '📡'},
    '0833': {'operator': 'AXIS', 'type': 'AXIS', 'emoji': '📡'},
    '0838': {'operator': 'AXIS', 'type': 'AXIS', 'emoji': '📡'},
    // Tri
    '0895': {'operator': 'Tri (3)', 'type': '3', 'emoji': '🔵'},
    '0896': {'operator': 'Tri (3)', 'type': '3', 'emoji': '🔵'},
    '0897': {'operator': 'Tri (3)', 'type': '3', 'emoji': '🔵'},
    '0898': {'operator': 'Tri (3)', 'type': '3', 'emoji': '🔵'},
    '0899': {'operator': 'Tri (3)', 'type': '3', 'emoji': '🔵'},
    // Smartfren
    '0881': {'operator': 'Smartfren', 'type': 'Smartfren', 'emoji': '🟠'},
    '0882': {'operator': 'Smartfren', 'type': 'Smartfren', 'emoji': '🟠'},
    '0883': {'operator': 'Smartfren', 'type': 'Smartfren', 'emoji': '🟠'},
    '0884': {'operator': 'Smartfren', 'type': 'Smartfren', 'emoji': '🟠'},
    '0885': {'operator': 'Smartfren', 'type': 'Smartfren', 'emoji': '🟠'},
    '0886': {'operator': 'Smartfren', 'type': 'Smartfren', 'emoji': '🟠'},
    '0887': {'operator': 'Smartfren', 'type': 'Smartfren', 'emoji': '🟠'},
    '0888': {'operator': 'Smartfren', 'type': 'Smartfren', 'emoji': '🟠'},
    '0889': {'operator': 'Smartfren', 'type': 'Smartfren', 'emoji': '🟠'},
  };

  Map<String, String>? _detectPrefix(String phone) {
    String normalized = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (normalized.startsWith('+62')) normalized = '0${normalized.substring(3)}';
    if (normalized.startsWith('62')) normalized = '0${normalized.substring(2)}';
    if (normalized.length < 4) return null;
    final prefix = normalized.substring(0, 4);
    return _prefixData[prefix];
  }

  Future<void> _lookup() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty) {
      setState(() => _error = "Masukkan nomor telepon.");
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _result = null;
    });

    try {
      final prefixInfo = _detectPrefix(phone);
      String normalized = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
      if (normalized.startsWith('+62')) normalized = '0${normalized.substring(3)}';
      if (normalized.startsWith('62')) normalized = '0${normalized.substring(2)}';

      final result = <String, dynamic>{
        'nomor_asli': phone,
        'nomor_format': normalized,
        'prefix': normalized.length >= 4 ? normalized.substring(0, 4) : '-',
        'operator': prefixInfo?['operator'] ?? 'Tidak diketahui',
        'tipe': prefixInfo?['type'] ?? '-',
        'emoji': prefixInfo?['emoji'] ?? '❓',
        'negara': 'Indonesia 🇮🇩',
        'kode_negara': '+62',
      };

      // Try numverify-compatible free API
      try {
        final resp = await http.get(
          Uri.parse('https://api.siputzx.my.id/api/tools/phoneinfo?number=${Uri.encodeComponent(normalized)}'),
        ).timeout(const Duration(seconds: 8));
        if (resp.statusCode == 200) {
          final data = jsonDecode(resp.body);
          if (data['status'] == true && data['data'] != null) {
            result.addAll(Map<String, dynamic>.from(data['data']));
          }
        }
      } catch (_) {}

      setState(() => _result = result);
    } catch (e) {
      setState(() => _error = "Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
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
          "PHONE LOOKUP",
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
                child: Icon(Icons.phone_android, color: lightPurple, size: 40),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Cek informasi nomor telepon Indonesia",
              style: TextStyle(
                  color: Colors.grey.shade500,
                  fontFamily: 'ShareTechMono',
                  fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            Container(
              decoration: BoxDecoration(
                color: cardDark,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: primaryPurple.withOpacity(0.5)),
              ),
              child: TextField(
                controller: _phoneCtrl,
                style: const TextStyle(
                    color: Colors.white, fontFamily: 'ShareTechMono'),
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: "0812xxxx / +628xxxx",
                  hintStyle: TextStyle(
                      color: Colors.grey.shade600, fontFamily: 'ShareTechMono'),
                  prefixIcon: Icon(Icons.phone, color: lightPurple),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 14),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _lookup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryPurple,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search, color: Colors.white),
                          SizedBox(width: 10),
                          Text("CEK NOMOR",
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
                    Text(
                      _result!['emoji'] ?? '📱',
                      style: const TextStyle(fontSize: 48),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _result!['operator'] ?? '-',
                      style: TextStyle(
                        color: lightPurple,
                        fontFamily: 'Orbitron',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _result!['tipe'] ?? '-',
                      style: TextStyle(
                          color: Colors.grey.shade400,
                          fontFamily: 'ShareTechMono'),
                    ),
                    const SizedBox(height: 16),
                    ...[
                      ['Nomor', _result!['nomor_format']],
                      ['Prefix', _result!['prefix']],
                      ['Negara', _result!['negara']],
                      ['Kode Negara', _result!['kode_negara']],
                    ].map((item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 100,
                                child: Text("${item[0]}",
                                    style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontFamily: 'ShareTechMono',
                                        fontSize: 12)),
                              ),
                              Text(": ${item[1]}",
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
