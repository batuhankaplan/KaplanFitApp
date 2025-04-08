import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../services/database_service.dart';
import '../../services/program_service.dart';
import '../activity_record.dart';
import '../meal_record.dart';
import '../chat_model.dart';

class DatabaseProvider extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  final ProgramService _programService = ProgramService();

  List<ActivityRecord> _activities = [];
  List<MealRecord> _meals = [];
  String? _userGoalMessage;
  bool _isInitialized = false;

  // Daha önce gösterilmiş ve kaydedilmiş mesaj ID'leri
  final Set<int> _existingConversationIds = {};

  ProgramService get programService => _programService;

  List<ActivityRecord> get activities => _activities;
  List<MealRecord> get meals => _meals;
  String? get userGoalMessage => _userGoalMessage;
  bool get isInitialized => _isInitialized;

  // Getter for accessing the database service
  DatabaseService get database => _databaseService;

  DatabaseProvider() {
    initialize();
  }

  // Veritabanını başlatmak için gerekli metod
  Future<void> initialize() async {
    if (!_isInitialized) {
      // Veritabanını başlat - açıkça await kullanarak başlatıyoruz
      await _databaseService.database;
      await _loadExistingConversations();
      _isInitialized = true;
      notifyListeners();
    }
  }

  @override
  void notifyListeners() {
    super.notifyListeners();
    print('DatabaseProvider: Listeners notified');
  }

  // Mevcut konuşmaları yükleyerek başlat
  Future<void> _loadExistingConversations() async {
    try {
      // Tüm konuşmaları getir
      final conversations = await _databaseService.getAllChatConversations();

      // Her konuşmayı kontrol et, boş olanları temizle
      for (final conversation in conversations) {
        if (conversation.id != null) {
          // Bu konuşmada kaç mesaj var
          final messages = await _databaseService
              .getMessagesForConversation(conversation.id!);

          // Kullanıcı tarafından mesaj yazılmış mı kontrol et (hoşgeldin mesajı dışında mesaj var mı)
          final hasUserMessage = messages.any((message) => message.isUser);

          // Hoşgeldin mesajı hariç toplam mesaj sayısı 2'den az ise boş konuşma kabul et
          final effectiveMessageCount = messages
              .where((msg) =>
                  msg.isUser ||
                  !msg.text.contains('AI Koçun olarak beslenme ve spor'))
              .length;

          if (hasUserMessage && effectiveMessageCount >= 2) {
            // Aktif ve içerikli bir sohbet var, ID'sini kaydet
            _existingConversationIds.add(conversation.id!);
            debugPrint("Geçerli konuşma bulundu: ${conversation.id}");
          } else {
            // Kullanıcı mesajı yoksa veya sadece hoşgeldin mesajı varsa, bu konuşmayı sil
            if (conversation.id != null) {
              await _databaseService.deleteChatConversation(conversation.id!);
              debugPrint("Boş konuşma silindi: ${conversation.id}");
            }
          }
        }
      }

      debugPrint("${_existingConversationIds.length} aktif konuşma yüklendi");
    } catch (e) {
      debugPrint("Konuşmalar yüklenirken hata: $e");
    }
  }

  // Bir konuşmada kullanıcı mesajı var mı kontrol et
  Future<bool> hasUserMessages(int conversationId) async {
    try {
      final messages =
          await _databaseService.getMessagesForConversation(conversationId);
      return messages.any((message) => message.isUser);
    } catch (e) {
      debugPrint("Kullanıcı mesajı kontrolünde hata: $e");
      return false;
    }
  }

  // Boş konuşmaları temizle (sadece AI mesajı olanlar)
  Future<void> cleanEmptyConversations() async {
    try {
      final conversations = await _databaseService.getAllChatConversations();

      for (final conversation in conversations) {
        if (conversation.id != null) {
          final hasUserMsg = await hasUserMessages(conversation.id!);

          if (!hasUserMsg) {
            await _databaseService.deleteChatConversation(conversation.id!);
            debugPrint("Temizleme: Boş konuşma silindi: ${conversation.id}");
          }
        }
      }
    } catch (e) {
      debugPrint("Boş konuşma temizleme hatası: $e");
    }
  }

  // Bu konuşma ID'si daha önce gösterilmiş mi
  bool isExistingConversation(int conversationId) {
    return _existingConversationIds.contains(conversationId);
  }

  // Yeni açılan konuşmayı kaydet
  void addExistingConversation(int conversationId) {
    _existingConversationIds.add(conversationId);
  }
}
