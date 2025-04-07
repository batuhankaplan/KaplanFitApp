import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme.dart';

class KaplanLoading extends StatefulWidget {
  final double size;
  final Color? color;
  final bool showLogo;

  const KaplanLoading({
    Key? key,
    this.size = 70.0,
    this.color,
    this.showLogo = true,
  }) : super(key: key);

  @override
  State<KaplanLoading> createState() => _KaplanLoadingState();
}

class _KaplanLoadingState extends State<KaplanLoading> with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    
    // Rotasyon animasyonu
    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    _rotationAnimation = CurvedAnimation(
      parent: _rotationController,
      curve: Curves.easeInOutCubic,
    );
    
    // Nabız animasyonu
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
    
    _glowAnimation = Tween<double>(begin: 0.4, end: 0.8).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final mainColor = widget.color ?? AppTheme.primaryColor;
    final accentColor = isDarkMode ? AppTheme.secondaryColor : AppTheme.accentColor;
    
    return Center(
      child: AnimatedBuilder(
        animation: Listenable.merge([_rotationController, _pulseController]),
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Parıltı efekti
              Container(
                width: widget.size * 1.4 * _pulseAnimation.value,
                height: widget.size * 1.4 * _pulseAnimation.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: mainColor.withOpacity(_glowAnimation.value * 0.4),
                      blurRadius: 24,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              
              // Ana çember
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _ProgressArcPainter(
                  progress: _rotationAnimation.value,
                  color: mainColor,
                  strokeWidth: widget.size * 0.07,
                ),
              ),
              
              // İkinci çember (ters yönde)
              Transform.rotate(
                angle: -math.pi * 2 * _rotationAnimation.value,
                child: CustomPaint(
                  size: Size(widget.size * 0.7, widget.size * 0.7),
                  painter: _ProgressArcPainter(
                    progress: 0.75,
                    color: accentColor,
                    strokeWidth: widget.size * 0.05,
                    startAngle: math.pi / 4,
                  ),
                ),
              ),
              
              // İkon veya logo
              if (widget.showLogo)
                ScaleTransition(
                  scale: Tween<double>(begin: 0.9, end: 1.0).animate(
                    CurvedAnimation(
                      parent: _pulseController,
                      curve: Curves.easeInOut,
                    ),
                  ),
                  child: Icon(
                    Icons.fitness_center,
                    size: widget.size * 0.45,
                    color: mainColor,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ProgressArcPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;
  final double startAngle;
  
  _ProgressArcPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
    this.startAngle = 0,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    
    // İlk kısmi çember
    canvas.drawArc(
      rect,
      startAngle, 
      math.pi * 1.8, // 270 derece
      false,
      paint,
    );
    
    // İkinci kısmi çember farklı renkte
    final secondPaint = Paint()
      ..color = color.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    
    canvas.drawArc(
      rect,
      startAngle + math.pi * 1.8, 
      math.pi * 0.4, // Kalan 90 derece
      false,
      secondPaint,
    );
    
    // Progres indikatörü nokta
    final angle = startAngle + math.pi * 2 * progress;
    final dx = size.width / 2 + (size.width / 2) * math.cos(angle);
    final dy = size.height / 2 + (size.height / 2) * math.sin(angle);
    
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(
      Offset(dx, dy),
      strokeWidth * 1.5,
      dotPaint,
    );
  }
  
  @override
  bool shouldRepaint(covariant _ProgressArcPainter oldDelegate) {
    return oldDelegate.progress != progress || 
           oldDelegate.color != color || 
           oldDelegate.strokeWidth != strokeWidth;
  }
} 