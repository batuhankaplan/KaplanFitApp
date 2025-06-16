import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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
  });

  @override
  Widget build(BuildContext context) {
    // Kontrol edilen sayfaları güncelleyelim
    if (!isRequiredPage &&
        title != 'Program' &&
        title != 'İstatistikler' &&
        title != 'Egzersiz Seç' &&
        title !=
            'Bildirim Ayarları' && // Bildirim Ayarları sayfası için eklendi
        title !=
            'Antrenman Programı' && // Antrenman Programı için appbar göstermek için ekledim
        !title.contains('Programı Düzenle') &&
        !title.contains('Yeni Kategori')) {
      return PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: SafeArea(
          child: SizedBox(height: 0),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: actions,
        leading: showBackButton
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: () {
                  debugPrint("KaplanAppBar: Geri butonu tıklandı");
                  Navigator.of(context).pop();
                },
              )
            : null,
      ),
    );
  }

  @override
  Size get preferredSize => isRequiredPage ||
          title == 'Program' ||
          title == 'İstatistikler' ||
          title ==
              'Bildirim Ayarları' || // Bildirim Ayarları için yükseklik ayarı
          title ==
              'Antrenman Programı' || // Antrenman Programı için yükseklik ayarı
          title.contains('Programı Düzenle') ||
          title.contains('Yeni Kategori') ||
          title == 'Egzersiz Seç'
      ? const Size.fromHeight(kToolbarHeight)
      : const Size.fromHeight(0); // AppBar gösterilmeyecekse yüksekliği 0 olsun
}
