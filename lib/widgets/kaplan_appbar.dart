import 'package:flutter/material.dart';
import '../theme.dart';

class KaplanAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool centerTitle;
  final double elevation;
  final Widget? leading;

  const KaplanAppBar({
    Key? key,
    this.title = 'KaplanFIT',
    this.actions,
    this.centerTitle = true,
    this.elevation = 0,
    this.leading,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return AppBar(
      backgroundColor: isDarkMode ? const Color(0xFF0A1A2F) : AppTheme.primaryColor,
      elevation: elevation,
      centerTitle: centerTitle,
      leading: leading,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/kaplan_logo.png',
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.fitness_center,
                    color: Colors.white,
                  );
                },
              ),
            ),
          ),
          SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ],
      ),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
} 