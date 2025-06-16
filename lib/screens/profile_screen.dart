import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../models/user_model.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/animations.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String? _profileImagePath;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _loadUserData() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.user;

    debugPrint("[ProfileScreen] _loadUserData çağrıldı, user: $user");

    if (user != null) {
      // Sadece mevcut kullanıcı düzenleme modunda veriyi yükle
      debugPrint(
          "[ProfileScreen] Mevcut kullanıcı düzenleme modu - veriler yükleniyor");
      setState(() {
        _nameController.text = user.name;
        _ageController.text = user.age.toString();
        _emailController.text = user.email ?? '';
        _phoneController.text = user.phoneNumber ?? '';
        _profileImagePath = user.profileImagePath;
      });
    } else {
      // Yeni kullanıcı oluşturma modu - tüm alanları boş bırak
      debugPrint("[ProfileScreen] Yeni kullanıcı oluşturma modu - alanlar boş");
      setState(() {
        _nameController.clear();
        _ageController.clear();
        _emailController.clear();
        _phoneController.clear();
        _profileImagePath = null;
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _profileImagePath = pickedFile.path;
      });
    }
  }

  Future<void> _saveUserData() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final currentUser = userProvider.user;

      // Form verilerini al
      final String name = _nameController.text;
      final int age = int.parse(_ageController.text);
      final String email = _emailController.text.trim();
      final String phoneNumber = _phoneController.text.trim();

      UserModel updatedUser;

      if (currentUser != null) {
        // Mevcut kullanıcıyı güncelle
        updatedUser = currentUser.copyWith(
          name: name,
          age: age,
          email: email.isNotEmpty ? email : null,
          phoneNumber: phoneNumber.isNotEmpty ? phoneNumber : null,
          profileImagePath: _profileImagePath,
          weeklyActivityGoal: currentUser.weeklyActivityGoal ?? 150.0,
        );
      } else {
        // Yeni kullanıcı oluştur - hedef alanları boş bırak
        updatedUser = UserModel(
          name: name,
          age: age,
          height:
              currentUser?.height ?? 0, // Bu değerler aslında formdan gelmeli
          weight:
              currentUser?.weight ?? 0, // Bu değerler aslında formdan gelmeli
          email: email.isNotEmpty ? email : null,
          phoneNumber: phoneNumber.isNotEmpty ? phoneNumber : null,
          profileImagePath: _profileImagePath,
          createdAt: DateTime.now(),
          lastWeightUpdate:
              DateTime.now(), // İlk ağırlık kaydı olarak düşünülebilir
          weeklyActivityGoal: null,
          targetCalories: null,
          targetProtein: null,
          targetCarbs: null,
          targetFat: null,
          targetWaterIntake: null,
          targetWeight: null,
          weeklyWeightGoal: null,
          activityLevel: null,
        );
      }

      // Hata ayıklama: Kullanıcı verilerini görelim
      debugPrint("Kaydedilecek kullanıcı: ${updatedUser.toMap()}");

      // Kullanıcıyı kaydet ve tam olarak tamamlanmasını bekle
      await userProvider.saveUser(updatedUser);

      // Kısa bir gecikme ekleyerek veritabanı işlemlerinin tamamlanmasını bekleyebiliriz
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil bilgileri kaydedildi')),
        );

        // Ana sayfaya git ve navigation stack'ini temizle - direk anasayfaya geç
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/home', (route) => false);
      }
    } catch (e) {
      debugPrint("Profil kaydetme hatası: $e");
      if (mounted) {
        // Daha detaylı hata mesajını göstermeyelim, basit bir mesaj verelim
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Profil kaydedilirken bir hata oluştu. Lütfen tekrar deneyin.')),
        );

        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: Text(user == null ? 'Profil Oluştur' : 'Profil Düzenle'),
        actions: [
          // Eğer mevcut bir kullanıcı varsa çıkış yap butonu göster
          if (user != null)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => _showLogoutConfirmationDialog(context),
              tooltip: 'Çıkış Yap',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Profil resmi seçme
                    KFSlideAnimation(
                      offsetBegin: const Offset(0, -0.2),
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Stack(
                          children: [
                            KFPulseAnimation(
                              duration: const Duration(milliseconds: 2000),
                              maxScale: 1.05,
                              child: CircleAvatar(
                                radius: 60,
                                backgroundColor: Colors.grey.shade200,
                                backgroundImage: _profileImagePath != null
                                    ? FileImage(File(_profileImagePath!))
                                    : null,
                                child: _profileImagePath == null
                                    ? Icon(
                                        Icons.person,
                                        size: 60,
                                        color: Colors.grey.shade600,
                                      )
                                    : null,
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.edit,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Form alanları - animasyonlu liste olarak gösterelim
                    KFAnimatedList(
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Ad Soyad',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Lütfen adınızı ve soyadınızı girin';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _ageController,
                          decoration: const InputDecoration(
                            labelText: 'Yaş',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Lütfen yaşınızı girin';
                            }
                            if (int.tryParse(value) == null) {
                              return 'Geçerli bir yaş girin';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // E-posta alanı
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'E-posta (opsiyonel)',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              // Basit bir e-posta validasyonu
                              if (!value.contains('@') ||
                                  !value.contains('.')) {
                                return 'Geçerli bir e-posta adresi girin';
                              }
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // Telefon numarası alanı
                        TextFormField(
                          controller: _phoneController,
                          decoration: const InputDecoration(
                            labelText: 'Telefon Numarası (opsiyonel)',
                            border: OutlineInputBorder(),
                            hintText: '05XX XXX XX XX',
                          ),
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              // Basit bir telefon numarası validasyonu
                              if (value.replaceAll(' ', '').length < 10) {
                                return 'Geçerli bir telefon numarası girin';
                              }
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 32),

                        // Kaydet butonu
                        KFSlideAnimation(
                          offsetBegin: const Offset(0, 0.5),
                          duration: const Duration(milliseconds: 600),
                          delay: const Duration(milliseconds: 300),
                          child: SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _saveUserData,
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'KAYDET',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // YENİ: Çıkış yapmak için onay diyaloğu göster
  void _showLogoutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Çıkış Yap'),
        content: const Text(
            'Mevcut profilden çıkış yapmak istediğinize emin misiniz? Bu işlem mevcut oturumu sonlandıracak.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İPTAL'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Diyaloğu kapat
              Navigator.of(context).pop();

              try {
                // Çıkış yap işlemini gerçekleştir
                await Provider.of<UserProvider>(context, listen: false)
                    .logoutUser();

                // Başarılı çıkış mesajı göster
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Çıkış yapıldı')),
                );

                // Profil sayfasından çık (ana sayfaya dön)
                Navigator.of(context).pop();
              } catch (e) {
                // Hata mesajı göster
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Çıkış yapılırken hata oluştu: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('ÇIKIŞ YAP'),
          ),
        ],
      ),
    );
  }
}
