import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../services/ai_coach_service.dart';
import '../models/chat_model.dart';
import '../providers/user_provider.dart';
import '../providers/gamification_provider.dart';
import 'conversations_screen.dart';
import '../widgets/kaplan_loading.dart';

class AICoachScreen extends StatefulWidget {
  final int? conversationId; // Sohbet kimliği, null ise yeni sohbet başlatılır

  const AICoachScreen({Key? key, this.conversationId}) ;

  @override
  State<AICoachScreen> createState() => _AICoachScreenState();
}

class _AICoachScreenState extends State<AICoachScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  int? _conversationId;
  String _conversationTitle = 'Yeni Sohbet';
  ChatMessage?
      _pendingWelcomeMessage; // Kullanıcı ilk mesajını gönderene kadar bekletilecek hoş geldin mesajı

  @override
  void initState() {
    super.initState();
    _conversationId = widget.conversationId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeChat();
    });
  }

  Future<void> _initializeChat() async {
    setState(() {
      _isLoading = true;
    });

    final databaseService =
        Provider.of<DatabaseService>(context, listen: false);

    try {
      if (widget.conversationId != null) {
        // Mevcut bir sohbet ID'si varsa
        _conversationId = widget.conversationId;
        final conversation =
            await databaseService.getChatConversation(_conversationId!);
        if (conversation != null) {
          _conversationTitle = conversation.title;
          final chatMessages = await databaseService
              .getMessagesForConversation(_conversationId!);
          debugPrint('Veritabanından ${chatMessages.length} mesaj yüklendi');
          chatMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          setState(() {
            _messages = chatMessages;
          });
        } else {
          // Mevcut conversationId ile sohbet bulunamadıysa, yeni sohbet gibi davran
          debugPrint(
              'Uyarı: ${widget.conversationId} ID\'li konuşma bulunamadı, yeni sohbet başlatılıyor.');
          _conversationId = null; // ID'yi sıfırla
          _prepareNewConversationUI();
        }
      } else {
        // Yeni sohbet durumu
        _prepareNewConversationUI();
      }
    } catch (e) {
      debugPrint('Sohbet yüklenirken hata: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sohbet yüklenirken hata oluştu: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        if (_messages.isNotEmpty) {
          _scrollToBottom();
        }
      }
    }
  }

  void _prepareNewConversationUI() {
    _conversationId = null; // Henüz DB'de yok
    _conversationTitle = 'Yeni Sohbet';
    _messages = []; // Mesaj listesini temizle
    _pendingWelcomeMessage = ChatMessage(
      // conversationId daha sonra atanacak
      conversationId: -1, // Geçici, DB'ye yazılmadan önce güncellenecek
      text:
          'Merhaba! AI Koçun olarak beslenme ve spor konularında sorularını yanıtlamaya hazırım.',
      isUser: false,
      timestamp: DateTime.now(),
    );
    if (mounted) {
      setState(() {
        _messages.add(_pendingWelcomeMessage!);
      });
    }
    debugPrint('Yeni sohbet UI için hazırlandı (henüz kaydedilmedi).');
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _addMessage(String text, bool isUser) async {
    if (isUser && text.trim().isEmpty) {
      debugPrint(
          "[AICoachScreen] Boş kullanıcı mesajı gönderilmeyecek ve kaydedilmeyecek.");
      return;
    }

    // Eğer sohbet henüz veritabanına kaydedilmemişse (yani _conversationId null ise)
    // ve bu bir AI mesajıysa, bu mesajı veritabanına kaydetme, sadece UI'da göster.
    // Kullanıcı mesajları bu kontrolden önce _sendMessage içinde _conversationId'yi oluşturur.
    if (_conversationId == null && !isUser) {
      debugPrint(
          "[AICoachScreen] Sohbet kalıcı değil, AI mesajı sadece UI'da gösterilecek: '$text'");
      // Sadece UI için geçici mesaj ekle (eğer zaten _pendingWelcomeMessage değilse)
      // Bu senaryo _setApiKey veya _listModels'den gelen AI mesajları için olabilir.
      // Bu mesajlar hoşgeldin mesajı gibi _pendingWelcomeMessage üzerinden yönetilmiyor.
      // Bu AI mesajlarının da geçici bir listede tutulup, sohbet kalıcı olunca DB'ye yazılması daha doğru olur.
      // Şimdilik basit tutmak için, bu tür AI mesajları sohbet kalıcı olmadan DB'ye yazılmaz.
      // Ve UI'da gösterilmeleri için _messages listesine eklenmeleri gerekir.
      final tempAIMessage = ChatMessage(
          conversationId: -1,
          text: text,
          isUser: isUser,
          timestamp: DateTime.now());
      if (mounted) {
        setState(() {
          _messages.add(tempAIMessage);
        });
        _scrollToBottom();
      }
      return;
    }

    // Eğer _conversationId hala null ise (kullanıcı mesajı için bu olmamalı, _sendMessage'de set edilir)
    // bir sorun var demektir, veya bu AI mesajı için sohbet henüz başlatılmamış.
    if (_conversationId == null && isUser) {
      debugPrint(
          "[AICoachScreen_addMessage] HATA: Kullanıcı mesajı için _conversationId null olmamalı.");
      return; // Kullanıcı mesajıysa ve ID yoksa bir şeyler ters gitmiştir.
    }
    // _conversationId null ise ve bu AI mesajıysa yukarıdaki blokta handle edildi.

    final databaseService =
        Provider.of<DatabaseService>(context, listen: false);

    final message = ChatMessage(
      conversationId:
          _conversationId!, // Bu noktada _conversationId'nin dolu olması beklenir.
      text: text,
      isUser: isUser,
      timestamp: DateTime.now(),
    );

    try {
      final messageId = await databaseService.createChatMessage(message);
      final savedMessage = message.copyWith(id: messageId);

      if (mounted) {
        // Eğer bu AI mesajı daha önce geçici olarak eklendiyse onu listeden çıkarıp ID'li olanı ekle.
        // Bu, _setApiKey veya _listModels gibi fonksiyonlardan gelen AI mesajları için geçerli olabilir.
        // Ancak mevcut mantıkta (_conversationId == null && !isUser) bloğu DB'ye yazmadan return ediyor.
        // Bu yüzden burada mükerrer ekleme olmamalı.
        // Sadece yeni mesajı ekle.

        // Eğer eklenen mesaj, daha önce UI'da gösterilen geçici bir AI mesajıysa,
        // onu listeden bulup ID ile güncellemek daha doğru olabilir.
        // Şimdilik, eğer _conversationId null iken AI mesajı geldiyse, o zaten yukarıda eklenip return edilmişti.
        // Bu blok sadece _conversationId var ve DB'ye yazıldıysa çalışır.

        // Daha önce eklenen geçici AI mesajını listeden kaldıralım (varsa)
        // Bu, özellikle _setApiKey ve _listModels için geçerli.
        // Onlar _addMessage'ı _conversationId null iken çağırabilir.
        // O durumda mesaj UI'ya eklenir, DB'ye yazılmaz.
        // Sohbet kalıcı olduktan sonra bu mesajlar tekrar _addMessage ile çağrılırsa ne olur?
        // Bu senaryo karmaşık. _setApiKey ve _listModels'in _addMessage'ı sohbet kalıcı olduktan sonra çağırması daha iyi.
        // Şimdilik, _addMessage'ın _conversationId null ise AI mesajlarını DB'ye yazmadığını varsayıyoruz.

        // Eğer bu mesaj pendingWelcomeMessage ise ve şimdi ID aldıysa, UI'daki mesajı güncelle.
        int existingMessageIndex = -1;
        if (!isUser &&
            _pendingWelcomeMessage != null &&
            _pendingWelcomeMessage!.text == text) {
          existingMessageIndex = _messages.indexWhere((m) =>
              m.text == _pendingWelcomeMessage!.text &&
              !m.isUser &&
              m.id == null);
        }

        setState(() {
          if (existingMessageIndex != -1) {
            _messages[existingMessageIndex] =
                savedMessage; // ID'li olanla değiştir
            _pendingWelcomeMessage = null; // Hoşgeldin mesajı işlendi.
          } else {
            // Daha önce UI'ya eklenmemişse (örneğin kullanıcı mesajı veya hoşgeldin mesajı dışındaki AI mesajı)
            // ya da UI'da zaten ID'li olarak varsa (bu olmamalı)
            // Geçici AI mesajlarını (_conversationId null iken eklenenler) listeden temizleyip, DB'den gelenleri almak daha sağlam olabilir.
            _messages.add(savedMessage);
          }
        });
        _scrollToBottom();
      }

      final logText = text.length > 50 ? "${text.substring(0, 47)}..." : text;
      debugPrint(
          "[AICoachScreen] Mesaj (isUser: $isUser) veritabanına kaydedildi. ID: $messageId, Text: '$logText'");
    } catch (e) {
      debugPrint("[AICoachScreen] Mesaj kaydedilirken hata: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mesaj kaydedilirken bir hata oluştu: $e')),
        );
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUser = userProvider.user;
    final gamificationProvider =
        Provider.of<GamificationProvider>(context, listen: false);

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kullanıcı bilgisi bulunamadı.')),
      );
      return;
    }

    _messageController.clear();
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    final databaseService =
        Provider.of<DatabaseService>(context, listen: false);
    final aiCoachService = AICoachService(
      databaseService,
      gamificationProvider,
    );

    int currentConversationId;

    if (_conversationId == null && _pendingWelcomeMessage != null) {
      final newConversation = ChatConversation(
        userId: currentUser.id!,
        title: 'Yeni Sohbet', // Başlık daha sonra ilk mesajdan alınacak
        createdAt: DateTime.now(), // createdAt eklendi
        lastMessageAt: DateTime.now(),
      );
      _conversationId =
          await databaseService.createChatConversation(newConversation);
      debugPrint(
          'Yeni sohbet oluşturuldu ve kaydedildi. ID: $_conversationId, Başlık: ${newConversation.title}');

      _pendingWelcomeMessage =
          _pendingWelcomeMessage!.copyWith(conversationId: _conversationId);
      await databaseService.createChatMessage(_pendingWelcomeMessage!);
      debugPrint(
          'Bekleyen hoşgeldin mesajı kaydedildi. ID: ${_pendingWelcomeMessage!.id}');
    }
    currentConversationId = _conversationId!;

    await _addMessage(text, true);
    debugPrint(
        '[AICoachScreen] Mesaj (isUser: true) veritabanına kaydedildi. ID: (bilinmiyor, _addMessage içinde loglanır), Text: \'$text\'');

    if (currentUser.id != null) {
      await gamificationProvider.recordChatInteraction(currentUser.id!);
      debugPrint(
          '[AICoachScreen] Recorded chat interaction for user ${currentUser.id}');
    }

    if (_conversationTitle == 'Yeni Sohbet' || _conversationId == null) {
      final newTitle = text.length > 50 ? '${text.substring(0, 47)}...' : text;
      await databaseService.updateChatConversationTitle(
          currentConversationId, newTitle);
      _conversationTitle = newTitle;
      debugPrint('Konuşma başlığı veritabanında güncellendi: $newTitle');
    }

    try {
      final response = await aiCoachService.getCoachResponse(text, currentUser);
      await _addMessage(response, false);

      await _updateConversationLastActivity();
    } catch (e) {
      debugPrint('[AICoachScreen] AI yanıtı alınırken hata: $e');
      String errorMessage =
          "Üzgünüm, bir hata oluştu. Lütfen daha sonra tekrar deneyin.";
      if (e.toString().toLowerCase().contains("api key not valid")) {
        errorMessage =
            "API anahtarınız geçerli değil. Lütfen ai_coach_service.dart dosyasındaki API anahtarınızı kontrol edin.";
      } else if (e.toString().toLowerCase().contains("quota") ||
          e.toString().toLowerCase().contains("rate limit")) {
        errorMessage =
            "API kullanım limitinize ulaştınız veya istek hız sınırını aştınız. Lütfen daha sonra tekrar deneyin.";
      }
      await _addMessage(errorMessage, false);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateConversationLastActivity() async {
    if (_conversationId == null) return;
    try {
      final databaseService =
          Provider.of<DatabaseService>(context, listen: false);
      await databaseService
          .updateChatConversationLastActivity(_conversationId!);
      debugPrint("Konuşma aktivite zamanı güncellendi. ID: $_conversationId");
    } catch (e) {
      debugPrint("Konuşma aktivite zamanı güncellenirken hata: $e");
    }
  }

  Future<void> _goToConversations() async {
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) => const ConversationsScreen(),
      ),
    )
        .then((_) {
      if (_conversationId != null) {
        _reloadCurrentConversation();
      } else {
        _prepareNewConversationUI();
      }
    });
  }

  Future<void> _reloadCurrentConversation() async {
    if (_conversationId == null) {
      _prepareNewConversationUI();
      return;
    }
    setState(() => _isLoading = true);
    try {
      final databaseService =
          Provider.of<DatabaseService>(context, listen: false);
      final conversation =
          await databaseService.getChatConversation(_conversationId!);

      if (conversation != null) {
        final chatMessages =
            await databaseService.getMessagesForConversation(_conversationId!);

        if (mounted) {
          setState(() {
            _conversationTitle = conversation.title;
            _messages = chatMessages
              ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
            _isLoading = false;
          });
          _scrollToBottom();
        }
      } else {
        if (mounted) {
          debugPrint(
              "Reload: $_conversationId ID'li sohbet DB'de bulunamadı. Yeni sohbete geçiliyor.");
          _prepareNewConversationUI();
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      debugPrint('Konuşma yeniden yüklenirken hata: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Sohbet yeniden yüklenirken bir hata oluştu.')),
        );
      }
    }
  }

  Future<void> _createNewConversation() async {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AICoachScreen(),
      ),
    );
  }

  Future<void> _startNewConversation() async {
    if (mounted) {
      setState(() {
        _prepareNewConversationUI();
      });
      FocusScope.of(context).unfocus();
      debugPrint("Yeni sohbet UI'da başlatıldı (silme sonrası).");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_conversationTitle),
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _createNewConversation,
            tooltip: 'Yeni sohbet',
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: _goToConversations,
            tooltip: 'Tüm sohbetler',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading && _messages.isEmpty
                ? const KaplanLoading()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(8.0),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return _buildMessageBubble(message);
                    },
                  ),
          ),
          if (_isLoading && _messages.isNotEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: KaplanLoading(size: 40.0),
            ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 14.0),
        decoration: BoxDecoration(
          color: message.isUser
              ? Theme.of(context).primaryColor
              : Colors.grey[300],
          borderRadius: BorderRadius.circular(18.0),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: message.isUser ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 4.0),
            Text(
              message.formattedTime,
              style: TextStyle(
                color: message.isUser ? Colors.white70 : Colors.black54,
                fontSize: 12.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -2),
            blurRadius: 2.0,
            color: Colors.black.withValues(alpha:0.1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: 'Mesajınızı yazın...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(25.0)),
                ),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8.0),
          FloatingActionButton(
            onPressed: _sendMessage,
            backgroundColor: Theme.of(context).primaryColor,
            elevation: 2.0,
            child: const Icon(Icons.send),
          ),
        ],
      ),
    );
  }
}
