import 'package:cloud_firestore/cloud_firestore.dart';

class FoodItem {
  final String? id; // Firestore document ID
  final String name;
  final String category;
  final double servingSizeG;
  final double caloriesKcal;
  final double carbsG;
  final double proteinG;
  final double fatG;
  final List<String> keywords;
  final bool isCustom;
  final String? nameLowercase;

  FoodItem({
    this.id,
    required this.name,
    required this.category,
    required this.servingSizeG,
    required this.caloriesKcal,
    required this.carbsG,
    required this.proteinG,
    required this.fatG,
    List<String>? keywords,
    this.isCustom = false,
  })  : keywords = keywords ?? generateKeywords(name),
        nameLowercase = name.toLowerCase();

  static List<String> generateKeywords(String name) {
    if (name.isEmpty) return [];
    return name
        .toLowerCase()
        .split(' ')
        .where((k) => k.isNotEmpty)
        .toSet()
        .toList();
  }

  factory FoodItem.fromSnapshot(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return FoodItem(
      id: doc.id,
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      servingSizeG: (data['servingSizeG'] as num?)?.toDouble() ?? 0.0,
      caloriesKcal: (data['caloriesKcal'] as num?)?.toDouble() ?? 0.0,
      carbsG: (data['carbsG'] as num?)?.toDouble() ?? 0.0,
      proteinG: (data['proteinG'] as num?)?.toDouble() ?? 0.0,
      fatG: (data['fatG'] as num?)?.toDouble() ?? 0.0,
      keywords: data['keywords'] != null
          ? List<String>.from(data['keywords'])
          : generateKeywords(data['name'] ?? ''),
      isCustom: data['isCustom'] as bool? ?? false,
    );
  }

  // SQLite için factory constructor
  factory FoodItem.fromDbMap(Map<String, dynamic> map) {
    List<String> keywordsList = [];
    if (map['keywords'] != null && (map['keywords'] as String).isNotEmpty) {
      // Virgülle ayrılmış string'i listeye çevir
      keywordsList = (map['keywords'] as String).split(',');
    } else if (map['name'] != null) {
      keywordsList = generateKeywords(map['name'] ?? '');
    }

    return FoodItem(
      id: map['id']?.toString(), // SQLite ID integer olabilir, string'e çevir
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      servingSizeG: (map['servingSizeG'] as num?)?.toDouble() ?? 0.0,
      caloriesKcal: (map['caloriesKcal'] as num?)?.toDouble() ?? 0.0,
      carbsG: (map['carbsG'] as num?)?.toDouble() ?? 0.0,
      proteinG: (map['proteinG'] as num?)?.toDouble() ?? 0.0,
      fatG: (map['fatG'] as num?)?.toDouble() ?? 0.0,
      keywords: keywordsList,
      isCustom: (map['isCustom'] as int? ?? 0) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      // id SQLite tarafından otomatik üretildiği için toMap'e eklenmeyebilir (insert için)
      // update için gerekirse eklenebilir.
      'name': name,
      'category': category,
      'servingSizeG': servingSizeG,
      'caloriesKcal': caloriesKcal,
      'carbsG': carbsG,
      'proteinG': proteinG,
      'fatG': fatG,
      'name_lowercase': nameLowercase ?? name.toLowerCase(),
      'keywords': keywords.join(','),
      'isCustom': isCustom ? 1 : 0,
      // 'createdAt': createdAt?.toIso8601String(), // Modelde yok
    };
  }
}
