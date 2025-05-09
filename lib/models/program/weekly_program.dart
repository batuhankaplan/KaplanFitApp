import 'daily_program.dart';

/// Haftalık program bilgilerini içeren model.
class WeeklyProgram {
  /// Haftalık program adı (örn: "Kilo Verme Programı")
  final String name;

  /// Programın haftası (örn: 1, 2, 3...)
  final int weekNumber;

  /// Haftanın her gününe ait programlar
  final List<DailyProgram> dailyPrograms;

  /// Genel haftalık tavsiyeler
  final List<String> tips;

  /// Programın başlangıç tarihi
  final DateTime? startDate;

  const WeeklyProgram({
    required this.name,
    required this.weekNumber,
    required this.dailyPrograms,
    this.tips = const [],
    this.startDate,
  });

  /// Verilen güne ait program bilgilerini döndürür
  DailyProgram getDailyProgram(int dayIndex) {
    return dailyPrograms.firstWhere(
      (program) => program.dayIndex == dayIndex,
      orElse: () =>
          throw Exception('Bu güne ait program bulunamadı: $dayIndex'),
    );
  }

  /// Bugüne ait program bilgilerini döndürür
  DailyProgram getTodayProgram() {
    final today = DateTime.now().weekday - 1; // 0-6 indeksi (Pazartesi: 0)
    return getDailyProgram(today);
  }
}
