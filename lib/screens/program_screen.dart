import 'package:flutter/material.dart';
import '../theme.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class ProgramScreen extends StatefulWidget {
  const ProgramScreen({Key? key}) : super(key: key);

  @override
  _ProgramScreenState createState() => _ProgramScreenState();
}

class _ProgramScreenState extends State<ProgramScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedDayIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    // Bugünün günü için tabı otomatik seç (0 = Pazartesi, 6 = Pazar)
    final today = DateTime.now().weekday - 1;
    setState(() {
      _selectedDayIndex = today;
    });
    _tabController.animateTo(today);
    
    // Tab değişimi dinleyicisi
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedDayIndex = _tabController.index;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    initializeDateFormatting('tr_TR');
    
    // Tab isimleri
    final List<String> weekDays = [
      'Pazartesi',
      'Salı',
      'Çarşamba',
      'Perşembe',
      'Cuma',
      'Cumartesi',
      'Pazar'
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Haftalık Program'),
        centerTitle: true,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
          indicatorColor: Colors.white,
          tabs: weekDays.map((day) => Tab(text: day)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDayProgramPage(0), // Pazartesi
          _buildDayProgramPage(1), // Salı
          _buildDayProgramPage(2), // Çarşamba
          _buildDayProgramPage(3), // Perşembe
          _buildDayProgramPage(4), // Cuma
          _buildDayProgramPage(5), // Cumartesi
          _buildDayProgramPage(6), // Pazar
        ],
      ),
    );
  }

  Widget _buildDayProgramPage(int dayIndex) {
    // dayIndex: 0 = Pazartesi, 6 = Pazar
    
    // Her günün sabah ve akşam programları ve yemekleri
    final List<String> titles = [];
    final List<String> descriptions = [];
    final List<IconData> icons = [];
    final List<Color> colors = [];
    
    // Sabah Programı, Öğle Yemeği, Akşam Egzersizi, Akşam Yemeği
    icons.add(Icons.sunny);
    icons.add(Icons.lunch_dining);
    icons.add(Icons.fitness_center);
    icons.add(Icons.dinner_dining);
    
    colors.add(AppTheme.morningExerciseColor);
    colors.add(AppTheme.lunchColor);
    colors.add(AppTheme.eveningExerciseColor);
    colors.add(AppTheme.dinnerColor);
    
    titles.add('Sabah Programı');
    titles.add('Öğle Yemeği');
    titles.add('Akşam Egzersizi');
    titles.add('Akşam Yemeği');
    
    switch (dayIndex) {
      case 0: // Pazartesi
        descriptions.add('🏊‍♂️ Havuz kapalı. Dinlen veya evde esneme yap.');
        descriptions.add('🍗 Izgara tavuk, 🍚 pirinç pilavı, 🥗 yağlı salata, 🥛 yoğurt, 🍌 muz, badem/ceviz');
        descriptions.add('🛑 Spor salonu kapalı. Dinlen veya hafif yürüyüş.');
        descriptions.add('🥗 Ton balıklı salata, yoğurt, 🥖 tahıllı ekmek');
        break;
      case 1: // Salı
        descriptions.add('🏊‍♂️ 08:45 - 09:15 yüzme');
        descriptions.add('🥣 Yulaf + süt + muz veya Pazartesi menüsü');
        descriptions.add('(18:00 - 18:45 Ağırlık): Squat, Leg Press, Bench Press, Lat Pull-Down');
        descriptions.add('🍗 Izgara tavuk veya 🐟 ton balıklı salata, yoğurt');
        break;
      case 2: // Çarşamba
        descriptions.add('🏊‍♂️ 08:45 - 09:15 yüzme');
        descriptions.add('🥣 Yulaf + süt + muz veya Pazartesi menüsü');
        descriptions.add('(18:00 - 18:45 Ağırlık): Row, Goblet Squat, Core Çalışmaları');
        descriptions.add('🐔 Tavuk veya 🐟 ton balık, 🥗 yağlı salata, yoğurt');
        break;
      case 3: // Perşembe
        descriptions.add('🏊‍♂️ 08:45 - 09:15 yüzme');
        descriptions.add('🍗 Izgara tavuk, 🍚 pirinç pilavı, 🥗 yağlı salata, 🥛 yoğurt, 🍌 muz, badem/ceviz veya yulaf alternatifi');
        descriptions.add('(18:00 - 18:45 Ağırlık): 🔄 Salı antrenmanı tekrarı');
        descriptions.add('🐔 Tavuk veya 🐟 ton balık, 🥗 salata, yoğurt');
        break;
      case 4: // Cuma
        descriptions.add('🚶‍♂️ İsteğe bağlı yüzme veya yürüyüş');
        descriptions.add('🥚 Tavuk, haşlanmış yumurta, 🥗 yoğurt, salata, kuruyemiş');
        descriptions.add('🤸‍♂️ Dinlenme veya esneme');
        descriptions.add('🍳 Menemen, 🥗 ton balıklı salata, yoğurt');
        break;
      case 5: // Cumartesi
        descriptions.add('🚶‍♂️ Hafif yürüyüş, esneme veya yüzme');
        descriptions.add('🐔 Tavuk, yumurta, pilav, salata');
        descriptions.add('⚡️ İsteğe bağlı egzersiz');
        descriptions.add('🍽️ Sağlıklı serbest menü');
        break;
      case 6: // Pazar
        descriptions.add('🧘‍♂️ Tam dinlenme veya 20-30 dk yürüyüş');
        descriptions.add('🔄 Hafta içi prensipteki öğünler');
        descriptions.add('💤 Dinlenme');
        descriptions.add('🍴 Hafif ve dengeli öğün');
        break;
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Program kartları
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: titles.length,
              itemBuilder: (context, index) {
                return Card(
                  elevation: 3,
                  margin: EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: colors[index],
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.all(16),
                      leading: CircleAvatar(
                        backgroundColor: Colors.white24,
                        child: Icon(icons[index], color: Colors.white),
                      ),
                      title: Text(
                        titles[index],
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      subtitle: Text(
                        descriptions[index],
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Genel Tavsiyeler kartı
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🔖 Genel Tavsiyeler',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 12),
                    _buildTipItem('💧 Günde en az 2-3 litre su iç.'),
                    _buildTipItem('❌ Şekerli içeceklerden uzak dur.'),
                    _buildTipItem('🍽️ Egzersiz yemekten önce, akşam yemeği hafif ve dengeli olsun.'),
                    _buildTipItem('🍌 Her gün 1 muz tüket (potasyum kaynağı).'),
                    _buildTipItem('🥄 Zeytinyağı 1-2 yemek kaşığı yeterlidir.'),
                    _buildTipItem('🏋️‍♂️ Ağırlık antrenmanları: Salı, Çarşamba, Perşembe günleri.'),
                    _buildTipItem('🥣 Yulaf + süt + muz mükemmel bir kahvaltıdır.'),
                    _buildTipItem('🧂 Pirinç pilavında çok fazla tereyağı ve bulyon kullanma.'),
                    _buildTipItem('💤 Sekiz saatlik kaliteli uyku çok önemlidir.'),
                    _buildTipItem('🧂 Tuzu azaltmaya çalış.'),
                  ],
                ),
              ),
            ),
          ),
          
          SizedBox(height: 20),
        ],
      ),
    );
  }
  
  Widget _buildTipItem(String tip) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, color: Colors.white, size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              tip,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 