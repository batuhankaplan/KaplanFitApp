import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';

class FeedbackService {
  // EmailJS kimliklerinizi buraya girin
  final String serviceId = 'service_73qbwr5'; // Örn: service_xyz789
  final String templateId = 'template_ok94zsw'; // Örn: template_abc123
  final String publicKey = 'ETzLN0EqxzmV-XlOp'; // Örn: user_def456

  Future<bool> sendFeedback(String name, String email, String message) async {
    try {
      // Alternatif 1: Standart EmailJS API kullanımı
      return await _sendWithStandardApi(name, email, message);
    } catch (e, stackTrace) {
      print('EmailJS entegrasyonu hatası: $e');
      print('Hata ayrıntıları: $stackTrace');
      return false;
    }
  }

  // Standart EmailJS API kullanımı
  Future<bool> _sendWithStandardApi(String name, String email, String message) async {
    final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
    
    // EmailJS'nin resmi dokümantasyonundaki format
    final Map<String, dynamic> requestBody = {
      'service_id': serviceId,
      'template_id': templateId,
      'user_id': publicKey, // Bazı eski sürümlerde user_id kullanılıyor
      'template_params': {
        'from_name': name,
        'reply_to': email,
        'user_email': email, // Şablonda kullanılan değişken adı değiştirildi
        'from_email': email,
        'email': email, // Her olasılığı deniyoruz
        'sender_email': email, // Her olasılığı deniyoruz
        'to_email': 'yzbatuhankaplan@outlook.com', // Doğru alıcı adresi
        'message': message,
      }
    };
    
    print('EmailJS isteği (Standart): ${json.encode(requestBody)}');
    
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Origin': 'http://localhost',
      },
      body: json.encode(requestBody),
    );
    
    print('EmailJS yanıt kodu: ${response.statusCode}');
    print('EmailJS yanıt içeriği: ${response.body}');
    
    if (response.statusCode != 200) {
      print('EmailJS hata detayları: ${response.body}');
      
      // Alternatif yöntemi deneyelim
      print('Alternatif EmailJS yöntemi deneniyor...');
      return await _sendWithAlternativeApi(name, email, message);
    }
    
    return true;
  }
  
  // Alternatif EmailJS API kullanımı (yeni sürüm)
  Future<bool> _sendWithAlternativeApi(String name, String email, String message) async {
    final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
    
    // Alternatif format (yeni API'de kullanılan)
    final Map<String, dynamic> requestBody = {
      'service_id': serviceId,
      'template_id': templateId,
      'accessToken': publicKey, // accessToken olarak deneyelim
      'template_params': {
        'from_name': name,
        'reply_to': email, 
        'user_email': email, // Şablonda kullanılan değişken adı değiştirildi
        'from_email': email,
        'email': email, // Her olasılığı deniyoruz
        'sender_email': email, // Her olasılığı deniyoruz
        'to_email': 'yzbatuhankaplan@outlook.com', // Doğru alıcı adresi
        'message': message,
      }
    };
    
    print('EmailJS isteği (Alternatif): ${json.encode(requestBody)}');
    
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Origin': 'http://localhost',
      },
      body: json.encode(requestBody),
    );
    
    print('Alternatif EmailJS yanıt kodu: ${response.statusCode}');
    print('Alternatif EmailJS yanıt içeriği: ${response.body}');
    
    return response.statusCode == 200;
  }
} 