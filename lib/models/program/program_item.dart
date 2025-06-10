import 'package:flutter/material.dart';

/// Bir program öğesini temsil eden model sınıfı.
class ProgramItem {
  /// Başlık (örn: "Sabah Programı")
  final String title;
  
  /// Açıklama (örn: "08:45 - 09:15 yüzme")
  final String description;
  
  /// İkon
  final IconData icon;
  
  /// Arka plan rengi
  final Color color;
  
  /// Zaman dilimi (sabah, öğle, akşam)
  final ProgramTimeSlot timeSlot;
  
  const ProgramItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.timeSlot,
  });
}

/// Program öğesinin zaman dilimini belirtir
enum ProgramTimeSlot {
  morning,
  lunch,
  evening,
  dinner,
} 
