import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/nutrition_provider.dart';
import '../providers/activity_provider.dart';
import '../models/user_model.dart';
import '../theme.dart';

class HomeMiniDashboard extends StatefulWidget {
  const HomeMiniDashboard({Key? key}) : super(key: key);

  @override
  State<HomeMiniDashboard> createState() => _HomeMiniDashboardState();
}

class _HomeMiniDashboardState extends State<HomeMiniDashboard> {
  final TextEditingController _waterInputController = TextEditingController();

  Future<void> _showAddWaterDialog(
      BuildContext context, UserProvider userProvider) async {
    _waterInputController.clear();
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Su Ekle (ml)'),
          content: TextField(
            controller: _waterInputController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              hintText: "Örn: 250",
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('İptal'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Ekle'),
              onPressed: () {
                final double? amount =
                    double.tryParse(_waterInputController.text);
                if (amount != null && amount > 0) {
                  userProvider.logWater(amount);
                  Navigator.of(dialogContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$amount ml su eklendi.'),
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Lütfen geçerli bir miktar girin.'),
                      duration: Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: Colors.redAccent,
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

  @override
  void dispose() {
    _waterInputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final nutritionProvider = Provider.of<NutritionProvider>(context);
    final activityProvider = Provider.of<ActivityProvider>(context);
    final UserModel? user = userProvider.user;

    final double targetCalories = user?.targetCalories ?? 2000;
    final double currentCalories = nutritionProvider.currentDailyCalories;

    final double weeklyActivityTarget = user?.weeklyActivityGoal ?? 0;
    final double dailyActivityTarget =
        weeklyActivityTarget > 0 ? weeklyActivityTarget / 7 : 15;
    final double currentDailyActivity =
        activityProvider.currentDailyActivityMinutes.toDouble();

    final double targetWaterMl = (user?.targetWaterIntake ?? 2.5) * 1000;
    final double currentWaterMl = user?.currentDailyWaterIntake ?? 0.0;

    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDarkMode ? AppTheme.darkSurfaceColor : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Günlük İlerlemen',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
            if (user == null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Center(
                  child: Text(
                    'Hedeflerini görmek için lütfen giriş yapın veya profil oluşturun.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                      fontSize: 14,
                    ),
                  ),
                ),
              )
            else
              Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildCircularGoalProgress(
                          context: context,
                          title: 'Kalori',
                          currentValue: currentCalories,
                          targetValue: targetCalories,
                          unit: 'Kcal',
                          icon: Icons.local_fire_department_rounded,
                          primaryColor: Colors.orange.shade700,
                          secondaryColor:
                              Colors.orange.shade200.withOpacity(0.2),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildCircularGoalProgress(
                          context: context,
                          title: 'Aktivite',
                          currentValue: currentDailyActivity,
                          targetValue: dailyActivityTarget,
                          unit: 'dk',
                          icon: Icons.directions_run_rounded,
                          primaryColor: AppTheme.activityColor,
                          secondaryColor:
                              AppTheme.activityColor.withOpacity(0.3),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildLinearGoalProgress(
                    context: context,
                    title: 'Su Tüketimi',
                    currentValue: currentWaterMl,
                    targetValue: targetWaterMl,
                    unit: 'ml',
                    icon: Icons.water_drop_rounded,
                    color: AppTheme.waterReminderColor,
                    onAddWater: (amount) {
                      userProvider.logWater(amount);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('$amount ml su eklendi.'),
                          duration: const Duration(seconds: 1),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    onManualAddWater: () =>
                        _showAddWaterDialog(context, userProvider),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircularGoalProgress({
    required BuildContext context,
    required String title,
    required double currentValue,
    required double targetValue,
    required String unit,
    required IconData icon,
    required Color primaryColor,
    required Color secondaryColor,
  }) {
    final double progress =
        targetValue > 0 ? (currentValue / targetValue).clamp(0.0, 1.0) : 0.0;
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: primaryColor, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDarkMode
                    ? Colors.white.withOpacity(0.9)
                    : Colors.black.withOpacity(0.8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: 120,
          child: Column(
            children: [
              SizedBox(
                width: 75,
                height: 75,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 75,
                      height: 75,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 8,
                        backgroundColor: secondaryColor,
                        valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                      ),
                    ),
                    Text(
                      '${(progress * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                targetValue > 0
                    ? '${currentValue.toStringAsFixed(0)} / ${targetValue.toStringAsFixed(0)} $unit'
                    : '${currentValue.toStringAsFixed(0)} $unit',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: primaryColor.withOpacity(0.9),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLinearGoalProgress({
    required BuildContext context,
    required String title,
    required double currentValue,
    required double targetValue,
    required String unit,
    required IconData icon,
    required Color color,
    required Function(double) onAddWater,
    required VoidCallback onManualAddWater,
  }) {
    final double progress =
        targetValue > 0 ? (currentValue / targetValue).clamp(0.0, 1.0) : 0.0;
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode
                        ? Colors.white.withOpacity(0.9)
                        : Colors.black.withOpacity(0.8),
                  ),
                ),
              ],
            ),
            Text(
              targetValue > 0
                  ? '${currentValue.toStringAsFixed(0)} / ${targetValue.toStringAsFixed(0)} $unit'
                  : '${currentValue.toStringAsFixed(0)} $unit',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (targetValue > 0)
          LinearProgressIndicator(
            value: progress,
            backgroundColor: color.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 10,
            borderRadius: BorderRadius.circular(5),
          )
        else
          Container(height: 10),
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.spaceEvenly,
          spacing: 8.0,
          runSpacing: 8.0,
          children: [
            _buildWaterActionButton(context, '-100ml', () => onAddWater(-100),
                Colors.redAccent.shade400,
                isOutlined: true,
                customPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
            _buildWaterActionButton(
                context, '+100ml', () => onAddWater(100), color,
                customPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
            _buildWaterActionButton(
                context, '+250ml', () => onAddWater(250), color,
                customPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
            _buildWaterActionButton(
                context, '+500ml', () => onAddWater(500), color,
                customPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
          ],
        ),
      ],
    );
  }

  Widget _buildWaterActionButton(
      BuildContext context, String label, VoidCallback onPressed, Color color,
      {bool isOutlined = false, EdgeInsetsGeometry? customPadding}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor:
            isOutlined ? Colors.transparent : color.withOpacity(0.15),
        foregroundColor: color,
        side:
            isOutlined ? BorderSide(color: color, width: 1.5) : BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        padding: customPadding ??
            const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        elevation: isOutlined ? 0 : 1,
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
      ),
      child: Text(label),
    );
  }
}
