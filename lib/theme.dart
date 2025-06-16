import 'package:flutter/material.dart';

class AppTheme {
  // Ana renkler
  static const Color primaryColor = Color(0xFF5D69BE); // Mor-mavi ana renk
  static const Color secondaryColor = Color(0xFF26C485); // Yeşil ikincil renk
  static const Color accentColor =
      Color(0xFFFF6B6B); // Canlı mercan aksan rengi
  static const Color infoColor = Color(0xFF2196F3); // Bilgi rengi - mavi

  // Arka plan ve metin renkleri
  static const Color backgroundColor = Color(0xFFF6F8FE);
  static const Color darkBackgroundColor = Color(0xFF121219);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color darkSurfaceColor = Color(0xFF1A1A26);
  static const Color cardBackgroundColor = Color(0xFF1C2E5E);
  static const Color darkCardBackgroundColor = Color(0xFF242436);
  static const Color textColor = Color(0xFF333333);
  static const Color darkTextColor = Color(0xFFE1E1E1);
  static const Color secondaryTextColor = Color(0xFF757575);
  static const Color darkSecondaryTextColor = Color(0xFFAAAAAA);

  // Görev kartı renkleri
  static const Color morningExerciseColor =
      Color(0xFF5878FF); // Sabah egzersizi (mavi)
  static const Color lunchColor = Color(0xFFFF8F5D); // Öğle yemeği (turuncu)
  static const Color eveningExerciseColor =
      Color(0xFFAF52DE); // Akşam egzersizi (mor)
  static const Color dinnerColor = Color(0xFF2DB886); // Akşam yemeği (yeşil)
  static const Color waterReminderColor =
      Color(0xFF54C5F8); // Su içme hatırlatıcı (açık mavi)

  // Tamamlanmış görevlerin rengi
  static const Color completedTaskColor =
      Color(0xFF243355); // Tamamlanmış görev arka planı

  // Kategori renkleri
  static const Color categoryWorkoutColor =
      Color(0xFF7C4DFF); // Antrenman kategorisi (mor)
  static const Color categoryNutritionColor =
      Color(0xFF00BFA5); // Beslenme kategorisi (turkuaz)
  static const Color categoryWaterColor =
      Color(0xFF29B6F6); // Su kategorisi (açık mavi)
  static const Color categoryRestColor =
      Color(0xFFFFB74D); // Dinlenme kategorisi (amber)
  static const Color categoryStatsColor =
      Color(0xFFEF5350); // İstatistik kategorisi (kırmızı)

  // Grafik renkleri
  static const Color chartSuccessColor =
      Color(0xFF66BB6A); // Başarı grafiği (yeşil)
  static const Color chartPendingColor =
      Color(0xFFFFCA28); // Bekleyen grafiği (sarı)
  static const Color chartFailedColor =
      Color(0xFFEF5350); // Başarısız grafiği (kırmızı)
  static const Color chartNeutralColor =
      Color(0xFF90A4AE); // Nötr grafiği (gri-mavi)

  // Görev kategorileri için renkler
  static const Color workoutColor = Color(0xFFFF6B6B);
  static const Color nutritionColor = Color(0xFF26C485);
  static const Color waterColor = Color(0xFF5D9CEC);
  static const Color sleepColor = Color(0xFF8C7AE6);
  static const Color meditationColor = Color(0xFFFFCF56);
  static const Color goalColor = Color(0xFFB795FF);

  // Hedef takibi renkleri
  static const Color weightColor = Color(0xFF7C4DFF); // Kilo takibi (mor)
  static const Color calorieColor =
      Color(0xFFFF8F5D); // Kalori takibi (turuncu)
  static const Color activityColor =
      Color(0xFF26C485); // Aktivite takibi (yeşil)
  static const Color successColor = Color(0xFF4CAF50); // Başarı rengi (yeşil)

  // Grafik renkleri
  static const List<Color> chartColors = [
    Color(0xFF5D69BE),
    Color(0xFFFF6B6B),
    Color(0xFF26C485),
    Color(0xFFFFCF56),
    Color(0xFF8C7AE6),
    Color(0xFF5D9CEC),
  ];

  // Gradyan renkler
  static const Color gradientStart = Color(0xFF516AE2);
  static const Color gradientEnd = Color(0xFF5D69BE);

  // İleride değişebilecek her renk için Getter
  static Color get taskCardColorLight => const Color(0xFFFFFFFF);
  static Color get taskCardColorDark => const Color(0xFF242424);
  static Color get cardColor => const Color(0xFF243355);

  // Koyu tema
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: darkBackgroundColor,
    cardColor: darkCardBackgroundColor,
    colorScheme: ColorScheme.dark(
      primary: primaryColor,
      secondary: secondaryColor,
      tertiary: accentColor,
      surface: darkSurfaceColor,
      error: Color(0xFFFF5252),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onTertiary: Colors.white,
      onSurface: darkTextColor,
      onError: Colors.white,
      brightness: Brightness.dark,
    ),
    textTheme: TextTheme(
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
        color: darkTextColor,
      ),
      headlineMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.3,
        color: darkTextColor,
      ),
      headlineSmall: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.2,
        color: darkTextColor,
      ),
      bodyLarge: TextStyle(
        fontSize: 18,
        letterSpacing: 0.1,
        color: darkTextColor,
      ),
      bodyMedium: TextStyle(
        fontSize: 16,
        letterSpacing: 0.1,
        color: darkTextColor,
      ),
      bodySmall: TextStyle(
        fontSize: 14,
        letterSpacing: 0.1,
        color: darkSecondaryTextColor,
      ),
      labelLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: darkTextColor,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
        color: Colors.white,
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: darkCardBackgroundColor,
      selectedItemColor: primaryColor,
      unselectedItemColor: darkSecondaryTextColor,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      unselectedLabelStyle: TextStyle(fontSize: 12),
    ),
    cardTheme: CardTheme(
      color: darkCardBackgroundColor,
      elevation: 4,
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      clipBehavior: Clip.antiAlias,
    ),
    buttonTheme: ButtonThemeData(
      buttonColor: primaryColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: secondaryColor,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 4,
      extendedTextStyle: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    ),
    dialogTheme: DialogTheme(
      backgroundColor: darkCardBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: darkTextColor,
      ),
      contentTextStyle: TextStyle(
        fontSize: 16,
        color: darkTextColor,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: darkCardBackgroundColor,
      contentTextStyle: TextStyle(color: darkTextColor),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      behavior: SnackBarBehavior.floating,
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: darkSecondaryTextColor, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
            color: darkSecondaryTextColor.withValues(alpha: 0.6), width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Color(0xFFFF5252), width: 1.5),
      ),
      filled: true,
      fillColor: darkSurfaceColor,
      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      labelStyle: TextStyle(color: darkSecondaryTextColor, fontSize: 16),
      hintStyle: TextStyle(
          color: darkSecondaryTextColor.withValues(alpha: 0.7), fontSize: 16),
    ),
    dividerTheme: DividerThemeData(
      thickness: 1,
      color: cardBackgroundColor,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: cardBackgroundColor,
      disabledColor: cardBackgroundColor.withValues(alpha: 0.6),
      selectedColor: primaryColor,
      secondarySelectedColor: secondaryColor,
      labelStyle: TextStyle(fontSize: 14),
      secondaryLabelStyle: TextStyle(fontSize: 14),
      brightness: Brightness.dark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: primaryColor,
      linearTrackColor: cardBackgroundColor,
      circularTrackColor: cardBackgroundColor,
    ),
    tabBarTheme: TabBarTheme(
      labelColor: primaryColor,
      unselectedLabelColor: secondaryTextColor,
      indicatorColor: primaryColor,
      indicatorSize: TabBarIndicatorSize.label,
      labelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      unselectedLabelStyle:
          TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
    ),
    disabledColor: darkSecondaryTextColor.withValues(alpha: 0.8),
  );

  // Açık tema
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: backgroundColor,
    cardColor: surfaceColor,
    colorScheme: ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      tertiary: accentColor,
      surface: surfaceColor,
      error: Color(0xFFD32F2F),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onTertiary: Colors.white,
      onSurface: textColor,
      onError: Colors.white,
      brightness: Brightness.light,
    ),
    textTheme: TextTheme(
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
        color: textColor,
      ),
      headlineMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.3,
        color: textColor,
      ),
      headlineSmall: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.2,
        color: textColor,
      ),
      bodyLarge: TextStyle(
        fontSize: 18,
        letterSpacing: 0.1,
        color: textColor,
      ),
      bodyMedium: TextStyle(
        fontSize: 16,
        letterSpacing: 0.1,
        color: textColor,
      ),
      bodySmall: TextStyle(
        fontSize: 14,
        letterSpacing: 0.1,
        color: secondaryTextColor,
      ),
      labelLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: textColor,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
        color: Colors.white,
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: surfaceColor,
      selectedItemColor: primaryColor,
      unselectedItemColor: secondaryTextColor,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      unselectedLabelStyle: TextStyle(fontSize: 12),
    ),
    cardTheme: CardTheme(
      color: surfaceColor,
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
    ),
    buttonTheme: ButtonThemeData(
      buttonColor: primaryColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      textTheme: ButtonTextTheme.primary,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: secondaryColor,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 4,
      extendedTextStyle: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    ),
    dialogTheme: DialogTheme(
      backgroundColor: surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
      contentTextStyle: TextStyle(
        fontSize: 16,
        color: textColor,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: textColor,
      contentTextStyle: TextStyle(color: surfaceColor),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      behavior: SnackBarBehavior.floating,
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: secondaryTextColor, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
            color: secondaryTextColor.withValues(alpha: 0.5), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Color(0xFFD32F2F), width: 1.5),
      ),
      labelStyle: TextStyle(color: secondaryTextColor),
      hintStyle: TextStyle(color: secondaryTextColor.withValues(alpha: 0.7)),
      prefixIconColor: secondaryTextColor,
      suffixIconColor: secondaryTextColor,
    ),
    dividerColor: secondaryTextColor.withValues(alpha: 0.3),
    disabledColor: secondaryTextColor.withValues(alpha: 0.8),
  );
}
