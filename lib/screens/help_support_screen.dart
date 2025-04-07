import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/kaplan_appbar.dart';
import '../utils/animations.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({Key? key}) : super(key: key);

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      throw Exception('URL açılamadı: $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: KaplanAppBar(
        title: 'Yardım ve Destek',
        isDarkMode: isDarkMode,
      ),
      backgroundColor: isDarkMode ? AppTheme.backgroundColor : const Color(0xFFF8F8FC),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              KFSlideAnimation(
                offsetBegin: const Offset(0.0, 0.1),
                child: Card(
                  color: isDarkMode 
                      ? const Color(0xFF243355)
                      : Colors.white,
                  elevation: 2,
                  shadowColor: Colors.black26,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sık Sorulan Sorular',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildFaqItem(
                          context,
                          'Bildirimler çalışmıyor, ne yapmalıyım?',
                          'Öncelikle ayarlar menüsünden bildirimlerin açık olduğundan emin olun. '
                          'Daha sonra cihazınızın bildirim ayarlarından KaplanFit uygulamasına izin '
                          'verildiğinden emin olun.',
                          isDarkMode: isDarkMode,
                        ),
                        const SizedBox(height: 16),
                        _buildFaqItem(
                          context,
                          'Uygulamayı nasıl güncelleyebilirim?',
                          'Uygulamanın en son sürümüne sahip olduğunuzdan emin olmak için '
                          'mobil cihazınızdaki uygulama mağazasını kontrol edin ve '
                          'mevcut bir güncelleme varsa yükleyin.',
                          isDarkMode: isDarkMode,
                        ),
                        const SizedBox(height: 16),
                        _buildFaqItem(
                          context,
                          'Verilerim ne kadar süreyle depolanır?',
                          'Uygulama verileri, siz hesabınızı silene kadar güvenli bir şekilde '
                          'depolanır. İlerleme ve aktivite verileri, size daha iyi hizmet '
                          'verebilmemiz için saklanmaktadır.',
                          isDarkMode: isDarkMode,
                        ),
                        const SizedBox(height: 16),
                        _buildFaqItem(
                          context,
                          'AI Koç nasıl çalışır?',
                          'AI Koç, fitness ve beslenme alanında eğitilmiş yapay zeka ile '
                          'antrenman ve beslenme konularında size özel tavsiyeler sunar. '
                          'Verileriniz ve hedeflerinize göre kişiselleştirilmiş öneriler alabilirsiniz.',
                          isDarkMode: isDarkMode,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              KFSlideAnimation(
                offsetBegin: const Offset(0.0, 0.1),
                child: Card(
                  color: isDarkMode 
                      ? const Color(0xFF243355)
                      : Colors.white,
                  elevation: 2,
                  shadowColor: Colors.black26,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'İletişim',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          leading: Icon(
                            Icons.email_outlined,
                            color: AppTheme.primaryColor,
                          ),
                          title: Text(
                            'E-posta ile Destek',
                            style: TextStyle(
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                          subtitle: Text(
                            'destek@kaplanfit.com',
                            style: TextStyle(
                              color: isDarkMode ? Colors.white70 : Colors.black54,
                            ),
                          ),
                          onTap: () {
                            _launchUrl('mailto:destek@kaplanfit.com?subject=KaplanFit%20Destek');
                          },
                        ),
                        const Divider(),
                        ListTile(
                          leading: Icon(
                            Icons.phone,
                            color: AppTheme.primaryColor,
                          ),
                          title: Text(
                            'Telefon Desteği',
                            style: TextStyle(
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                          subtitle: Text(
                            '+90 555 123 4567',
                            style: TextStyle(
                              color: isDarkMode ? Colors.white70 : Colors.black54,
                            ),
                          ),
                          onTap: () {
                            _launchUrl('https://wa.me/905551234567');
                          },
                        ),
                        const Divider(),
                        ListTile(
                          leading: Icon(
                            Icons.web,
                            color: AppTheme.primaryColor,
                          ),
                          title: Text(
                            'Web Sitemiz',
                            style: TextStyle(
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                          subtitle: Text(
                            'www.kaplanfit.com',
                            style: TextStyle(
                              color: isDarkMode ? Colors.white70 : Colors.black54,
                            ),
                          ),
                          onTap: () {
                            _launchUrl('https://www.kaplanfit.com');
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              KFSlideAnimation(
                offsetBegin: const Offset(0.0, 0.1),
                child: Card(
                  color: isDarkMode 
                      ? const Color(0xFF243355)
                      : Colors.white,
                  elevation: 2,
                  shadowColor: Colors.black26,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Uygulama Hakkında',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Column(
                              children: [
                                Icon(
                                  Icons.fitness_center,
                                  size: 48,
                                  color: AppTheme.primaryColor,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'KaplanFit',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isDarkMode ? Colors.white : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Sürüm 1.0.1',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDarkMode ? Colors.white70 : Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'KaplanFit, sağlıklı bir yaşam tarzı ve kişisel fitness hedeflerinize '
                          'ulaşmanıza yardımcı olmak için tasarlanmış bir uygulamadır. '
                          'Egzersiz rutinleri, beslenme takibi ve motivasyonel rehberlik '
                          'ile daha sağlıklı bir yaşama adım atın.',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildFaqItem(BuildContext context, String question, String answer, {required bool isDarkMode}) {
    return ExpansionTile(
      title: Text(
        question,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDarkMode ? Colors.white : Colors.black87,
        ),
      ),
      collapsedIconColor: AppTheme.primaryColor,
      iconColor: AppTheme.primaryColor,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            answer,
            style: TextStyle(
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
          ),
        ),
      ],
    );
  }
} 