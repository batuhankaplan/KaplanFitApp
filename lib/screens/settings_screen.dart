import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import '../providers/user_provider.dart';
import '../providers/theme_provider.dart';
import '../theme.dart';
import 'profile_screen.dart';
import 'notification_settings_screen.dart';
import 'faq_screen.dart';

import 'goal_settings_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? profileImagePath;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // Profil resmi yükle
  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      profileImagePath = prefs.getString('profileImagePath');
    });
  }

  // Profil resmi kaydet
  Future<void> _saveProfileImage(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profileImagePath', path);
  }

  // Profil resmi seçme
  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        profileImagePath = image.path;
      });
      await _saveProfileImage(image.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final user = userProvider.user;
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark ||
        (themeProvider.themeMode == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);

    return Scaffold(
      backgroundColor:
          isDarkMode ? AppTheme.darkBackgroundColor : AppTheme.backgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Kullanıcı profil özeti
            _buildProfileSection(),

            // Ayarlar menüsü
            _buildSettingsOption(
              context,
              'Profil',
              Icons.person,
              Colors.blue,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfileScreen()),
                );
              },
            ),

            Card(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color:
                  isDarkMode ? AppTheme.darkCardBackgroundColor : Colors.white,
              child: Padding(
                padding: const EdgeInsets.only(
                    left: 16.0, right: 16.0, top: 8.0, bottom: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.palette_rounded,
                            color: Colors.deepPurpleAccent, size: 24),
                        SizedBox(width: 16),
                        Text('Tema',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w500)),
                      ],
                    ),
                    DropdownButton<ThemeMode>(
                      value: themeProvider.themeMode,
                      icon: Icon(Icons.arrow_drop_down_rounded,
                          color: isDarkMode ? Colors.white70 : Colors.black54),
                      dropdownColor:
                          isDarkMode ? AppTheme.darkSurfaceColor : Colors.white,
                      underline: SizedBox(),
                      items: [
                        DropdownMenuItem(
                          value: ThemeMode.light,
                          child: Text('Açık',
                              style: TextStyle(
                                  color: isDarkMode
                                      ? Colors.white
                                      : Colors.black)),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.dark,
                          child: Text('Koyu',
                              style: TextStyle(
                                  color: isDarkMode
                                      ? Colors.white
                                      : Colors.black)),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.system,
                          child: Text('Sistem Varsayılanı',
                              style: TextStyle(
                                  color: isDarkMode
                                      ? Colors.white
                                      : Colors.black)),
                        ),
                      ],
                      onChanged: (ThemeMode? newValue) {
                        if (newValue != null) {
                          themeProvider.setThemeMode(newValue);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),

            _buildSettingsOption(
              context,
              'Bildirimler',
              Icons.notifications,
              Colors.orange,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const NotificationSettingsScreen()),
                );
              },
            ),

            _buildSettingsOption(
              context,
              'Hedefler',
              Icons.track_changes,
              Colors.teal,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const GoalSettingsScreen()),
                );
              },
            ),

            _buildSettingsOption(
              context,
              'Yardım ve Destek',
              Icons.help,
              Colors.green,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FAQScreen()),
                );
              },
            ),

            _buildSettingsOption(
              context,
              'Uygulama Hakkında',
              Icons.info,
              Colors.purple,
              () {
                _showAboutDialog(context);
              },
            ),

            // Uygulamayı sıfırla seçeneği
            _buildSettingsOption(
              context,
              'Uygulamayı Sıfırla',
              Icons.restore,
              Colors.deepOrange,
              () {
                _showResetAppDialog(context);
              },
            ),

            SizedBox(height: 16),

            // Çıkış düğmesi
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: Material(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    onTap: () {
                      _showLogoutDialog(context);
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.exit_to_app, color: Colors.white),
                          SizedBox(width: 8),
                          Text('Çıkış Yap',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 16)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Uygulama versiyonu
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Versiyon 1.0.0',
                style: TextStyle(
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    final user = Provider.of<UserProvider>(context).user;
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark ||
        (themeProvider.themeMode == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isDarkMode ? AppTheme.darkCardBackgroundColor : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: user?.profileImagePath != null
                  ? FileImage(File(user!.profileImagePath!))
                  : null,
              child: user?.profileImagePath == null
                  ? Icon(
                      Icons.person,
                      size: 30,
                      color: Colors.grey.shade600,
                    )
                  : null,
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.name ?? 'Kullanıcı',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsOption(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark ||
        (themeProvider.themeMode == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isDarkMode ? AppTheme.darkCardBackgroundColor : Colors.white,
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
          ),
        ),
        title: Text(title),
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark ||
        (themeProvider.themeMode == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Çıkış Yap'),
          content: const Text(
              'Hesabınızdan çıkış yapmak istediğinize emin misiniz? Bu işlem, mevcut oturumunuzu sonlandıracak ve sizi başlangıç ekranına yönlendirecektir.'),
          actions: <Widget>[
            TextButton(
              child: const Text('İptal'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Diyaloğu kapat
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Çıkış Yap',
                  style: TextStyle(color: Colors.white)),
              onPressed: () async {
                Navigator.of(dialogContext).pop(); // Onay diyaloğunu kapat

                try {
                  // UserProvider'dan logoutUser metodunu çağır
                  await Provider.of<UserProvider>(context, listen: false)
                      .logoutUser();

                  // Kullanıcıyı ana ekrana (veya giriş ekranına) yönlendir ve geçmişi temizle
                  // Projenizin başlangıç ekranı rotasını buraya yazın.
                  // Genellikle '/' veya '/auth' veya '/login' olabilir.
                  // Bu örnekte, UserProvider'ın kullanıcı durumu değiştiğinde
                  // main.dart veya ilgili yönlendiricinin doğru ekranı göstermesini bekliyoruz.
                  // Bu yüzden direkt ana sayfaya yönlendirme ve stack'i temizleme genel bir yaklaşımdır.
                  Navigator.of(context).pushNamedAndRemoveUntil(
                      '/', (Route<dynamic> route) => false);

                  // Geri bildirim göstermek için (opsiyonel, logoutUser içinde de olabilir)
                  // ScaffoldMessenger.of(context).showSnackBar(
                  //   const SnackBar(content: Text('Başarıyla çıkış yapıldı.')),
                  // );
                } catch (e) {
                  // Hata durumunda kullanıcıya bilgi ver
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content:
                              Text('Çıkış yapılırken bir hata oluştu: $e')),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showNotImplementedDialog(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Geliştirme Aşamasında'),
        content: Text('$feature özelliği henüz geliştirme aşamasındadır.'),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _showResetAppDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.deepOrange),
              SizedBox(width: 8),
              Text('Uygulamayı Sıfırla'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bu işlem aşağıdaki tüm verileri KALICI olarak silecektir:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 12),
              Text('• Kullanıcı profili ve bilgileri'),
              Text('• Antrenman kayıtları'),
              Text('• Beslenme geçmişi'),
              Text('• Kilo takibi ve geçmiş'),
              Text('• Su içme kayıtları'),
              Text('• AI sohbet geçmişi'),
              Text('• Tüm rozetler ve puanlar'),
              Text('• Uygulama ayarları'),
              SizedBox(height: 12),
              Text(
                'Bu işlem GERİ ALINAMAZ!',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('İptal'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
              ),
              child:
                  const Text('SIFIRLA', style: TextStyle(color: Colors.white)),
              onPressed: () async {
                Navigator.of(dialogContext).pop();

                // Loading dialog göster
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => AlertDialog(
                    content: Row(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(width: 16),
                        Text('Uygulama sıfırlanıyor...'),
                      ],
                    ),
                  ),
                );

                try {
                  await Provider.of<UserProvider>(context, listen: false)
                      .resetApp();

                  Navigator.of(context).pop(); // Loading dialog'u kapat

                  // Başarı mesajı göster
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Uygulama başarıyla sıfırlandı!'),
                      backgroundColor: Colors.green,
                    ),
                  );

                  // Ana ekrana yönlendir
                  Navigator.of(context).pushNamedAndRemoveUntil(
                      '/', (Route<dynamic> route) => false);
                } catch (e) {
                  Navigator.of(context).pop(); // Loading dialog'u kapat

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Sıfırlama hatası: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showAboutDialog(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark ||
        (themeProvider.themeMode == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);

    showAboutDialog(
      context: context,
      applicationName: 'KaplanFit',
      applicationVersion: '1.0.0',
      applicationIcon: Icon(
        Icons.fitness_center,
        color: Theme.of(context).primaryColor,
        size: 40,
      ),
      children: [
        Text(
            'KaplanFit – Kişiye Özel Spor, Sağlık ve Beslenme Takip Uygulaması'),
        SizedBox(height: 16),
        Text(
            'Bu uygulama kilo verme, ayak/bacak dolaşım bozukluklarını azaltma ve motivasyon artırmaya yardımcı olmak için tasarlanmıştır.'),
      ],
    );
  }
}
