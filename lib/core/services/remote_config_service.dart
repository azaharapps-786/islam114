import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class RemoteConfigService extends ChangeNotifier {
  static final RemoteConfigService _instance = RemoteConfigService._internal();
  factory RemoteConfigService() => _instance;
  RemoteConfigService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Config state ─────────────────────────────────────────────────────
  bool _maintenanceMode = false;
  String _maintenanceMessage = '';
  bool _forceUpdate = false;
  String _forceUpdateMessage = '';
  String _minSupportedVersion = '1.0.0';
  Map<String, bool> _disabledFeatures = {};
  String? _forcedTheme;
  String? _forcedLanguage;
  bool _bannerEnabled = false;
  String _bannerMessage = '';
  String _bannerType = 'info';
  List<Map<String, dynamic>> _announcements = [];
  List<Map<String, dynamic>> _pushMessages = [];
  bool _isInitialized = false;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get maintenanceMode => _maintenanceMode;
  String get maintenanceMessage => _maintenanceMessage;
  bool get forceUpdate => _forceUpdate;
  String get forceUpdateMessage => _forceUpdateMessage;
  String get minSupportedVersion => _minSupportedVersion;
  Map<String, bool> get disabledFeatures => _disabledFeatures;
  String? get forcedTheme => _forcedTheme;
  String? get forcedLanguage => _forcedLanguage;
  bool get bannerEnabled => _bannerEnabled;
  String get bannerMessage => _bannerMessage;
  String get bannerType => _bannerType;
  List<Map<String, dynamic>> get announcements => _announcements;
  List<Map<String, dynamic>> get pushMessages => _pushMessages;

  /// Returns true if the admin has disabled this feature
  bool isFeatureDisabled(String featureKey) =>
      _disabledFeatures[featureKey] == true;

  /// Returns count of currently disabled features
  int get disabledCount =>
      _disabledFeatures.values.where((v) => v).length;

  // ── Callbacks (for specific actions like showing block screens) ──────
  VoidCallback? onMaintenanceModeChanged;
  VoidCallback? onForceUpdateRequired;
  VoidCallback? onNewAnnouncement;
  VoidCallback? onNewPushMessage;

  StreamSubscription? _configSub;
  StreamSubscription? _announcementSub;
  StreamSubscription? _pushSub;

  // ── Initialize ───────────────────────────────────────────────────────
  Future<void> initialize() async {
    try {
      // Listen to app config — this is the SINGLE source of truth
      _configSub = _db
          .collection('app_config')
          .doc('current')
          .snapshots()
          .listen((snapshot) {
        if (!snapshot.exists) return;
        final data = snapshot.data()!;

        // Snapshot old values to detect changes
        final oldMaintenance = _maintenanceMode;
        final oldForceUpdate = _forceUpdate;
        final oldBanner = _bannerEnabled;
        final oldTheme = _forcedTheme;
        final oldLanguage = _forcedLanguage;
        final oldFeatures = Map<String, bool>.from(_disabledFeatures);

        // ── Update ALL fields from Firestore ────────────────────────
        _maintenanceMode = data['maintenance_mode'] as bool? ?? false;
        _maintenanceMessage =
            data['maintenance_message'] as String? ?? '';
        _forceUpdate = data['force_update'] as bool? ?? false;
        _forceUpdateMessage =
            data['force_update_message'] as String? ?? '';
        _minSupportedVersion =
            data['min_supported_version'] as String? ?? '1.0.0';
        _disabledFeatures =
        Map<String, bool>.from(data['disabled_features'] as Map? ?? {});
        _forcedTheme = data['forced_theme'] as String?;
        _forcedLanguage = data['forced_language'] as String?;
        _bannerEnabled = data['banner_enabled'] as bool? ?? false;
        _bannerMessage = data['banner_message'] as String? ?? '';
        _bannerType = data['banner_type'] as String? ?? 'info';

        _isInitialized = true;

        // ── Fire specific callbacks for blocking screens ────────────
        if (oldMaintenance != _maintenanceMode) {
          onMaintenanceModeChanged?.call();
        }
        if (!oldForceUpdate && _forceUpdate) {
          onForceUpdateRequired?.call();
        }

        // ── Notify ALL listeners (banner, theme, features, etc.) ────
        //    This makes Provider.of<RemoteConfigService> in the UI
        //    trigger a rebuild whenever ANY config field changes.
        notifyListeners();

        debugPrint('━━━ RemoteConfig Updated ━━━');
        debugPrint('  maintenance: $_maintenanceMode');
        debugPrint('  forceUpdate: $_forceUpdate');
        debugPrint('  banner: $_bannerEnabled → "$_bannerMessage"');
        debugPrint('  theme: $_forcedTheme | lang: $_forcedLanguage');
        debugPrint('  disabled: $_disabledFeatures');
      });

      // Listen to active announcements
      _announcementSub = _db
          .collection('announcements')
          .where('active', isEqualTo: true)
          .snapshots()
          .listen((snapshot) {
        _announcements =
            snapshot.docs.map((d) => {'id': d.id, ...d.data()}).toList();
        if (_announcements.isNotEmpty) onNewAnnouncement?.call();
      });

      // Listen to push messages
      _pushSub = _db
          .collection('push_messages')
          .where('status', isEqualTo: 'sent')
          .orderBy('created_at', descending: true)
          .snapshots()
          .listen((snapshot) {
        final newMsgs =
        snapshot.docs.map((d) => {'id': d.id, ...d.data()}).toList();
        if (newMsgs.length > _pushMessages.length) {
          onNewPushMessage?.call();
        }
        _pushMessages = newMsgs;
      });
    } catch (e) {
      debugPrint('RemoteConfigService initialize error: $e');
    }
  }

  // ── Language override helper ─────────────────────────────────────────
  /// Called from main.dart to apply admin-forced language.
  /// Only acts if the admin has set a forced language.
  /// Your SettingsService needs this method — add it there.
  void setLanguageIfOverridden(String language) {
    // This is a signal to SettingsService to override the user's
    // language preference. The actual implementation lives in
    // SettingsService (see note below).
    debugPrint('Admin forced language: $language');
  }

  // ── Device check ─────────────────────────────────────────────────────
  Future<bool> isDeviceBlocked(String deviceId) async {
    try {
      final doc =
      await _db.collection('blocked_devices').doc(deviceId).get();
      return doc.exists;
    } catch (_) {
      return false;
    }
  }

  // ── Version check ────────────────────────────────────────────────────
  Future<bool> isVersionSupported() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final current = info.version;
      return _compareVersions(current, _minSupportedVersion) >= 0;
    } catch (_) {
      return true;
    }
  }

  int _compareVersions(String a, String b) {
    final aParts = a.split('.').map(int.parse).toList();
    final bParts = b.split('.').map(int.parse).toList();
    for (var i = 0; i < 3; i++) {
      final aVal = i < aParts.length ? aParts[i] : 0;
      final bVal = i < bParts.length ? bParts[i] : 0;
      if (aVal != bVal) return aVal.compareTo(bVal);
    }
    return 0;
  }

  void dispose() {
    _configSub?.cancel();
    _announcementSub?.cancel();
    _pushSub?.cancel();
    super.dispose();
  }
}