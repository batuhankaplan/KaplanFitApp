import 'package:flutter/material.dart';
import '../models/badge_model.dart';
import 'badge_widget.dart';

class BadgeGrid extends StatelessWidget {
  final List<BadgeModel> badges;
  final Function(BadgeModel)? onBadgeTap;
  final double badgeSize;
  final double spacing;
  final int crossAxisCount;
  final bool showInfo;

  const BadgeGrid({
    Key? key,
    required this.badges,
    this.onBadgeTap,
    this.badgeSize = 70.0,
    this.spacing = 12.0,
    this.crossAxisCount = 4,
    this.showInfo = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing +
            (showInfo
                ? 20
                : 0), // Eğer bilgi gösteriliyorsa dikey boşluğu artır
        childAspectRatio:
            showInfo ? 0.8 : 1.0, // İsim gösteriliyorsa aspect ratio'yu ayarla
      ),
      itemCount: badges.length,
      itemBuilder: (context, index) {
        final badge = badges[index];
        return BadgeWidget(
          badge: badge,
          size: badgeSize,
          showInfo: showInfo,
          onTap: onBadgeTap != null ? () => onBadgeTap!(badge) : null,
        );
      },
    );
  }
}
