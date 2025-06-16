import 'package:flutter/material.dart';

enum BadgeType {
  // Aktivite tabanlı rozetler
  dailyStreak, // Günlük görevleri üst üste tamamlama
  weeklyGoal, // Haftalık hedefleri tamamlama
  monthlyGoal, // Aylık hedefleri tamamlama
  yearlyGoal, // Yıllık hedefleri tamamlama

  // Antrenman tabanlı rozetler
  workoutCount, // Belirli sayıda antrenman tamamlama
  workoutStreak, // Üst üste günlerde antrenman yapma

  // Su tabanlı rozetler
  waterStreak, // Üst üste günlerde su hedefini tamamlama

  // Kilo tabanlı rozetler
  weightLoss, // Belirli miktar kilo verme
  weightGain, // Belirli miktar kilo alma
  targetWeight, // Hedef kiloya ulaşma
  maintainWeight, // Hedef kiloda kalma

  // Beslenme tabanlı rozetler
  calorieStreak, // Üst üste günlerde kalori hedefini tamamlama

  // Etkileşim tabanlı rozetler
  chatInteraction, // AI sohbet ile etkileşim

  // Genel rozetler
  beginner, // Yeni başlayan
  consistent, // Tutarlı kullanıcı
  expert, // Uzman kullanıcı
  master // Usta kullanıcı
}

enum BadgeRarity {
  common, // Yaygın (kolay kazanılan)
  uncommon, // Az yaygın
  rare, // Nadir
  epic, // Epik
  legendary, // Efsanevi (çok zor kazanılan)
  mythic // Efsanevi (neredeyse imkansız)
}

class BadgeModel {
  final int id;
  final String name;
  final String description;
  final BadgeType type;
  final BadgeRarity rarity;
  final int
      threshold; // Rozeti kazanmak için gerekli değer (örn: 7 günlük seri)
  final Color color; // Rozet rengi
  final int points; // Rozet ile kazanılan puan
  final DateTime?
      unlockedAt; // Rozetin kilidinin açıldığı tarih, null ise kilitli

  const BadgeModel({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.rarity,
    required this.threshold,
    required this.color,
    required this.points,
    this.unlockedAt,
  });

  // Rozetin kilidi açıldı mı?
  bool get isUnlocked => unlockedAt != null;

  // Rozetin kopyasını oluşturup kilidi açılmış olarak işaretleyen yardımcı metod
  BadgeModel unlock() {
    if (isUnlocked) return this;

    return BadgeModel(
      id: id,
      name: name,
      description: description,
      type: type,
      rarity: rarity,
      threshold: threshold,
      color: color,
      points: points,
      unlockedAt: DateTime.now(),
    );
  }

  // JSON'dan model oluşturma
  factory BadgeModel.fromJson(Map<String, dynamic> json) {
    return BadgeModel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      type: BadgeType.values.firstWhere(
        (e) => e.toString() == 'BadgeType.${json['type']}',
        orElse: () => BadgeType.beginner,
      ),
      rarity: BadgeRarity.values.firstWhere(
        (e) => e.toString() == 'BadgeRarity.${json['rarity']}',
        orElse: () => BadgeRarity.common,
      ),
      threshold: json['threshold'],
      color: Color(json['color']),
      points: json['points'],
      unlockedAt: json['unlockedAt'] != null
          ? DateTime.parse(json['unlockedAt'])
          : null,
    );
  }

  // Model'den JSON oluşturma
  Map<String, dynamic> toJson() {
    final typeStr = type.toString().split('.').last;
    final rarityStr = rarity.toString().split('.').last;

    return {
      'id': id,
      'name': name,
      'description': description,
      'type': typeStr,
      'rarity': rarityStr,
      'threshold': threshold,
      'color': color.value,
      'points': points,
      'unlockedAt': unlockedAt?.toIso8601String(),
    };
  }
}
