import 'program_item.dart';

/// Bir güne ait program bilgilerini içeren model.
class DailyProgram {
  /// Günün adı (örn: "Pazartesi")
  final String dayName;
  
  /// Günün indeksi (0: Pazartesi, 6: Pazar)
  final int dayIndex;
  
  /// Gün programı öğeleri (sabah, öğle, akşam vs)
  final List<ProgramItem> items;
  
  /// Genel günlük tavsiyeler
  final List<String> tips;
  
  const DailyProgram({
    required this.dayName,
    required this.dayIndex,
    required this.items,
    this.tips = const [],
  });
}

/// Haftanın günleri
enum WeekDay {
  monday,
  tuesday,
  wednesday,
  thursday,
  friday,
  saturday,
  sunday,
} 
