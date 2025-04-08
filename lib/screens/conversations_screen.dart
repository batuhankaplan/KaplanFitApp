import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/providers/database_provider.dart';
import '../models/chat_model.dart';
import 'ai_coach_screen.dart';
import '../widgets/kaplan_loading.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({Key? key}) : super(key: key);

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  List<ChatConversation> _conversations = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final databaseProvider =
          Provider.of<DatabaseProvider>(context, listen: false);

      // Önce boş konuşmaları temizle
      await databaseProvider.cleanEmptyConversations();

      // Sonra konuşmaları yükle
      final conversations =
          await databaseProvider.database.getAllChatConversations();

      setState(() {
        _conversations = conversations;
      });
    } catch (e) {
      _showErrorDialog('Konuşmalar yüklenirken hata oluştu: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createNewConversation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final databaseProvider =
          Provider.of<DatabaseProvider>(context, listen: false);
      // Önce boş konuşmaları temizle
      await databaseProvider.cleanEmptyConversations();

      // Yeni bir konuşma başlatmak için doğrudan AICoachScreen'e yönlendir
      Navigator.of(context)
          .push(
        MaterialPageRoute(
          builder: (context) => const AICoachScreen(),
        ),
      )
          .then((_) {
        // Konuşma ekranından döndükten sonra konuşmaları yeniden yükle
        _loadConversations();
      });
    } catch (e) {
      _showErrorDialog('Yeni konuşma oluşturulurken hata oluştu: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteConversation(ChatConversation conversation) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konuşmayı Sil'),
        content: const Text(
            'Bu konuşmayı silmek istediğinize emin misiniz? Bu işlem geri alınamaz.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final databaseProvider =
          Provider.of<DatabaseProvider>(context, listen: false);
      await databaseProvider.database.deleteChatConversation(conversation.id!);

      setState(() {
        _conversations.removeWhere((c) => c.id == conversation.id);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Konuşma silindi')),
        );
      }
    } catch (e) {
      _showErrorDialog('Konuşma silinirken hata oluştu: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hata'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Konuşmalarım'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: _isLoading
          ? const Center(child: KaplanLoading())
          : _conversations.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.chat_bubble_outline,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Henüz hiç konuşma başlatmadınız',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _createNewConversation,
                        icon: const Icon(Icons.add),
                        label: const Text('Yeni Konuşma Başlat'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadConversations,
                  child: ListView.builder(
                    itemCount: _conversations.length,
                    itemBuilder: (context, index) {
                      final conversation = _conversations[index];
                      return Dismissible(
                        key: Key('conversation-${conversation.id}'),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) => _deleteConversation(conversation),
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 16.0),
                          child: const Icon(
                            Icons.delete,
                            color: Colors.white,
                          ),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                Theme.of(context).primaryColor.withOpacity(0.2),
                            child: Icon(
                              Icons.chat,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          title: Text(
                            conversation.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            'Oluşturulma: ${_formatDate(conversation.createdAt)}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                          onTap: () {
                            Navigator.of(context)
                                .push(
                              MaterialPageRoute(
                                builder: (context) => AICoachScreen(
                                  conversationId: conversation.id,
                                ),
                              ),
                            )
                                .then((_) {
                              // Konuşma ekranından döndükten sonra konuşmaları yeniden yükle
                              _loadConversations();
                            });
                          },
                          trailing:
                              const Icon(Icons.arrow_forward_ios, size: 16),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewConversation,
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
