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
  String _apiKey = 'AIzaSyB5c4nbG1J7842wkmESVt0tUgD2I-Ey3M8';
  int? _conversationId;
  String _conversationTitle = 'Yeni Sohbet';

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
      if (_conversationId != null) {
        final conversation =
            await databaseService.getChatConversation(_conversationId!);
        if (conversation != null) {
          _conversationTitle = conversation.title;

          final chatMessages = await databaseService
              .getMessagesForConversation(_conversationId!);

          debugPrint('Veritabanından ${chatMessages.length} mesaj yüklendi');

          final hasUserMessage = chatMessages.any((message) => message.isUser);

          chatMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

          setState(() {
            _messages = chatMessages;
          });
        } else {
          debugPrint('Uyarı: $_conversationId ID\'li konuşma bulunamadı');
          await _createNewConversationInDatabase();
        }
      } else {
        await _createNewConversationInDatabase();
      }
    } catch (e) {
      debugPrint('Sohbet yüklenirken hata: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sohbet yüklenirken hata oluştu: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });

      if (_messages.isNotEmpty) {
        _scrollToBottom();
      }
    }
  }

  Future<void> _createNewConversationInDatabase() async {
    final databaseService =
        Provider.of<DatabaseService>(context, listen: false);
    final now = DateTime.now();

    final newTitle = 'Yeni Sohbet';

    final newConversation = ChatConversation(
      title: newTitle,
      createdAt: now,
    );

    final newConversationId =
        await databaseService.createChatConversation(newConversation);

    setState(() {
      _conversationId = newConversationId;
      _conversationTitle = newTitle;
    });

    final welcomeMessage = ChatMessage(
      conversationId: newConversationId,
      text:
          'Merhaba! AI Koçun olarak beslenme ve spor konularında sorularını yanıtlamaya hazırım.',
      isUser: false,
      timestamp: now,
    );

    await databaseService.createChatMessage(welcomeMessage);

    setState(() {
      _messages.add(welcomeMessage);
    });

    debugPrint(
        'Yeni konuşma oluşturuldu. ID: $newConversationId, Başlık: $newTitle');
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
    if (_conversationId == null) return;

    final databaseService =
        Provider.of<DatabaseService>(context, listen: false);

    final message = ChatMessage(
      conversationId: _conversationId!,
      text: text,
      isUser: isUser,
      timestamp: DateTime.now(),
    );

    try {
      final messageId = await databaseService.createChatMessage(message);

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

    await _addMessage(messageText, true);
    _messageController.clear();

    setState(() {
      _isLoading = true;
    });

    if (_conversationId != null &&
        _messages.length <= 2 &&
        _conversationTitle.startsWith('Yeni Sohbet')) {
      _updateConversationTitle(messageText);
    }

    try {
      final databaseService =
          Provider.of<DatabaseService>(context, listen: false);
      final AICoachService aiCoachService = AICoachService(databaseService)
        ..apiKey = _apiKey;

      final response = await aiCoachService.getCoachResponse(messageText);

      await _addMessage(response, false);
    } catch (e) {
      debugPrint('AI yanıtı alınırken hata: $e');

      await _addMessage("Üzgünüm, bir hata oluştu: $e", false);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateConversationTitle(String userMessage) async {
    if (_conversationId == null) return;

    final databaseService =
        Provider.of<DatabaseService>(context, listen: false);

    // Başlığı kullanıcı mesajının ilk 30 karakteri yapalım
    String newTitle = userMessage.length > 30
        ? "${userMessage.substring(0, 27)}..."
        : userMessage;

    try {
      await databaseService.updateChatConversationTitle(
        _conversationId!,
        newTitle,
      );
      setState(() {
        _conversationTitle = newTitle;
      });
      debugPrint('Konuşma başlığı güncellendi: $newTitle');
    } catch (e) {
      debugPrint('Konuşma başlığı güncellenirken hata: $e');
      // Hata durumunda başlık güncellenmez, kullanıcı bilgilendirilmez
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
      _reloadCurrentConversation();
    });
  }

  Future<void> _reloadCurrentConversation() async {
    if (_conversationId == null) return;

    try {
      final databaseService =
          Provider.of<DatabaseService>(context, listen: false);
      final conversation =
          await databaseService.getChatConversation(_conversationId!);

      if (conversation != null) {
        final chatMessages =
            await databaseService.getMessagesForConversation(_conversationId!);

        setState(() {
          _conversationTitle = conversation.title;
          _messages = chatMessages;
        });

        if (_messages.isNotEmpty) {
          _scrollToBottom();
        }
      }
    } catch (e) {
      debugPrint('Konuşma yeniden yüklenirken hata: $e');
    }
  }

  Future<void> _createNewConversation() async {
    try {
      Navigator.of(context)
          .push(
        MaterialPageRoute(
          builder: (context) => const AICoachScreen(),
        ),
      )
          .then((_) {
        if (_conversationId != null) {
          _reloadCurrentConversation();
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Yeni sohbet oluşturulurken hata: $e')),
      );
    }
  }

  Future<void> _startNewConversation() async {
    setState(() {
      _conversationId = null;
      _messages = [];
      _conversationTitle = 'Yeni Sohbet';
    });
    FocusScope.of(context).unfocus();
    print("Yeni sohbet başlatıldı.");
  }

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
        if (_conversationId == conversationId) {
          await _startNewConversation();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sohbet silindi')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sohbet silinirken hata: $e')),
        );
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
                    hintText: 'Google AI Studio\'dan API anahtarını yapıştır',
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
    final databaseService =
        Provider.of<DatabaseService>(context, listen: false);
    final AICoachService aiCoachService = AICoachService(databaseService)
      ..apiKey = _apiKey;

    final modelsList = await aiCoachService.listAvailableModels();

    await _addMessage(modelsList, false);
  }
}
