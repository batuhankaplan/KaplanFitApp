import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/badge_model.dart';
import '../providers/gamification_provider.dart';
import '../widgets/badge_widget.dart';
import '../widgets/badge_detail_dialog.dart';
import '../theme.dart';

class AllBadgesScreen extends StatelessWidget {
  const AllBadgesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final gamificationProvider = Provider.of<GamificationProvider>(context);

    return Scaffold(
      backgroundColor:
          isDarkMode ? AppTheme.darkBackgroundColor : const Color(0xFFF8F9FF),
      appBar: AppBar(
        title: const Text(
          'Rozetlerim',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryColor,
                AppTheme.primaryColor.withOpacity(0.8),
              ],
            ),
          ),
        ),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: _buildHeroSection(context, gamificationProvider, isDarkMode),
          ),
          SliverToBoxAdapter(
            child: _buildStatsCards(context, gamificationProvider, isDarkMode),
          ),
          SliverToBoxAdapter(
            child: _buildCategoriesSection(
                context, gamificationProvider, isDarkMode),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(
      BuildContext context, GamificationProvider provider, bool isDarkMode) {
    final totalEarnedPoints = provider.totalPoints;
    final unlockedCount = provider.unlockedBadges.length;
    final totalBadgesCount = provider.badges.length;
    final badgeProgress =
        totalBadgesCount > 0 ? unlockedCount / totalBadgesCount : 0.0;

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.withOpacity(0.1),
            AppTheme.secondaryColor.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryColor,
                  AppTheme.secondaryColor,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 100,
                  height: 100,
                  child: CircularProgressIndicator(
                    value: badgeProgress,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 8,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.emoji_events_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$unlockedCount',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Toplam $unlockedCount/$totalBadgesCount Rozet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$totalEarnedPoints Puan Kazandınız',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(
      BuildContext context, GamificationProvider provider, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Günlük Seri',
              '${provider.streaks['daily'] ?? 0} gün',
              Icons.calendar_today_rounded,
              AppTheme.primaryColor,
              isDarkMode,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Antrenman',
              '${provider.workoutCount}',
              Icons.fitness_center_rounded,
              AppTheme.workoutColor,
              isDarkMode,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Su Seri',
              '${provider.streaks['water'] ?? 0} gün',
              Icons.water_drop_rounded,
              AppTheme.waterColor,
              isDarkMode,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? AppTheme.darkCardBackgroundColor : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: color.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: isDarkMode
                  ? AppTheme.darkSecondaryTextColor
                  : AppTheme.secondaryTextColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesSection(
      BuildContext context, GamificationProvider provider, bool isDarkMode) {
    final Map<String, List<BadgeModel>> categorizedBadges = {
      'Günlük Hedefler': provider.badges
          .where((badge) =>
              badge.type == BadgeType.dailyStreak ||
              badge.type == BadgeType.weeklyGoal ||
              badge.type == BadgeType.monthlyGoal ||
              badge.type == BadgeType.yearlyGoal)
          .toList(),
      'Antrenman': provider.badges
          .where((badge) =>
              badge.type == BadgeType.workoutCount ||
              badge.type == BadgeType.workoutStreak)
          .toList(),
      'Su İçme': provider.badges
          .where((badge) => badge.type == BadgeType.waterStreak)
          .toList(),
      'Kilo Yönetimi': provider.badges
          .where((badge) =>
              badge.type == BadgeType.weightLoss ||
              badge.type == BadgeType.weightGain ||
              badge.type == BadgeType.targetWeight ||
              badge.type == BadgeType.maintainWeight)
          .toList(),
      'Beslenme': provider.badges
          .where((badge) => badge.type == BadgeType.calorieStreak)
          .toList(),
      'Sosyal': provider.badges
          .where((badge) => badge.type == BadgeType.chatInteraction)
          .toList(),
      'Genel': provider.badges
          .where((badge) =>
              badge.type == BadgeType.beginner ||
              badge.type == BadgeType.consistent ||
              badge.type == BadgeType.expert ||
              badge.type == BadgeType.master)
          .toList(),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: categorizedBadges.entries.map((entry) {
        if (entry.value.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    entry.key,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${entry.value.where((badge) => provider.unlockedBadges.any((unlockedBadge) => unlockedBadge.id == badge.id)).length}/${entry.value.length}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 320,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: entry.value.length,
                itemBuilder: (context, index) {
                  final badge = entry.value[index];
                  final isUnlocked = provider.unlockedBadges
                      .any((unlockedBadge) => unlockedBadge.id == badge.id);

                  return Container(
                    width: 200,
                    margin: const EdgeInsets.only(right: 16),
                    child: _buildBadgeCard(
                        context, badge, isUnlocked, provider, isDarkMode),
                  );
                },
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildBadgeCard(BuildContext context, BadgeModel badge,
      bool isUnlocked, GamificationProvider provider, bool isDarkMode) {
    final progress = provider.getBadgeProgress(badge);

    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => BadgeDetailDialog(badge: badge),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? AppTheme.darkCardBackgroundColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              spreadRadius: 0,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(
            color: isUnlocked
                ? badge.color.withOpacity(0.5)
                : Colors.grey.withOpacity(0.1),
            width: 2,
          ),
          gradient: isUnlocked
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    badge.color.withOpacity(0.05),
                  ],
                )
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  BadgeWidget(
                    badge: badge,
                    size: 80,
                  ),
                  if (!isUnlocked)
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                badge.name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isUnlocked
                      ? (isDarkMode ? Colors.white : Colors.black87)
                      : Colors.grey,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                badge.description,
                style: TextStyle(
                  fontSize: 12,
                  color: isUnlocked
                      ? (isDarkMode
                          ? AppTheme.darkSecondaryTextColor
                          : AppTheme.secondaryTextColor)
                      : Colors.grey,
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              if (!isUnlocked && progress > 0) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${(progress * 100).toInt()}% Tamamlandı',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if (isUnlocked) ...[
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.star_rounded,
                        color: AppTheme.secondaryColor,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${badge.points} Puan',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.secondaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
