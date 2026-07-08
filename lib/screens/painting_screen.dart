import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/drawing.dart';
import '../models/stroke.dart';
import '../providers/painting_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/drawing_image.dart';
import 'completion_screen.dart';

class PaintingScreen extends StatefulWidget {
  final Drawing drawing;

  const PaintingScreen({super.key, required this.drawing});

  @override
  State<PaintingScreen> createState() => _PaintingScreenState();
}

class _PaintingScreenState extends State<PaintingScreen> {
  final GlobalKey _canvasKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PaintingProvider(),
      child: _PaintingView(
        drawing: widget.drawing,
        canvasKey: _canvasKey,
      ),
    );
  }
}

class _PaintingView extends StatelessWidget {
  final Drawing drawing;
  final GlobalKey canvasKey;

  const _PaintingView({required this.drawing, required this.canvasKey});

  Future<void> _complete(BuildContext context) async {
    try {
      final boundary =
          canvasKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2.5);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      if (context.mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                CompletionScreen(drawing: drawing, imageBytes: bytes),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Resim kaydedilemedi, tekrar dene!',
                style: GoogleFonts.nunito()),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF6EE),
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(drawing: drawing),
            Expanded(
              child: _PaintingCanvas(drawing: drawing, boundaryKey: canvasKey),
            ),
            _BottomToolPanel(onComplete: () => _complete(context)),
          ],
        ),
      ),
    );
  }
}

// ── Üst Bar ─────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final Drawing drawing;
  const _TopBar({required this.drawing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
      child: Row(
        children: [
          _RoundIcon(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Center(
              child: Text(
                drawing.name,
                style: GoogleFonts.nunito(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textDark,
                ),
              ),
            ),
          ),
          // Üst barın simetrisi için sağda boşluk
          const SizedBox(width: 44),
        ],
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(icon, size: 20, color: const Color(0xFF6B6B8A)),
      ),
    );
  }
}

// ── Tuval ───────────────────────────────────────────────────────────────────

class _PaintingCanvas extends StatelessWidget {
  final Drawing drawing;
  final GlobalKey boundaryKey;

  const _PaintingCanvas({required this.drawing, required this.boundaryKey});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PaintingProvider>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: LayoutBuilder(builder: (context, constraints) {
            final available = constraints.maxWidth / constraints.maxHeight;
            final aspect = available.clamp(0.72, 1.4);
            return Center(
              child: AspectRatio(
                aspectRatio: aspect,
                child: RepaintBoundary(
                  key: boundaryKey,
                  child: GestureDetector(
                    onPanStart: (d) => provider.startStroke(d.localPosition),
                    onPanUpdate: (d) => provider.continueStroke(d.localPosition),
                    onPanEnd: (_) => provider.endStroke(),
                    child: Container(
                      color: Colors.white,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          DrawingImage(source: drawing.svgData, fit: BoxFit.fill),
                          CustomPaint(
                            painter: _StrokePainter(
                              strokes: provider.strokes,
                              currentStroke: provider.currentStroke,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _StrokePainter extends CustomPainter {
  final List<Stroke> strokes;
  final Stroke? currentStroke;

  const _StrokePainter({required this.strokes, this.currentStroke});

  @override
  void paint(Canvas canvas, Size size) {
    final allStrokes = [
      ...strokes,
      if (currentStroke != null) currentStroke!,
    ];

    canvas.clipRect(Offset.zero & size);
    canvas.saveLayer(
      Offset.zero & size,
      Paint()..blendMode = BlendMode.multiply,
    );
    for (final stroke in allStrokes) {
      if (stroke.points.isEmpty) continue;
      switch (stroke.brush) {
        case BrushType.sprey:
          _paintSpray(canvas, stroke);
          break;
        case BrushType.pastel:
          _paintPastel(canvas, stroke);
          break;
        default:
          _paintPath(canvas, stroke);
      }
    }
    canvas.restore();
  }

  Path _buildPath(List<Offset> points) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      path.quadraticBezierTo(
          p0.dx, p0.dy, (p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
    }
    path.lineTo(points.last.dx, points.last.dy);
    return path;
  }

  void _paintPath(Canvas canvas, Stroke stroke) {
    double width = stroke.width;
    double opacity = 1.0;
    StrokeCap cap = StrokeCap.round;
    MaskFilter? mask;

    switch (stroke.brush) {
      case BrushType.kursun:
        width = stroke.width * 0.45;
        opacity = 0.8;
        break;
      case BrushType.keceli:
        break;
      case BrushType.firca:
        opacity = 0.95;
        mask = MaskFilter.blur(BlurStyle.normal, stroke.width * 0.18);
        break;
      case BrushType.tukenmez:
        width = stroke.width * 0.3;
        break;
      case BrushType.fosforlu:
        width = stroke.width * 1.9;
        opacity = 0.35;
        cap = StrokeCap.square;
        break;
      case BrushType.silgi:
        width = stroke.width * 1.6;
        break;
      default:
        break;
    }

    final paint = Paint()
      ..color = stroke.color.withValues(alpha: opacity)
      ..strokeWidth = width
      ..strokeCap = cap
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    if (mask != null) paint.maskFilter = mask;

    if (stroke.points.length == 1) {
      canvas.drawCircle(stroke.points.first, width / 2,
          Paint()..color = paint.color..maskFilter = mask);
      return;
    }
    canvas.drawPath(_buildPath(stroke.points), paint);
  }

  void _paintPastel(Canvas canvas, Stroke stroke) {
    final rnd = math.Random(stroke.seed);
    for (int pass = 0; pass < 3; pass++) {
      final dx = (rnd.nextDouble() - 0.5) * stroke.width * 0.25;
      final dy = (rnd.nextDouble() - 0.5) * stroke.width * 0.25;
      final paint = Paint()
        ..color = stroke.color.withValues(alpha: 0.35)
        ..strokeWidth = stroke.width * (0.55 + rnd.nextDouble() * 0.35)
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      if (stroke.points.length == 1) {
        canvas.drawCircle(stroke.points.first.translate(dx, dy),
            stroke.width / 2, Paint()..color = paint.color);
        continue;
      }
      final shifted = stroke.points.map((p) => p.translate(dx, dy)).toList();
      canvas.drawPath(_buildPath(shifted), paint);
    }
  }

  void _paintSpray(Canvas canvas, Stroke stroke) {
    final rnd = math.Random(stroke.seed);
    final radius = stroke.width * 1.2;
    final dot = Paint()..color = stroke.color.withValues(alpha: 0.55);

    for (final p in stroke.points) {
      for (int i = 0; i < 14; i++) {
        final angle = rnd.nextDouble() * 2 * math.pi;
        final dist = math.sqrt(rnd.nextDouble()) * radius;
        canvas.drawCircle(
          Offset(p.dx + math.cos(angle) * dist, p.dy + math.sin(angle) * dist),
          0.8 + rnd.nextDouble() * 1.4,
          dot,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_StrokePainter old) =>
      old.strokes != strokes || old.currentStroke != currentStroke;
}

// ── Alt Araç Paneli ─────────────────────────────────────────────────────────

class _BottomToolPanel extends StatelessWidget {
  final VoidCallback onComplete;
  const _BottomToolPanel({required this.onComplete});

  // Zenginleştirilmiş çocuk paleti — gruplandırılmış tonlar.
  static const List<Color> _palette = [
    // Kırmızı & pembe
    Color(0xFFFF5A5A), Color(0xFFFF7A9C), Color(0xFFF472B6), Color(0xFFFFB3B3),
    // Turuncu & sarı
    Color(0xFFFF8C42), Color(0xFFFFA94D), Color(0xFFFFD166), Color(0xFFFFEB99),
    // Yeşiller
    Color(0xFF6BCB77), Color(0xFF2EC4B6), Color(0xFFA8E6CF), Color(0xFF9DE38A),
    // Maviler
    Color(0xFF74B9FF), Color(0xFF4D96FF), Color(0xFF60D0E4), Color(0xFFB5DEFF),
    // Morlar
    Color(0xFFA78BFA), Color(0xFFC084FC), Color(0xFFD8B4FE), Color(0xFFE9D5FF),
    // Kahve & ten
    Color(0xFF8B5E3C), Color(0xFFC4956A), Color(0xFFE0AC69), Color(0xFFF5CBA7),
    // Nötr
    Color(0xFF3D3D5C), Color(0xFF6B6B8A), Color(0xFFB8B8C8), Color(0xFFFFFFFF),
  ];

  static const _brushes = <_BrushDef>[
    _BrushDef(BrushType.keceli, 'Keçeli', Icons.edit_rounded),
    _BrushDef(BrushType.firca, 'Fırça', Icons.brush_rounded),
    _BrushDef(BrushType.pastel, 'Pastel', Icons.colorize_rounded),
    _BrushDef(BrushType.kursun, 'Kurşun', Icons.create_rounded),
    _BrushDef(BrushType.fosforlu, 'Fosforlu', Icons.highlight_rounded),
    _BrushDef(BrushType.sprey, 'Sprey', Icons.water_drop_rounded),
    _BrushDef(BrushType.silgi, 'Silgi', Icons.auto_fix_normal_rounded),
  ];

  static const _sizes = <double>[6, 12, 20, 32];
  static const _sizeLabels = <String>['S', 'M', 'L', 'XL'];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PaintingProvider>();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            // Renk paleti
            SizedBox(
              height: 60,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                itemCount: _palette.length,
                itemBuilder: (context, index) {
                  final color = _palette[index];
                  final isSelected = provider.selectedColor == color;
                  return _ColorBlob(
                    color: color,
                    isSelected: isSelected,
                    onTap: () => provider.setColor(color),
                  );
                },
              ),
            ),
            const SizedBox(height: 6),
            // Fırça araçları
            SizedBox(
              height: 68,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _brushes.length,
                itemBuilder: (context, index) {
                  final brush = _brushes[index];
                  final isSelected = provider.selectedBrush == brush.type;
                  return _BrushButton(
                    def: brush,
                    color: provider.selectedColor,
                    isSelected: isSelected,
                    onTap: () => provider.setBrush(brush.type),
                  );
                },
              ),
            ),
            // Kalınlık + aksiyonlar — dar ekranda taşmasın diye kaydırılabilir
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
              child: LayoutBuilder(builder: (context, constraints) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minWidth: constraints.maxWidth),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: List.generate(_sizes.length, (i) {
                            final size = _sizes[i];
                            final active =
                                (provider.brushSize - size).abs() < 0.5;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: _SizeDot(
                                diameter: 14.0 + i * 6,
                                label: _sizeLabels[i],
                                color: provider.isEraser
                                    ? Colors.grey.shade500
                                    : provider.selectedColor,
                                active: active,
                                onTap: () => provider.setBrushSize(size),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(width: 12),
                        Row(
                          children: [
                            _ActionIcon(
                              icon: Icons.undo_rounded,
                              enabled: provider.canUndo,
                              onTap: provider.undo,
                            ),
                            const SizedBox(width: 6),
                            _ActionIcon(
                              icon: Icons.redo_rounded,
                              enabled: provider.canRedo,
                              onTap: provider.redo,
                            ),
                            const SizedBox(width: 6),
                            _ActionIcon(
                              icon: Icons.delete_outline_rounded,
                              enabled: provider.canUndo,
                              onTap: () => _confirmReset(context),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
            // Bitti butonu
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: onComplete,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6BCB77),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shadowColor: const Color(0xFF6BCB77).withOpacity(0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  icon: const Icon(Icons.check_circle_rounded, size: 24),
                  label: Text(
                    'Bitti!',
                    style: GoogleFonts.nunito(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context) async {
    final provider = context.read<PaintingProvider>();
    if (!provider.canUndo) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Sıfırla?',
            style: GoogleFonts.nunito(
                fontWeight: FontWeight.w800, color: AppTheme.textDark)),
        content: Text('Tüm boyamalar silinecek. Emin misin?',
            style: GoogleFonts.nunito(
                fontSize: 15, color: const Color(0xFF6B6B8A))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Hayır',
                style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B6B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Evet',
                style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) provider.reset();
  }
}

class _BrushDef {
  final BrushType type;
  final String label;
  final IconData icon;
  const _BrushDef(this.type, this.label, this.icon);
}

class _ColorBlob extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorBlob({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isWhite = color == Colors.white;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutBack,
        width: isSelected ? 52 : 44,
        height: isSelected ? 52 : 44,
        margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected
                ? const Color(0xFF3D3D5C)
                : (isWhite ? const Color(0xFFE0E0E8) : Colors.white),
            width: isSelected ? 3 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(isWhite ? 0.1 : 0.35),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: isSelected
            ? Icon(Icons.check_rounded,
                color: isWhite ? const Color(0xFF3D3D5C) : Colors.white,
                size: 22)
            : null,
      ),
    );
  }
}

class _BrushButton extends StatelessWidget {
  final _BrushDef def;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _BrushButton({
    required this.def,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isEraser = def.type == BrushType.silgi;
    final accent = isEraser ? Colors.grey.shade500 : color;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? accent.withOpacity(0.14) : const Color(0xFFF6F6FA),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? accent : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(def.icon, color: accent, size: 22),
            const SizedBox(height: 2),
            Text(
              def.label,
              style: GoogleFonts.nunito(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SizeDot extends StatelessWidget {
  final double diameter;
  final String label;
  final Color color;
  final bool active;
  final VoidCallback onTap;

  const _SizeDot({
    required this.diameter,
    required this.label,
    required this.color,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: active ? color.withOpacity(0.14) : const Color(0xFFF6F6FA),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active ? color : Colors.transparent,
            width: 2,
          ),
        ),
        alignment: Alignment.center,
        child: Container(
          width: diameter,
          height: diameter,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _ActionIcon({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        opacity: enabled ? 1.0 : 0.35,
        duration: const Duration(milliseconds: 200),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFF6F6FA),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: const Color(0xFF5C5C7A), size: 22),
        ),
      ),
    );
  }
}
