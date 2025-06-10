import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/badge_model.dart';
import '../providers/gamification_provider.dart';
import 'badge_widget.dart';
import 'badge_detail_dialog.dart';
import '../theme.dart';

class BadgesShowcase extends StatelessWidget {
  final int maxBadges;
  final String title;
  final VoidCallback? onViewAllPressed;

  const BadgesShowcase({
    Key? key,
    this.maxBadges = 5,
    this.title = 'Rozetlerim',
    this.onViewAllPressed,
  });

  @override
  Widget build(BuildContext context) {
    final gamificationProvider = Provider.of<GamificationProvider>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (gamificationProvider.isLoading) {
      return _buildLoadingState(context);
    }

    // Açılan rozetler ve kilitli rozetler
    final unlockedBadges = gamificationProvider.unlockedBadges;
    final lockedBadges = gamificationProvider.lockedBadges;

    // Önce açılan, sonra kilitli rozetleri göster (sınırlı sayıda)
    final displayBadges = [
      ...unlockedBadges,
      ...lockedBadges,
    ].take(maxBadges).toList();

    // Tüm rozetlerin sayısı
    final totalBadges = gamificationProvider.badges.length;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: isDarkMode ? AppTheme.darkSurfaceColor : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, unlockedBadges.length, totalBadges),
            if (displayBadges.isEmpty)
              _buildEmptyState(context)
            else
              _buildBadgeList(context, displayBadges),
            if (totalBadges > maxBadges) _buildViewAllButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int unlocked, int total) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final progress = total > 0 ? unlocked / total : 0.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        Row(
          children: [
            Text(
              '$unlocked/$total',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 4,
                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBadgeList(BuildContext context, List<BadgeModel> badges) {
    return Container(
      height: 110, // Sabit yükseklik
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: badges.length,
        itemBuilder: (context, index) {
          final badge = badges[index];
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: BadgeWidget(
              badge: badge,
              size: 70,
              showInfo: true,
              onTap: () => _showBadgeDetails(context, badge),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 120,
      margin: const EdgeInsets.symmetric(vertical: 16),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.emoji_events_outlined,
            size: 40,
            color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade400,
          ),
          const SizedBox(height: 8),
          Text(
            'Henüz rozet kazanmadınız',
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Görevleri tamamlayarak rozetler kazanın',
            style: TextStyle(
              fontSize: 12,
              color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewAllButton(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: onViewAllPressed,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Tümünü Gör',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_forward_ios,
              size: 12,
              color: AppTheme.primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        height: 180,
        padding: const EdgeInsets.all(16),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }

  void _showBadgeDetails(BuildContext context, BadgeModel badge) {
    showDialog(
      context: context,
      builder: (context) => BadgeDetailDialog(badge: badge),
    );
  }
}
