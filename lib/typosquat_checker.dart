import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class TyposquatPage extends StatefulWidget {
  const TyposquatPage({super.key});

  @override
  State<TyposquatPage> createState() => _TyposquatPageState();
}

class _TyposquatPageState extends State<TyposquatPage> {
  final TextEditingController _domainCtrl = TextEditingController();
  bool _isLoading = false;
  List<Map<String, dynamic>> _variants = [];
  String? _error;
  int _checked = 0;

  final Color primaryDark = const Color(0xFF0D0221);
  final Color primaryPurple = const Color(0xFF7B1FA2);
  final Color accentPurple = const Color(0xFFAA00FF);
  final Color lightPurple = const Color(0xFFE040FB);
  final Color cardDark = const Color(0xFF1A1A2E);
  final Color dangerRed = const Color(0xFFFF1744);
  final Color safeGreen = const Color(0xFF00E676);

  List<String> _generateVariants(String domain) {
    // Strip TLD
    final parts = domain.split('.');
    if (parts.length < 2) return [];
    final name = parts.sublist(0, parts.length - 1).join('.');
    final tld = parts.last;

    final variants = <String>{};

    // Common TLDs
    for (final t in ['com', 'net', 'org', 'info', 'biz', 'co', 'id', 'io', 'xyz']) {
      if (t != tld) variants.add('$name.$t');
    }

    // Character substitution (homoglyphs)
    const subs = {'a': ['@', '4'], 'e': ['3'], 'i': ['1', 'l'], 'o': ['0'], 's': ['5'], 'l': ['1']};
    for (int i = 0; i < name.length; i++) {
      final c = name[i].toLowerCase();
      if (subs.containsKey(c)) {
        for (final sub in subs[c]!) {
          variants.add('${name.substring(0, i)}$sub${name.substring(i + 1)}.$tld');
        }
      }
    }

    // Double characters
    for (int i = 0; i < name.length; i++) {
      variants.add('${name.substring(0, i)}${name[i]}${name[i]}${name.substring(i + 1)}.$tld');
    }

    // Missing characters
    for (int i = 0; i < name.length; i++) {
      final v = '${name.substring(0, i)}${name.substring(i + 1)}.$tld';
      if (v.split('.').first.length >= 2) variants.add(v);
    }

    // Transpositions
    for (int i = 0; i < name.length - 1; i++) {
      final chars = name.split('');
      final tmp = chars[i]; chars[i] = chars[i + 1]; chars[i + 1] = tmp;
      variants.add('${chars.join()}.$tld');
    }

    // Prefix/suffix additions
    for (final prefix in ['my', 'the', 'get', 'login', 'secure', 'app']) {
      variants.add('$prefix-$name.$tld');
      variants.add('$prefix$name.$tld');
    }
    for (final suffix in ['app', 'login', 'web', 'official', '-id']) {
      variants.add('$name$suffix.$tld');
    }

    // Remove original
    variants.remove(domain);
    return variants.take(40).toList();
  }

  Future<void> _check() async {
    final domain = _domainCtrl.text.trim().toLowerCase().replaceAll('https://', '').replaceAll('http://', '').split('/').first;
    if (domain.isEmpty || !domain.contains('.')) {
      setState(() => _error = "Masukkan domain yang valid (cth: google.com)");
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _variants = [];
      _checked = 0;
    });

    final variantList = _generateVariants(domain);
    final results = <Map<String, dynamic>>[];

    // Check DNS resolution for each variant (limited to avoid slowness)
    for (int i = 0; i < variantList.length && i < 20; i++) {
      final v = variantList[i];
      setState(() => _checked = i + 1);
      try {
        final resp = await http.head(
          Uri.parse('http://$v'),
          headers: {'User-Agent': 'Mozilla/5.0 Rangers'},
        ).timeout(const Duration(seconds: 3));
        results.add({'domain': v, 'status': 'REGISTERED', 'code': resp.statusCode});
      } catch (_) {
        // Try DNS lookup via API
        try {
          final dnsResp = await http.get(
            Uri.parse('https://dns.google/resolve?name=$v&type=A'),
          ).timeout(const Duration(seconds: 3));
          if (dnsResp.statusCode == 200) {
            final data = jsonDecode(dnsResp.body);
            final hasAnswer = (data['Answer'] ?? []).isNotEmpty;
            results.add({'domain': v, 'status': hasAnswer ? 'REGISTERED' : 'FREE', 'code': hasAnswer ? 200 : 404});
          }
        } catch (_) {
          results.add({'domain': v, 'status': 'FREE', 'code': 0});
        }
      }
    }

    // Add remaining as unchecked
    for (int i = 20; i < variantList.length; i++) {
      results.add({'domain': variantList[i], 'status': 'UNCHECKED', 'code': -1});
    }

    // Sort: registered first
    results.sort((a, b) {
      final order = {'REGISTERED': 0, 'UNCHECKED': 1, 'FREE': 2};
      return (order[a['status']] ?? 2).compareTo(order[b['status']] ?? 2);
    });

    setState(() {
      _variants = results;
      _isLoading = false;
    });
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'REGISTERED': return dangerRed;
      case 'FREE': return safeGreen;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final registered = _variants.where((v) => v['status'] == 'REGISTERED').length;

    return Scaffold(
      backgroundColor: primaryDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("TYPOSQUAT CHECKER",
            style: TextStyle(
              color: Colors.white, fontFamily: 'Orbitron',
              fontWeight: FontWeight.bold, fontSize: 13,
              shadows: [Shadow(color: dangerRed.withOpacity(0.8), blurRadius: 10)],
            )),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryPurple.withOpacity(0.4), Colors.transparent],
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              Container(
                decoration: BoxDecoration(
                  color: cardDark, borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: primaryPurple.withOpacity(0.5)),
                ),
                child: TextField(
                  controller: _domainCtrl,
                  style: const TextStyle(color: Colors.white, fontFamily: 'ShareTechMono'),
                  decoration: InputDecoration(
                    hintText: "google.com",
                    hintStyle: TextStyle(color: Colors.grey.shade600, fontFamily: 'ShareTechMono'),
                    prefixIcon: Icon(Icons.domain, color: lightPurple),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _check,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryPurple,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          const SizedBox(width: 18, height: 18,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                          const SizedBox(width: 12),
                          Text("Mengecek $_checked domain...",
                              style: const TextStyle(fontFamily: 'Orbitron', color: Colors.white)),
                        ])
                      : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.find_replace, color: Colors.white),
                          SizedBox(width: 10),
                          Text("SCAN TYPOSQUAT", style: TextStyle(
                              fontFamily: 'Orbitron', color: Colors.white,
                              letterSpacing: 1.2, fontWeight: FontWeight.bold)),
                        ]),
                ),
              ),
            ]),
          ),

          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Text(_error!, style: const TextStyle(color: Colors.red, fontFamily: 'ShareTechMono')),
              ),
            ),

          if (_variants.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(children: [
                _statPill("TOTAL", _variants.length.toString(), Colors.grey),
                const SizedBox(width: 8),
                _statPill("REGISTERED", registered.toString(), dangerRed),
                const SizedBox(width: 8),
                _statPill("FREE", (_variants.length - registered).toString(), safeGreen),
              ]),
            ),
          ],

          Expanded(
            child: _variants.isEmpty && !_isLoading
                ? Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.security, color: Colors.grey.shade700, size: 60),
                      const SizedBox(height: 12),
                      Text("Masukkan domain untuk dicek",
                          style: TextStyle(color: Colors.grey.shade600, fontFamily: 'ShareTechMono')),
                    ]),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _variants.length,
                    itemBuilder: (_, i) {
                      final item = _variants[i];
                      final color = _statusColor(item['status']);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: cardDark,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: color.withOpacity(0.3)),
                        ),
                        child: Row(children: [
                          Container(
                            width: 8, height: 8,
                            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(item['domain'],
                                style: const TextStyle(color: Colors.white, fontFamily: 'ShareTechMono', fontSize: 13)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(item['status'],
                                style: TextStyle(color: color, fontFamily: 'Orbitron', fontSize: 9, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                            icon: Icon(Icons.copy, color: Colors.grey.shade600, size: 16),
                            onPressed: () => Clipboard.setData(ClipboardData(text: item['domain'])),
                          ),
                        ]),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _statPill(String label, String val, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Text("$label: $val",
        style: TextStyle(color: color, fontFamily: 'ShareTechMono', fontSize: 11, fontWeight: FontWeight.bold)),
  );
}
