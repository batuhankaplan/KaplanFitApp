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
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () {
                debugPrint("KaplanAppBar: Geri butonu tıklandı");
                Navigator.of(context).pop();
              },
            )
          : null,
    );
  }

  @override
  Size get preferredSize => isRequiredPage ||
          title == 'Program' ||
          title == 'İstatistikler' ||
          title ==
              'Antrenman Programı' || // Antrenman Programı için yükseklik ayarı
          title.contains('Programı Düzenle') ||
          title.contains('Yeni Kategori') ||
          title == 'Egzersiz Seç'
      ? const Size.fromHeight(kToolbarHeight)
      : const Size.fromHeight(0); // AppBar gösterilmeyecekse yüksekliği 0 olsun
}
