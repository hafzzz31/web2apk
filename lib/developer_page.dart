import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'fa_icon_ext.dart';

class DeveloperPage extends StatefulWidget {
  final String sessionKey;
  final String username;

  const DeveloperPage({
    super.key,
    required this.sessionKey,
    required this.username,
  });

  @override
  State<DeveloperPage> createState() => _DeveloperPageState();
}

class _DeveloperPageState extends State<DeveloperPage> {
  late String sessionKey;
  List<dynamic> fullUserList = [];
  List<dynamic> filteredList = [];

  final List<String> roleOptions = ['member', 'reseller', 'partner', 'owner', 'tk', 'moderator', 'admin'];
  String selectedRole = 'member';

  int currentPage = 1;
  int itemsPerPage = 25;

  final deleteController = TextEditingController();
  final createUsernameController = TextEditingController();
  final createPasswordController = TextEditingController();
  final createDayController = TextEditingController();
  final editUsernameController = TextEditingController();
  final editDayController = TextEditingController();

  String newUserRole = 'member';
  bool isLoading = false;

  // ── VARIABLE UPLOAD BUKTI TF ──
  File? _buktiImage;
  String _buktiBase64 = '';
  final ImagePicker _picker = ImagePicker();

  final Color bgDark = const Color(0xFF0A0A0A);
  final Color primaryCyan = const Color(0xFF00BCD4);
  final Color accentCyan = const Color(0xFF26C6DA);
  final Color primaryWhite = Colors.white;
  final Color textGrey = Colors.grey.shade400;
  final Color cardGlass = Colors.white.withOpacity(0.05);
  final Color borderGlass = Colors.white.withOpacity(0.1);

  @override
  void initState() {
    super.initState();
    sessionKey = widget.sessionKey;
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() => isLoading = true);
    try {
      final res = await http.get(
        Uri.parse('http://hoxtenhafz.jscloud.my.id:2001/listUsers?key=$sessionKey'),
      );
      final data = jsonDecode(res.body);
      if (data['valid'] == true && data['authorized'] == true) {
        fullUserList = data['users'] ?? [];
        _filterAndPaginate();
      } else {
        _alert('Info', data['message'] ?? 'Gagal memuat user.');
      }
    } catch (_) {
      _alert('Error', 'Gagal terhubung ke server.');
    }
    setState(() => isLoading = false);
  }

  void _filterAndPaginate() {
    setState(() {
      currentPage = 1;
      filteredList = fullUserList.where((u) => u['role'] == selectedRole).toList();
    });
  }

  List<dynamic> _getCurrentPageData() {
    final start = (currentPage - 1) * itemsPerPage;
    final end = (start + itemsPerPage);
    return filteredList.sublist(
      start,
      end > filteredList.length ? filteredList.length : end,
    );
  }

  int get totalPages => (filteredList.length / itemsPerPage).ceil();

  Future<void> _deleteUser() async {
    final username = deleteController.text.trim();
    if (username.isEmpty) {
      _alert('⚠️ Error', 'Masukkan username yang ingin dihapus.');
      return;
    }
    setState(() => isLoading = true);
    try {
      final res = await http.get(
        Uri.parse('http://hoxtenhafz.jscloud.my.id:2001/deleteUser?key=$sessionKey&username=$username'),
      );
      final data = jsonDecode(res.body);
      if (data['deleted'] == true) {
        _alert('✅ Berhasil', "User '${data['user']['username']}' telah dihapus.");
        deleteController.clear();
        _fetchUsers();
      } else {
        _alert('❌ Gagal', data['message'] ?? 'Gagal menghapus user.');
      }
    } catch (_) {
      _alert('🌐 Error', 'Tidak dapat menghubungi server.');
    }
    setState(() => isLoading = false);
  }

  // ── PILIH GAMBAR ──
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 70,
      );
      if (picked != null) {
        final File imageFile = File(picked.path);
        final bytes = await imageFile.readAsBytes();
        final base64 = base64Encode(bytes);
        setState(() {
          _buktiImage = imageFile;
          _buktiBase64 = base64;
        });
      }
    } catch (e) {
      _alert('⚠️ Error', 'Gagal memilih gambar: $e');
    }
  }

  // ── SHOW IMAGE PICKER DIALOG ──
  void _showImagePickerDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: bgDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "PILIH SUMBER GAMBAR",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Orbitron',
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _imagePickerOption(
                    icon: Icons.photo_library_rounded,
                    label: "Galeri",
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                  _imagePickerOption(
                    icon: Icons.camera_alt_rounded,
                    label: "Kamera",
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickImage(ImageSource.camera);
                    },
                  ),
                ],
              ),
              if (_buktiImage != null) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          _buktiImage!,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.redAccent),
                      onPressed: () => setState(() {
                        _buktiImage = null;
                        _buktiBase64 = '';
                      }),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _imagePickerOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: cardGlass,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderGlass),
        ),
        child: Column(
          children: [
            Icon(icon, color: accentCyan, size: 32),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  // ── CREATE ACCOUNT DENGAN UPLOAD BUKTI TF ──
  Future<void> _createAccount() async {
    final username = createUsernameController.text.trim();
    final password = createPasswordController.text.trim();
    final day = createDayController.text.trim();

    if (username.isEmpty || password.isEmpty || day.isEmpty) {
      _alert('⚠️ Error', 'Semua field wajib diisi.');
      return;
    }

    if (_buktiImage == null) {
      _alert('⚠️ Error', 'Harap upload bukti transfer terlebih dahulu!');
      return;
    }

    setState(() => isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionKey = prefs.getString('session_key') ?? widget.sessionKey;

      final url = Uri.parse('http://hoxtenhafz.jscloud.my.id:2001/submitPending');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'key': sessionKey,
          'username': username,
          'password': password,
          'day': day,
          'role': newUserRole,
          'imageBase64': _buktiBase64,
        }),
      );

      final data = jsonDecode(response.body);

      if (data['valid'] == true) {
        _alert(
          '✅ Berhasil',
          'Request pembuatan akun \'$username\' telah dikirim!\n'
          'Menunggu approval dari Owner.\n'
          'ID Request: ${data['pendingId']}',
        );
        createUsernameController.clear();
        createPasswordController.clear();
        createDayController.clear();
        newUserRole = 'member';
        setState(() {
          _buktiImage = null;
          _buktiBase64 = '';
        });
        _fetchUsers();
      } else {
        _alert('❌ Gagal', data['message'] ?? 'Gagal mengirim request.');
      }
    } catch (e) {
      _alert('🌐 Error', 'Gagal menghubungi server: $e');
    }

    setState(() => isLoading = false);
  }

  Future<void> _editUser() async {
    final username = editUsernameController.text.trim();
    final day = editDayController.text.trim();
    if (username.isEmpty || day.isEmpty) {
      _alert('⚠️ Error', 'Username dan hari wajib diisi.');
      return;
    }
    setState(() => isLoading = true);
    try {
      final res = await http.get(
        Uri.parse('http://hoxtenhafz.jscloud.my.id:2001/editUser?key=$sessionKey&username=$username&day=$day'),
      );
      final data = jsonDecode(res.body);
      if (data['edited'] == true || data['updated'] == true) {
        _alert('✅ Berhasil', "User '$username' berhasil diperbarui.");
        editUsernameController.clear();
        editDayController.clear();
        _fetchUsers();
      } else {
        _alert('❌ Gagal', data['message'] ?? 'Gagal mengedit user.');
      }
    } catch (_) {
      _alert('🌐 Error', 'Gagal menghubungi server.');
    }
    setState(() => isLoading = false);
  }

  void _alert(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: bgDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: accentCyan.withOpacity(0.3)),
        ),
        title: Row(
          children: [
            Icon(Icons.info_outline, color: accentCyan),
            const SizedBox(width: 10),
            Text('Information', style: TextStyle(color: primaryWhite)),
          ],
        ),
        content: Text(message, style: TextStyle(color: Colors.white70)),
        actions: [
          Center(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [primaryCyan, accentCyan]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType type = TextInputType.text,
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextField(
        controller: controller,
        keyboardType: type,
        style: TextStyle(color: primaryWhite),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white30),
          labelStyle: TextStyle(color: accentCyan),
          prefixIcon: Icon(icon, color: accentCyan),
          filled: true,
          fillColor: cardGlass,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderGlass)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderGlass)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: accentCyan, width: 2)),
        ),
      ),
    );
  }

  Widget _buildGlassCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 30),
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardGlass,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderGlass),
        boxShadow: [BoxShadow(color: primaryCyan.withOpacity(0.1), blurRadius: 15, offset: Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(color: primaryCyan.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: accentCyan),
              ),
              SizedBox(width: 12),
              Text(title, style: TextStyle(color: primaryWhite, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Orbitron', letterSpacing: 1)),
            ],
          ),
          SizedBox(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildUserItem(Map user) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: cardGlass, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderGlass)),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(color: primaryCyan.withOpacity(0.2), shape: BoxShape.circle),
            child: Icon(Icons.person, color: accentCyan),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user['username'], style: TextStyle(color: primaryWhite, fontWeight: FontWeight.bold, fontSize: 16)),
                SizedBox(height: 4),
                Text("${user['role'].toUpperCase()} | Exp: ${user['expiredDate']}", style: TextStyle(color: Colors.white70, fontSize: 13)),
                SizedBox(height: 2),
                Text("Parent: ${user['parent'] ?? 'SYSTEM'}", style: TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), shape: BoxShape.circle, border: Border.all(color: Colors.redAccent.withOpacity(0.3))),
            child: IconButton(
              icon: Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    backgroundColor: bgDark,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: accentCyan.withOpacity(0.3))),
                    title: Row(children: [Icon(Icons.info_outline, color: accentCyan), const SizedBox(width: 10), Text('Konfirmasi', style: TextStyle(color: primaryWhite))]),
                    content: Text("Yakin ingin menghapus user '${user['username']}'?", style: TextStyle(color: Colors.white70)),
                    actions: [
                      Container(
                        width: double.infinity,
                        margin: EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              decoration: BoxDecoration(gradient: LinearGradient(colors: [primaryCyan, accentCyan]), borderRadius: BorderRadius.circular(12)),
                              child: TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Batal', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold))),
                            ),
                            Container(
                              decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.redAccent, Colors.red]), borderRadius: BorderRadius.circular(12)),
                              child: TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Hapus', style: TextStyle(color: primaryWhite, fontWeight: FontWeight.bold))),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  deleteController.text = user['username'];
                  _deleteUser();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPagination() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(totalPages, (index) {
        final page = index + 1;
        return ElevatedButton(
          onPressed: () => setState(() => currentPage = page),
          style: ElevatedButton.styleFrom(
            backgroundColor: currentPage == page ? accentCyan : Colors.transparent,
            foregroundColor: currentPage == page ? Colors.black : Colors.white54,
            padding: EdgeInsets.symmetric(horizontal: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: borderGlass)),
          ),
          child: Text('$page', style: TextStyle(fontSize: 12)),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [bgDark, primaryCyan.withOpacity(0.05), bgDark]),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.code_rounded, color: accentCyan, size: 50),
                SizedBox(height: 10),
                Text(
                  'DEVELOPER DASHBOARD',
                  style: TextStyle(color: accentCyan, fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Orbitron', letterSpacing: 2,
                    shadows: [Shadow(color: accentCyan.withOpacity(0.8), blurRadius: 10)]),
                ),
                SizedBox(height: 6),
                Text('Bisa buat Member, Reseller, Partner, Owner, TK, Moderator, Admin — Butuh Approval Owner',
                  style: TextStyle(color: textGrey, fontSize: 12), textAlign: TextAlign.center),
                SizedBox(height: 40),

                _buildGlassCard(
                  title: 'DELETE USER',
                  icon: FontAwesomeIcons.userSlash.toIcon(),
                  children: [
                    _buildInput(label: 'Username Target', controller: deleteController, icon: FontAwesomeIcons.user.toIcon()),
                    SizedBox(height: 10),
                    Container(
                      height: 50,
                      decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.redAccent, Colors.red]), borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.3), blurRadius: 10, offset: Offset(0, 4))]),
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _deleteUser,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        child: const Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.delete, size: 18, color: Colors.white),
                          SizedBox(width: 8),
                          Text('DELETE ACCOUNT', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                        ]),
                      ),
                    ),
                  ],
                ),

                _buildGlassCard(
                  title: 'CREATE ACCOUNT',
                  icon: FontAwesomeIcons.userPlus.toIcon(),
                  children: [
                    _buildInput(label: 'Username', controller: createUsernameController, icon: FontAwesomeIcons.user.toIcon()),
                    _buildInput(label: 'Password', controller: createPasswordController, icon: FontAwesomeIcons.lock.toIcon()),
                    _buildInput(label: 'Durasi (Hari)', controller: createDayController, icon: FontAwesomeIcons.calendarDay.toIcon(), type: TextInputType.number, hint: 'Masukkan durasi hari'),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(color: Colors.black.withOpacity(0.2), borderRadius: BorderRadius.circular(12), border: Border.all(color: borderGlass)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: newUserRole,
                          dropdownColor: bgDark,
                          style: TextStyle(color: primaryWhite),
                          items: roleOptions.map((role) => DropdownMenuItem(value: role, child: Text(role.toUpperCase()))).toList(),
                          onChanged: (val) => setState(() => newUserRole = val ?? 'member'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ── UPLOAD BUKTI TF ──
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: _showImagePickerDialog,
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                color: cardGlass,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _buktiImage != null ? Colors.greenAccent : borderGlass,
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _buktiImage != null ? Icons.check_circle_rounded : Icons.upload_file_rounded,
                                    color: _buktiImage != null ? Colors.greenAccent : accentCyan,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _buktiImage != null ? "Bukti TF Terupload" : "Upload Bukti Transfer",
                                    style: TextStyle(
                                      color: _buktiImage != null ? Colors.greenAccent : Colors.white70,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (_buktiImage != null) ...[
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (_) => Dialog(
                                  backgroundColor: bgDark,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.file(
                                      _buktiImage!,
                                      width: double.infinity,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: cardGlass,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: borderGlass),
                              ),
                              child: const Icon(Icons.visibility_rounded, color: Colors.white70, size: 20),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (_buktiImage != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: Colors.greenAccent, size: 14),
                            const SizedBox(width: 6),
                            const Text(
                              "Bukti TF terupload, menunggu approval Owner",
                              style: TextStyle(color: Colors.greenAccent, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    Container(
                      height: 50,
                      decoration: BoxDecoration(gradient: LinearGradient(colors: [primaryCyan, accentCyan]), borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: primaryCyan.withOpacity(0.4), blurRadius: 10, offset: Offset(0, 4))]),
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _createAccount,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        child: isLoading
                            ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                            : Text('REQUEST CREATE ACCOUNT', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      ),
                    ),
                  ],
                ),

                _buildGlassCard(
                  title: 'EDIT USER / TAMBAH HARI',
                  icon: FontAwesomeIcons.userPen.toIcon(),
                  children: [
                    _buildInput(label: 'Username Target', controller: editUsernameController, icon: FontAwesomeIcons.user.toIcon()),
                    _buildInput(label: 'Tambah Hari', controller: editDayController, icon: FontAwesomeIcons.calendarPlus.toIcon(), type: TextInputType.number),
                    Container(
                      height: 50,
                      decoration: BoxDecoration(gradient: LinearGradient(colors: [primaryCyan, accentCyan]), borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: primaryCyan.withOpacity(0.4), blurRadius: 10, offset: Offset(0, 4))]),
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _editUser,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        child: Text('UPDATE USER', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      ),
                    ),
                  ],
                ),

                _buildGlassCard(
                  title: 'USER MANAGEMENT',
                  icon: FontAwesomeIcons.users.toIcon(),
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(color: Colors.black.withOpacity(0.2), borderRadius: BorderRadius.circular(12), border: Border.all(color: borderGlass)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedRole,
                          dropdownColor: bgDark,
                          style: TextStyle(color: primaryWhite),
                          items: roleOptions.map((role) => DropdownMenuItem(value: role, child: Text(role.toUpperCase()))).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              selectedRole = val;
                              _filterAndPaginate();
                            }
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    isLoading
                        ? Center(child: CircularProgressIndicator(color: accentCyan))
                        : Column(
                            children: [
                              ..._getCurrentPageData().map((u) => _buildUserItem(u)).toList(),
                              SizedBox(height: 20),
                              _buildPagination(),
                            ],
                          ),
                  ],
                ),
                SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}