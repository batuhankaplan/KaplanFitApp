import 'package:flutter/material.dart';
import '../models/badge_model.dart';

class BadgeWidget extends StatelessWidget {
  final BadgeModel badge;
  final VoidCallback? onTap;
  final double size;
  final bool showInfo;

  const BadgeWidget({
    Key? key,
    required this.badge,
    this.onTap,
    this.size = 60.0,
    this.showInfo = false,
  }) ;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildBadgeIcon(context),
          if (showInfo) ...[
            const SizedBox(height: 4),
            _buildBadgeTitle(context),
          ],
        ],
      ),
    );
  }

  Widget _buildBadgeIcon(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isUnlocked = badge.isUnlocked;

    return Stack(
      alignment: Alignment.center,
      children: [
        // Rozet arka planı
        Container(width: size, height: size,
          decoration: BoxDecoration(
            color: isUnlocked
                ? badge.color.withValues(alpha:0.2)
                : (isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300),
            shape: BoxShape.circle,
            border: Border.all(
              color: isUnlocked ? badge.color : Colors.grey.shade500,
              width: 2,
            ),
            boxShadow: isUnlocked
                ? [
                    BoxShadow(
                      color: badge.color.withValues(alpha:0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                    )
                  ]
                : null,
          ),
          child: Padding(
            padding: EdgeInsets.all(size * 0.2),
            child: Center(
              child: _buildBadgeContent(isUnlocked),
            ),
          ),
        ),

        // Rozet kilit durumu
        if (!isUnlocked)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha:0.5),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  Icons.lock,
                  color: Colors.white,
                  size: size * 0.4,
                ),
              ),
            ),
          ),

        // Rozet nadir derecesi
        if (isUnlocked)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: _getRarityColor(badge.rarity),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 1,
                ),
              ),
              width: size * 0.3,
              height: size * 0.3,
              child: Center(
                child: Text(
                  _getRarityShortName(badge.rarity),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: size * 0.12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBadgeContent(bool isUnlocked) {
    IconData iconData;

    switch (badge.type) {
      case BadgeType.dailyStreak:
        switch (badge.threshold) {
          case 3:
            iconData = Icons.looks_3_rounded; // 3 günlük seri
            break;
          case 7:
            iconData = Icons.calendar_view_week_rounded; // 7 günlük seri
            break;
          case 30:
            iconData = Icons.calendar_month_rounded; // 30 günlük seri
            break;
          case 90:
            iconData = Icons.calendar_view_month_rounded; // 90 günlük seri
            break;
          case 365:
            iconData = Icons.emoji_events_rounded; // 365 günlük seri
            break;
          default:
            iconData = Icons.calendar_today_rounded;
        }
        break;
      case BadgeType.weeklyGoal:
        iconData = Icons.flag_rounded;
        break;
      case BadgeType.monthlyGoal:
        iconData = Icons.insert_invitation_rounded;
        break;
      case BadgeType.yearlyGoal:
        iconData = Icons.workspace_premium_rounded;
        break;
      case BadgeType.workoutCount:
        switch (badge.threshold) {
          case 1:
            iconData = Icons.fitness_center_rounded; // İlk antrenman
            break;
          case 10:
            iconData = Icons.sports_gymnastics_rounded; // 10 antrenman
            break;
          case 50:
            iconData = Icons.sports_martial_arts_rounded; // 50 antrenman
            break;
          case 100:
            iconData = Icons.directions_run_rounded; // 100 antrenman
            break;
          case 500:
            iconData = Icons.sports_score_rounded; // 500 antrenman
            break;
          default:
            iconData = Icons.fitness_center_rounded;
        }
        break;
      case BadgeType.waterStreak:
        switch (badge.threshold) {
          case 5:
            iconData = Icons.water_drop_rounded; // 5 günlük su serisi
            break;
          case 20:
            iconData = Icons.water_rounded; // 20 günlük su serisi
            break;
          default:
            iconData = Icons.water_drop_rounded;
        }
        break;
      case BadgeType.weightLoss:
        switch (badge.threshold) {
          case 1:
            iconData = Icons.monitor_weight_rounded; // 1 kg
            break;
          case 5:
            iconData = Icons.trending_down_rounded; // 5 kg
            break;
          case 10:
            iconData = Icons.balance_rounded; // 10 kg
            break;
          default:
            iconData = Icons.monitor_weight_rounded;
        }
        break;
      case BadgeType.chatInteraction:
        switch (badge.threshold) {
          case 1:
            iconData = Icons.chat_bubble_outline_rounded; // İlk sohbet
            break;
          case 50:
            iconData = Icons.forum_rounded; // 50 sohbet
            break;
          case 100:
            iconData = Icons.psychology_rounded; // 100 sohbet
            break;
          default:
            iconData = Icons.chat_rounded;
        }
        break;
      case BadgeType.beginner:
        iconData = Icons.rocket_launch_rounded;
        break;
      case BadgeType.consistent:
        iconData = Icons.repeat_rounded;
        break;
      case BadgeType.expert:
        iconData = Icons.auto_awesome_rounded;
        break;
      case BadgeType.master:
        iconData = Icons.workspace_premium_rounded;
        break;
    }

    return Icon(
      iconData,
      color: isUnlocked ? badge.color : Colors.grey.shade500,
      size: size * 0.5,
    );
  }

  Widget _buildBadgeTitle(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      width: size * 1.2,
      child: Text(
        badge.name,
        textAlign: TextAlign.center,
        style: textTheme.bodySmall?.copyWith(
          color:
              badge.isUnlocked ? badge.color : Theme.of(context).disabledColor,
          fontWeight: FontWeight.w600,
          fontSize: size * 0.18,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
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

  String _getRarityShortName(BadgeRarity rarity) {
    switch (rarity) {
      case BadgeRarity.common:
        return 'C';
      case BadgeRarity.uncommon:
        return 'U';
      case BadgeRarity.rare:
        return 'R';
      case BadgeRarity.epic:
        return 'E';
      case BadgeRarity.legendary:
        return 'L';
    }
  }
}


