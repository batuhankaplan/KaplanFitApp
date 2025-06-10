import 'package:flutter/material.dart';
import 'dart:math' show sin, pi;
import 'dart:math' as math;

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
  }) ;

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
  }) ;

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
  }) ;
  
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
  }) ;
  
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

/// Yükseklik dalgası animasyonu
class KFWaveAnimation extends StatefulWidget {
  final Color color;
  final double height;
  final int waveCount;
  final Duration duration;

  const KFWaveAnimation({
    Key? key,
    required this.color,
    this.height = 100.0,
    this.waveCount = 3,
    this.duration = const Duration(seconds: 3),
  }) ;

  @override
  State<KFWaveAnimation> createState() => _KFWaveAnimationState();
}

class _KFWaveAnimationState extends State<KFWaveAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(height: widget.height, width: double.infinity,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _WavePainter(
              animation: _controller,
              waveColor: widget.color,
              waveCount: widget.waveCount,
            ),
            size: Size(double.infinity, widget.height),
          );
        },
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  final Animation<double> animation;
  final Color waveColor;
  final int waveCount;

  _WavePainter({
    required this.animation,
    required this.waveColor,
    required this.waveCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final baseWave = Path();

    // Başlangıç noktası
    baseWave.moveTo(0, size.height - (size.height / 3));

    // Dalgalı çizim
    for (int i = 0; i < waveCount * 2 + 1; i++) {
      if (i % 2 == 0) {
        // Dalga tepesi
        baseWave.quadraticBezierTo(
          size.width / (waveCount * 2) * (i + 1),
          size.height - (size.height / 3) - 20,
          size.width / (waveCount * 2) * (i + 2),
          size.height - (size.height / 3),
        );
      } else {
        // Dalga çukuru
        baseWave.quadraticBezierTo(
          size.width / (waveCount * 2) * (i + 1),
          size.height - (size.height / 3) + 20,
          size.width / (waveCount * 2) * (i + 2),
          size.height - (size.height / 3),
        );
      }
    }

    // Kapatma
    baseWave.lineTo(size.width, size.height);
    baseWave.lineTo(0, size.height);
    baseWave.close();

    // Animasyon için offset
    final animationPhase = animation.value * 2 * math.pi;
    final animatedPath = Path();
    
    for (int i = 0; i < size.width.toInt(); i++) {
      final offset = math.sin((i / size.width * 2 * math.pi) + animationPhase) * 10;
      final x = i.toDouble();
      final y = baseWave.getBounds().top + offset;
      
      if (i == 0) {
        animatedPath.moveTo(x, y);
      } else {
        animatedPath.lineTo(x, y);
      }
    }
    
    // Kapatma
    animatedPath.lineTo(size.width, size.height);
    animatedPath.lineTo(0, size.height);
    animatedPath.close();

    // Çizim
    canvas.drawPath(
      animatedPath,
      Paint()
        ..color = waveColor
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_WavePainter oldDelegate) => true;
}

/// Kayan giriş animasyonu
class KFSlideAnimation extends StatefulWidget {
  final Widget child;
  final Offset offsetBegin;
  final Duration duration;
  final Duration delay;
  final Curve curve;

  const KFSlideAnimation({
    Key? key,
    required this.child,
    this.offsetBegin = const Offset(0.0, 0.35),
    this.duration = const Duration(milliseconds: 800),
    this.delay = const Duration(milliseconds: 0),
    this.curve = Curves.easeOutCubic,
  }) ;

  @override
  State<KFSlideAnimation> createState() => _KFSlideAnimationState();
}

class _KFSlideAnimationState extends State<KFSlideAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    
    _offsetAnimation = Tween<Offset>(
      begin: widget.offsetBegin,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Interval(0.0, 0.7, curve: widget.curve),
    ));
    
    if (widget.delay.inMilliseconds == 0) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) {
          _controller.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _offsetAnimation,
        child: widget.child,
      ),
    );
  }
}

/// Nabız animasyonu
class KFPulseAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double maxScale;
  final Curve curve;
  final bool infinite;

  const KFPulseAnimation({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: 1500),
    this.maxScale = 1.1,
    this.curve = Curves.easeInOut,
    this.infinite = true,
  }) ;

  @override
  State<KFPulseAnimation> createState() => _KFPulseAnimationState();
}

class _KFPulseAnimationState extends State<KFPulseAnimation> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    
    _animation = Tween<double>(
      begin: 1.0,
      end: widget.maxScale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));
    
    if (widget.infinite) {
      _controller.repeat(reverse: true);
    } else {
      _controller.forward();
    }
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
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: widget.child,
        );
      },
    );
  }
}

/// Şimşek efekti
class KFShimmerEffect extends StatefulWidget {
  final Widget child;
  final Color baseColor;
  final Color highlightColor;
  final Duration duration;
  
  const KFShimmerEffect({
    Key? key,
    required this.child,
    required this.baseColor,
    required this.highlightColor,
    this.duration = const Duration(milliseconds: 1500),
  }) ;

  @override
  State<KFShimmerEffect> createState() => _KFShimmerEffectState();
}

class _KFShimmerEffectState extends State<KFShimmerEffect> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat();
    
    _animation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(_controller);
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
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: [
                _clamp(_animation.value - 1.0),
                _clamp(_animation.value),
                _clamp(_animation.value + 1.0),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
  
  double _clamp(double value) {
    return math.max(0.0, math.min(1.0, value));
  }
}

/// 3D Flip Animasyonu
class KFFlipAnimation extends StatefulWidget {
  final Widget front;
  final Widget back;
  final bool showBackSide;
  final Duration duration;
  final Axis direction;
  final Curve curve;

  const KFFlipAnimation({
    Key? key,
    required this.front,
    required this.back,
    this.showBackSide = false,
    this.duration = const Duration(milliseconds: 500),
    this.direction = Axis.horizontal,
    this.curve = Curves.easeInOut,
  }) ;

  @override
  State<KFFlipAnimation> createState() => _KFFlipAnimationState();
}

class _KFFlipAnimationState extends State<KFFlipAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _showBackSide = false;

  @override
  void initState() {
    super.initState();
    _showBackSide = widget.showBackSide;
    
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));
    
    if (_showBackSide) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(KFFlipAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showBackSide != oldWidget.showBackSide) {
      if (widget.showBackSide) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
      _showBackSide = widget.showBackSide;
    }
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
      builder: (context, child) {
        final isHorizontal = widget.direction == Axis.horizontal;
        
        final transform = Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateX(isHorizontal ? 0.0 : _animation.value * math.pi)
          ..rotateY(isHorizontal ? _animation.value * math.pi : 0.0);
        
        final frontOpacity = _animation.value < 0.5 ? 1.0 : 0.0;
        final backOpacity = _animation.value < 0.5 ? 0.0 : 1.0;
        
        return Transform(
          transform: transform,
          alignment: Alignment.center,
          child: Stack(
            children: [
              Opacity(
                opacity: frontOpacity,
                child: _animation.value < 0.5 
                  ? widget.front 
                  : Transform(
                      transform: Matrix4.identity()
                        ..rotateX(isHorizontal ? 0.0 : math.pi)
                        ..rotateY(isHorizontal ? math.pi : 0.0),
                      alignment: Alignment.center,
                      child: widget.front,
                    ),
              ),
              Opacity(
                opacity: backOpacity,
                child: _animation.value >= 0.5 
                  ? widget.back 
                  : Transform(
                      transform: Matrix4.identity()
                        ..rotateX(isHorizontal ? 0.0 : math.pi)
                        ..rotateY(isHorizontal ? math.pi : 0.0),
                      alignment: Alignment.center,
                      child: widget.back,
                    ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Dairesel ilerleme animasyonu
class KFCircularProgressIndicator extends StatefulWidget {
  final double size;
  final double strokeWidth;
  final Color color;
  final Color backgroundColor;
  final double value;
  final String? label;
  final TextStyle? labelStyle;
  final bool animate;
  final Duration animationDuration;

  const KFCircularProgressIndicator({
    Key? key,
    this.size = 100.0,
    this.strokeWidth = 10.0,
    required this.color,
    required this.backgroundColor,
    this.value = 0.0,
    this.label,
    this.labelStyle,
    this.animate = true,
    this.animationDuration = const Duration(milliseconds: 1000),
  }) ;

  @override
  State<KFCircularProgressIndicator> createState() => _KFCircularProgressIndicatorState();
}

class _KFCircularProgressIndicatorState extends State<KFCircularProgressIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    
    _updateAnimation();
    
    if (widget.animate) {
      _controller.forward();
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(KFCircularProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.value != oldWidget.value) {
      _updateAnimation();
      if (widget.animate) {
        _controller.forward(from: 0.0);
      } else {
        _controller.value = 1.0;
      }
    }
  }

  void _updateAnimation() {
    _animation = Tween<double>(
      begin: 0.0,
      end: widget.value.clamp(0.0, 1.0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        children: [
          // Arka plan daire
          CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _CircularProgressPainter(
              progress: 1.0,
              color: widget.backgroundColor,
              strokeWidth: widget.strokeWidth,
            ),
          ),
          
          // Animasyonlu ilerleme dairesi
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _CircularProgressPainter(
                  progress: _animation.value,
                  color: widget.color,
                  strokeWidth: widget.strokeWidth,
                ),
              );
            },
          ),
          
          // Metin etiketi
          if (widget.label != null)
            Center(
              child: Text(
                widget.label!,
                style: widget.labelStyle ?? TextStyle(
                  fontSize: widget.size * 0.2,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _CircularProgressPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    
    // Çember çiz
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    
    // 3pi/2 başlangıç noktası (üst orta)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, 
      2 * math.pi * progress,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
           oldDelegate.color != color ||
           oldDelegate.strokeWidth != strokeWidth;
  }
}

/// Kayan gösterge animasyonu (sayaç)
class KFCounterAnimation extends StatefulWidget {
  final int begin;
  final int end;
  final Duration duration;
  final TextStyle? style;
  final String prefix;
  final String suffix;

  const KFCounterAnimation({
    Key? key,
    required this.begin,
    required this.end,
    this.duration = const Duration(milliseconds: 1500),
    this.style,
    this.prefix = '',
    this.suffix = '',
  }) ;

  @override
  State<KFCounterAnimation> createState() => _KFCounterAnimationState();
}

class _KFCounterAnimationState extends State<KFCounterAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int _currentCount = 0;

  @override
  void initState() {
    super.initState();
    _currentCount = widget.begin;
    
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    
    _animation = Tween<double>(
      begin: widget.begin.toDouble(),
      end: widget.end.toDouble(),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ))..addListener(() {
      setState(() {
        _currentCount = _animation.value.toInt();
      });
    });
    
    _controller.forward();
  }

  @override
  void didUpdateWidget(KFCounterAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.end != oldWidget.end) {
      _animation = Tween<double>(
        begin: _currentCount.toDouble(),
        end: widget.end.toDouble(),
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ));
      
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      '${widget.prefix}$_currentCount${widget.suffix}',
      style: widget.style,
    );
  }
} 


