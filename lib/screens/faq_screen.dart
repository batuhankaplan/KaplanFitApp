import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import '../services/feedback_service.dart';

class FAQScreen extends StatefulWidget {
  const FAQScreen({Key? key}) : super(key: key);

  @override
  State<FAQScreen> createState() => _FAQScreenState();
}

class _FAQScreenState extends State<FAQScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  // SSS veri listesi
  final List<Map<String, dynamic>> _faqItems = [
    {
      'question': 'KaplanFIT uygulaması nedir?',
      'answer': 'KaplanFIT, kişisel sağlık ve fitness hedeflerinize ulaşmanıza yardımcı olan bir mobil uygulamadır. Egzersiz takibi, beslenme planı, su tüketimi takibi ve AI koçluk özellikleri sunar. Uygulamamız, günlük aktivitelerinizi ve beslenme alışkanlıklarınızı takip etmenize, kişisel egzersiz programları oluşturmanıza ve sağlık hedeflerinize ulaşmanıza yardımcı olur.',
      'isExpanded': false
    },
    {
      'question': 'Uygulamayı nasıl kullanabilirim?',
      'answer': 'Uygulamayı kullanmak için önce profil oluşturmalısınız. Ardından, Anasayfa\'da günlük programınızı görebilir, Spor sekmesinden aktivitelerinizi kaydedebilir, Beslenme bölümünden yemeklerinizi takip edebilir ve AI Koç ile sağlık ve fitness konularında tavsiyelere ulaşabilirsiniz. Profil bilgilerinizi doğru girmeniz, size daha uygun öneriler sunmamızı sağlayacaktır.',
      'isExpanded': false
    },
    {
      'question': 'KaplanFIT uygulaması ücretli mi?',
      'answer': 'KaplanFIT uygulaması temel özellikleriyle ücretsiz olarak sunulmaktadır. İlerleyen süreçte premium özellikler için ücretli bir abonelik seçeneği eklenebilir. Ücretsiz sürümde anasayfa, spor, beslenme ve AI koç özelliklerine tam erişim sağlayabilirsiniz. Premium özelliklere dair bilgilendirmeler ileri tarihlerde yapılacaktır.',
      'isExpanded': false
    },
    {
      'question': 'Egzersizlerimi nasıl kaydedebilirim?',
      'answer': 'Spor sekmesinden "Yeni Aktivite Ekle" butonuna tıklayarak egzersiz türünü, süresini ve detaylarını kaydedebilirsiniz. Kaydedilen tüm aktiviteleriniz İstatistik bölümünde görüntülenecektir. Kayıtlı egzersizlerinizi görüntüleyebilir, düzenleyebilir veya silebilirsiniz. Düzenli aktivite girişi, gelişiminizi daha iyi takip etmenize olanak sağlar.',
      'isExpanded': false
    },
    {
      'question': 'Öğünlerimi nasıl takip edebilirim?',
      'answer': 'Beslenme sekmesinden "Öğün Ekle" butonunu kullanarak yediğiniz yemekleri, miktarlarını ve kalori değerlerini kaydedebilirsiniz. Günlük kalori alımınız otomatik olarak hesaplanacaktır. Beslenme günlüğünüzde yer alan grafikler sayesinde haftalık kalori alımınızı görsel olarak takip edebilir, beslenme alışkanlıklarınızı analiz edebilirsiniz.',
      'isExpanded': false
    },
    {
      'question': 'AI Koç özelliği nedir?',
      'answer': 'AI Koç, beslenme, egzersiz ve sağlık konularında kişiselleştirilmiş tavsiyeler sunan yapay zeka destekli bir asistanıdır. Sorularınızı AI Koç\'a sorabilir ve hızlı yanıtlar alabilirsiniz. AI Koç\'un önerileri genel bilgilendirme amaçlıdır ve profesyonel tıbbi tavsiye yerine geçmez. Ciddi sağlık sorunlarınız varsa mutlaka bir sağlık uzmanına danışmalısınız.',
      'isExpanded': false
    },
    {
      'question': 'Programımı özelleştirebilir miyim?',
      'answer': 'Evet, Program sekmesinden haftalık egzersiz ve beslenme planınızı görebilir ve düzenleyebilirsiniz. Değişiklikler anasayfadaki günlük programınıza otomatik olarak yansıyacaktır. Program içeriklerini kendi ihtiyaçlarınıza ve hedeflerinize göre özelleştirebilir, sabah egzersizi, öğle yemeği, akşam egzersizi ve akşam yemeği planlarınızı detaylı olarak oluşturabilirsiniz.',
      'isExpanded': false
    },
    {
      'question': 'Uygulamada bildirimler nasıl çalışır?',
      'answer': 'Ayarlar bölümündeki Bildirim Ayarları\'ndan egzersiz, öğün, su içme ve hedef hatırlatmalarını açıp kapatabilir, bildirim seslerini ve titreşimlerini özelleştirebilirsiniz. Bildirimlerin çalışması için uygulamaya gerekli izinleri vermeniz gerekir. Bildirim ayarlarınızı kişiselleştirerek günlük rutininize uygun hatırlatma zamanları belirleyebilirsiniz.',
      'isExpanded': false
    },
    {
      'question': 'Verilerim güvende mi?',
      'answer': 'Tüm verileriniz cihazınızda yerel olarak saklanır ve sadece siz erişebilirsiniz. Verileriniz üçüncü taraflarla paylaşılmaz veya satılmaz. KaplanFIT, kullanıcı gizliliğini en üst düzeyde önemser ve verilerinizin güvenliğini sağlamak için gerekli önlemleri alır. Uygulama içinde girdiğiniz kişisel bilgiler, sadece size daha iyi hizmet sunmak amacıyla kullanılır.',
      'isExpanded': false
    },
    {
      'question': 'Uygulamada bir hata buldum veya önerim var, nasıl bildirebilirim?',
      'answer': 'Bu ekranın alt kısmındaki iletişim formunu kullanarak bize geri bildirim gönderebilirsiniz. Tüm geri bildirimler dikkatle incelenmektedir. Geri bildirimleriniz uygulamamızı geliştirmemize yardımcı olur. Ayrıca, uygulama içindeki Ayarlar > Yardım ve Destek menüsünden de bize ulaşabilirsiniz. Bildirdiğiniz hatalar ve öneriler için teşekkür ederiz.',
      'isExpanded': false
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yardım ve Destek'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // SSS Başlığı
              const Text(
                'Sık Sorulan Sorular',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              // SSS Listesi
              _buildFAQList(),
              
              const Divider(height: 32),
              
              // İletişim Formu Başlığı
              const Text(
                'Bize Ulaşın',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Sorularınız veya önerileriniz için aşağıdaki formu kullanabilirsiniz.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              
              // İletişim Formu
              _buildContactForm(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFAQList() {
    return ExpansionPanelList(
      elevation: 2,
      expandedHeaderPadding: const EdgeInsets.symmetric(vertical: 0),
      dividerColor: Colors.grey.shade300,
      expansionCallback: (int index, bool isExpanded) {
        setState(() {
          _faqItems[index]['isExpanded'] = !isExpanded;
        });
      },
      children: _faqItems.map<ExpansionPanel>((Map<String, dynamic> item) {
        return ExpansionPanel(
          headerBuilder: (BuildContext context, bool isExpanded) {
            return ListTile(
              title: Text(
                item['question'],
                style: TextStyle(
                  fontWeight: FontWeight.w600, 
                  color: Theme.of(context).textTheme.titleMedium?.color),
              ),
              onTap: () {
                setState(() {
                  item['isExpanded'] = !item['isExpanded'];
                });
              },
            );
          },
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['answer'],
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          isExpanded: item['isExpanded'] ?? false,
          canTapOnHeader: true,
        );
      }).toList(),
    );
  }

  Widget _buildContactForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Ad Alanı
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Adınız',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Lütfen adınızı girin';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // E-mail Alanı
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'E-posta Adresiniz',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.email),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Lütfen e-posta adresinizi girin';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'Geçerli bir e-posta adresi girin';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Mesaj Alanı
          TextFormField(
            controller: _messageController,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Mesajınız',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.message),
              alignLabelWithHint: true,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Lütfen mesajınızı girin';
              }
              if (value.length < 10) {
                return 'Mesajınız en az 10 karakter olmalıdır';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          
          // Gönder Butonu
          ElevatedButton(
            onPressed: _submitForm,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Mesajı Gönder'),
          ),
        ],
      ),
    );
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      // Form verilerini al
      final String name = _nameController.text;
      final String email = _emailController.text;
      final String message = _messageController.text;
      
      // Yükleme göstergesi
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(child: CircularProgressIndicator());
        },
      );
      
      // Geri bildirim servisini kullan
      final feedbackService = FeedbackService();
      final success = await feedbackService.sendFeedback(name, email, message);
      
      // Yükleme göstergesini kapat
      if (context.mounted) Navigator.of(context).pop();
      
      if (success) {
        // Form alanlarını temizle
        _nameController.clear();
        _emailController.clear();
        _messageController.clear();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Mesajınız başarıyla gönderildi. Teşekkürler!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Mesaj gönderilirken bir hata oluştu. Lütfen tekrar deneyin.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }
} 