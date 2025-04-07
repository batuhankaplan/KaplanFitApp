import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../providers/database_provider.dart';
// import '../models/chat_conversation.dart';
import 'ai_coach_screen.dart';
import '../widgets/kaplan_loading.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({Key? key}) : super(key: key);

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  // List<ChatConversation> _conversations = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // _loadConversations();
  }

  /*
  Future<void> _loadConversations() async {
    // İçerik devre dışı bırakıldı
  }
  */

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hata'),
        content: Text(message),
        actions: [
          TextButton(
            child: const Text('Tamam'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }

  Future<void> _createNewConversation() async {
    setState(() => _isLoading = true);
    
    try {
      /*
      final databaseProvider = Provider.of<DatabaseProvider>(context, listen: false);
      final newConversation = ChatConversation(
        title: 'Yeni Sohbet',
        createdAt: DateTime.now(),
      );
      
      final int? id = await databaseProvider.database.insertChatConversation(newConversation);
      */
      
      final int id = 1; // Geçici ID
      
      if (!mounted) return;
      
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => AICoachScreen(conversationId: id),
        ),
      ).then((_) {
        // Geri döndüğünde sohbetleri yeniden yükle
        // _loadConversations();
      });
    } catch (e) {
      _showErrorDialog('Yeni sohbet oluşturulurken hata: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /*
  Future<void> _deleteConversation(ChatConversation conversation) async {
    // İçerik devre dışı bırakıldı
  }
  */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sohbetler'),
        backgroundColor: Theme.of(context).primaryColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const KaplanLoading()
          : _buildEmptyState(),
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
            'Geliştirme aşamasında',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'AI Koç özelliği geliştirme aşamasındadır. Yakında hizmetinizde olacak.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _createNewConversation,
            child: const Text('Yeni Sohbet'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              minimumSize: const Size(200, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /*
  Widget _buildConversationsList() {
    // İçerik devre dışı bırakıldı
  }

  Future<void> _showDeleteConfirmationDialog(ChatConversation conversation) async {
    // İçerik devre dışı bırakıldı
  }
  */
} 