import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ai_coach_service.dart';
import '../models/providers/database_provider.dart';
import '../models/chat_model.dart';
import 'conversations_screen.dart';

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
  bool _showApiKeyInput = false; // API anahtarı girişini varsayılan olarak gizli tutuyoruz
  String _apiKey = 'AIzaSyB5c4nbG1J7842wkmESVt0tUgD2I-Ey3M8';
  int? _conversationId;
  String _conversationTitle = 'Yeni Sohbet';
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _conversationId = widget.conversationId;
    // Kolay erişim için mevcut _messages listesini kullanıyoruz,
    // ama ChatMessage tipinde nesnelere dönüştürüyoruz
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeChat();
    });
  }

  Future<void> _initializeChat() async {
    if (_isInitialized) return;
    
    setState(() {
      _isLoading = true;
    });
    
    final databaseProvider = Provider.of<DatabaseProvider>(context, listen: false);
    
    try {
      if (_conversationId != null) {
        // Mevcut sohbeti yükle
        final conversation = await databaseProvider.database.getChatConversation(_conversationId!);
        if (conversation != null) {
          _conversationTitle = conversation.title;
          final chatMessages = await databaseProvider.database.getMessagesForConversation(_conversationId!);
          
          setState(() {
            _messages = chatMessages;
          });
        }
      } else {
        // Yeni sohbet oluştur
        final now = DateTime.now();
        final newConversation = ChatConversation(
          title: _conversationTitle,
          createdAt: now,
        );
        
        final newConversationId = await databaseProvider.database.createChatConversation(newConversation);
        _conversationId = newConversationId;
        
        // Hoşgeldin mesajını ekle
        final welcomeMessage = ChatMessage(
          conversationId: newConversationId,
          text: 'Merhaba! AI Koçun olarak beslenme ve spor konularında sorularını yanıtlamaya hazırım.',
          isUser: false,
          timestamp: now,
        );
        
        await databaseProvider.database.createChatMessage(welcomeMessage);
        setState(() {
          _messages.add(welcomeMessage);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sohbet yüklenirken hata oluştu: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
        _isInitialized = true;
      });
      
      // Mesajlar yüklendikten sonra en alta kaydır
      if (_messages.isNotEmpty) {
        _scrollToBottom();
      }
    }
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
      
      // API anahtarı ayarlandı mesajını ekle
      _addMessage(
        'API anahtarı ayarlandı. Nasıl yardımcı olabilirim?',
        false,
      );
    }
  }

  // Kullanıcının ya da AI'ın mesajını mesaj listesine ve veri tabanına ekle
  Future<void> _addMessage(String text, bool isUser) async {
    if (_conversationId == null) return;
    
    final databaseProvider = Provider.of<DatabaseProvider>(context, listen: false);
    
    final message = ChatMessage(
      conversationId: _conversationId!,
      text: text,
      isUser: isUser,
      timestamp: DateTime.now(),
    );
    
    try {
      // Mesajı veritabanına ekle
      final messageId = await databaseProvider.database.createChatMessage(message);
      
      // Mesajı UI'da göster
      setState(() {
        _messages.add(message);
      });
      
      _scrollToBottom();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mesaj kaydedilirken hata oluştu: $e')),
      );
    }
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;

    // Kullanıcı mesajını ekle
    await _addMessage(messageText, true);
    _messageController.clear();

    setState(() {
      _isLoading = true;
    });

    // AI yanıtını al
    try {
      final databaseProvider = Provider.of<DatabaseProvider>(context, listen: false);
      final AICoachService aiCoachService = AICoachService(databaseProvider.database)
        ..apiKey = _apiKey;
      
      final response = await aiCoachService.getCoachResponse(messageText);
      
      // AI yanıtını ekle
      await _addMessage(response, false);
    } catch (e) {
      // Hata mesajını ekle
      await _addMessage("Üzgünüm, bir hata oluştu: $e", false);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _goToConversations() async {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ConversationsScreen(),
      ),
    ).then((_) {
      // Konuşma ekranından döndükten sonra güncel bilgileri yükle
      _reloadCurrentConversation();
    });
  }

  Future<void> _reloadCurrentConversation() async {
    if (_conversationId == null) return;
    
    try {
      final databaseProvider = Provider.of<DatabaseProvider>(context, listen: false);
      final conversation = await databaseProvider.database.getChatConversation(_conversationId!);
      
      if (conversation != null) {
        setState(() {
          _conversationTitle = conversation.title;
        });
      }
    } catch (e) {
      // Sessizce devam et
    }
  }

  Future<void> _createNewConversation() async {
    try {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const AICoachScreen(),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Yeni sohbet oluşturulurken hata: $e')),
      );
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
                ? const Center(child: CircularProgressIndicator())
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
              child: Center(
                child: CircularProgressIndicator(),
              ),
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
                    hintText: 'Google AI Studio\'dan API anahtarını yapıştır',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Not: Gemini API anahtarını https://aistudio.google.com/app/apikey adresinden alabilirsiniz.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              TextButton(
                onPressed: _listModels,
                child: const Text('Modelleri Listele'),
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
                contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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

  // Kullanılabilir modelleri listelemek için metot
  Future<void> _listModels() async {
    // API anahtarı kontrolünü kaldırıyoruz
    
    final databaseProvider = Provider.of<DatabaseProvider>(context, listen: false);
    final AICoachService aiCoachService = AICoachService(databaseProvider.database)
      ..apiKey = _apiKey;
      
    final modelsList = await aiCoachService.listAvailableModels();
    
    // Modeller mesajını ekle
    await _addMessage(modelsList, false);
  }
} 