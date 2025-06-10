import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';
import '../widgets/kaplan_loading.dart';

class SplashScreen extends StatefulWidget {
  final Widget? nextScreen;

  const SplashScreen({
    Key? key,
    this.nextScreen,
  }) ;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeInAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Durum çubuğunu şeffaf yap
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    // Animasyonları ayarla
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeInAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<double>(begin: 50, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.2, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.2, 0.8, curve: Curves.easeOut),
      ),
    );

    // Animasyonları başlat
    _controller.forward();

    // Sonraki ekrana git
    _navigateToMain();
  }

  _navigateToMain() async {
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      if (widget.nextScreen != null) {
        // Geçiş animasyonu ile belirtilen ekrana geç
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: Duration(milliseconds: 1000),
            pageBuilder: (_, animation, secondaryAnimation) => FadeTransition(
              opacity: animation,
              child: widget.nextScreen!,
            ),
          ),
        );
      } else {
        // nextScreen belirtilmemişse /home rotasına geç
        Navigator.of(context).pushReplacementNamed('/home');
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.gradientStart,
              AppTheme.gradientEnd,
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Dekoratif arka plan animasyonu
              Positioned(
                top: size.height * 0.05,
                right: -30,
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeInAnimation.value * 0.3,
                      child: Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Container(width: 160, height: 160,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha:0.1),
                            borderRadius: BorderRadius.circular(100),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              Positioned(
                bottom: -50,
                left: -20,
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeInAnimation.value * 0.2,
                      child: Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Container(width: 200, height: 200,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha:0.1),
                            borderRadius: BorderRadius.circular(100),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Ana içerik
              Center(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _slideAnimation.value),
                      child: Opacity(
                        opacity: _fadeInAnimation.value,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Logo container
                            Container(
                              padding: EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha:0.1),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        AppTheme.primaryColor.withValues(alpha:0.3),
                                    blurRadius: 30,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: Container(width: 100, height: 100,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withValues(alpha:0.3),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Image.asset(
                                  'assets/images/kaplan_logo.png',
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Center(
                                      child: Icon(
                                        Icons.fitness_center,
                                        size: 60,
                                        color: Colors.white,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            SizedBox(height: 30),

                            // Uygulama adı
                            Text(
                              'KaplanFit',
                              style: TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    color: Colors.black26,
                                    offset: Offset(1, 2),
                                    blurRadius: 5,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 8),

                            // Slogan
                            Text(
                              'Sağlıklı Yaşamın Anahtarı',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w400,
                                color: Colors.white.withValues(alpha:0.9),
                              ),
                            ),
                            SizedBox(height: 50),

                            // Yükleme animasyonu
                            KaplanLoading(
                              size: 70,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Sürüm bilgisi
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeInAnimation.value,
                      child: Text(
                        'Sürüm 1.0.0',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha:0.7),
                          fontSize: 14,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


