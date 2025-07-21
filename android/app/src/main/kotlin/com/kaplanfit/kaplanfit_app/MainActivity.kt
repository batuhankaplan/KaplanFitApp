package com.kaplanfit.kaplanfit_app

import android.os.Bundle
import android.content.pm.PackageManager
import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.*
import androidx.health.connect.client.HealthConnectClient
import androidx.health.connect.client.PermissionController
import androidx.health.connect.client.permission.HealthPermission
import androidx.health.connect.client.records.StepsRecord
import androidx.health.connect.client.records.HeartRateRecord
import androidx.health.connect.client.records.ExerciseSessionRecord
import androidx.health.connect.client.records.SleepSessionRecord
import androidx.health.connect.client.request.ReadRecordsRequest
import androidx.health.connect.client.time.TimeRangeFilter
import java.time.Instant
import java.time.LocalDateTime
import java.time.ZoneId
import java.io.File

// Samsung Health Data SDK temporarily disabled due to API complexity
// import com.samsung.android.sdk.healthdata.*
import java.util.*

class MainActivity: FlutterActivity() {
    private val CHANNEL = "kaplanfit/health_data"
    private lateinit var healthConnectClient: HealthConnectClient
    private val scope = CoroutineScope(Dispatchers.Main + SupervisorJob())
    
    // Samsung Health Data SDK temporarily disabled - using mock system
    // private var mHealthDataStore: HealthDataStore? = null
    // private var mPermissionManager: HealthPermissionManager? = null
    // private var mResolver: HealthDataResolver? = null
    private var mockSamsungHealthConnected = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Health Connect client'ını başlat
        healthConnectClient = HealthConnectClient.getOrCreate(this)
        
        // Samsung Health mock system başlat
        initMockSamsungHealthSystem()
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkSamsungHealthSDK" -> {
                    checkSamsungHealthSDK(result)
                }
                "checkHealthConnect" -> {
                    checkHealthConnect(result)
                }
                "checkHealthServices" -> {
                    checkHealthServices(result)
                }
                "checkGoogleFit" -> {
                    checkGoogleFit(result)
                }
                "getConnectedDeviceType" -> {
                    getConnectedDeviceType(result)
                }
                "requestPermissions" -> {
                    val permissions = call.argument<List<String>>("permissions")
                    val provider = call.argument<String>("provider")
                    requestPermissions(permissions, provider, result)
                }
                "checkPermissions" -> {
                    val permissions = call.argument<List<String>>("permissions")
                    val provider = call.argument<String>("provider")
                    checkPermissions(permissions, provider, result)
                }
                "getWorkoutData" -> {
                    val provider = call.argument<String>("provider")
                    val startDate = call.argument<Long>("startDate")
                    val endDate = call.argument<Long>("endDate")
                    getWorkoutData(provider, startDate, endDate, result)
                }
                "getHeartRateData" -> {
                    val provider = call.argument<String>("provider")
                    val startDate = call.argument<Long>("startDate")
                    val endDate = call.argument<Long>("endDate")
                    getHeartRateData(provider, startDate, endDate, result)
                }
                "getStepsData" -> {
                    val provider = call.argument<String>("provider")
                    val startDate = call.argument<Long>("startDate")
                    val endDate = call.argument<Long>("endDate")
                    getStepsData(provider, startDate, endDate, result)
                }
                "getSleepData" -> {
                    val provider = call.argument<String>("provider")
                    val startDate = call.argument<Long>("startDate")
                    val endDate = call.argument<Long>("endDate")
                    getSleepData(provider, startDate, endDate, result)
                }
                "startWorkoutTracking" -> {
                    val provider = call.argument<String>("provider")
                    val workoutType = call.argument<String>("workoutType")
                    startWorkoutTracking(provider, workoutType, result)
                }
                "stopWorkoutTracking" -> {
                    val provider = call.argument<String>("provider")
                    stopWorkoutTracking(provider, result)
                }
                "getSamsungSensorData" -> {
                    getSamsungSensorData(result)
                }
                "requestSamsungHealthDirectPermissions" -> {
                    val permissions = call.argument<List<String>>("permissions")
                    requestSamsungHealthDirectPermissions(permissions, result)
                }
                "requestGoogleFitPermissions" -> {
                    val permissions = call.argument<List<String>>("permissions")
                    requestGoogleFitPermissions(permissions, result)
                }
                "enableRealSamsungHealthMode" -> enableRealSamsungHealthMode(result)
                "clearMockDataDuplicates" -> clearMockDataDuplicates(result)
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    // Samsung Health Mock System initialization
    private fun initMockSamsungHealthSystem() {
        try {
            println("Initializing Samsung Health Mock System...")
            // Samsung Health uygulamasının yüklü olup olmadığını kontrol et
            val packageName = "com.sec.android.app.shealth"
            packageManager.getPackageInfo(packageName, PackageManager.GET_ACTIVITIES)
            mockSamsungHealthConnected = true
            println("Samsung Health mock system initialized successfully")
        } catch (e: Exception) {
            println("Samsung Health not installed: ${e.message}")
            mockSamsungHealthConnected = false
        }
    }

    private fun checkSamsungHealthSDK(result: MethodChannel.Result) {
        try {
            // Samsung Health uygulamasının yüklü olup olmadığını kontrol et
            val packageName = "com.sec.android.app.shealth"
            packageManager.getPackageInfo(packageName, PackageManager.GET_ACTIVITIES)
            result.success(true)
        } catch (e: PackageManager.NameNotFoundException) {
            result.success(false)
        }
    }

    private fun checkHealthConnect(result: MethodChannel.Result) {
        scope.launch {
            try {
                val status = HealthConnectClient.getSdkStatus(this@MainActivity)
                val isAvailable = status == HealthConnectClient.SDK_AVAILABLE
                result.success(isAvailable)
            } catch (e: Exception) {
                result.success(false)
            }
        }
    }

    private fun checkHealthServices(result: MethodChannel.Result) {
        try {
            // Wear OS Health Services'in mevcut olup olmadığını kontrol et
            val packageName = "com.google.android.wearable.healthservices"
            packageManager.getPackageInfo(packageName, PackageManager.GET_ACTIVITIES)
            result.success(true)
        } catch (e: PackageManager.NameNotFoundException) {
            result.success(false)
        }
    }

    private fun checkGoogleFit(result: MethodChannel.Result) {
        try {
            // Google Fit uygulamasının yüklü olup olmadığını kontrol et
            val packageName = "com.google.android.apps.fitness"
            packageManager.getPackageInfo(packageName, PackageManager.GET_ACTIVITIES)
            result.success(true)
        } catch (e: PackageManager.NameNotFoundException) {
            result.success(false)
        }
    }

    private fun getConnectedDeviceType(result: MethodChannel.Result) {
        // Bağlı cihaz türünü tespit etme mantığı
        scope.launch {
            try {
                // Health Connect durumunu kontrol et
                val healthConnectStatus = HealthConnectClient.getSdkStatus(this@MainActivity)
                
                // Samsung Health varsa ve Health Connect aktifse Samsung Watch'u kabul et
                if (checkSamsungHealthExists() && healthConnectStatus == HealthConnectClient.SDK_AVAILABLE) {
                    println("Samsung Health + Health Connect tespit edildi")
                    result.success("samsung_watch")
                } else if (checkSamsungHealthExists()) {
                    println("Sadece Samsung Health tespit edildi")
                    result.success("samsung_watch")
                } else {
                    result.success("other")
                }
            } catch (e: Exception) {
                println("Device type detection error: ${e.message}")
                result.success("other")
            }
        }
    }

    private fun checkSamsungHealthExists(): Boolean {
        return try {
            packageManager.getPackageInfo("com.sec.android.app.shealth", PackageManager.GET_ACTIVITIES)
            true
        } catch (e: PackageManager.NameNotFoundException) {
            false
        }
    }

    private fun requestPermissions(permissions: List<String>?, provider: String?, result: MethodChannel.Result) {
        scope.launch {
            try {
                println("MainActivity: requestPermissions çağrıldı - provider: $provider, permissions: $permissions")
                when (provider) {
                    "healthConnect" -> {
                        println("MainActivity: Health Connect izin verme işlemi başlatılıyor...")
                        
                        val healthPermissions = permissions?.map { permission ->
                            when (permission) {
                                "heartRate" -> HealthPermission.getReadPermission(HeartRateRecord::class)
                                "steps" -> HealthPermission.getReadPermission(StepsRecord::class)
                                "exercise" -> HealthPermission.getReadPermission(ExerciseSessionRecord::class)
                                "sleep" -> HealthPermission.getReadPermission(SleepSessionRecord::class)
                                else -> HealthPermission.getReadPermission(StepsRecord::class)
                            }
                        }?.toSet() ?: emptySet()

                        println("MainActivity: İstenen Health Connect izinleri: $healthPermissions")

                        // İzinleri kontrol et
                        val grantedPermissions = healthConnectClient.permissionController.getGrantedPermissions()
                        val hasAllPermissions = grantedPermissions.containsAll(healthPermissions)
                        
                        println("MainActivity: Mevcut izinler: $grantedPermissions")
                        println("MainActivity: Tüm izinler mevcut mu: $hasAllPermissions")
                        
                        if (!hasAllPermissions) {
                            // Health Connect izin akışını başlat
                            try {
                                println("MainActivity: Health Connect izin akışı başlatılıyor...")
                                
                                // Samsung Health'ın Health Connect'e veri paylaşımını aktif etmesi için önce Samsung Health'ı aç
                                if (checkSamsungHealthExists()) {
                                    println("MainActivity: Samsung Health'a yönlendiriliyor...")
                                    try {
                                        val samsungHealthIntent = packageManager.getLaunchIntentForPackage("com.sec.android.app.shealth")
                                        if (samsungHealthIntent != null) {
                                            samsungHealthIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                            startActivity(samsungHealthIntent)
                                            println("MainActivity: Samsung Health açıldı")
                                            
                                            // 3 saniye bekle, sonra Health Connect'i aç
                                            Thread.sleep(3000)
                                        }
                                    } catch (e: Exception) {
                                        println("MainActivity: Samsung Health açma hatası: ${e.message}")
                                    }
                                }
                                
                                // Health Connect'in izin sayfasını aç
                                val intent = HealthConnectClient.getHealthConnectManageDataIntent(this@MainActivity, packageName)
                                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                intent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
                                startActivity(intent)
                                println("MainActivity: Health Connect izin sayfası açıldı")
                                
                                result.success(true)
                            } catch (e: Exception) {
                                println("MainActivity: Health Connect izin akışı hatası: ${e.message}")
                                
                                // Alternative: Android sistem ayarları
                                try {
                                    println("MainActivity: Android sistem ayarları açılıyor...")
                                    val settingsIntent = Intent("android.settings.HEALTH_CONNECT_SETTINGS")
                                    settingsIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                    startActivity(settingsIntent)
                                    println("MainActivity: Health Connect sistem ayarları açıldı")
                                    result.success(true)
                                } catch (settingsError: Exception) {
                                    println("MainActivity: Sistem ayarları hatası: ${settingsError.message}")
                                    result.success(false)
                                }
                            }
                        } else {
                            println("MainActivity: Health Connect izinleri zaten mevcut!")
                            result.success(true)
                        }
                    }
                    "samsungHealth" -> {
                        // Samsung Health mock permission system
                        println("MainActivity: Samsung Health mock permission system...")
                        requestMockSamsungHealthPermissions(permissions, result)
                    }
                    else -> {
                        result.success(false)
                    }
                }
            } catch (e: Exception) {
                result.success(false)
            }
        }
    }

    // Silent permission check - sadece kontrol et, UI açma
    private fun checkPermissions(permissions: List<String>?, provider: String?, result: MethodChannel.Result) {
        scope.launch {
            try {
                println("MainActivity: checkPermissions (silent) çağrıldı - provider: $provider, permissions: $permissions")
                when (provider) {
                    "healthConnect" -> {
                        val healthPermissions = permissions?.map { permission ->
                            when (permission) {
                                "heartRate" -> HealthPermission.getReadPermission(HeartRateRecord::class)
                                "steps" -> HealthPermission.getReadPermission(StepsRecord::class)
                                "exercise" -> HealthPermission.getReadPermission(ExerciseSessionRecord::class)
                                "sleep" -> HealthPermission.getReadPermission(SleepSessionRecord::class)
                                else -> HealthPermission.getReadPermission(StepsRecord::class)
                            }
                        }?.toSet() ?: emptySet()

                        // Sadece izinleri kontrol et, UI açma
                        val grantedPermissions = healthConnectClient.permissionController.getGrantedPermissions()
                        val hasAllPermissions = grantedPermissions.containsAll(healthPermissions)
                        
                        println("MainActivity: Silent check - İzinler mevcut mu: $hasAllPermissions")
                        result.success(hasAllPermissions)
                    }
                    "samsungHealth" -> {
                        // Samsung Health mock permission check
                        checkMockSamsungHealthPermissions(permissions, result)
                    }
                    else -> {
                        result.success(false)
                    }
                }
            } catch (e: Exception) {
                println("MainActivity: checkPermissions hatası: ${e.message}")
                result.success(false)
            }
        }
    }

    private fun getWorkoutData(provider: String?, startDate: Long?, endDate: Long?, result: MethodChannel.Result) {
        scope.launch {
            try {
                println("MainActivity: getWorkoutData çağrıldı - provider: $provider")
                when (provider) {
                    "healthConnect" -> {
                        // Health Connect'ten gerçek egzersiz verilerini al
                        val timeRange = TimeRangeFilter.between(
                            Instant.ofEpochMilli(startDate ?: (System.currentTimeMillis() - 86400000)), // 24 saat önce
                            Instant.ofEpochMilli(endDate ?: System.currentTimeMillis())
                        )
                        
                        val request = ReadRecordsRequest(
                            recordType = ExerciseSessionRecord::class,
                            timeRangeFilter = timeRange
                        )
                        
                        val response = healthConnectClient.readRecords(request)
                        val exercises = response.records
                        
                        var totalDuration = 0L
                        var totalCalories = 0.0
                        val exercisesList = mutableListOf<Map<String, Any>>()
                        
                        exercises.forEach { exercise ->
                            val duration = exercise.endTime.toEpochMilli() - exercise.startTime.toEpochMilli()
                            totalDuration += duration
                            
                            exercisesList.add(hashMapOf<String, Any>(
                                "type" to (exercise.exerciseType.toString()),
                                "startTime" to exercise.startTime.toEpochMilli(),
                                "endTime" to exercise.endTime.toEpochMilli(),
                                "duration" to duration,
                                "title" to (exercise.title ?: "Egzersiz")
                            ))
                        }
                        
                        println("MainActivity: Health Connect exercises bulundu: ${exercises.size}")
                        
                        val workoutData = hashMapOf<String, Any>(
                            "totalExercises" to exercises.size,
                            "totalDuration" to totalDuration,
                            "exercises" to exercisesList,
                            "provider" to (provider ?: "healthConnect")
                        )
                        result.success(workoutData)
                    }
                    "samsungHealth" -> {
                        // Samsung Health: Önce Health Connect'i dene, sonra mock system
                        println("MainActivity: Samsung Health - Health Connect deneniyor...")
                        
                        try {
                            val healthConnectStatus = HealthConnectClient.getSdkStatus(this@MainActivity)
                            if (healthConnectStatus == HealthConnectClient.SDK_AVAILABLE) {
                                println("MainActivity: Health Connect mevcut, Samsung Health verisi Health Connect üzerinden çekiliyor...")
                                
                                val timeRange = TimeRangeFilter.between(
                                    Instant.ofEpochMilli(startDate ?: (System.currentTimeMillis() - 86400000)), 
                                    Instant.ofEpochMilli(endDate ?: System.currentTimeMillis())
                                )
                                
                                val request = ReadRecordsRequest(
                                    recordType = ExerciseSessionRecord::class,
                                    timeRangeFilter = timeRange
                                )
                                
                                val response = healthConnectClient.readRecords(request)
                                val exercises = response.records
                                
                                if (exercises.isNotEmpty()) {
                                    var totalDuration = 0L
                                    val exercisesList = mutableListOf<Map<String, Any>>()
                                    
                                    exercises.forEach { exercise ->
                                        val duration = exercise.endTime.toEpochMilli() - exercise.startTime.toEpochMilli()
                                        totalDuration += duration
                                        
                                        exercisesList.add(hashMapOf<String, Any>(
                                            "type" to (exercise.exerciseType.toString()),
                                            "startTime" to exercise.startTime.toEpochMilli(),
                                            "endTime" to exercise.endTime.toEpochMilli(),
                                            "duration" to duration,
                                            "title" to (exercise.title ?: "Samsung Health Egzersiz")
                                        ))
                                    }
                                    
                                    println("MainActivity: Samsung Health verisi Health Connect'ten başarıyla alındı: ${exercises.size} egzersiz")
                                    
                                    val workoutData = hashMapOf<String, Any>(
                                        "totalExercises" to exercises.size,
                                        "totalDuration" to totalDuration,
                                        "exercises" to exercisesList,
                                        "provider" to "samsungHealth"
                                    )
                                    result.success(workoutData)
                                    return@launch
                                } else {
                                    println("MainActivity: Health Connect'te egzersiz verisi bulunamadı, mock system kullanılıyor...")
                                }
                            } else {
                                println("MainActivity: Health Connect mevcut değil, mock system kullanılıyor...")
                            }
                        } catch (e: Exception) {
                            println("MainActivity: Health Connect hatası: ${e.message}, mock system kullanılıyor...")
                        }
                        
                        // Health Connect başarısızsa mock system kullan
                        getMockSamsungHealthWorkoutData(startDate, endDate, result)
                    }
                    else -> {
                        // Mock veri
                        val workoutData = hashMapOf<String, Any>(
                            "totalExercises" to 0,
                            "totalDuration" to 0,
                            "exercises" to emptyList<Map<String, Any>>(),
                            "provider" to "mock"
                        )
                        result.success(workoutData)
                    }
                }
            } catch (e: Exception) {
                println("MainActivity: getWorkoutData hatası: ${e.message}")
                result.error("WORKOUT_ERROR", e.message, null)
            }
        }
    }

    private fun getHeartRateData(provider: String?, startDate: Long?, endDate: Long?, result: MethodChannel.Result) {
        scope.launch {
            try {
                // Mock veri - gerçek implementasyon gerekiyor
                val heartRateData = listOf(
                    hashMapOf<String, Any>("timestamp" to System.currentTimeMillis(), "bpm" to 72),
                    hashMapOf<String, Any>("timestamp" to System.currentTimeMillis() - 60000, "bpm" to 75),
                    hashMapOf<String, Any>("timestamp" to System.currentTimeMillis() - 120000, "bpm" to 68)
                )
                result.success(heartRateData)
            } catch (e: Exception) {
                result.error("HEART_RATE_ERROR", e.message, null)
            }
        }
    }

    private fun getStepsData(provider: String?, startDate: Long?, endDate: Long?, result: MethodChannel.Result) {
        scope.launch {
            try {
                when (provider) {
                    "healthConnect", "samsungHealth" -> {
                        // Health Connect'ten gerçek adım verilerini al
                        val timeRange = TimeRangeFilter.between(
                            Instant.ofEpochMilli(startDate ?: (System.currentTimeMillis() - 86400000)), // 24 saat önce
                            Instant.ofEpochMilli(endDate ?: System.currentTimeMillis())
                        )
                        
                        val request = ReadRecordsRequest(
                            recordType = StepsRecord::class,
                            timeRangeFilter = timeRange
                        )
                        
                        val response = healthConnectClient.readRecords(request)
                        val stepsRecords = response.records
                        
                        var totalSteps = 0L
                        stepsRecords.forEach { record ->
                            totalSteps += record.count
                        }
                        
                        val stepsData = hashMapOf<String, Any>(
                            "totalSteps" to totalSteps,
                            "dailyAverage" to totalSteps, // Basit hesaplama
                            "goalProgress" to (totalSteps / 10000.0), // 10k hedef
                            "provider" to (provider ?: "healthConnect"),
                            "recordsCount" to stepsRecords.size
                        )
                        result.success(stepsData)
                    }
                    else -> {
                        // Mock veri
                        val stepsData = hashMapOf<String, Any>(
                            "totalSteps" to 0,
                            "dailyAverage" to 0,
                            "goalProgress" to 0.0,
                            "provider" to "mock"
                        )
                        result.success(stepsData)
                    }
                }
            } catch (e: Exception) {
                result.error("STEPS_ERROR", e.message, null)
            }
        }
    }

    private fun getSleepData(provider: String?, startDate: Long?, endDate: Long?, result: MethodChannel.Result) {
        scope.launch {
            try {
                // Mock veri - gerçek implementasyon gerekiyor
                val sleepData = hashMapOf<String, Any>(
                    "totalSleepMinutes" to 450, // 7.5 saat
                    "deepSleepMinutes" to 120,
                    "lightSleepMinutes" to 240,
                    "remSleepMinutes" to 90,
                    "sleepScore" to 78
                )
                result.success(sleepData)
            } catch (e: Exception) {
                result.error("SLEEP_ERROR", e.message, null)
            }
        }
    }

    private fun startWorkoutTracking(provider: String?, workoutType: String?, result: MethodChannel.Result) {
        scope.launch {
            try {
                // Real-time antreman takibi başlatma mantığı
                result.success(true)
            } catch (e: Exception) {
                result.success(false)
            }
        }
    }

    private fun stopWorkoutTracking(provider: String?, result: MethodChannel.Result) {
        scope.launch {
            try {
                // Real-time antreman takibi durdurma mantığı
                result.success(true)
            } catch (e: Exception) {
                result.success(false)
            }
        }
    }

    private fun getSamsungSensorData(result: MethodChannel.Result) {
        scope.launch {
            try {
                // Samsung özel sensör verilerini alma mantığı
                val sensorData = hashMapOf<String, Any>(
                    "skinTemperature" to 36.5,
                    "bodyComposition" to hashMapOf<String, Any>(
                        "bodyFat" to 15.2,
                        "muscleMass" to 32.1,
                        "boneMass" to 3.2
                    ),
                    "stressLevel" to 42,
                    "bloodOxygen" to 98.5
                )
                result.success(sensorData)
            } catch (e: Exception) {
                result.error("SAMSUNG_SENSOR_ERROR", e.message, null)
            }
        }
    }

    private fun requestSamsungHealthDirectPermissions(permissions: List<String>?, result: MethodChannel.Result) {
        scope.launch {
            try {
                println("MainActivity: Samsung Health Direct permission request başlatılıyor...")
                
                // Samsung Health uygulamasını direkt aç
                val samsungHealthPackage = "com.sec.android.app.shealth"
                val intent = Intent()
                intent.setClassName(samsungHealthPackage, "com.sec.android.app.shealth.permission.PermissionManagerActivity")
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                intent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
                
                // Extra data ile uygulama bilgisini ekle
                intent.putExtra("CALLING_PACKAGE", packageName)
                intent.putExtra("REQUESTED_PERMISSIONS", permissions?.toTypedArray())
                
                try {
                    startActivity(intent)
                    println("MainActivity: Samsung Health permission sayfası açıldı")
                    result.success(true)
                } catch (activityError: Exception) {
                    println("MainActivity: Samsung Health permission activity hatası: ${activityError.message}")
                    
                    // Fallback: Samsung Health ana sayfasını aç
                    val launchIntent = packageManager.getLaunchIntentForPackage(samsungHealthPackage)
                    if (launchIntent != null) {
                        launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        startActivity(launchIntent)
                        println("MainActivity: Samsung Health ana sayfa açıldı")
                        result.success(true)
                    } else {
                        println("MainActivity: Samsung Health yüklü değil")
                        result.success(false)
                    }
                }
            } catch (e: Exception) {
                println("MainActivity: Samsung Health Direct permission error: ${e.message}")
                result.success(false)
            }
        }
    }

    private fun requestGoogleFitPermissions(permissions: List<String>?, result: MethodChannel.Result) {
        scope.launch {
            try {
                println("MainActivity: Google Fit permission request başlatılıyor...")
                
                // Google Fit uygulamasını aç
                val googleFitPackage = "com.google.android.apps.fitness"
                
                try {
                    // Google Fit data access intent
                    val intent = Intent("com.google.android.gms.fitness.VIEW")
                    intent.setPackage(googleFitPackage)
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    
                    startActivity(intent)
                    println("MainActivity: Google Fit açıldı")
                    result.success(true)
                } catch (intentError: Exception) {
                    println("MainActivity: Google Fit intent hatası: ${intentError.message}")
                    
                    // Fallback: Google Fit ana sayfasını aç
                    val launchIntent = packageManager.getLaunchIntentForPackage(googleFitPackage)
                    if (launchIntent != null) {
                        launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        startActivity(launchIntent)
                        println("MainActivity: Google Fit ana sayfa açıldı")
                        result.success(true)
                    } else {
                        println("MainActivity: Google Fit yüklü değil - Play Store'a yönlendiriliyor")
                        val playStoreIntent = Intent(Intent.ACTION_VIEW, android.net.Uri.parse("market://details?id=com.google.android.apps.fitness"))
                        playStoreIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        startActivity(playStoreIntent)
                        result.success(true)
                    }
                }
            } catch (e: Exception) {
                println("MainActivity: Google Fit permission error: ${e.message}")
                result.success(false)
            }
        }
    }

    // Samsung Health gerçek SDK modunu aktif et
    private fun enableRealSamsungHealthMode(result: MethodChannel.Result) {
        scope.launch {
            try {
                println("MainActivity: Samsung Health gerçek SDK modu aktif ediliyor...")
                
                // Gerçek Samsung Health SDK implementasyonu için gerekli kontroller
                val samsungHealthPackage = "com.sec.android.app.shealth"
                val packageInfo = packageManager.getPackageInfo(samsungHealthPackage, PackageManager.GET_ACTIVITIES)
                
                println("MainActivity: Samsung Health sürümü: ${packageInfo.versionName}")
                
                // TODO: Gerçek Samsung Health Data SDK entegrasyonu
                // Bu kısım Samsung Health Data SDK v1.0.0-beta2 ile yapılacak
                
                result.success(mapOf(
                    "enabled" to true,
                    "samsungHealthVersion" to packageInfo.versionName,
                    "sdkMode" to "mock", // Şu an için mock
                    "message" to "Samsung Health SDK aktif, gerçek entegrasyon için Samsung Health Data SDK v1.0.0-beta2 gerekiyor"
                ))
            } catch (e: Exception) {
                println("MainActivity: Samsung Health SDK aktif etme hatası: ${e.message}")
                result.success(mapOf(
                    "enabled" to false,
                    "error" to e.message
                ))
            }
        }
    }

    // Mock veri tekrarlarını temizle (Flutter tarafından çağrılacak)
    private fun clearMockDataDuplicates(result: MethodChannel.Result) {
        scope.launch {
            try {
                println("MainActivity: Mock veri tekrarları temizleniyor...")
                
                // Bu Flutter tarafından veritabanı temizliği için kullanılacak
                // Sadece platform tarafında bir sinyal gönderiyoruz
                
                result.success(mapOf(
                    "cleared" to true,
                    "message" to "Mock veri tekrarlarının temizlenmesi için Flutter tarafında işlem yapılacak",
                    "timestamp" to System.currentTimeMillis()
                ))
            } catch (e: Exception) {
                println("MainActivity: Mock veri temizleme hatası: ${e.message}")
                result.success(mapOf(
                    "cleared" to false,
                    "error" to e.message
                ))
            }
        }
    }

    // Samsung Health Mock System - Permission request
    private fun requestMockSamsungHealthPermissions(permissions: List<String>?, result: MethodChannel.Result) {
        scope.launch {
            try {
                if (!mockSamsungHealthConnected) {
                    println("Samsung Health mock system not connected")
                    result.success(false)
                    return@launch
                }
                
                println("Samsung Health Mock: Permission request - ${permissions?.size} permissions")
                
                // Samsung Health uygulamasını aç (izin UI simülasyonu)
                try {
                    val samsungHealthPackage = "com.sec.android.app.shealth"
                    val intent = packageManager.getLaunchIntentForPackage(samsungHealthPackage)
                    if (intent != null) {
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        intent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
                        startActivity(intent)
                        
                        // Mock izin başarılı
                        android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
                            println("Samsung Health Mock: Permission granted")
                            result.success(true)
                        }, 100)
                    } else {
                        result.success(false)
                    }
                } catch (e: Exception) {
                    println("Samsung Health Mock permission error: ${e.message}")
                    result.success(false)
                }
                
            } catch (e: Exception) {
                println("Samsung Health Mock permission error: ${e.message}")
                result.success(false)
            }
        }
    }

    // Samsung Health Mock System - Permission check (silent)
    private fun checkMockSamsungHealthPermissions(permissions: List<String>?, result: MethodChannel.Result) {
        scope.launch {
            try {
                if (!mockSamsungHealthConnected) {
                    result.success(false)
                    return@launch
                }
                
                // Mock sistem her zaman izin var der
                println("Samsung Health Mock: Permission check - Always granted for mock")
                result.success(true)
                
            } catch (e: Exception) {
                println("Samsung Health Mock permission check error: ${e.message}")
                result.success(false)
            }
        }
    }

    // Samsung Health Real Data System - Try to get actual data
    private fun getMockSamsungHealthWorkoutData(startDate: Long?, endDate: Long?, result: MethodChannel.Result) {
        scope.launch {
            try {
                if (!mockSamsungHealthConnected) {
                    result.error("SDK_ERROR", "Samsung Health system not connected", null)
                    return@launch
                }
                
                println("Samsung Health: Attempting to get real workout data...")
                
                // Samsung Health'tan gerçek veri çekmeye çalış
                val realData = tryToGetRealSamsungHealthData(startDate, endDate)
                
                if (realData.isNotEmpty()) {
                    println("Samsung Health: ${realData.size} gerçek egzersiz bulundu!")
                    
                    val totalDuration = realData.sumOf { it["duration"] as Long }
                    val workoutData = hashMapOf<String, Any>(
                        "totalExercises" to realData.size,
                        "totalDuration" to totalDuration,
                        "exercises" to realData,
                        "provider" to "samsungHealth"
                    )
                    
                    result.success(workoutData)
                } else {
                    // Gerçek veri yoksa boş sonuç döndür
                    println("Samsung Health: Henüz gerçek egzersiz verisi bulunamadı")
                    
                    val workoutData = hashMapOf<String, Any>(
                        "totalExercises" to 0,
                        "totalDuration" to 0L,
                        "exercises" to emptyList<Map<String, Any>>(),
                        "provider" to "samsungHealth"
                    )
                    
                    result.success(workoutData)
                }
                
            } catch (e: Exception) {
                println("Samsung Health real data error: ${e.message}")
                result.error("SDK_ERROR", e.message, null)
            }
        }
    }

    // Samsung Health'tan gerçek veri çekmeye çalışır
    private fun tryToGetRealSamsungHealthData(startDate: Long?, endDate: Long?): List<Map<String, Any>> {
        try {
            println("Samsung Health: Gerçek veri arama başlatıldı...")
            
            // Samsung Health uygulamasının veri dizinlerini kontrol et
            val exercises = checkSamsungHealthExerciseData()
            
            if (exercises.isNotEmpty()) {
                println("Samsung Health: ${exercises.size} gerçek egzersiz bulundu")
                return exercises
            }
            
            println("Samsung Health: Henüz gerçek egzersiz verisi bulunamadı")
            return emptyList()
            
        } catch (e: Exception) {
            println("Samsung Health real data check error: ${e.message}")
            return emptyList()
        }
    }

    // Samsung Health'ın exercise verilerini kontrol et (basit yaklaşım)
    private fun checkSamsungHealthExerciseData(): List<Map<String, Any>> {
        try {
            // Samsung Health'ın SharedPreferences'larını kontrol et
            val shealthPrefs = getSharedPreferences("samsung_health_exercise", MODE_PRIVATE)
            
            // Samsung Health content provider'ını kontrol et (eğer public ise)
            return checkSamsungHealthContentProvider()
            
        } catch (e: Exception) {
            println("Samsung Health exercise data check error: ${e.message}")
            return emptyList()
        }
    }

    // Samsung Health ContentProvider kontrolü
    private fun checkSamsungHealthContentProvider(): List<Map<String, Any>> {
        try {
            // Samsung Health'ın public content provider'larını kontrol et
            val exercises = mutableListOf<Map<String, Any>>()
            
            // Samsung Health Data SDK AAR kontrol et
            val realSamsungData = tryRealSamsungHealthSDK()
            if (realSamsungData.isNotEmpty()) {
                println("Samsung Health: Gerçek SDK'dan ${realSamsungData.size} egzersiz bulundu!")
                return realSamsungData
            }
            
            // Samsung Health Content Resolver kullanarak veri çekmeye çalış
            val contentResolverData = tryContentResolverMethod()
            if (contentResolverData.isNotEmpty()) {
                println("Samsung Health: ContentResolver'dan ${contentResolverData.size} egzersiz bulundu!")
                return contentResolverData
            }
            
            println("Samsung Health: Henüz gerçek veri bulunamadı")
            return exercises
            
        } catch (e: Exception) {
            println("Samsung Health ContentProvider error: ${e.message}")
            return emptyList()
        }
    }

    // Samsung Health Data SDK v1.0.0-beta2 kullanarak gerçek veri çekme
    private fun tryRealSamsungHealthSDK(): List<Map<String, Any>> {
        try {
            println("Samsung Health: Gerçek SDK denemeleri başlıyor...")
            
            // Samsung Health Data SDK AAR dosyaları kontrol et
            val aarFiles = checkSamsungHealthAARs()
            if (!aarFiles) {
                println("Samsung Health: AAR dosyaları bulunamadı")
                return emptyList()
            }
            
            // TODO: Gerçek Samsung Health Data SDK implementasyonu
            // val healthDataStore = HealthDataStore.getInstance(applicationContext)
            // val exerciseData = healthDataStore.readData(ExerciseSession.class)
            
            println("Samsung Health: SDK AAR dosyaları mevcut ama implementasyon henüz tamamlanmadı")
            return emptyList()
            
        } catch (e: Exception) {
            println("Samsung Health SDK error: ${e.message}")
            return emptyList()
        }
    }

    // Samsung Health AAR dosyalarının varlığını kontrol et
    private fun checkSamsungHealthAARs(): Boolean {
        try {
            val libsDir = File(applicationContext.applicationInfo.nativeLibraryDir).parent + "/libs"
            val aarFiles = listOf(
                "samsung-health-data-1.0.0-beta2.aar",
                "samsung-health-common-1.0.0-beta2.aar"
            )
            
            for (aarFile in aarFiles) {
                val file = File(libsDir, aarFile)
                if (file.exists()) {
                    println("Samsung Health: AAR bulundu: $aarFile")
                    return true
                }
            }
            
            return false
        } catch (e: Exception) {
            println("Samsung Health AAR check error: ${e.message}")
            return false
        }
    }

    // ContentResolver ile Samsung Health verilerini çekmeye çalış
    private fun tryContentResolverMethod(): List<Map<String, Any>> {
        try {
            val exercises = mutableListOf<Map<String, Any>>()
            
            // Samsung Health'ın bilinen content URI'leri
            val samsungHealthURIs = listOf(
                "content://com.sec.android.provider.shealth/steps",
                "content://com.sec.android.provider.shealth/exercise",
                "content://com.samsung.health.steps",
                "content://com.samsung.health.exercise"
            )
            
            for (uri in samsungHealthURIs) {
                try {
                    val contentUri = android.net.Uri.parse(uri)
                    val cursor = contentResolver.query(
                        contentUri,
                        null, // projection
                        null, // selection
                        null, // selectionArgs
                        null  // sortOrder
                    )
                    
                    if (cursor != null && cursor.count > 0) {
                        println("Samsung Health: ContentResolver'da veri bulundu - $uri")
                        while (cursor.moveToNext()) {
                            val exercise = hashMapOf<String, Any>()
                            
                            // Cursor'dan veri al
                            for (i in 0 until cursor.columnCount) {
                                val columnName = cursor.getColumnName(i)
                                val value = cursor.getString(i) ?: ""
                                exercise[columnName] = value
                            }
                            
                            exercises.add(exercise)
                            
                            // En fazla 10 kayıt al (test için)
                            if (exercises.size >= 10) break
                        }
                        cursor.close()
                        
                        if (exercises.isNotEmpty()) {
                            break // İlk başarılı URI'den veri aldık
                        }
                    }
                    cursor?.close()
                } catch (e: SecurityException) {
                    println("Samsung Health: Content URI erişim reddedildi - $uri")
                } catch (e: Exception) {
                    println("Samsung Health: Content URI hatası - $uri: ${e.message}")
                }
            }
            
            return exercises
        } catch (e: Exception) {
            println("Samsung Health ContentResolver error: ${e.message}")
            return emptyList()
        }
    }

    // SAMSUNG HEALTH SDK METHODS - TEMPORARILY DISABLED
    /*
    // Samsung Health Data SDK - Gerçek permission request
    private fun requestSamsungHealthPermissions(permissions: List<String>?, result: MethodChannel.Result) {
        scope.launch {
            try {
                if (mHealthDataStore == null || mPermissionManager == null) {
                    println("Samsung Health Data Store not initialized")
                    result.success(false)
                    return@launch
                }
                
                println("Samsung Health Data SDK: Permission request başlatılıyor...")
                
                // Permission key'leri oluştur
                val permissionKeys = HashSet<HealthPermissionManager.PermissionKey>()
                
                permissions?.forEach { permission ->
                    when (permission) {
                        "steps" -> {
                            permissionKeys.add(HealthPermissionManager.PermissionKey(
                                HealthConstants.StepCount.HEALTH_DATA_TYPE,
                                HealthPermissionManager.PermissionType.READ
                            ))
                        }
                        "exercise" -> {
                            permissionKeys.add(HealthPermissionManager.PermissionKey(
                                HealthConstants.Exercise.HEALTH_DATA_TYPE,
                                HealthPermissionManager.PermissionType.READ
                            ))
                        }
                        "heartRate" -> {
                            permissionKeys.add(HealthPermissionManager.PermissionKey(
                                HealthConstants.HeartRate.HEALTH_DATA_TYPE,
                                HealthPermissionManager.PermissionType.READ
                            ))
                        }
                        "sleep" -> {
                            permissionKeys.add(HealthPermissionManager.PermissionKey(
                                HealthConstants.Sleep.HEALTH_DATA_TYPE,
                                HealthPermissionManager.PermissionType.READ
                            ))
                        }
                    }
                }
                
                if (permissionKeys.isNotEmpty()) {
                    println("Samsung Health Data SDK: ${permissionKeys.size} permission request ediliyor")
                    
                    val permissionResult = mPermissionManager!!.requestPermissions(permissionKeys, this@MainActivity)
                    permissionResult.setResultListener { permResult ->
                        val resultMap = permResult.resultMap
                        val hasAllPermissions = !resultMap.values.contains(false)
                        
                        println("Samsung Health Data SDK: Permission result - Başarılı: $hasAllPermissions")
                        result.success(hasAllPermissions)
                    }
                } else {
                    println("Samsung Health Data SDK: Hiç permission key bulunamadı")
                    result.success(false)
                }
                
            } catch (e: Exception) {
                println("Samsung Health Data SDK permission error: ${e.message}")
                result.success(false)
            }
        }
    }
    
        // Samsung Health Data SDK - Gerçek workout verilerini çek
    private fun getSamsungHealthWorkoutData(startDate: Long?, endDate: Long?, result: MethodChannel.Result) {
        scope.launch {
            try {
                if (mHealthDataStore == null || mResolver == null) {
                    println("Samsung Health Data Store not initialized")
                    result.error("SDK_ERROR", "Samsung Health Data Store not initialized", null)
                    return@launch
                }
                
                val startTime = startDate ?: (System.currentTimeMillis() - 86400000) // 24 saat önce
                val endTime = endDate ?: System.currentTimeMillis()
                
                println("Samsung Health Data SDK: Exercise data çekiliyor ($startTime - $endTime)")
                
                // Exercise data için filter oluştur
                val filter = HealthDataResolver.Filter.greaterThanEquals(
                    HealthConstants.Exercise.START_TIME, startTime
                ).and(
                    HealthDataResolver.Filter.lessThanEquals(
                        HealthConstants.Exercise.START_TIME, endTime
                    )
                )
                
                // Read request oluştur
                val request = HealthDataResolver.ReadRequest.Builder()
                    .setDataType(HealthConstants.Exercise.HEALTH_DATA_TYPE)
                    .setFilter(filter)
                    .build()
                
                // Asenkron olarak veri çek
                val readResult = mResolver!!.read(request)
                readResult.setResultListener { exerciseResult ->
                    try {
                        val cursor = exerciseResult.resultSet
                        val exercisesList = mutableListOf<Map<String, Any>>()
                        var totalDuration = 0L
                        
                        if (cursor != null) {
                            while (cursor.moveToNext()) {
                                val startTimeMs = cursor.getLong(HealthConstants.Exercise.START_TIME)
                                val endTimeMs = cursor.getLong(HealthConstants.Exercise.END_TIME)
                                val exerciseType = cursor.getString(HealthConstants.Exercise.EXERCISE_TYPE)
                                val title = cursor.getString(HealthConstants.Exercise.EXERCISE_CUSTOM_TYPE) ?: "Samsung Health Egzersiz"
                                
                                val duration = endTimeMs - startTimeMs
                                totalDuration += duration
                                
                                exercisesList.add(hashMapOf<String, Any>(
                                    "type" to (exerciseType ?: "UNKNOWN"),
                                    "startTime" to startTimeMs,
                                    "endTime" to endTimeMs,
                                    "duration" to duration,
                                    "title" to title
                                ))
                            }
                            cursor.close()
                        }
                        
                        println("Samsung Health Data SDK: ${exercisesList.size} exercise bulundu")
                        
                        val workoutData = hashMapOf<String, Any>(
                            "totalExercises" to exercisesList.size,
                            "totalDuration" to totalDuration,
                            "exercises" to exercisesList,
                            "provider" to "samsungHealth"
                        )
                        
                        result.success(workoutData)
                        
                    } catch (e: Exception) {
                        println("Samsung Health Data SDK exercise parse error: ${e.message}")
                        result.error("PARSE_ERROR", e.message, null)
                    }
                }
                
            } catch (e: Exception) {
                println("Samsung Health Data SDK exercise read error: ${e.message}")
                result.error("SDK_ERROR", e.message, null)
            }
        }
    }
    
     // Samsung Health Data SDK - Permission check (silent)
     private fun checkSamsungHealthPermissions(permissions: List<String>?, result: MethodChannel.Result) {
        scope.launch {
            try {
                if (mHealthDataStore == null || mPermissionManager == null) {
                    println("Samsung Health Data Store not initialized")
                    result.success(false)
                    return@launch
                }
                
                // Permission key'leri oluştur
                val permissionKeys = HashSet<HealthPermissionManager.PermissionKey>()
                
                permissions?.forEach { permission ->
                    when (permission) {
                        "steps" -> {
                            permissionKeys.add(HealthPermissionManager.PermissionKey(
                                HealthConstants.StepCount.HEALTH_DATA_TYPE,
                                HealthPermissionManager.PermissionType.READ
                            ))
                        }
                        "exercise" -> {
                            permissionKeys.add(HealthPermissionManager.PermissionKey(
                                HealthConstants.Exercise.HEALTH_DATA_TYPE,
                                HealthPermissionManager.PermissionType.READ
                            ))
                        }
                        "heartRate" -> {
                            permissionKeys.add(HealthPermissionManager.PermissionKey(
                                HealthConstants.HeartRate.HEALTH_DATA_TYPE,
                                HealthPermissionManager.PermissionType.READ
                            ))
                        }
                        "sleep" -> {
                            permissionKeys.add(HealthPermissionManager.PermissionKey(
                                HealthConstants.Sleep.HEALTH_DATA_TYPE,
                                HealthPermissionManager.PermissionType.READ
                            ))
                        }
                    }
                }
                
                if (permissionKeys.isNotEmpty()) {
                    val resultMap = mPermissionManager!!.isPermissionAcquired(permissionKeys)
                    val hasAllPermissions = !resultMap.values.contains(false)
                    
                    println("Samsung Health Data SDK: Permission check - Başarılı: $hasAllPermissions")
                    result.success(hasAllPermissions)
                } else {
                    result.success(false)
                }
                
            } catch (e: Exception) {
                println("Samsung Health Data SDK permission check error: ${e.message}")
                result.success(false)
            }
        }
    }

    */

    override fun onDestroy() {
        super.onDestroy()
        scope.cancel()
        // mHealthDataStore?.disconnectService() // Mock system doesn't need cleanup
    }
}
