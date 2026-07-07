import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/drawing.dart';
import '../screens/home_screen.dart';

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
  late AnimationController _starController;
  late AnimationController _cardController;
  late AnimationController _confettiController;
  late Animation<double> _cardAnimation;

  @override
  void initState() {
    super.initState();

    _starController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _cardAnimation = CurvedAnimation(
      parent: _cardController,
      curve: Curves.elasticOut,
    );

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _cardController.forward();
        _confettiController.forward();
      }
    });
  }

  @override
  void dispose() {
    _starController.dispose();
    _cardController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _saveImage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('Resim kaydedildi! 🎉',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
        backgroundColor: const Color(0xFF66BB6A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _shareImage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.share, color: Colors.white),
            SizedBox(width: 8),
            Text('Paylaşım yakında!',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
        backgroundColor: const Color(0xFF4FC3F7),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
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
            colors: [Color(0xFFFFF9C4), Color(0xFFE8F5E9), Color(0xFFE3F2FD)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              _FloatingStars(controller: _starController),
              _ConfettiBlast(controller: _confettiController),
              Column(
                children: [
                  _buildTopSection(),
                  Expanded(child: _buildDrawingCard()),
                  _buildActions(context),
                  const SizedBox(height: 20),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD166).withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Text('🎉', style: TextStyle(fontSize: 46)),
          ),
          const SizedBox(height: 12),
          Text(
            'Harika iş çıkardın!',
            style: GoogleFonts.nunito(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF3D3D5C),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${widget.drawing.emoji} ${widget.drawing.name} resmini tamamladın!',
            style: GoogleFonts.nunito(
              fontSize: 15,
              color: const Color(0xFF8888AA),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawingCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: ScaleTransition(
        scale: _cardAnimation,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            color: Colors.white,
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
            border: Border.all(color: Colors.white.withOpacity(0.8), width: 5),
          ),
          clipBehavior: Clip.hardEdge,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: Image.memory(
                  widget.imageBytes,
                  fit: BoxFit.contain,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                color: const Color(0xFFFAFAFA),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.star_rounded,
                        color: Color(0xFFFFD700), size: 24),
                    const Icon(Icons.star_rounded,
                        color: Color(0xFFFFD700), size: 24),
                    const Icon(Icons.star_rounded,
                        color: Color(0xFFFFD700), size: 24),
                    const SizedBox(width: 10),
                    Text(
                      'Süper ressam!',
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF6B6B8A),
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
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: Icons.save_alt_rounded,
                  label: 'Kaydet',
                  color: const Color(0xFF66BB6A),
                  onTap: () => _saveImage(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionButton(
                  icon: Icons.share_rounded,
                  label: 'Paylaş',
                  color: const Color(0xFF4FC3F7),
                  onTap: () => _shareImage(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const HomeScreen()),
                (route) => false,
              ),
              icon: const Icon(Icons.palette_rounded),
              label: Text('Yeni Çizim Seç',
                  style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w800, fontSize: 15)),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: Color(0xFFE4E2EA)),
                foregroundColor: const Color(0xFFE6B400),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 22),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        elevation: 2,
        shadowColor: Colors.black26,
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _FloatingStars extends StatelessWidget {
  final AnimationController controller;

  const _FloatingStars({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        return IgnorePointer(
          child: CustomPaint(
            size: MediaQuery.of(context).size,
            painter: _StarsPainter(progress: controller.value),
          ),
        );
      },
    );
  }
}

class _StarsPainter extends CustomPainter {
  final double progress;

  const _StarsPainter({required this.progress});

  static const _positions = [
    Offset(0.1, 0.15),
    Offset(0.85, 0.12),
    Offset(0.25, 0.08),
    Offset(0.7, 0.22),
    Offset(0.05, 0.35),
    Offset(0.92, 0.4),
    Offset(0.15, 0.75),
    Offset(0.88, 0.7),
  ];

  static const _colors = [
    Color(0xFFFFD700),
    Color(0xFFFF8C42),
    Color(0xFF4FC3F7),
    Color(0xFFE91E63),
    Color(0xFF66BB6A),
    Color(0xFFFFD700),
    Color(0xFFFF8C42),
    Color(0xFF4FC3F7),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < _positions.length; i++) {
      final phase = (progress + i / _positions.length) % 1.0;
      final opacity = 0.4 + 0.6 * math.sin(phase * math.pi).abs();
      final scale = 0.6 + 0.4 * (phase < 0.5 ? phase * 2 : (1 - phase) * 2);

      final paint = Paint()
        ..color = _colors[i].withOpacity(opacity * 0.7)
        ..style = PaintingStyle.fill;

      final pos = Offset(
        _positions[i].dx * size.width,
        _positions[i].dy * size.height,
      );

      _drawStar(canvas, pos, 10 * scale, paint);
    }
  }

  void _drawStar(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final outerAngle = (i * 72 - 90) * math.pi / 180;
      final innerAngle = outerAngle + 36 * math.pi / 180;
      final outer = Offset(
        center.dx + size * math.cos(outerAngle),
        center.dy + size * math.sin(outerAngle),
      );
      final inner = Offset(
        center.dx + size * 0.4 * math.cos(innerAngle),
        center.dy + size * 0.4 * math.sin(innerAngle),
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
  bool shouldRepaint(_StarsPainter old) => old.progress != progress;
}

class _ConfettiBlast extends StatelessWidget {
  final AnimationController controller;

  const _ConfettiBlast({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        return IgnorePointer(
          child: CustomPaint(
            size: MediaQuery.of(context).size,
            painter: _ConfettiPainter(progress: controller.value),
          ),
        );
      },
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
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(42);
    for (int i = 0; i < 40; i++) {
      final startX = rnd.nextDouble() * size.width;
      final startY = -20 - rnd.nextDouble() * 100;
      final x = startX + math.sin(progress * math.pi * 2 + i) * 40;
      final y = startY + progress * (size.height + 150);
      final rotation = progress * math.pi * 4 * (rnd.nextDouble() - 0.5);
      final color = _colors[i % _colors.length];

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);
      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: 8 + rnd.nextDouble() * 6,
        height: 5 + rnd.nextDouble() * 4,
      );
      canvas.drawRect(
        rect,
        Paint()..color = color.withOpacity(1 - progress * 0.5),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}
