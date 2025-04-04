import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../models/user_model.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String? _profileImagePath;
  bool _isLoading = false;
  double _bmi = 0;
  String _bmiCategory = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _loadUserData() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.user;
    if (user != null) {
      setState(() {
        _nameController.text = user.name;
        _ageController.text = user.age.toString();
        _heightController.text = user.height.toString();
        _weightController.text = user.weight.toString();
        _emailController.text = user.email ?? '';
        _phoneController.text = user.phoneNumber ?? '';
        _profileImagePath = user.profileImagePath;
        _bmi = user.bmi;
        _bmiCategory = user.bmiCategory;
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

  void _calculateBMI() {
    try {
      final weight = double.parse(_weightController.text);
      final height = double.parse(_heightController.text);
      
      if (weight > 0 && height > 0) {
        final bmi = weight / ((height / 100) * (height / 100));
        setState(() {
          _bmi = bmi;
          _bmiCategory = _getBMICategory(bmi);
        });
      }
    } catch (e) {
      // Geçersiz değerler için hesaplama yapma
    }
  }
  
  String _getBMICategory(double bmi) {
    if (bmi < 18.5) {
      return "Zayıf";
    } else if (bmi < 25) {
      return "Normal";
    } else if (bmi < 30) {
      return "Fazla Kilolu";
    } else if (bmi < 35) {
      return "Obez (Sınıf I)";
    } else if (bmi < 40) {
      return "Obez (Sınıf II)";
    } else {
      return "Aşırı Obez (Sınıf III)";
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
      final double height = double.parse(_heightController.text);
      final double weight = double.parse(_weightController.text);
      final String email = _emailController.text.trim();
      final String phoneNumber = _phoneController.text.trim();
      
      UserModel updatedUser;
      
      if (currentUser != null) {
        // Mevcut kullanıcıyı güncelle
        updatedUser = currentUser.copyWith(
          name: name,
          age: age,
          height: height,
          weight: weight,
          email: email.isNotEmpty ? email : null,
          phoneNumber: phoneNumber.isNotEmpty ? phoneNumber : null,
          profileImagePath: _profileImagePath,
          lastWeightUpdate: DateTime.now(),
        );
      } else {
        // Yeni kullanıcı oluştur
        updatedUser = UserModel(
          name: name,
          age: age,
          height: height,
          weight: weight,
          email: email.isNotEmpty ? email : null,
          phoneNumber: phoneNumber.isNotEmpty ? phoneNumber : null,
          profileImagePath: _profileImagePath,
          lastWeightUpdate: DateTime.now(),
          createdAt: DateTime.now(),
        );
      }
      
      await userProvider.saveUser(updatedUser);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil bilgileri kaydedildi')),
        );
        
        // Ana ekrana veya profil görünümüne dön
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    } finally {
      if (mounted) {
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
                  GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      children: [
                        CircleAvatar(
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
                  
                  const SizedBox(height: 32),
                  
                  // Form alanları
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
                      try {
                        final age = int.parse(value);
                        if (age <= 0 || age > 120) {
                          return 'Geçerli bir yaş girin (1-120)';
                        }
                      } catch (e) {
                        return 'Geçerli bir sayı girin';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _heightController,
                    decoration: const InputDecoration(
                      labelText: 'Boy (cm)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Lütfen boyunuzu girin';
                      }
                      try {
                        final height = double.parse(value);
                        if (height <= 0 || height > 250) {
                          return 'Geçerli bir boy girin (1-250 cm)';
                        }
                      } catch (e) {
                        return 'Geçerli bir sayı girin';
                      }
                      return null;
                    },
                    onChanged: (_) => _calculateBMI(),
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _weightController,
                    decoration: const InputDecoration(
                      labelText: 'Kilo (kg)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Lütfen kilonuzu girin';
                      }
                      try {
                        final weight = double.parse(value);
                        if (weight <= 0 || weight > 300) {
                          return 'Geçerli bir kilo girin (1-300 kg)';
                        }
                      } catch (e) {
                        return 'Geçerli bir sayı girin';
                      }
                      return null;
                    },
                    onChanged: (_) => _calculateBMI(),
                  ),
                  const SizedBox(height: 16),
                  
                  // BMI gösterimi
                  if (_bmi > 0)
                    Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Text(
                              'Vücut Kitle İndeksi (BMI)',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${_bmi.toStringAsFixed(1)}',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _bmiCategory,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  
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
                        if (!value.contains('@') || !value.contains('.')) {
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
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveUserData,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'KAYDET',
                        style: TextStyle(
                          fontSize: 18, 
                          fontWeight: FontWeight.bold
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }
} 