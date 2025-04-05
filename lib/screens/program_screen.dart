import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../models/program/daily_program.dart';
import '../models/program/program_item.dart';
import '../services/program_service.dart';
import '../utils/animations.dart';

class ProgramScreen extends StatefulWidget {
  const ProgramScreen({Key? key}) : super(key: key);

  @override
  _ProgramScreenState createState() => _ProgramScreenState();
}

class _ProgramScreenState extends State<ProgramScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedDayIndex = 0;
  bool _isLoading = false;
  
  // Animasyon değişkenleri
  final List<GlobalKey<AnimatedListState>> _listKeys = List.generate(7, (_) => GlobalKey<AnimatedListState>());
  
  // Sabit stil tanımları
  static const _titleTextStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );
  
  static const _subtitleTextStyle = TextStyle(
    fontSize: 16,
    color: Colors.white70,
  );
  
  static const _tipTitleTextStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );
  
  static const _tipTextStyle = TextStyle(
    fontSize: 16,
    color: Colors.white,
  );

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
    
    // Provider üzerinden program servisini al
    final programService = Provider.of<ProgramService>(context);
    
    // Program servisi üzerinden gün isimlerini al
    final List<String> weekDays = programService.getCurrentProgram()?.dailyPrograms.map((p) => p.dayName).toList() ?? 
        const ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];

    return Scaffold(
      body: Column(
        children: [
          Container(
            color: const Color(0xFF303030), // NavigationBar ile aynı renk
            width: double.infinity,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              padding: const EdgeInsets.only(left: 0), // Sol tarafta sıfır padding
              tabAlignment: TabAlignment.start, // Tab'ları sola hizala
              labelPadding: const EdgeInsets.symmetric(horizontal: 16.0),
              labelColor: Theme.of(context).primaryColor, // Seçili sekme turuncu
              unselectedLabelColor: Colors.white.withOpacity(0.7),
              indicatorColor: Theme.of(context).primaryColor, // İndikatör turuncu
              tabs: weekDays.map((day) => Tab(text: day)).toList(),
            ),
          ),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  // Animasyonlu scroll için bouncing fizik ekle
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildDayProgramPage(context, 0), // Pazartesi
                    _buildDayProgramPage(context, 1), // Salı
                    _buildDayProgramPage(context, 2), // Çarşamba
                    _buildDayProgramPage(context, 3), // Perşembe
                    _buildDayProgramPage(context, 4), // Cuma
                    _buildDayProgramPage(context, 5), // Cumartesi
                    _buildDayProgramPage(context, 6), // Pazar
                  ],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayProgramPage(BuildContext context, int dayIndex) {
    // Program servisinden günlük programı al
    final programService = Provider.of<ProgramService>(context);
    final dailyProgram = programService.getDailyProgram(dayIndex);
    
    if (dailyProgram == null) {
      return const Center(
        child: Text('Bu gün için program bulunamadı'),
      );
    }
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Program kartları
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: ListView.builder(
                key: ValueKey<int>(dayIndex), // AnimatedSwitcher için her tab için unique key
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: dailyProgram.items.length,
                itemBuilder: (context, index) {
                  // Her kart için sıralı gecikme ekleyerek animasyon
                  return _buildProgramItemCard(dailyProgram.items[index]);
                },
              ),
            ),
          ),
          
          // Genel Tavsiyeler kartı
          if (dailyProgram.tips.isNotEmpty)
            _buildTipsCard(dailyProgram.tips),
        ],
      ),
    );
  }
  
  /// Kademeli animasyon efekti için widget
  Widget _buildProgramItemCard(ProgramItem item) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      child: InkWell(
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        onTap: () {
          // Dokunma efekti ekleyerek kartın etkileşimli olduğunu gösterelim
          // (Gelecekte detay sayfası açılabilir)
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(12)),
            color: item.color,
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: Colors.white24,
              child: Icon(item.icon, color: Colors.white),
            ),
            title: Text(
              item.title,
              style: _titleTextStyle,
            ),
            subtitle: Text(
              item.description,
              style: item.description.length > 50 
                  ? _subtitleTextStyle 
                  : _subtitleTextStyle.copyWith(height: 1.5),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
          ),
        ),
      ),
    );
  }
  
  Widget _buildTipsCard(List<String> tips) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      elevation: 4,
      color: AppTheme.primaryColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Günün İpuçları",
              style: TextStyle(
                fontSize: 20, 
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            ...tips.map((tip) => KFAnimatedTip(tip: tip)).toList(),
          ],
        ),
      ),
    );
  }
} 