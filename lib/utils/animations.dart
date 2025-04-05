import 'package:flutter/material.dart';
import 'dart:math' show sin, pi;

/// Öğeleri belirli bir gecikmeyle ve animasyonla gösteren widget
/// Not: Bu sınıfı kullanmıyoruz, Flutter SDK'da aynı isimde bir sınıf var.
/// İsim çakışmasını önlemek için KFAnimatedItem ismini kullanın.
class KFAnimatedItem extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration duration;
  final Duration delay;
  final Curve curve;

  const KFAnimatedItem({
    Key? key,
    required this.child,
    required this.index,
    this.duration = const Duration(milliseconds: 500),
    this.delay = const Duration(milliseconds: 100),
    this.curve = Curves.easeOutQuint,
  }) : super(key: key);

  @override
  State<KFAnimatedItem> createState() => _KFAnimatedItemState();
}

class _KFAnimatedItemState extends State<KFAnimatedItem> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    
    final delay = Duration(milliseconds: widget.delay.inMilliseconds * widget.index);
    Future.delayed(delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
    
    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: widget.curve,
      ),
    );
    
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: widget.child,
          ),
        );
      },
    );
  }
}

/// Yukarıdan aşağıya kaydırma animasyonu için widget
class KFAnimatedSlide extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Offset offsetBegin;
  final Offset offsetEnd;
  final Curve curve;
  final Duration delay;

  const KFAnimatedSlide({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
    this.offsetBegin = const Offset(0, 0.2),
    this.offsetEnd = Offset.zero,
    this.curve = Curves.easeOutCubic,
    this.delay = const Duration(milliseconds: 100),
  }) : super(key: key);

  @override
  State<KFAnimatedSlide> createState() => _KFAnimatedSlideState();
}

class _KFAnimatedSlideState extends State<KFAnimatedSlide> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: widget.offsetBegin,
      end: widget.offsetEnd,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: widget.curve,
      ),
    );
    
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.0, 0.65, curve: Curves.easeIn),
      ),
    );
    
    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return FadeTransition(
          opacity: _opacityAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: widget.child,
          ),
        );
      },
    );
  }
}

/// Animasyonlu öğe görüntüleme için widget
class KFAnimatedTip extends StatelessWidget {
  final String tip;
  final Duration duration;
  final Curve curve;
  final Widget? leading;
  final TextStyle? textStyle;
  
  const KFAnimatedTip({
    Key? key,
    required this.tip,
    this.duration = const Duration(milliseconds: 800),
    this.curve = Curves.easeOutCubic,
    this.leading,
    this.textStyle,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final defaultTextStyle = TextStyle(
      fontSize: 16,
      color: Colors.white,
    );
    
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Transform.translate(
              offset: Offset(20 * (1 - value), 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  leading ?? const Icon(Icons.check_circle, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tip,
                      style: textStyle ?? defaultTextStyle,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Herhangi bir widget'ı kademeli olarak gösteren yardımcı sınıf
class KFAnimatedList extends StatelessWidget {
  final List<Widget> children;
  final Duration itemDuration;
  final Duration itemDelay;
  final Curve curve;
  final Axis direction;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;
  
  const KFAnimatedList({
    Key? key,
    required this.children,
    this.itemDuration = const Duration(milliseconds: 500),
    this.itemDelay = const Duration(milliseconds: 100),
    this.curve = Curves.easeOutQuint,
    this.direction = Axis.vertical,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisSize = MainAxisSize.max,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return direction == Axis.vertical
        ? Column(
            mainAxisAlignment: mainAxisAlignment,
            crossAxisAlignment: crossAxisAlignment,
            mainAxisSize: mainAxisSize,
            children: _buildAnimatedChildren(),
          )
        : Row(
            mainAxisAlignment: mainAxisAlignment,
            crossAxisAlignment: crossAxisAlignment,
            mainAxisSize: mainAxisSize,
            children: _buildAnimatedChildren(),
          );
  }
  
  List<Widget> _buildAnimatedChildren() {
    return List.generate(
      children.length,
      (index) => KFAnimatedItem(
        index: index,
        duration: itemDuration,
        delay: itemDelay,
        curve: curve,
        child: children[index],
      ),
    );
  }
}

/// Bir sayfanın arka planında kullanılabilecek bir dalga animasyonu
class KFWaveAnimation extends StatefulWidget {
  final Color color;
  final double height;
  
  const KFWaveAnimation({
    Key? key,
    required this.color,
    this.height = 200,
  }) : super(key: key);
  
  @override
  State<KFWaveAnimation> createState() => _KFWaveAnimationState();
}

class _KFWaveAnimationState extends State<KFWaveAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      width: double.infinity,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: WavePainter(
              animation: _controller,
              color: widget.color,
            ),
          );
        },
      ),
    );
  }
}

class WavePainter extends CustomPainter {
  final Animation<double> animation;
  final Color color;
  
  WavePainter({
    required this.animation,
    required this.color,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    final path = Path();
    final height = size.height;
    final width = size.width;
    
    path.moveTo(0, height * 0.8);
    
    // İlk dalga
    for (int i = 0; i < width; i++) {
      path.lineTo(
        i.toDouble(), 
        height * 0.8 + sin((i / width * 4 * pi) + animation.value * 2 * pi) * 10,
      );
    }
    
    path.lineTo(width, height);
    path.lineTo(0, height);
    path.close();
    
    canvas.drawPath(path, paint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Basit bir pulse (atım) animasyonu ekler
class KFPulseAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;
  final double maxScale;
  
  const KFPulseAnimation({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: 1500),
    this.curve = Curves.easeInOut,
    this.maxScale = 1.1,
  }) : super(key: key);
  
  @override
  State<KFPulseAnimation> createState() => _KFPulseAnimationState();
}

class _KFPulseAnimationState extends State<KFPulseAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat(reverse: true);
    
    _animation = Tween<double>(
      begin: 1.0,
      end: widget.maxScale,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: widget.curve,
      ),
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      child: widget.child,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: child,
        );
      },
    );
  }
} 