import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../services/ai_coach_service.dart';
import '../models/chat_model.dart';
import 'conversations_screen.dart';
import '../widgets/kaplan_loading.dart';

class AICoachScreen extends StatefulWidget {
  final int? conversationId; // Sohbet kimliği, null ise yeni sohbet başlatılır

  const AICoachScreen({Key? key, this.conversationId}) : super(key: key);

  @override
  State<AICoachScreen> createState() => _AICoachScreenState();
}

class _AICoachScreenState extends State<AICoachScreen> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _apiKeyController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _showApiKeyInput =
      false; // API anahtarı girişini varsayılan olarak gizli tutuyoruz
  String _apiKey =
      'YOUR_API_KEY_HERE'; // TODO: API anahtarını güvenli bir yerden al
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
    _apiKeyController.dispose();
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

  void _setApiKey() {
    if (_apiKeyController.text.trim().isNotEmpty) {
      setState(() {
        _apiKey = _apiKeyController.text.trim();
        _showApiKeyInput = false;
      });

      _addMessage(
        'API anahtarı ayarlandı. Nasıl yardımcı olabilirim?',
        false,
      );
    }
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
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) {
      return;
    }

    final databaseService =
        Provider.of<DatabaseService>(context, listen: false);
    bool conversationJustCreated = false;

    if (_conversationId == null) {
      // İlk kullanıcı mesajı, sohbeti şimdi oluştur
      conversationJustCreated = true;
      // Başlığı kullanıcı mesajının ilk kısmından oluştur
      String tempTitle = messageText.length > 30
          ? "${messageText.substring(0, 27)}..."
          : messageText;
      if (tempTitle.isEmpty) tempTitle = "Yeni Sohbet"; // Çok nadir bir durum

      final newConversation = ChatConversation(
        title:
            tempTitle, // Başlık _updateConversationTitle ile ayrıca DB'de güncellenecek
        createdAt: DateTime.now(),
        lastMessageAt: DateTime.now(), // İlk mesajla aktivite zamanı
      );

      try {
        final newConversationId =
            await databaseService.createChatConversation(newConversation);
        _conversationId = newConversationId;
        _conversationTitle = tempTitle; // UI için başlığı hemen güncelle
        debugPrint(
            "Yeni sohbet oluşturuldu ve kaydedildi. ID: $_conversationId, Başlık: $_conversationTitle");

        // Bekleyen hoş geldin mesajını şimdi kaydet (eğer varsa)
        if (_pendingWelcomeMessage != null) {
          final welcomeMessageToSave = _pendingWelcomeMessage!.copyWith(
            conversationId: _conversationId!,
          );
          // _addMessage'ı hoşgeldin mesajını DB'ye kaydetmek için doğrudan çağırmak yerine,
          // createChatMessage'i burada çağıralım ve UI'daki mesajı güncelleyelim.
          final welcomeMessageId =
              await databaseService.createChatMessage(welcomeMessageToSave);
          final savedWelcomeMessage =
              welcomeMessageToSave.copyWith(id: welcomeMessageId);

          // UI'daki geçici hoşgeldin mesajını ID'li olanla değiştir
          int welcomeIndex = _messages.indexWhere(
              (msg) => msg.text == _pendingWelcomeMessage!.text && !msg.isUser);
          if (welcomeIndex != -1 && mounted) {
            setState(() {
              _messages[welcomeIndex] = savedWelcomeMessage;
            });
          }
          _pendingWelcomeMessage = null; // Hoş geldin mesajı işlendi.
          debugPrint(
              "Bekleyen hoşgeldin mesajı kaydedildi. ID: $welcomeMessageId");
        }
      } catch (e) {
        debugPrint("Yeni sohbet veya hoşgeldin mesajı kaydedilirken hata: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Sohbet başlatılırken hata oluştu: $e')),
          );
        }
        return; // Sohbet oluşturulamazsa devam etme
      }
    }

    // Artık _conversationId'nin dolu olduğundan eminiz (ya vardı ya da yeni oluşturuldu).
    // Kullanıcının mesajını ekle (bu _addMessage zaten DB'ye yazar)
    await _addMessage(messageText, true);
    _messageController.clear();

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    // Sohbet başlığını DB'de güncelle (eğer yeni oluşturulduysa veya ilk mesajsa ve başlık varsayılansa)
    // _updateConversationTitle, _conversationId null değilse çalışır.
    if (conversationJustCreated) {
      await _updateConversationTitle(
          messageText); // Bu metod DB'deki başlığı günceller.
    }

    try {
      final AICoachService aiCoachService = AICoachService(databaseService)
        ..apiKey = _apiKey;

      final response = await aiCoachService.getCoachResponse(messageText);
      await _addMessage(
          response, false); // AI yanıtını ekle (bu da DB'ye yazar)

      await _updateConversationLastActivity(); // Sohbet aktivitesini güncelle
    } catch (e) {
      debugPrint('[AICoachScreen] AI yanıtı alınırken hata: $e');
      String errorMessage =
          "Üzgünüm, bir hata oluştu. Lütfen daha sonra tekrar deneyin.";
      if (e.toString().toLowerCase().contains("api key not valid")) {
        errorMessage = "API anahtarınız geçerli değil. Lütfen kontrol edin.";
        if (mounted) {
          setState(() => _showApiKeyInput = true);
        }
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

  Future<void> _updateConversationTitle(String userMessage) async {
    if (_conversationId == null) {
      debugPrint(
          "[AICoachScreen] Başlık güncellenemedi, _conversationId null.");
      return;
    }

    final databaseService =
        Provider.of<DatabaseService>(context, listen: false);

    String newTitle = userMessage.length > 30
        ? "${userMessage.substring(0, 27)}..."
        : userMessage;
    if (newTitle.trim().isEmpty)
      newTitle = "Sohbet"; // Kullanıcı mesajı sadece boşluk içeriyorsa

    try {
      await databaseService.updateChatConversationTitle(
        _conversationId!,
        newTitle,
      );
      if (mounted) {
        setState(() {
          _conversationTitle = newTitle;
        });
      }
      debugPrint('Konuşma başlığı veritabanında güncellendi: $newTitle');
    } catch (e) {
      debugPrint('Konuşma başlığı güncellenirken hata: $e');
    }
  }

  Future<void> _updateConversationLastActivity() async {
    if (_conversationId == null) return;
    // ... (mevcut kod)
    try {
      final databaseService =
          Provider.of<DatabaseService>(context, listen: false);
      await databaseService
          .updateChatConversationLastActivity(_conversationId!);
      print("Konuşma aktivite zamanı güncellendi. ID: $_conversationId");
    } catch (e) {
      print("Konuşma aktivite zamanı güncellenirken hata: $e");
    }
  }

  Future<void> _goToConversations() async {
    // ... (mevcut kod)
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) => const ConversationsScreen(),
      ),
    )
        .then((_) {
      // Geri dönüldüğünde, eğer bir sohbet açıksa onu yeniden yükle
      // Bu, ConversationsScreen'den bir sohbet silinmişse veya güncellenmişse faydalı olabilir.
      if (_conversationId != null) {
        _reloadCurrentConversation();
      } else {
        // Eğer aktif bir sohbet yoksa (yeni sohbet ekranıydı ve kullanıcı mesaj atmadı)
        // ve kullanıcı geri geldiyse, ekranı yeni sohbet durumuna resetleyebiliriz.
        _prepareNewConversationUI();
      }
    });
  }

  Future<void> _reloadCurrentConversation() async {
    if (_conversationId == null) {
      // Eğer yeniden yüklenecek bir ID yoksa (örneğin, yeni sohbet hiç kaydedilmediyse)
      // UI'ı yeni sohbet durumuna getirebiliriz.
      _prepareNewConversationUI();
      return;
    }
    // ... (mevcut kodun devamı, _conversationId null değilse çalışır)
    // ...
    setState(() => _isLoading = true); // Yüklemeyi başlat
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
        // Sohbet DB'de bulunamadı (belki silindi), UI'ı yeni sohbete resetle.
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
    // AppBar'daki + butonu
    // Kullanıcıyı yeni, boş bir AICoachScreen'e yönlendir.
    // Mevcut ekranın state'i korunur, Navigator stack'ine yeni bir sayfa eklenir.
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            const AICoachScreen(), // Yeni bir instance, conversationId = null
      ),
    );
  }

  Future<void> _startNewConversation() async {
    // Sohbet silindikten sonra çağrılır
    if (mounted) {
      setState(() {
        _prepareNewConversationUI(); // UI'ı temizle ve geçici hoşgeldin mesajını göster
      });
      FocusScope.of(context).unfocus();
      debugPrint("Yeni sohbet UI'da başlatıldı (silme sonrası).");
    }
  }

  // ... (deleteConversation, build ve diğer widget metodları mevcut halleriyle kalabilir)
  // _buildMessageBubble, _buildMessageInput, _buildApiKeyInput, _listModels

  Future<void> _deleteConversation(int conversationId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sohbeti Sil'),
        content: Text(
            'Bu sohbeti ve içindeki tüm mesajları silmek istiyor musunuz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final databaseService =
            Provider.of<DatabaseService>(context, listen: false);
        await databaseService.deleteChatConversation(conversationId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Sohbet silindi')),
          );
          // Eğer silinen sohbet şu an açık olan sohbetse, ekranı yeni sohbet moduna al
          if (_conversationId == conversationId) {
            _startNewConversation();
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Sohbet silinirken hata: $e')),
          );
        }
      }
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
          if (_showApiKeyInput) _buildApiKeyInput(),
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

  Widget _buildApiKeyInput() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, 1),
            blurRadius: 2.0,
            color: Colors.black.withOpacity(0.1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Gemini API Anahtarı',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _apiKeyController,
                  decoration: const InputDecoration(
                    hintText:
                        'Google AI Studio\'dan API anahtarınızı yapıştırın',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  ),
                  obscureText: true,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _setApiKey,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                ),
                child: const Text('Kaydet'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Not: Gemini API anahtarınızı aistudio.google.com/app/apikey adresinden alabilirsiniz.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ],
          ),
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
            color: Colors.black.withOpacity(0.1),
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

  Future<void> _listModels() async {
    if (_conversationId == null) {
      debugPrint(
          "[AICoachScreen] _listModels: Sohbet kalıcı değil. Modeller listelenemiyor/DB'ye yazılamaz.");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Model listesini görmek için önce bir mesaj göndererek sohbeti başlatın.')),
        );
      }
      return;
    }
    final databaseService =
        Provider.of<DatabaseService>(context, listen: false);
    final AICoachService aiCoachService = AICoachService(databaseService)
      ..apiKey = _apiKey;
    if (mounted) setState(() => _isLoading = true);
    try {
      final modelsList = await aiCoachService.listAvailableModels();
      await _addMessage(modelsList, false);
    } catch (e) {
      await _addMessage("Modeller listelenirken hata: $e", false);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
