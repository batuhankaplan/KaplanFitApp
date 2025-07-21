import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../models/program_model.dart';

import '../services/program_service.dart';
import '../widgets/program_detail_dialog.dart';
import 'package:provider/provider.dart';

import '../theme.dart';
import '../widgets/kaplan_appbar.dart';

class ProgramScreen extends StatefulWidget {
  const ProgramScreen({super.key});

  @override
  State<ProgramScreen> createState() => _ProgramScreenState();
}

class _ProgramScreenState extends State<ProgramScreen> {
  int _selectedDayIndex = 0;
  final List<String> _weekDays = [
    'Pazartesi',
    'Salı',
    'Çarşamba',
    'Perşembe',
    'Cuma',
    'Cumartesi',
    'Pazar'
  ];
  final List<String> _weekDayAbbr = [
    'Pzt',
    'Sal',
    'Çar',
    'Per',
    'Cum',
    'Cmt',
    'Paz'
  ];
  List<DailyProgram> _weeklyProgram = [];
  bool _isLoading = true;
  final Map<String, bool> _expansionStates = {};

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('tr_TR', null);
    // _loadProgram(); // didChangeDependencies'te çağrılacak

    // Uygulamayı açtığımızda bugünü seçelim
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final today = DateTime.now().weekday - 1;
      setState(() {
        _selectedDayIndex = today;
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadProgram(); // Provider bağımlılığı olduğu için burada yükle
  }

  Future<void> _loadProgram() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final programService = Provider.of<ProgramService>(context,
          listen: false); // YENİ: Provider'dan al
      final weeklyProgram = await programService.getWeeklyProgram();
      if (mounted) {
        setState(() {
          _weeklyProgram = weeklyProgram;
          _isLoading = false;
          _weeklyProgram.forEach((day) {
            _updateExpansionState(day.morningExercise, false);
            _updateExpansionState(day.eveningExercise, false);
          });
        });
      }
    } catch (e) {
      debugPrint('Program yüklenirken hata: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _updateExpansionState(ProgramItem item, bool isExpanded) {
    if (item.type == ProgramItemType.workout && item.id != null) {
      _expansionStates[item.id!] = isExpanded;
    }
  }

  void _showEditDialog(ProgramItem item, String type) async {
    final result = await showDialog<ProgramItem>(
      context: context,
      builder: (BuildContext context) {
        if (item.id == null) {
          debugPrint(
              "Uyarı: Düzenlenecek ProgramItem'ın ID'si yok: ${item.title}");
        }
        return ProgramDetailDialog(
          programItem: item,
          type: type,
        );
      },
    );

    if (result != null) {
      // Programı güncelle
      final currentProgram = _weeklyProgram[_selectedDayIndex];
      final programService =
          Provider.of<ProgramService>(context, listen: false);

      setState(() {
        switch (type) {
          case 'morning':
            currentProgram.morningExercise = result;
            // ProgramSets içindeki herhangi bir exercise ID'si geçersizse veya boşsa görsel düzeltme yap
            _ensureValidProgramSets(currentProgram.morningExercise);
            break;
          case 'lunch':
            currentProgram.lunch = result;
            break;
          case 'evening':
            currentProgram.eveningExercise = result;
            // ProgramSets içindeki herhangi bir exercise ID'si geçersizse veya boşsa görsel düzeltme yap
            _ensureValidProgramSets(currentProgram.eveningExercise);
            break;
          case 'dinner':
            currentProgram.dinner = result;
            break;
        }
      });

      // Değişiklikleri kaydet
      await programService.updateDailyProgramByName(
          _weekDays[_selectedDayIndex], currentProgram);

      // Bugünün programı değiştirilmişse ana sayfayı güncelle
      if (_selectedDayIndex == DateTime.now().weekday - 1) {
        // Burada anasayfanın güncellenmesi için bir bildirim veya event gönderilebilir
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Program güncellendi')),
      );
    }
  }

  // Yeni yardımcı metod: ProgramSets içindeki geçersiz veya boş exercise ID'lerini temizler
  void _ensureValidProgramSets(ProgramItem item) {
    if (item.type == ProgramItemType.workout && item.programSets != null) {
      // Geçersiz programSets öğelerini filtrele
      item.programSets = item.programSets!.where((set) {
        return set.exerciseId != null && set.exerciseId!.isNotEmpty;
      }).toList();

      // Eğer hiç geçerli programSet kalmadıysa, item'ın tipini değiştir
      if (item.programSets!.isEmpty) {
        item.programSets = null;
        // Başlık boşsa varsayılan bir başlık ekle
        if (item.title.isEmpty) {
          if (item == _weeklyProgram[_selectedDayIndex].morningExercise) {
            item.title = "Sabah Aktivitesi";
          } else if (item ==
              _weeklyProgram[_selectedDayIndex].eveningExercise) {
            item.title = "Akşam Aktivitesi";
          }
        }
      }
    }
  }

  void _showEditCurrentDayDialog(DailyProgram dailyProgram) {
    // Seçili günün aktivitelerini düzenlemek için bir dialog gösterelim
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('${dailyProgram.dayName} Programını Düzenle'),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                // Sabah Aktivitesi
                ListTile(
                  leading: Icon(Icons.wb_sunny, color: Colors.orange),
                  title: Text('Sabah Aktivitesi'),
                  subtitle: Text(
                      dailyProgram.morningExercise?.title ?? 'Belirtilmedi'),
                  onTap: () {
                    Navigator.pop(context); // Dialog'u kapat
                    _showEditDialog(
                        dailyProgram.morningExercise ??
                            ProgramItem(
                              type: ProgramItemType.workout,
                              title: 'Sabah Aktivitesi',
                              icon: Icons.wb_sunny,
                              color: Colors.orange,
                            ),
                        'morning');
                  },
                ),
                Divider(),
                // Öğle Yemeği
                ListTile(
                  leading: Icon(Icons.restaurant, color: Colors.brown),
                  title: Text('Öğle Yemeği'),
                  subtitle: Text(dailyProgram.lunch?.title ?? 'Belirtilmedi'),
                  onTap: () {
                    Navigator.pop(context); // Dialog'u kapat
                    _showEditDialog(
                        dailyProgram.lunch ??
                            ProgramItem(
                              type: ProgramItemType.meal,
                              title: 'Öğle Yemeği',
                              icon: Icons.restaurant,
                              color: Colors.brown,
                            ),
                        'lunch');
                  },
                ),
                Divider(),
                // Akşam Aktivitesi
                ListTile(
                  leading:
                      Icon(Icons.nightlight_round, color: Colors.deepPurple),
                  title: Text('Akşam Aktivitesi'),
                  subtitle: Text(
                      dailyProgram.eveningExercise?.title ?? 'Belirtilmedi'),
                  onTap: () {
                    Navigator.pop(context); // Dialog'u kapat
                    _showEditDialog(
                        dailyProgram.eveningExercise ??
                            ProgramItem(
                              type: ProgramItemType.workout,
                              title: 'Akşam Aktivitesi',
                              icon: Icons.nightlight_round,
                              color: Colors.deepPurple,
                            ),
                        'evening');
                  },
                ),
                Divider(),
                // Akşam Yemeği
                ListTile(
                  leading: Icon(Icons.dinner_dining, color: Colors.teal),
                  title: Text('Akşam Yemeği'),
                  subtitle: Text(dailyProgram.dinner?.title ?? 'Belirtilmedi'),
                  onTap: () {
                    Navigator.pop(context); // Dialog'u kapat
                    _showEditDialog(
                        dailyProgram.dinner ??
                            ProgramItem(
                              type: ProgramItemType.meal,
                              title: 'Akşam Yemeği',
                              icon: Icons.dinner_dining,
                              color: Colors.teal,
                            ),
                        'dinner');
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text('İptal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
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
                  padding:
                      const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        isDarkMode
                            ? const Color(0xFF2C2C2C)
                            : AppTheme.primaryColor.withValues(alpha: 0.7),
                        isDarkMode
                            ? const Color(0xFF1F1F1F)
                            : AppTheme.primaryColor,
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
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
                              debugPrint(
                                  'Seçilen gün: $index (${_weekDays[index]})');
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
                                        ? AppTheme.accentColor
                                            .withValues(alpha: 0.2)
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
                                title: _weeklyProgram[_selectedDayIndex]
                                    .morningExercise
                                    .title,
                                icon: _weeklyProgram[_selectedDayIndex]
                                    .morningExercise
                                    .icon,
                                color: AppTheme.morningExerciseColor,
                                item: _weeklyProgram[_selectedDayIndex]
                                    .morningExercise,
                                onTap: () {
                                  final item = _weeklyProgram[_selectedDayIndex]
                                      .morningExercise;
                                  _showEditDialog(item, 'morning');
                                },
                              ),

                              const SizedBox(height: 16),

                              // Öğle Yemeği
                              _buildProgramCard(
                                context: context,
                                title: _weeklyProgram[_selectedDayIndex]
                                    .lunch
                                    .title,
                                icon: _weeklyProgram[_selectedDayIndex]
                                    .lunch
                                    .icon,
                                color: AppTheme.lunchColor,
                                item: _weeklyProgram[_selectedDayIndex].lunch,
                                onTap: () => _showEditDialog(
                                    _weeklyProgram[_selectedDayIndex].lunch,
                                    'lunch'),
                              ),

                              const SizedBox(height: 16),

                              // Akşam Egzersizi
                              _buildProgramCard(
                                context: context,
                                title: _weeklyProgram[_selectedDayIndex]
                                    .eveningExercise
                                    .title,
                                icon: _weeklyProgram[_selectedDayIndex]
                                    .eveningExercise
                                    .icon,
                                color: AppTheme.eveningExerciseColor,
                                item: _weeklyProgram[_selectedDayIndex]
                                    .eveningExercise,
                                onTap: () {
                                  final item = _weeklyProgram[_selectedDayIndex]
                                      .eveningExercise;
                                  _showEditDialog(item, 'evening');
                                },
                              ),

                              const SizedBox(height: 16),

                              // Akşam Yemeği
                              _buildProgramCard(
                                context: context,
                                title: _weeklyProgram[_selectedDayIndex]
                                    .dinner
                                    .title,
                                icon: _weeklyProgram[_selectedDayIndex]
                                    .dinner
                                    .icon,
                                color: AppTheme.dinnerColor,
                                item: _weeklyProgram[_selectedDayIndex].dinner,
                                onTap: () => _showEditDialog(
                                    _weeklyProgram[_selectedDayIndex].dinner,
                                    'dinner'),
                              ),

                              const SizedBox(height: 24),

                              // Notlar ve tavsiyeler
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.grey.shade800
                                      : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
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
                                          color: Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.lightBlue.shade300
                                              : Colors.blue,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Genel Tavsiyeler',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color:
                                                Theme.of(context).brightness ==
                                                        Brightness.dark
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
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
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
    required ProgramItem item,
    required VoidCallback onTap,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bool isWorkout = item.type == ProgramItemType.workout;
    final bool hasSets =
        item.programSets != null && item.programSets!.isNotEmpty;
    bool isExpanded = _expansionStates[item.id ?? ''] ?? false;

    Widget cardContent = Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Colors.black26
                      : Colors.white.withValues(alpha: 0.7),
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
              if (hasSets)
                Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
            ],
          ),
          if (!hasSets) ...[
            const Divider(height: 24),
            _buildItemContent(context, item, isDarkMode),
          ]
        ],
      ),
    );

    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: isDarkMode ? 0.3 : 0.2),
                color.withValues(alpha: isDarkMode ? 0.1 : 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: isWorkout
              ? Theme(
                  data: Theme.of(context).copyWith(
                    dividerColor: Colors.transparent,
                  ),
                  child: ExpansionTile(
                    key: ValueKey(item.id ?? ''),
                    initiallyExpanded: isExpanded,
                    onExpansionChanged: (expanding) {
                      setState(() {
                        _expansionStates[item.id ?? ''] = expanding;
                      });
                    },
                    title: cardContent,
                    trailing: SizedBox.shrink(),
                    childrenPadding: const EdgeInsets.only(
                        left: 16.0, right: 16.0, bottom: 16.0),
                    tilePadding: EdgeInsets.zero,
                    children: <Widget>[
                      const SizedBox(height: 10),
                      _buildItemContent(context, item, isDarkMode),
                    ],
                  ),
                )
              : InkWell(
                  borderRadius: BorderRadius.circular(12),
                  child: cardContent,
                ),
        ),
      ),
    );
  }

  /// ProgramItem tipine göre içeriği oluşturan yardımcı metod
  Widget _buildItemContent(
      BuildContext context, ProgramItem item, bool isDarkMode) {
    if (item.type == ProgramItemType.workout &&
        item.programSets != null &&
        item.programSets!.isNotEmpty) {
      // Antrenman içeriği (ExpansionTile içinde gösterilecek)
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: item.programSets!.map((set) {
          final exerciseName =
              set.exerciseDetails?.name ?? 'Egzersiz #${set.exerciseId}';

          String details = '';
          if (set.setsDescription != null && set.repsDescription != null) {
            details +=
                '${set.setsDescription} set x ${set.repsDescription} tekrar';
          } else if (set.repsDescription != null) {
            details +=
                '${set.repsDescription}'; // Sadece tekrar veya süre varsa (örn: 30 dk Yürüyüş)
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.chevron_right,
                    size: 16,
                    color: isDarkMode ? Colors.white54 : Colors.black54),
                const SizedBox(width: 4),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 15,
                        color: isDarkMode ? Colors.white70 : Colors.black87,
                      ),
                      children: <TextSpan>[
                        TextSpan(
                            text: '$exerciseName: ',
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        TextSpan(text: details),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      );
    } else {
      // Yemek, dinlenme veya diğer içerik (açıklama)
      if (item.type == ProgramItemType.workout) {
        return Text(
          item.description ?? 'Bu antrenman için henüz egzersiz eklenmemiş.',
          style: TextStyle(
            fontSize: 15,
            color: isDarkMode ? Colors.white70 : Colors.black87,
            fontStyle: FontStyle.italic,
          ),
        );
      } else {
        return Text(
          item.description ?? 'Açıklama yok.',
          style: TextStyle(
            fontSize: 15,
            color: isDarkMode ? Colors.white70 : Colors.black87,
          ),
        );
      }
    }
  }
}
