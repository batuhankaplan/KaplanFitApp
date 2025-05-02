// Örnek: lib/constants/activity_constants.dart

// Aktivite tipini ve MET değerini tutacak basit bir sınıf
class ActivityType {
  final String id;
  final String name;
  final double metValue; // Yaklaşık MET değeri (kalori hesabı için)

  const ActivityType(
      {required this.id, required this.name, required this.metValue});
}

// Varsayılan aktivite türleri listesi
const List<ActivityType> defaultActivityTypes = [
  // Kardiyo
  ActivityType(
      id: 'walking_moderate', name: 'Yürüyüş (Orta Tempo)', metValue: 3.5),
  ActivityType(
      id: 'walking_fast', name: 'Yürüyüş (Hızlı Tempo)', metValue: 4.5),
  ActivityType(id: 'running_slow', name: 'Koşu (Yavaş Tempo)', metValue: 7.0),
  ActivityType(
      id: 'running_moderate', name: 'Koşu (Orta Tempo)', metValue: 10.0),
  ActivityType(
      id: 'cycling_leisure', name: 'Bisiklet (Hafif Tempo)', metValue: 4.0),
  ActivityType(
      id: 'cycling_moderate', name: 'Bisiklet (Orta Tempo)', metValue: 8.0),
  ActivityType(
      id: 'swimming_freestyle', name: 'Yüzme (Serbest Stil)', metValue: 7.0),
  ActivityType(
      id: 'swimming_breaststroke', name: 'Yüzme (Kurbağalama)', metValue: 10.0),
  ActivityType(id: 'elliptical', name: 'Eliptik Bisiklet', metValue: 5.0),
  ActivityType(
      id: 'rowing_moderate', name: 'Kürek (Orta Tempo)', metValue: 7.0),
  ActivityType(id: 'jumping_rope', name: 'İp Atlama', metValue: 10.0),
  ActivityType(id: 'stair_climbing', name: 'Merdiven Tırmanma', metValue: 8.0),
  ActivityType(id: 'hiking', name: 'Doğa Yürüyüşü', metValue: 6.0),

  // Güç Antrenmanı
  ActivityType(
      id: 'weight_lifting_general',
      name: 'Ağırlık Antrenmanı (Genel)',
      metValue: 5.0),
  ActivityType(
      id: 'bodyweight_exercise',
      name: 'Vücut Ağırlığı Egzersizi',
      metValue: 4.0),
  ActivityType(id: 'crossfit', name: 'CrossFit', metValue: 12.0),

  // Esneklik & Denge
  ActivityType(id: 'yoga_hatha', name: 'Yoga (Hatha)', metValue: 2.5),
  ActivityType(id: 'yoga_power', name: 'Yoga (Power)', metValue: 4.0),
  ActivityType(id: 'pilates', name: 'Pilates', metValue: 3.0),
  ActivityType(id: 'stretching', name: 'Esneme', metValue: 2.0),
  ActivityType(id: 'tai_chi', name: 'Tai Chi', metValue: 3.0),

  // Sporlar
  ActivityType(id: 'basketball_game', name: 'Basketbol (Maç)', metValue: 8.0),
  ActivityType(id: 'soccer_game', name: 'Futbol (Maç)', metValue: 9.0),
  ActivityType(id: 'volleyball_game', name: 'Voleybol (Maç)', metValue: 4.0),
  ActivityType(id: 'tennis_singles', name: 'Tenis (Tekler)', metValue: 7.0),
  ActivityType(id: 'boxing_sparring', name: 'Boks (Sparring)', metValue: 9.0),
  ActivityType(id: 'martial_arts', name: 'Dövüş Sanatları', metValue: 10.0),

  // Diğer
  ActivityType(id: 'dancing_aerobic', name: 'Dans (Aerobik)', metValue: 7.0),
  ActivityType(id: 'gardening', name: 'Bahçe İşleri', metValue: 3.5),
  ActivityType(
      id: 'cleaning_moderate', name: 'Ev Temizliği (Orta)', metValue: 3.0),
];
