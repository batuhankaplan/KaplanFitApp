import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../models/program_model.dart';
import '../services/program_service.dart';
import '../widgets/program_detail_dialog.dart';
import 'package:provider/provider.dart';
import '../models/providers/database_provider.dart';
import '../theme.dart';
import '../widgets/kaplan_appbar.dart';

class ProgramScreen extends StatefulWidget {
  const ProgramScreen({Key? key}) : super(key: key);

  @override
  State<ProgramScreen> createState() => _ProgramScreenState();
}

class _ProgramScreenState extends State<ProgramScreen> {
  int _selectedDayIndex = 0;
  final List<String> _weekDays = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];
  final List<String> _weekDayAbbr = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
  final ProgramService _programService = ProgramService();
  List<DailyProgram> _weeklyProgram = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('tr_TR', null);
    _loadProgram();
    
    // Uygulamayı açtığımızda bugünü seçelim
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final today = DateTime.now().weekday - 1;
      setState(() {
        _selectedDayIndex = today;
      });
    });
  }

  Future<void> _loadProgram() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final weeklyProgram = await _programService.getWeeklyProgram();
      setState(() {
        _weeklyProgram = weeklyProgram;
        _isLoading = false;
      });
    } catch (e) {
      print('Program yüklenirken hata: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showEditDialog(ProgramItem item, String type) async {
    final result = await showDialog<ProgramItem>(
      context: context,
      builder: (BuildContext context) {
        return ProgramDetailDialog(
          programItem: item,
          type: type,
        );
      },
    );

    if (result != null) {
      // Programı güncelle
      final currentProgram = _weeklyProgram[_selectedDayIndex];
      
      setState(() {
        switch (type) {
          case 'morning':
            currentProgram.morningExercise = result;
            break;
          case 'lunch':
            currentProgram.lunch = result;
            break;
          case 'evening':
            currentProgram.eveningExercise = result;
            break;
          case 'dinner':
            currentProgram.dinner = result;
            break;
        }
      });
      
      // Değişiklikleri kaydet
      await _programService.updateDailyProgram(_selectedDayIndex, currentProgram);
      
      // Bugünün programı değiştirilmişse ana sayfayı güncelle
      if (_selectedDayIndex == DateTime.now().weekday - 1) {
        // Burada anasayfanın güncellenmesi için bir bildirim veya event gönderilebilir
        // Örneğin bir GlobalKey veya Event Bus kullanılabilir
        // Şimdilik Provider üzerinden doğrudan güncelleyeceğiz
        Provider.of<DatabaseProvider>(context, listen: false).notifyListeners();
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Program güncellendi')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: KaplanAppBar(
        title: 'Haftalık Program',
        isDarkMode: isDarkMode,
        isRequiredPage: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Gün seçici
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        isDarkMode ? const Color(0xFF2C2C2C) : AppTheme.primaryColor.withOpacity(0.7),
                        isDarkMode ? const Color(0xFF1F1F1F) : AppTheme.primaryColor,
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Gün seçici butonlar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(7, (index) {
                          final isSelected = index == _selectedDayIndex;
                          final isToday = index == (DateTime.now().weekday - 1);
                          
                          return GestureDetector(
                            onTap: () {
                              print('Seçilen gün: $index (${_weekDays[index]})');
                              setState(() {
                                _selectedDayIndex = index;
                              });
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isSelected
                                  ? AppTheme.accentColor
                                  : isToday 
                                    ? AppTheme.accentColor.withOpacity(0.2) 
                                    : Colors.transparent,
                                shape: BoxShape.circle,
                                border: !isSelected && isToday
                                  ? Border.all(color: AppTheme.accentColor)
                                  : null,
                              ),
                              child: Center(
                                child: Text(
                                  _weekDayAbbr[index],
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                      ? Colors.white
                                      : isToday
                                        ? AppTheme.accentColor
                                        : Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Program kartları
                Expanded(
                  child: _weeklyProgram.isEmpty
                      ? const Center(child: Text('Program bulunamadı'))
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              // Sabah Egzersizi
                              _buildProgramCard(
                                context: context,
                                title: 'Sabah Egzersizi',
                                icon: Icons.wb_sunny,
                                color: AppTheme.morningExerciseColor,
                                description: _weeklyProgram[_selectedDayIndex].morningExercise.description,
                                onTap: () => _showEditDialog(_weeklyProgram[_selectedDayIndex].morningExercise, 'morning'),
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Öğle Yemeği
                              _buildProgramCard(
                                context: context,
                                title: 'Öğle Yemeği',
                                icon: Icons.restaurant,
                                color: AppTheme.lunchColor,
                                description: _weeklyProgram[_selectedDayIndex].lunch.description,
                                onTap: () => _showEditDialog(_weeklyProgram[_selectedDayIndex].lunch, 'lunch'),
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Akşam Egzersizi
                              _buildProgramCard(
                                context: context,
                                title: 'Akşam Egzersizi',
                                icon: Icons.fitness_center,
                                color: AppTheme.eveningExerciseColor,
                                description: _weeklyProgram[_selectedDayIndex].eveningExercise.description,
                                onTap: () => _showEditDialog(_weeklyProgram[_selectedDayIndex].eveningExercise, 'evening'),
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Akşam Yemeği
                              _buildProgramCard(
                                context: context,
                                title: 'Akşam Yemeği',
                                icon: Icons.dinner_dining,
                                color: AppTheme.dinnerColor,
                                description: _weeklyProgram[_selectedDayIndex].dinner.description,
                                onTap: () => _showEditDialog(_weeklyProgram[_selectedDayIndex].dinner, 'dinner'),
                              ),
                              
                              const SizedBox(height: 24),
                              
                              // Notlar ve tavsiyeler
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).brightness == Brightness.dark 
                                      ? Colors.grey.shade800 
                                      : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Theme.of(context).brightness == Brightness.dark 
                                        ? Colors.grey.shade700 
                                        : Colors.grey.shade300,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.info_outline, 
                                          color: Theme.of(context).brightness == Brightness.dark 
                                              ? Colors.lightBlue.shade300 
                                              : Colors.blue,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Genel Tavsiyeler',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context).brightness == Brightness.dark 
                                                ? Colors.white 
                                                : Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '• Günde en az 2-3 litre su içmeyi unutmayın.\n'
                                      '• Şekerli içeceklerden ve abur cuburdan uzak durun.\n'
                                      '• Her gün en az 30 dakika hareket etmeye çalışın.\n'
                                      '• Yemekten 2 saat önce uyumayın.',
                                      style: TextStyle(
                                        color: Theme.of(context).brightness == Brightness.dark 
                                            ? Colors.white70 
                                            : Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildProgramCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required String description,
    required VoidCallback onTap,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(isDarkMode ? 0.3 : 0.2),
                color.withOpacity(isDarkMode ? 0.1 : 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.black26 : Colors.white.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        icon,
                        color: color,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 15,
                    color: isDarkMode ? Colors.white70 : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 