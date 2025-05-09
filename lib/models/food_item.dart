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
  }) : keywords = keywords ?? _generateKeywords(name);

  static List<String> _generateKeywords(String name) {
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
          : _generateKeywords(data['name'] ?? ''),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'servingSizeG': servingSizeG,
      'caloriesKcal': caloriesKcal,
      'carbsG': carbsG,
      'proteinG': proteinG,
      'fatG': fatG,
      'name_lowercase': name.toLowerCase(),
      'keywords': keywords,
    };
  }
}
