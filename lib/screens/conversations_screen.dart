import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chat_model.dart';
import '../services/database_service.dart';
import '../models/providers/database_provider.dart';
import 'ai_coach_screen.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({Key? key}) : super(key: key);

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  List<ChatConversation> _conversations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _createTablesIfNeeded();
    _loadConversations();
  }

  Future<void> _createTablesIfNeeded() async {
    try {
      final databaseProvider = Provider.of<DatabaseProvider>(context, listen: false);
      final db = await databaseProvider.database.database;
      
      await db.execute('''
        CREATE TABLE IF NOT EXISTS chat_conversations(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          createdAt INTEGER NOT NULL,
          lastMessageAt INTEGER
        )
      ''');
      
      await db.execute('''
        CREATE TABLE IF NOT EXISTS chat_messages(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          conversationId INTEGER NOT NULL,
          text TEXT NOT NULL,
          isUser INTEGER NOT NULL,
          timestamp INTEGER NOT NULL,
          FOREIGN KEY (conversationId) REFERENCES chat_conversations (id) ON DELETE CASCADE
        )
      ''');
    } catch (e) {
      print('Tablolar oluşturulurken hata: $e');
    }
  }

  Future<void> _loadConversations() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final databaseProvider = Provider.of<DatabaseProvider>(context, listen: false);
      final conversations = await databaseProvider.database.getAllChatConversations();

      setState(() {
        _conversations = conversations;
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sohbet geçmişi yüklenirken hata oluştu: $e')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createNewConversation() async {
    try {
      final databaseProvider = Provider.of<DatabaseProvider>(context, listen: false);
      final now = DateTime.now();
      
      final newConversation = ChatConversation(
        title: 'Yeni Sohbet',
        createdAt: now,
      );
      
      final conversationId = await databaseProvider.database.createChatConversation(newConversation);
      
      if (!mounted) return;
      
      // AICoachScreen'e git ve yeni sohbeti başlat
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => AICoachScreen(conversationId: conversationId),
        ),
      ).then((_) {
        // Geri döndüğünde sohbetleri yeniden yükle
        _loadConversations();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Yeni sohbet oluşturulurken hata: $e')),
      );
    }
  }

  Future<void> _deleteConversation(ChatConversation conversation) async {
    try {
      final databaseProvider = Provider.of<DatabaseProvider>(context, listen: false);
      await databaseProvider.database.deleteChatConversation(conversation.id!);
      
      setState(() {
        _conversations.removeWhere((c) => c.id == conversation.id);
      });
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sohbet silindi')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sohbet silinirken hata: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _conversations.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: [
                    Expanded(
                      child: _buildConversationsList(),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ElevatedButton.icon(
                        onPressed: _createNewConversation,
                        icon: const Icon(Icons.add),
                        label: const Text('Yeni Sohbet'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(200, 45),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'Henüz hiç sohbet yok',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'AI Koç ile yeni bir sohbet başlatmak için + butonuna dokunun',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _createNewConversation,
            icon: const Icon(Icons.add),
            label: const Text('Yeni Sohbet'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationsList() {
    return ListView.separated(
      padding: const EdgeInsets.all(8.0),
      itemCount: _conversations.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final conversation = _conversations[index];
        return ListTile(
          title: Text(
            conversation.title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            'Oluşturulma: ${conversation.formattedDate}' +
            (conversation.lastMessageAt != null 
              ? ' • Son mesaj: ${conversation.formattedLastMessageTime}' 
              : ''),
          ),
          leading: const CircleAvatar(
            backgroundColor: Colors.orange,
            child: Icon(Icons.chat, color: Colors.white),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _showDeleteConfirmationDialog(conversation),
          ),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => AICoachScreen(conversationId: conversation.id!),
              ),
            ).then((_) {
              // Geri döndüğünde sohbetleri yeniden yükle
              _loadConversations();
            });
          },
        );
      },
    );
  }

  Future<void> _showDeleteConfirmationDialog(ChatConversation conversation) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sohbeti Sil'),
          content: SingleChildScrollView(
            child: ListBody(
              children: const <Widget>[
                Text('Bu sohbeti silmek istediğinize emin misiniz?'),
                Text('Bu işlem geri alınamaz.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('İptal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Sil', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteConversation(conversation);
              },
            ),
          ],
        );
      },
    );
  }
} 