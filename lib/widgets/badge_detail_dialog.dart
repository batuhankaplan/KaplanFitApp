import 'package:flutter/material.dart';
import '../models/badge_model.dart';
import '../theme.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/gamification_provider.dart';

class BadgeDetailDialog extends StatelessWidget {
  final BadgeModel badge;

  const BadgeDetailDialog({Key? key, required this.badge}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;
    final gamificationProvider = Provider.of<GamificationProvider>(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 10,
      backgroundColor: isDarkMode ? AppTheme.darkSurfaceColor : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeaderRow(context),
            const SizedBox(height: 20),
            _buildContentSection(context, textTheme, isDarkMode),
            const SizedBox(height: 20),
            _buildFooterSection(
                context, textTheme, isDarkMode, gamificationProvider),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: badge.color,
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: Text(
                'Kapat',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            badge.name,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
              color: badge.color,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _getRarityColor(badge.rarity),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _getRarityName(badge.rarity),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContentSection(
      BuildContext context, TextTheme textTheme, bool isDarkMode) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBadgeImage(),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Açıklama',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                badge.description,
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Kazanım',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.star,
                    color: Colors.amber,
                    size: 18,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${badge.points} Puan',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFooterSection(BuildContext context, TextTheme textTheme,
      bool isDarkMode, GamificationProvider gamificationProvider) {
    final progress = gamificationProvider.getBadgeProgress(badge);
    final progressText = gamificationProvider.getProgressText(badge);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (isDarkMode
                ? AppTheme.darkCardBackgroundColor
                : Colors.grey.shade100)
            .withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Durum',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                badge.isUnlocked ? Icons.check_circle : Icons.hourglass_empty,
                color:
                    badge.isUnlocked ? AppTheme.secondaryColor : Colors.amber,
                size: 18,
              ),
              const SizedBox(width: 4),
              Text(
                badge.isUnlocked
                    ? 'Kazanıldı: ${DateFormat('d MMM y', 'tr_TR').format(badge.unlockedAt!)}'
                    : 'Henüz kazanılmadı',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
            ],
          ),
          if (!badge.isUnlocked) ...[
            const SizedBox(height: 12),
            Text(
              'İlerleme: $progressText',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: badge.color.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(badge.color),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBadgeImage() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: badge.color.withOpacity(0.2),
        shape: BoxShape.circle,
        border: Border.all(
          color: badge.color,
          width: 3,
        ),
      ),
      child: Center(
        child: Icon(
          _getBadgeIcon(),
          color: badge.color,
          size: 50,
        ),
      ),
    );
  }

  IconData _getBadgeIcon() {
    switch (badge.type) {
      case BadgeType.dailyStreak:
        switch (badge.threshold) {
          case 3:
            return Icons.looks_3_rounded; // 3 günlük seri
          case 7:
            return Icons.calendar_view_week_rounded; // 7 günlük seri
          case 30:
            return Icons.calendar_month_rounded; // 30 günlük seri
          case 90:
            return Icons.calendar_view_month_rounded; // 90 günlük seri
          case 365:
            return Icons.emoji_events_rounded; // 365 günlük seri
          default:
            return Icons.calendar_today_rounded;
        }
      case BadgeType.weeklyGoal:
        return Icons.flag_rounded;
      case BadgeType.monthlyGoal:
        return Icons.insert_invitation_rounded;
      case BadgeType.yearlyGoal:
        return Icons.workspace_premium_rounded;
      case BadgeType.workoutCount:
        switch (badge.threshold) {
          case 1:
            return Icons.fitness_center_rounded; // İlk antrenman
          case 10:
            return Icons.sports_gymnastics_rounded; // 10 antrenman
          case 50:
            return Icons.sports_martial_arts_rounded; // 50 antrenman
          case 100:
            return Icons.directions_run_rounded; // 100 antrenman
          case 500:
            return Icons.sports_score_rounded; // 500 antrenman
          default:
            return Icons.fitness_center_rounded;
        }
      case BadgeType.waterStreak:
        switch (badge.threshold) {
          case 5:
            return Icons.water_drop_rounded; // 5 günlük su serisi
          case 20:
            return Icons.water_rounded; // 20 günlük su serisi
          default:
            return Icons.water_drop_rounded;
        }
      case BadgeType.weightLoss:
        switch (badge.threshold) {
          case 1:
            return Icons.monitor_weight_rounded; // 1 kg
          case 5:
            return Icons.trending_down_rounded; // 5 kg
          case 10:
            return Icons.balance_rounded; // 10 kg
          default:
            return Icons.monitor_weight_rounded;
        }
      case BadgeType.chatInteraction:
        switch (badge.threshold) {
          case 1:
            return Icons.chat_bubble_outline_rounded; // İlk sohbet
          case 50:
            return Icons.forum_rounded; // 50 sohbet
          case 100:
            return Icons.psychology_rounded; // 100 sohbet
          default:
            return Icons.chat_rounded;
        }
      case BadgeType.beginner:
        return Icons.rocket_launch_rounded;
      case BadgeType.consistent:
        return Icons.repeat_rounded;
      case BadgeType.expert:
        return Icons.auto_awesome_rounded;
      case BadgeType.master:
        return Icons.workspace_premium_rounded;
      default:
        return Icons.stars;
    }
  }

  String _getThresholdUnit(BadgeType type) {
    switch (type) {
      case BadgeType.dailyStreak:
      case BadgeType.waterStreak:
        return 'gün';
      case BadgeType.workoutCount:
        return 'antrenman';
      case BadgeType.chatInteraction:
        return 'sohbet';
      case BadgeType.weightLoss:
        return 'kg';
      default:
        return 'kez';
    }
  }

  Color _getRarityColor(BadgeRarity rarity) {
    switch (rarity) {
      case BadgeRarity.common:
        return Colors.green;
      case BadgeRarity.uncommon:
        return Colors.blue;
      case BadgeRarity.rare:
        return Colors.purple;
      case BadgeRarity.epic:
        return Colors.orange;
      case BadgeRarity.legendary:
        return Colors.red;
    }
  }

  String _getRarityName(BadgeRarity rarity) {
    switch (rarity) {
      case BadgeRarity.common:
        return 'Yaygın';
      case BadgeRarity.uncommon:
        return 'Az Yaygın';
      case BadgeRarity.rare:
        return 'Nadir';
      case BadgeRarity.epic:
        return 'Epik';
      case BadgeRarity.legendary:
        return 'Efsanevi';
    }
  }
}
