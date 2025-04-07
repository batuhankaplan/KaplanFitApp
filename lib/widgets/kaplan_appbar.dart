import 'package:flutter/material.dart';
import '../theme.dart';

class KaplanAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool isDarkMode;
  final List<Widget>? actions;
  final bool showBackButton;
  final bool isRequiredPage; // Program ve İstatistikler sayfaları için

  const KaplanAppBar({
    Key? key,
    required this.title,
    required this.isDarkMode,
    this.actions,
    this.showBackButton = true,
    this.isRequiredPage = false, // Varsayılan olarak false
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Program ve İstatistikler sayfaları dışında AppBar gösterme
    if (!isRequiredPage && title != 'Program' && title != 'İstatistikler') {
      return PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: SafeArea(
          child: Container(
            height: 0,
          ),
        ),
      );
    }
    
    return AppBar(
      backgroundColor: AppTheme.primaryColor,
      elevation: 4,
      shadowColor: Colors.black26,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
      centerTitle: true,
      actions: actions,
      leading: showBackButton && Navigator.canPop(context)
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () => Navigator.of(context).pop(),
            )
          : null,
    );
  }

  @override
  Size get preferredSize => isRequiredPage || title == 'Program' || title == 'İstatistikler' 
      ? const Size.fromHeight(kToolbarHeight)
      : const Size.fromHeight(kToolbarHeight); // Tüm durumlarda boşluk bırak
} 