import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:location/location.dart' hide LocationAccuracy;
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart' hide PermissionStatus;
import '../providers/activity_provider.dart';
import '../models/activity_record.dart';
import '../models/task_type.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({Key? key}) : super(key: key);

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  FitActivityType _selectedActivityType = FitActivityType.walking;
  
  // Konum izleme değişkenleri
  bool _isTrackingActivity = false;
  bool _hasLocationPermission = false;
  DateTime? _activityStartTime;
  Position? _lastPosition;
  double _distanceInMeters = 0;
  int _elapsedTimeInSeconds = 0;
  late Location _location;
  
  @override
  void initState() {
    super.initState();
    _location = Location();
    _checkLocationPermission();
  }
  
  // Konum izni kontrolü
  Future<void> _checkLocationPermission() async {
    try {
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) {
          return;
        }
      }
      
      PermissionStatus permissionStatus = await _location.hasPermission();
      if (permissionStatus == PermissionStatus.denied) {
        permissionStatus = await _location.requestPermission();
        if (permissionStatus != PermissionStatus.granted) {
          return;
        }
      }
      
      setState(() {
        _hasLocationPermission = true;
      });
    } catch (e) {
      print('Konum izni hatası: $e');
    }
  }
  
  // Aktivite takibini başlat
  Future<void> _startActivityTracking() async {
    try {
      // Konum izni kontrolü
      if (!_hasLocationPermission) {
        await _checkLocationPermission();
        if (!_hasLocationPermission) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Aktivite takibi için konum izni gereklidir')),
          );
          return;
        }
      }
      
      // Konum servisi aktif mi kontrolü
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Konum servisi kapalı. Lütfen açın.')),
        );
        return;
      }
      
      // Konumu yüksek doğrulukla almaya başla
      _lastPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      setState(() {
        _isTrackingActivity = true;
        _activityStartTime = DateTime.now();
        _distanceInMeters = 0;
        _elapsedTimeInSeconds = 0;
      });
      
      // Periyodik olarak konum güncelleme
      Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // 10 metre hareket edince bildirim
        ),
      ).listen((Position position) {
        if (_lastPosition != null && _isTrackingActivity) {
          // Mesafe hesaplama
          double distance = Geolocator.distanceBetween(
            _lastPosition!.latitude, 
            _lastPosition!.longitude,
            position.latitude, 
            position.longitude,
          );
          
          setState(() {
            _distanceInMeters += distance;
            _elapsedTimeInSeconds = 
                DateTime.now().difference(_activityStartTime!).inSeconds;
            _lastPosition = position;
          });
        }
      });
      
      // Süre takibi için timer
      Stream.periodic(Duration(seconds: 1)).listen((event) {
        if (_isTrackingActivity && mounted) {
          setState(() {
            _elapsedTimeInSeconds = 
                DateTime.now().difference(_activityStartTime!).inSeconds;
          });
        }
      });
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Aktivite takibi başlatılamadı: $e')),
      );
    }
  }
  
  // Aktivite takibini durdur
  Future<void> _stopActivityTracking() async {
    if (!_isTrackingActivity) return;
    
    // Aktiviteyi kaydet
    final activityProvider = Provider.of<ActivityProvider>(context, listen: false);
    
    // Dakika olarak süre (en az 1 dakika)
    int durationMinutes = (_elapsedTimeInSeconds / 60).ceil();
    if (durationMinutes < 1) durationMinutes = 1;
    
    // Mesafeyi kilometre cinsinden (2 decimal)
    double distanceKm = _distanceInMeters / 1000;
    String distanceStr = distanceKm.toStringAsFixed(2);
    
    // Hız hesaplama (km/saat)
    double speedKmH = _elapsedTimeInSeconds > 0 
        ? (distanceKm / (_elapsedTimeInSeconds / 3600)) 
        : 0;
    String speedStr = speedKmH.toStringAsFixed(1);
    
    final activity = ActivityRecord(
      type: _selectedActivityType,
      durationMinutes: durationMinutes,
      date: _activityStartTime ?? DateTime.now(),
      notes: 'Mesafe: ${distanceStr} km, Hız: ${speedStr} km/s',
    );
    
    await activityProvider.addActivity(activity);
    
    setState(() {
      _isTrackingActivity = false;
      _activityStartTime = null;
      _lastPosition = null;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Aktivite kaydedildi!')),
    );
  }
  
  // Süreyi formatlı gösterme
  String _formatDuration(int seconds) {
    final int hours = seconds ~/ 3600;
    final int minutes = (seconds % 3600) ~/ 60;
    final int remainingSeconds = seconds % 60;
    
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
  
  @override
  void dispose() {
    _durationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ActivityProvider>(context);
    final isLoading = provider.isLoading;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spor Aktivitelerim'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _selectDate,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Tarih seçici
                Container(
                  padding: const EdgeInsets.all(16.0),
                  color: Theme.of(context).brightness == Brightness.dark ? AppTheme.cardColor : Theme.of(context).scaffoldBackgroundColor,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios),
                        onPressed: _previousDay,
                      ),
                      Text(
                        DateFormat('d MMMM y', 'tr_TR').format(_selectedDate),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward_ios),
                        onPressed: _nextDay,
                      ),
                    ],
                  ),
                ),
                const Divider(),
                // Aktivite listesi
                Expanded(
                  child: provider.activities.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.directions_run,
                                size: 80,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Bugün için aktivite yok',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 24),
                              _buildAddActivityButton(),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: provider.activities.length + 1,
                          itemBuilder: (context, index) {
                            if (index == provider.activities.length) {
                              return Center(
                                child: _buildAddActivityButton(),
                              );
                            }
                            
                            final activity = provider.activities[index];
                            return _buildActivityCard(activity);
                          },
                        ),
                ),
              ],
            ),
    );
  }
  
  Widget _buildActivityCard(ActivityRecord activity) {
    Color activityColor = _getActivityColor(activity.type);
    String activityTypeName = _getActivityTypeName(activity.type);
    String formattedDate = DateFormat('d MMM, HH:mm', 'tr_TR').format(activity.date);
    
    return Dismissible(
      key: Key('activity_${activity.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        color: Colors.red,
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      onDismissed: (direction) {
        Provider.of<ActivityProvider>(context, listen: false).deleteActivity(activity.id!);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$activityTypeName aktivitesi silindi'),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Aktivite Sil'),
              content: Text('Bu $activityTypeName aktivitesini silmek istediğinize emin misiniz?'),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('İptal'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Sil'),
                ),
              ],
            );
          },
        );
      },
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: () => _showEditActivityDialog(activity),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: activityColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _getActivityIcon(activity.type),
                            color: activityColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              activityTypeName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              formattedDate,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.teal.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '${activity.durationMinutes} dk',
                        style: const TextStyle(
                          color: Colors.teal,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                if (activity.notes != null && activity.notes!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Notlar:',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    activity.notes!,
                    style: const TextStyle(
                      fontSize: 15,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Aktivite ekle butonunu ortalı ve daha güzel göster
  Widget _buildAddActivityButton() {
    return Container(
      width: 200,
      margin: EdgeInsets.symmetric(vertical: 16),
      child: ElevatedButton(
        onPressed: _showAddActivityDialog,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppTheme.primaryColor
            : AppTheme.primaryColor,
          padding: EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Aktivite Ekle',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(Duration(days: 7)),
    );
    
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
      Provider.of<ActivityProvider>(context, listen: false).setSelectedDate(_selectedDate);
    }
  }
  
  void _previousDay() {
    setState(() {
      _selectedDate = _selectedDate.subtract(const Duration(days: 1));
    });
    Provider.of<ActivityProvider>(context, listen: false).setSelectedDate(_selectedDate);
  }
  
  void _nextDay() {
    if (_selectedDate.isBefore(DateTime.now())) {
      setState(() {
        _selectedDate = _selectedDate.add(const Duration(days: 1));
      });
      Provider.of<ActivityProvider>(context, listen: false).setSelectedDate(_selectedDate);
    }
  }
  
  void _showAddActivityDialog() {
    _durationController.clear();
    _notesController.clear();
    _selectedActivityType = FitActivityType.walking;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Aktivite Ekle'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Aktivite türü seçici
                DropdownButtonFormField<FitActivityType>(
                  value: _selectedActivityType,
                  decoration: const InputDecoration(
                    labelText: 'Aktivite Türü',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    FitActivityType.walking,
                    FitActivityType.running,
                    FitActivityType.swimming,
                    FitActivityType.weightTraining,
                    FitActivityType.cycling,
                    FitActivityType.yoga,
                    FitActivityType.other,
                  ].map((type) {
                    return DropdownMenuItem<FitActivityType>(
                      value: type,
                      child: Text(_getActivityTypeName(type)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedActivityType = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                
                // Süre girişi
                TextField(
                  controller: _durationController,
                  decoration: const InputDecoration(
                    labelText: 'Süre (dakika)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                
                // Notlar
                TextField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notlar',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('İptal'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('Ekle'),
              onPressed: () {
                if (_durationController.text.isNotEmpty) {
                  final duration = int.tryParse(_durationController.text);
                  if (duration != null && duration > 0) {
                    final provider = Provider.of<ActivityProvider>(context, listen: false);
                    final now = DateTime.now();
                    
                    final activity = ActivityRecord(
                      type: _selectedActivityType,
                      durationMinutes: duration,
                      date: _selectedDate.copyWith(
                        hour: now.hour, 
                        minute: now.minute,
                      ),
                      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
                    );
                    
                    provider.addActivity(activity);
                    Navigator.of(context).pop();
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // Aktivite ikonu alma
  IconData _getActivityIcon(FitActivityType type) {
    switch (type) {
      case FitActivityType.swimming:
        return Icons.pool;
      case FitActivityType.walking:
        return Icons.directions_walk;
      case FitActivityType.running:
        return Icons.directions_run;
      case FitActivityType.weightTraining:
        return Icons.fitness_center;
      default:
        return Icons.sports;
    }
  }

  String _getActivityTypeName(FitActivityType type) {
    switch (type) {
      case FitActivityType.swimming:
        return 'Yüzme';
      case FitActivityType.walking:
        return 'Yürüyüş';
      case FitActivityType.running:
        return 'Koşu';
      case FitActivityType.weightTraining:
        return 'Ağırlık Antrenmanı';
      default:
        return 'Diğer Aktivite';
    }
  }

  Color _getActivityColor(FitActivityType type) {
    switch (type) {
      case FitActivityType.swimming:
        return Colors.blue;
      case FitActivityType.walking:
        return Colors.green;
      case FitActivityType.running:
        return Colors.orange;
      case FitActivityType.weightTraining:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  // Aktivite düzenleme dialogu
  void _showEditActivityDialog(ActivityRecord activity) {
    _selectedActivityType = activity.type;
    _durationController.text = activity.durationMinutes.toString();
    _notesController.text = activity.notes ?? '';
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Aktivite Düzenle'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Aktivite türü seçici
                DropdownButtonFormField<FitActivityType>(
                  value: _selectedActivityType,
                  decoration: const InputDecoration(
                    labelText: 'Aktivite Türü',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    FitActivityType.walking,
                    FitActivityType.running,
                    FitActivityType.swimming,
                    FitActivityType.weightTraining,
                    FitActivityType.cycling,
                    FitActivityType.yoga,
                    FitActivityType.other,
                  ].map((type) {
                    return DropdownMenuItem<FitActivityType>(
                      value: type,
                      child: Text(_getActivityTypeName(type)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedActivityType = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                
                // Süre girişi
                TextField(
                  controller: _durationController,
                  decoration: const InputDecoration(
                    labelText: 'Süre (dakika)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                
                // Notlar
                TextField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notlar',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.delete),
                  SizedBox(width: 4),
                  Text('Sil'),
                ],
              ),
              onPressed: () {
                if (activity.id != null) {
                  Provider.of<ActivityProvider>(context, listen: false).deleteActivity(activity.id!);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${_getActivityTypeName(activity.type)} aktivitesi silindi'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('İptal'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('Kaydet'),
              onPressed: () {
                if (_durationController.text.isNotEmpty) {
                  final duration = int.tryParse(_durationController.text);
                  if (duration != null && duration > 0) {
                    final provider = Provider.of<ActivityProvider>(context, listen: false);
                    
                    final updatedActivity = ActivityRecord(
                      id: activity.id,
                      type: _selectedActivityType,
                      durationMinutes: duration,
                      date: activity.date, // Orijinal tarihi koru
                      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
                    );
                    
                    provider.updateActivity(updatedActivity);
                    Navigator.of(context).pop();
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
} 