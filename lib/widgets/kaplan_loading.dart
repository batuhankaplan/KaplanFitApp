import 'package:flutter/material.dart';
import '../theme.dart';

class KaplanLoading extends StatefulWidget {
  final double size;
  final Color? color;

  const KaplanLoading({
    Key? key,
    this.size = 80.0,
    this.color,
  }) : super(key: key);

  @override
  State<KaplanLoading> createState() => _KaplanLoadingState();
}

class _KaplanLoadingState extends State<KaplanLoading> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final color = widget.color ?? (isDarkMode ? AppTheme.primaryColor : AppTheme.primaryColor);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: RotationTransition(
              turns: _controller,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Dış dönen halka
                  Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: SweepGradient(
                        colors: [
                          color.withOpacity(0.0),
                          color.withOpacity(1.0),
                        ],
                        stops: const [0.0, 1.0],
                      ),
                    ),
                  ),
                  // İç logo
                  ClipOval(
                    child: Image.asset(
                      'assets/images/kaplan_logo.png',
                      width: widget.size * 0.8,
                      height: widget.size * 0.8,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.fitness_center,
                          size: widget.size * 0.5,
                          color: color,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Yükleniyor...',
            style: TextStyle(
              color: isDarkMode ? Colors.white70 : Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
} 