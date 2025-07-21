import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'database_service.dart';

// Desteklenen sağlık veri tipleri
enum HealthDataType {
  heartRate,
  steps,
  calories,
  distance,
  sleep,
  exercise,
  bloodOxygen,
  skinTemperature,
  bodyComposition,
  stress
}

// Desteklenen cihaz tipleri
enum DeviceType { samsungWatch, wearOS, fitbit, other }

// Veri sağlayıcı tipleri
enum DataProvider { samsungHealthSDK, healthConnect, healthServices, googleFit }

/// Samsung akıllı saatler ve diğer wearable cihazlarla bağlantı kurmak için
/// kapsamlı sağlık veri servisi
class HealthDataService {
  static final HealthDataService _instance = HealthDataService._internal();
  factory HealthDataService() => _instance;
  HealthDataService._internal();

  // Platform kanalları
  static const MethodChannel _healthChannel =
      MethodChannel('kaplanfit/health_data');

  // Bağlantı durumu
  bool _isInitialized = false;
  bool _hasPermissions = false;
  DeviceType? _connectedDeviceType;
  List<DataProvider> _availableProviders = [];

  // Stream controllers
  final StreamController<Map<String, dynamic>> _healthDataStreamController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<bool> _connectionStatusStreamController =
      StreamController<bool>.broadcast();

  // Getters
  bool get isInitialized => _isInitialized;
  bool get hasPermissions => _hasPermissions;
  DeviceType? get connectedDeviceType => _connectedDeviceType;
  List<DataProvider> get availableProviders => _availableProviders;

  Stream<Map<String, dynamic>> get healthDataStream =>
      _healthDataStreamController.stream;
  Stream<bool> get connectionStatusStream =>
      _connectionStatusStreamController.stream;

  /// Sağlık veri servisini başlatır
  Future<bool> initialize() async {
    try {
      debugPrint('HealthDataService: Initializing...');

      // Platform desteğini kontrol et
      if (!Platform.isAndroid) {
        debugPrint('HealthDataService: Only Android platform is supported');
        return false;
      }

      // Mevcut sağlayıcıları tespit et
      await _detectAvailableProviders();

      // Cihaz türünü tespit et
      await _detectDeviceType();

      _isInitialized = true;
      _connectionStatusStreamController.add(true);

      debugPrint('HealthDataService: Initialized successfully');
      debugPrint('Available providers: $_availableProviders');
      debugPrint('Connected device: $_connectedDeviceType');

      return true;
    } catch (e) {
      debugPrint('HealthDataService: Initialization failed: $e');
      return false;
    }
  }

  /// Mevcut sağlık veri sağlayıcılarını tespit eder
  Future<void> _detectAvailableProviders() async {
    _availableProviders.clear();

    try {
      // Windows ve debug ortamında mock providers sağla
      if (Platform.isWindows || kDebugMode) {
        debugPrint('HealthDataService: Debug/Windows ortamında - mock providers ekleniyor');
        _availableProviders.addAll([
          DataProvider.healthConnect,
          DataProvider.samsungHealthSDK,
        ]);
        return;
      }

      // Samsung Health SDK kontrolü
      try {
        final bool hasSamsungHealth =
            await _healthChannel.invokeMethod('checkSamsungHealthSDK');
        if (hasSamsungHealth) {
          _availableProviders.add(DataProvider.samsungHealthSDK);
        }
      } catch (e) {
        debugPrint('HealthDataService: Samsung Health SDK kontrol hatası: $e');
      }

      // Health Connect kontrolü
      try {
        final bool hasHealthConnect =
            await _healthChannel.invokeMethod('checkHealthConnect');
        if (hasHealthConnect) {
          _availableProviders.add(DataProvider.healthConnect);
        }
      } catch (e) {
        debugPrint('HealthDataService: Health Connect kontrol hatası: $e');
      }

      // Health Services kontrolü (Wear OS)
      try {
        final bool hasHealthServices =
            await _healthChannel.invokeMethod('checkHealthServices');
        if (hasHealthServices) {
          _availableProviders.add(DataProvider.healthServices);
        }
      } catch (e) {
        debugPrint('HealthDataService: Health Services kontrol hatası: $e');
      }

      // Google Fit kontrolü
      try {
        final bool hasGoogleFit =
            await _healthChannel.invokeMethod('checkGoogleFit');
        if (hasGoogleFit) {
          _availableProviders.add(DataProvider.googleFit);
        }
      } catch (e) {
        debugPrint('HealthDataService: Google Fit kontrol hatası: $e');
      }
    } catch (e) {
      debugPrint('HealthDataService: Error detecting providers: $e');
      // Fallback: Health Connect varsayılan olarak ekle
      if (_availableProviders.isEmpty) {
        _availableProviders.add(DataProvider.healthConnect);
      }
    }
  }

  /// Bağlı cihaz türünü tespit eder
  Future<void> _detectDeviceType() async {
    try {
      // Windows ve debug ortamında mock device sağla
      if (Platform.isWindows || kDebugMode) {
        debugPrint('HealthDataService: Debug/Windows ortamında - mock Samsung Watch cihazı');
        _connectedDeviceType = DeviceType.samsungWatch;
        return;
      }

      final String? deviceType =
          await _healthChannel.invokeMethod('getConnectedDeviceType');

      switch (deviceType) {
        case 'samsung_watch':
          _connectedDeviceType = DeviceType.samsungWatch;
          break;
        case 'wear_os':
          _connectedDeviceType = DeviceType.wearOS;
          break;
        case 'fitbit':
          _connectedDeviceType = DeviceType.fitbit;
          break;
        default:
          _connectedDeviceType = DeviceType.other;
      }
    } catch (e) {
      debugPrint('HealthDataService: Error detecting device type: $e');
      _connectedDeviceType = DeviceType.other;
    }
  }

  /// Gerekli izinleri ister
  Future<bool> requestPermissions(List<HealthDataType> dataTypes) async {
    try {
      final List<String> permissions =
          dataTypes.map((type) => type.toString().split('.').last).toList();
      final String providerString = _getProviderString(_getBestProvider());

      debugPrint('HealthDataService: İzin isteme başlatılıyor...');
      debugPrint('HealthDataService: Provider: $providerString');
      debugPrint('HealthDataService: İzinler: $permissions');

      // Try-catch ile güvenli çağrı yapıyoruz
      try {
        // Windows ve debug ortamında mock response döndür
        if (Platform.isWindows || kDebugMode) {
          debugPrint('HealthDataService: Debug/Windows ortamında - mock izin veriliyor');
          await Future.delayed(const Duration(milliseconds: 500)); // Simüle edilmiş gecikme
          _hasPermissions = true;
          return true;
        }

        final result = await _healthChannel.invokeMethod('requestPermissions',
            {'permissions': permissions, 'provider': providerString});

        final bool granted = result as bool? ?? false;
        debugPrint('HealthDataService: İzin verme sonucu: $granted');
        _hasPermissions = granted;
        return granted;
      } catch (platformError) {
        debugPrint(
            'HealthDataService: Platform channel hatası: $platformError');
        
        // Native implementation yoksa fallback
        if (platformError.toString().contains('MissingPluginException') || 
            platformError.toString().contains('not found')) {
          debugPrint('HealthDataService: Native health implementation bulunamadı, fallback modu');
          _hasPermissions = false;
          return false;
        }
        
        _hasPermissions = false;
        return false;
      }
    } catch (e) {
      debugPrint('HealthDataService: Error requesting permissions: $e');
      return false;
    }
  }

  /// İzin durumunu kontrol eder (UI açmadan)
  Future<bool> checkPermissions(List<HealthDataType> dataTypes) async {
    try {
      final List<String> permissions =
          dataTypes.map((type) => type.toString().split('.').last).toList();
      final String providerString = _getProviderString(_getBestProvider());

      debugPrint('HealthDataService: Silent izin kontrolü...');
      debugPrint('HealthDataService: Provider: $providerString');
      debugPrint('HealthDataService: İzinler: $permissions');

      // Silent check - UI açmaz
      final result = await _healthChannel.invokeMethod('checkPermissions',
          {'permissions': permissions, 'provider': providerString});

      final bool granted = result as bool? ?? false;
      debugPrint('HealthDataService: Silent check sonucu: $granted');
      _hasPermissions = granted;
      return granted;
    } catch (e) {
      debugPrint('HealthDataService: Silent check hatası: $e');
      _hasPermissions = false;
      return false;
    }
  }

  /// Provider enum'unu MainActivity'nin beklediği string'e çevirir
  String _getProviderString(DataProvider provider) {
    switch (provider) {
      case DataProvider.samsungHealthSDK:
        return 'samsungHealth';
      case DataProvider.healthConnect:
        return 'healthConnect';
      case DataProvider.healthServices:
        return 'healthServices';
      case DataProvider.googleFit:
        return 'googleFit';
    }
  }

  /// En iyi veri sağlayıcıyı seçer (Samsung Watch'ta Samsung Health öncelikli)
  DataProvider _getBestProvider() {
    // Samsung Watch tespit edildiğinde Samsung Health SDK'yı öncelikli kullan
    // Çünkü Samsung Health verilerine direkt erişim sağlar
    if (_connectedDeviceType == DeviceType.samsungWatch &&
        _availableProviders.contains(DataProvider.samsungHealthSDK)) {
      return DataProvider.samsungHealthSDK;
    }

    // Diğer durumlarda Health Connect'i kullan (Android'in yerleşik sistemi)
    if (_availableProviders.contains(DataProvider.healthConnect)) {
      return DataProvider.healthConnect;
    }

    // Wear OS cihazlarda Health Services'i tercih et
    if (_connectedDeviceType == DeviceType.wearOS &&
        _availableProviders.contains(DataProvider.healthServices)) {
      return DataProvider.healthServices;
    }

    // Son seçenek olarak Google Fit
    if (_availableProviders.contains(DataProvider.googleFit)) {
      return DataProvider.googleFit;
    }

    throw Exception('No suitable health data provider available');
  }

  /// Antreman verilerini alır
  Future<Map<String, dynamic>?> getWorkoutData({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (!_isInitialized || !_hasPermissions) {
      throw Exception('Service not initialized or permissions not granted');
    }

    try {
      final result = await _healthChannel.invokeMethod('getWorkoutData', {
        'provider': _getProviderString(_getBestProvider()),
        'startDate': startDate?.millisecondsSinceEpoch,
        'endDate': endDate?.millisecondsSinceEpoch,
      });

      return Map<String, dynamic>.from(result as Map);
    } catch (e) {
      debugPrint('HealthDataService: Error getting workout data: $e');
      return null;
    }
  }

  /// Kalp atış hızı verilerini alır
  Future<List<Map<String, dynamic>>?> getHeartRateData({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (!_isInitialized || !_hasPermissions) {
      throw Exception('Service not initialized or permissions not granted');
    }

    try {
      final result = await _healthChannel.invokeMethod('getHeartRateData', {
        'provider': _getProviderString(_getBestProvider()),
        'startDate': startDate?.millisecondsSinceEpoch,
        'endDate': endDate?.millisecondsSinceEpoch,
      });

      return (result as List)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    } catch (e) {
      debugPrint('HealthDataService: Error getting heart rate data: $e');
      return null;
    }
  }

  /// Adım sayısı verilerini alır
  Future<Map<String, dynamic>?> getStepsData({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (!_isInitialized || !_hasPermissions) {
      throw Exception('Service not initialized or permissions not granted');
    }

    try {
      final result = await _healthChannel.invokeMethod('getStepsData', {
        'provider': _getProviderString(_getBestProvider()),
        'startDate': startDate?.millisecondsSinceEpoch,
        'endDate': endDate?.millisecondsSinceEpoch,
      });

      return Map<String, dynamic>.from(result as Map);
    } catch (e) {
      debugPrint('HealthDataService: Error getting steps data: $e');
      return null;
    }
  }

  /// Uyku verilerini alır
  Future<Map<String, dynamic>?> getSleepData({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (!_isInitialized || !_hasPermissions) {
      throw Exception('Service not initialized or permissions not granted');
    }

    try {
      final result = await _healthChannel.invokeMethod('getSleepData', {
        'provider': _getProviderString(_getBestProvider()),
        'startDate': startDate?.millisecondsSinceEpoch,
        'endDate': endDate?.millisecondsSinceEpoch,
      });

      return Map<String, dynamic>.from(result as Map);
    } catch (e) {
      debugPrint('HealthDataService: Error getting sleep data: $e');
      return null;
    }
  }

  /// Real-time antreman takibi başlatır (Samsung Watch için)
  Future<bool> startWorkoutTracking(String workoutType) async {
    if (!_isInitialized || !_hasPermissions) {
      throw Exception('Service not initialized or permissions not granted');
    }

    try {
      final bool result =
          await _healthChannel.invokeMethod('startWorkoutTracking', {
        'provider': _getProviderString(_getBestProvider()),
        'workoutType': workoutType,
      });

      return result;
    } catch (e) {
      debugPrint('HealthDataService: Error starting workout tracking: $e');
      return false;
    }
  }

  /// Real-time antreman takibi durdurur
  Future<bool> stopWorkoutTracking() async {
    try {
      final bool result =
          await _healthChannel.invokeMethod('stopWorkoutTracking', {
        'provider': _getProviderString(_getBestProvider()),
      });

      return result;
    } catch (e) {
      debugPrint('HealthDataService: Error stopping workout tracking: $e');
      return false;
    }
  }

  /// Tüm sağlık verilerini senkronize eder
  Future<bool> syncAllHealthData() async {
    if (!_isInitialized || !_hasPermissions) {
      throw Exception('Service not initialized or permissions not granted');
    }

    try {
      // Son 30 günlük verileri al
      final DateTime endDate = DateTime.now();
      final DateTime startDate = endDate.subtract(const Duration(days: 30));

      // Paralel olarak tüm verileri al
      final List<Future> futures = [
        getWorkoutData(startDate: startDate, endDate: endDate),
        getHeartRateData(startDate: startDate, endDate: endDate),
        getStepsData(startDate: startDate, endDate: endDate),
        getSleepData(startDate: startDate, endDate: endDate),
      ];

      final List results = await Future.wait(futures);

      // Sonuçları stream'e gönder
      _healthDataStreamController.add({
        'workoutData': results[0],
        'heartRateData': results[1],
        'stepsData': results[2],
        'sleepData': results[3],
        'syncTime': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      debugPrint('HealthDataService: Error syncing health data: $e');
      return false;
    }
  }

  /// Samsung Watch özel sensör verilerini alır
  Future<Map<String, dynamic>?> getSamsungSensorData() async {
    if (_connectedDeviceType != DeviceType.samsungWatch) {
      debugPrint(
          'HealthDataService: Samsung sensor data only available on Samsung Watch');
      return null;
    }

    try {
      final result = await _healthChannel.invokeMethod('getSamsungSensorData');
      return Map<String, dynamic>.from(result as Map);
    } catch (e) {
      debugPrint('HealthDataService: Error getting Samsung sensor data: $e');
      return null;
    }
  }

  /// Servisi temizler
  void dispose() {
    _healthDataStreamController.close();
    _connectionStatusStreamController.close();
    _isInitialized = false;
    _hasPermissions = false;
    _connectedDeviceType = null;
    _availableProviders.clear();
  }

  // Samsung Health Direct Connection (Health Connect bypass)
  Future<bool> requestSamsungHealthDirectPermissions() async {
    try {
      debugPrint('HealthDataService: Samsung Health Direct permission request');

      final result = await _healthChannel
          .invokeMethod('requestSamsungHealthDirectPermissions', {
        'permissions': ['steps', 'heartRate', 'exercise', 'sleep']
      });

      return result == true;
    } catch (e) {
      debugPrint('HealthDataService: Samsung Health Direct permission error: $e');
      return false;
    }
  }

  // Google Fit API Connection (Alternative)
  Future<bool> requestGoogleFitPermissions() async {
    try {
      debugPrint('HealthDataService: Google Fit permission request');

      final result =
          await _healthChannel.invokeMethod('requestGoogleFitPermissions', {
        'permissions': ['steps', 'heartRate', 'exercise', 'sleep']
      });

      return result == true;
    } catch (e) {
      debugPrint('HealthDataService: Google Fit permission error: $e');
      return false;
    }
  }

  // Samsung Health gerçek SDK modunu aktif et
  Future<Map<String, dynamic>?> enableRealSamsungHealthMode() async {
    try {
      debugPrint(
          'HealthDataService: Samsung Health gerçek SDK modu aktif ediliyor...');

      final result =
          await _healthChannel.invokeMethod('enableRealSamsungHealthMode');
      return Map<String, dynamic>.from(result as Map);
    } catch (e) {
      debugPrint('HealthDataService: Samsung Health SDK aktif etme hatası: $e');
      return null;
    }
  }

  // Mock veri tekrarlarını temizle
  Future<Map<String, dynamic>?> clearMockDataDuplicates() async {
    try {
      debugPrint('HealthDataService: Mock veri tekrarları temizleniyor...');

      final result =
          await _healthChannel.invokeMethod('clearMockDataDuplicates');
      return Map<String, dynamic>.from(result as Map);
    } catch (e) {
      debugPrint('HealthDataService: Mock veri temizleme hatası: $e');
      return null;
    }
  }

  /// Samsung Watch mock aktivitelerini database'den temizle
  Future<Map<String, dynamic>> clearSamsungWatchMockActivities() async {
    try {
      debugPrint(
          'HealthDataService: Samsung Watch mock aktiviteleri veritabanından temizleniyor...');

      final result = await DatabaseService().clearSamsungWatchMockActivities();
      return result;
    } catch (e) {
      debugPrint('HealthDataService: Samsung Watch mock temizleme error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Duplicate aktiviteleri database'den temizle
  Future<Map<String, dynamic>> clearDuplicateActivities() async {
    try {
      debugPrint(
          'HealthDataService: Duplicate aktiviteler veritabanından temizleniyor...');

      final result = await DatabaseService().clearDuplicateActivities();
      return result;
    } catch (e) {
      debugPrint('HealthDataService: Duplicate aktivite temizleme error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Hem mock verileri hem database'deki tekrarlanan kayıtları temizle
  Future<Map<String, dynamic>> fullCleanupMockData() async {
    try {
      debugPrint('HealthDataService: 🧹 KAPSAMLI TEMİZLİK başlatılıyor...');

      // 1. Platform tarafında mock veri üretimini durdur
      final platformResult = await clearMockDataDuplicates();
      debugPrint('Platform cleanup: $platformResult');

      // 2. Database'deki Samsung Watch kayıtlarını temizle
      final samsungResult = await clearSamsungWatchMockActivities();
      debugPrint('Samsung Watch cleanup: $samsungResult');

      // 3. Duplicate aktiviteleri temizle
      final duplicateResult = await clearDuplicateActivities();
      debugPrint('Duplicate cleanup: $duplicateResult');

      final totalDeleted = (samsungResult['deletedCount'] ?? 0) +
          (duplicateResult['deletedCount'] ?? 0);

      return {
        'success': true,
        'message': 'Mock veri kapsamlı temizliği tamamlandı',
        'totalDeleted': totalDeleted,
        'details': {
          'platform': platformResult,
          'samsung': samsungResult,
          'duplicates': duplicateResult,
        }
      };
    } catch (e) {
      debugPrint('HealthDataService: Kapsamlı temizlik hatası: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}
