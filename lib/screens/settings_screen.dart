import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import '../providers/user_provider.dart';
import '../theme.dart';
import 'profile_screen.dart';
import 'notification_settings_screen.dart';
import 'faq_screen.dart';
import '../models/user_model.dart';
import 'goal_settings_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

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
    final user = userProvider.user;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? AppTheme.darkBackgroundColor : Colors.white,
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isDarkMode ? AppTheme.darkCardBackgroundColor : Colors.white,
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
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
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Çıkış Yap'),
        content: Text('Hesabınızdan çıkış yapmak istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Kullanıcı profil bilgilerini sıfırla
              await userProvider.clearUser();

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Hesabınızdan çıkış yapıldı')),
              );
            },
            child: Text('Çıkış Yap'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
          ),
        ],
      ),
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

  void _showAboutDialog(BuildContext context) {
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
