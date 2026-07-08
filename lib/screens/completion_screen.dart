import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/drawing.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

class CompletionScreen extends StatefulWidget {
  final Drawing drawing;
  final Uint8List imageBytes;

  const CompletionScreen({
    super.key,
    required this.drawing,
    required this.imageBytes,
  });

  @override
  State<CompletionScreen> createState() => _CompletionScreenState();
}

class _CompletionScreenState extends State<CompletionScreen>
    with TickerProviderStateMixin {
  late final AnimationController _sparkleController;
  late final AnimationController _cardController;
  late final AnimationController _confettiController;
  late final Animation<double> _cardAnimation;

  static const _rainbow = [
    Color(0xFFFF6B6B),
    Color(0xFFFF8C42),
    Color(0xFFFFD166),
    Color(0xFF6BCB77),
    Color(0xFF74B9FF),
    Color(0xFFA78BFA),
    Color(0xFFF472B6),
    Color(0xFF4D96FF),
    Color(0xFFC084FC),
    Color(0xFF2EC4B6),
    Color(0xFFFF8C42),
  ];

  @override
  void initState() {
    super.initState();
    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _cardAnimation =
        CurvedAnimation(parent: _cardController, curve: Curves.elasticOut);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cardController.forward();
      _confettiController.forward();
    });
  }

  @override
  void dispose() {
    _sparkleController.dispose();
    _cardController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _snack(BuildContext context, String message, Color color, IconData icon) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 10),
              Text(
                message,
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.bgStart, AppTheme.bgEnd],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              _FloatingSparkles(controller: _sparkleController),
              _Confetti(controller: _confettiController),
              Column(
                children: [
                  _buildTopBar(context),
                  const SizedBox(height: 4),
                  _buildHeader(),
                  const SizedBox(height: 12),
                  Expanded(child: _buildDrawingCard()),
                  const SizedBox(height: 12),
                  _buildActions(context),
                  const SizedBox(height: 12),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          _PillIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: () => Navigator.of(context).pop(),
          ),
          const Spacer(),
          _PillIconButton(
            icon: Icons.home_rounded,
            onTap: () => Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const HomeScreen()),
              (route) => false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    const title = 'Süper iş!';
    final style = GoogleFonts.nunito(
      fontSize: 34,
      fontWeight: FontWeight.w900,
      letterSpacing: 0.4,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          _BouncingMedal(controller: _sparkleController),
          const SizedBox(height: 14),
          RichText(
            text: TextSpan(
              children: List.generate(title.length, (i) {
                final ch = title[i];
                if (ch == ' ') {
                  return TextSpan(text: ch, style: style);
                }
                return TextSpan(
                  text: ch,
                  style: style.copyWith(
                    color: _rainbow[i % _rainbow.length],
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${widget.drawing.emoji}  ${widget.drawing.name} tamamlandı',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 15,
              color: const Color(0xFF6B6B8A),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawingCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: ScaleTransition(
        scale: _cardAnimation,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withOpacity(0.18),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Expanded(
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(14),
                  child: Image.memory(widget.imageBytes, fit: BoxFit.contain),
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFFF6E5), Color(0xFFFFE9D6)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (int i = 0; i < 3; i++)
                      _WigglyStar(
                        controller: _sparkleController,
                        phase: i * 0.33,
                      ),
                    const SizedBox(width: 10),
                    Text(
                      'Süper ressam!',
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFFE6941C),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _BigActionButton(
                  icon: Icons.save_alt_rounded,
                  label: 'Kaydet',
                  color: AppTheme.success,
                  onTap: () => _snack(context, 'Resim kaydedildi! 🎉',
                      AppTheme.success, Icons.check_circle_rounded),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _BigActionButton(
                  icon: Icons.share_rounded,
                  label: 'Paylaş',
                  color: AppTheme.secondary,
                  onTap: () => _snack(context, 'Paylaşım yakında geliyor!',
                      AppTheme.secondary, Icons.share_rounded),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: _BigActionButton(
              icon: Icons.palette_rounded,
              label: 'Yeni Çizim Seç',
              color: AppTheme.primary,
              filled: true,
              onTap: () => Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const HomeScreen()),
                (route) => false,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Küçük parçalar ──────────────────────────────────────────────────────────

class _PillIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _PillIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, size: 20, color: AppTheme.textDark),
        ),
      ),
    );
  }
}

class _BigActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool filled;
  final VoidCallback onTap;

  const _BigActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = filled ? color : Colors.white;
    final fg = filled ? Colors.white : color;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(20),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(20),
            border: filled
                ? null
                : Border.all(color: color.withOpacity(0.25), width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(filled ? 0.35 : 0.15),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 22, color: fg),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BouncingMedal extends StatelessWidget {
  final AnimationController controller;
  const _BouncingMedal({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final t = controller.value * 2 * math.pi;
        final scale = 1 + math.sin(t) * 0.05;
        final rotate = math.sin(t) * 0.08;
        return Transform.rotate(
          angle: rotate,
          child: Transform.scale(
            scale: scale,
            child: Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFE28A), Color(0xFFFFB84D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: Colors.white, width: 5),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accent.withOpacity(0.45),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Center(
                child: Text('🏆', style: TextStyle(fontSize: 44)),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _WigglyStar extends StatelessWidget {
  final AnimationController controller;
  final double phase;
  const _WigglyStar({required this.controller, required this.phase});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final t = (controller.value + phase) * 2 * math.pi;
        final scale = 0.9 + math.sin(t).abs() * 0.25;
        return Transform.scale(
          scale: scale,
          child: const Icon(
            Icons.star_rounded,
            color: Color(0xFFFFD166),
            size: 26,
          ),
        );
      },
    );
  }
}

// ── Arka plan efektleri ─────────────────────────────────────────────────────

class _FloatingSparkles extends StatelessWidget {
  final AnimationController controller;
  const _FloatingSparkles({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) => IgnorePointer(
        child: CustomPaint(
          size: MediaQuery.of(context).size,
          painter: _SparklesPainter(progress: controller.value),
        ),
      ),
    );
  }
}

class _SparklesPainter extends CustomPainter {
  final double progress;
  const _SparklesPainter({required this.progress});

  static const _positions = [
    Offset(0.08, 0.12),
    Offset(0.88, 0.10),
    Offset(0.22, 0.06),
    Offset(0.72, 0.20),
    Offset(0.04, 0.32),
    Offset(0.94, 0.36),
    Offset(0.12, 0.70),
    Offset(0.86, 0.68),
    Offset(0.5, 0.05),
    Offset(0.5, 0.95),
  ];

  static const _colors = [
    Color(0xFFFFD166),
    Color(0xFFFF8C42),
    Color(0xFF74B9FF),
    Color(0xFFF472B6),
    Color(0xFF6BCB77),
    Color(0xFFA78BFA),
    Color(0xFFFFD166),
    Color(0xFF74B9FF),
    Color(0xFFFF6B6B),
    Color(0xFF2EC4B6),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < _positions.length; i++) {
      final phase = (progress + i / _positions.length) % 1.0;
      final opacity = 0.35 + 0.55 * math.sin(phase * math.pi).abs();
      final scale = 0.55 + 0.55 * (phase < 0.5 ? phase * 2 : (1 - phase) * 2);
      final pos = Offset(
        _positions[i].dx * size.width,
        _positions[i].dy * size.height,
      );
      final paint = Paint()..color = _colors[i].withOpacity(opacity * 0.65);
      _drawStar(canvas, pos, 9 * scale, paint);
    }
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final outerAngle = (i * 72 - 90) * math.pi / 180;
      final innerAngle = outerAngle + 36 * math.pi / 180;
      final outer = Offset(
        center.dx + radius * math.cos(outerAngle),
        center.dy + radius * math.sin(outerAngle),
      );
      final inner = Offset(
        center.dx + radius * 0.42 * math.cos(innerAngle),
        center.dy + radius * 0.42 * math.sin(innerAngle),
      );
      if (i == 0) {
        path.moveTo(outer.dx, outer.dy);
      } else {
        path.lineTo(outer.dx, outer.dy);
      }
      path.lineTo(inner.dx, inner.dy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_SparklesPainter old) => old.progress != progress;
}

class _Confetti extends StatelessWidget {
  final AnimationController controller;
  const _Confetti({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) => IgnorePointer(
        child: CustomPaint(
          size: MediaQuery.of(context).size,
          painter: _ConfettiPainter(progress: controller.value),
        ),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final double progress;
  const _ConfettiPainter({required this.progress});

  static const _colors = [
    Color(0xFFFF6B6B),
    Color(0xFFFFD166),
    Color(0xFF6BCB77),
    Color(0xFF74B9FF),
    Color(0xFFA78BFA),
    Color(0xFFF472B6),
    Color(0xFFFF8C42),
    Color(0xFF2EC4B6),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(7);
    for (int i = 0; i < 55; i++) {
      final startX = rnd.nextDouble() * size.width;
      final startY = -20 - rnd.nextDouble() * 120;
      final drift = math.sin(progress * math.pi * 2 + i) * 46;
      final x = startX + drift;
      final y = startY + progress * (size.height + 180);
      final rotation = progress * math.pi * 5 * (rnd.nextDouble() - 0.5);
      final color = _colors[i % _colors.length];
      final opacity = (1 - progress * 0.6).clamp(0.0, 1.0);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);
      final w = 7 + rnd.nextDouble() * 7;
      final h = 4 + rnd.nextDouble() * 5;
      final rrect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: w, height: h),
        const Radius.circular(2),
      );
      canvas.drawRRect(rrect, Paint()..color = color.withOpacity(opacity));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}
