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
import '../widgets/info_dialog.dart';
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
            builder: (_) => CompletionScreen(drawing: drawing, imageBytes: bytes),
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
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF8888AA),
            ),
            child: Text('Hayır',
                style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B6B),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Evet, Sıfırla',
                style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      context.read<PaintingProvider>().reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(drawing.emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Text(
              drawing.name,
              style: GoogleFonts.nunito(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppTheme.textDark,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(Icons.info_outline_rounded,
                  color: Color(0xFF8A8AA3), size: 22),
            ),
            onPressed: () => InfoDialog.show(context, drawing),
            tooltip: 'Eğlenceli bilgi',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _PaintingCanvas(drawing: drawing, boundaryKey: canvasKey),
          ),
          const _BottomToolPanel(),
        ],
      ),
      floatingActionButton: _CompleteButton(
        onComplete: () => _complete(context),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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

    return LayoutBuilder(builder: (context, constraints) {
      final available = constraints.maxWidth / constraints.maxHeight;
      final aspect = available.clamp(0.72, 1.4);

      return Container(
        color: const Color(0xFFEDEDF1),
        child: Center(
          child: AspectRatio(
            aspectRatio: aspect,
            child: RepaintBoundary(
              key: boundaryKey,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
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
          ),
        ),
      );
    });
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
  const _BottomToolPanel();

  static const List<Color> _palette = [
    Color(0xFFFF6B6B),
    Color(0xFFF472B6),
    Color(0xFFFF8C42),
    Color(0xFFFFD166),
    Color(0xFF6BCB77),
    Color(0xFF2EC4B6),
    Color(0xFF74B9FF),
    Color(0xFF4D96FF),
    Color(0xFFA78BFA),
    Color(0xFFC084FC),
    Color(0xFFC4956A),
    Color(0xFF94A3B8),
    Color(0xFF3D3D5C),
    Color(0xFFFFFFFF),
  ];

  static const _brushes = [
    BrushType.keceli,
    BrushType.firca,
    BrushType.pastel,
    BrushType.fosforlu,
    BrushType.sprey,
    BrushType.silgi,
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PaintingProvider>();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Renk paleti
            Container(
              height: 74,
              padding: const EdgeInsets.symmetric(vertical: 12),
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
            const Divider(height: 1, indent: 20, endIndent: 20),
            // Fırça seçimi
            Container(
              height: 72,
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                itemCount: _brushes.length,
                itemBuilder: (context, index) {
                  final brush = _brushes[index];
                  final isSelected = provider.selectedBrush == brush;
                  return _BrushButton(
                    brush: brush,
                    color: provider.selectedColor,
                    isSelected: isSelected,
                    onTap: () => provider.setBrush(brush),
                  );
                },
              ),
            ),
            // Kalınlık + aksiyonlar
            _SizeAndActions(),
          ],
        ),
      ),
    );
  }
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: isSelected ? 52 : 44,
        height: isSelected ? 52 : 44,
        margin: const EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? const Color(0xFF3D3D5C) : Colors.white,
            width: isSelected ? 3 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.35),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: isSelected
            ? const Icon(Icons.check_rounded,
                color: Colors.white, size: 22)
            : null,
      ),
    );
  }
}

class _BrushButton extends StatelessWidget {
  final BrushType brush;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _BrushButton({
    required this.brush,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isEraser = brush == BrushType.silgi;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.symmetric(horizontal: 5),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (isEraser ? Colors.grey.shade200 : color.withOpacity(0.15))
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? (isEraser ? Colors.grey.shade400 : color)
                : Colors.grey.shade200,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _brushIcon(brush),
              color: isEraser ? Colors.grey.shade500 : color,
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              brush.label,
              style: GoogleFonts.nunito(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: isEraser ? Colors.grey.shade500 : color.withOpacity(0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _brushIcon(BrushType brush) {
    switch (brush) {
      case BrushType.keceli:
        return Icons.edit_rounded;
      case BrushType.firca:
        return Icons.brush_rounded;
      case BrushType.pastel:
        return Icons.colorize_rounded;
      case BrushType.fosforlu:
        return Icons.highlight_rounded;
      case BrushType.sprey:
        return Icons.water_drop_rounded;
      case BrushType.silgi:
        return Icons.auto_fix_normal_rounded;
      default:
        return Icons.circle;
    }
  }
}

class _SizeAndActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PaintingProvider>();
    final activeColor =
        provider.isEraser ? Colors.grey.shade400 : provider.selectedColor;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
      child: Row(
        children: [
          // Kalınlık önizlemesi
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: activeColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: activeColor.withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Slider
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: activeColor,
                thumbColor: activeColor,
                overlayColor: activeColor.withOpacity(0.15),
                inactiveTrackColor: Colors.grey.shade200,
                trackHeight: 5,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
              ),
              child: Slider(
                value: provider.brushSize,
                min: 4,
                max: 40,
                onChanged: provider.setBrushSize,
              ),
            ),
          ),
          // Aksiyon butonları
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

    if (confirm == true && context.mounted) {
      provider.reset();
    }
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
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFF4F4F6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF5C5C7A),
            size: 22,
          ),
        ),
      ),
    );
  }
}

class _CompleteButton extends StatelessWidget {
  final VoidCallback onComplete;

  const _CompleteButton({required this.onComplete});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: onComplete,
      backgroundColor: const Color(0xFF6BCB77),
      foregroundColor: Colors.white,
      icon: const Icon(Icons.check_rounded),
      label: Text(
        'Tamamla',
        style: GoogleFonts.nunito(fontWeight: FontWeight.w800),
      ),
    );
  }
}
