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
        child: Stack(
          children: [
            // Ana çalışma alanı: sol tuval + sağ araç çubuğu
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
              child: Row(
                children: [
                  Expanded(
                    child: _PaintingCanvas(
                        drawing: drawing, boundaryKey: canvasKey),
                  ),
                  const SizedBox(width: 8),
                  _VerticalArtToolbar(
                    onComplete: () => _complete(context),
                    onBack: () => Navigator.of(context).pop(),
                    drawingName: drawing.name,
                  ),
                ],
              ),
            ),
          ],
        ),
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: LayoutBuilder(builder: (context, constraints) {
          final available = constraints.maxWidth / constraints.maxHeight;
          final aspect = available.clamp(0.7, 1.6);
          return Center(
            child: AspectRatio(
              aspectRatio: aspect,
              child: RepaintBoundary(
                key: boundaryKey,
                child: GestureDetector(
                  onPanStart: (d) => provider.startStroke(d.localPosition),
                  onPanUpdate: (d) =>
                      provider.continueStroke(d.localPosition),
                  onPanEnd: (_) => provider.endStroke(),
                  child: Container(
                    color: Colors.white,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        DrawingImage(
                            source: drawing.svgData, fit: BoxFit.fill),
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

// ── Sağ dikey araç çubuğu ───────────────────────────────────────────────────

class _VerticalArtToolbar extends StatelessWidget {
  final VoidCallback onComplete;
  final VoidCallback onBack;
  final String drawingName;

  const _VerticalArtToolbar({
    required this.onComplete,
    required this.onBack,
    required this.drawingName,
  });

  static const _tools = <_ToolDef>[
    _ToolDef(BrushType.keceli, 'Keçeli', _ArtToolKind.marker),
    _ToolDef(BrushType.firca, 'Fırça', _ArtToolKind.brush),
    _ToolDef(BrushType.pastel, 'Pastel', _ArtToolKind.crayon),
    _ToolDef(BrushType.kursun, 'Kurşun', _ArtToolKind.pencil),
    _ToolDef(BrushType.fosforlu, 'Fosforlu', _ArtToolKind.highlighter),
    _ToolDef(BrushType.sprey, 'Sprey', _ArtToolKind.spray),
    _ToolDef(BrushType.silgi, 'Silgi', _ArtToolKind.eraser),
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PaintingProvider>();
    return SizedBox(
      width: 88,
      child: Column(
        children: [
          // Üst: geri + başlık chip
          _MiniIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: onBack,
          ),
          const SizedBox(height: 12),
          // Renk seçici
          _CircularColorButton(
            color: provider.selectedColor,
            onTap: () => _openColorPicker(context, provider),
          ),
          const SizedBox(height: 12),
          // Araçlar — kaydırılabilir dikey liste
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  for (final t in _tools)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: _ArtToolChip(
                        def: t,
                        color: provider.selectedColor,
                        selected: provider.selectedBrush == t.type,
                        onTap: () => provider.setBrush(t.type),
                        onLongPress: () =>
                            _openBrushSizePopover(context, provider),
                      ),
                    ),
                  const SizedBox(height: 4),
                  // Kalınlık butonu
                  _MiniIconButton(
                    icon: Icons.tune_rounded,
                    tooltip: 'Kalınlık',
                    onTap: () => _openBrushSizePopover(context, provider),
                    child: _BrushSizeDot(
                      color: provider.isEraser
                          ? Colors.grey.shade500
                          : provider.selectedColor,
                      size: provider.brushSize,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _MiniIconButton(
                    icon: Icons.undo_rounded,
                    enabled: provider.canUndo,
                    onTap: provider.undo,
                  ),
                  const SizedBox(height: 6),
                  _MiniIconButton(
                    icon: Icons.redo_rounded,
                    enabled: provider.canRedo,
                    onTap: provider.redo,
                  ),
                  const SizedBox(height: 6),
                  _MiniIconButton(
                    icon: Icons.delete_outline_rounded,
                    enabled: provider.canUndo,
                    onTap: () => _confirmReset(context, provider),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          _CompactDoneButton(onTap: onComplete),
        ],
      ),
    );
  }

  Future<void> _confirmReset(
      BuildContext context, PaintingProvider provider) async {
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
    if (confirm == true) provider.reset();
  }

  void _openColorPicker(BuildContext context, PaintingProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ColorPickerPanel(
        selected: provider.selectedColor,
        onSelected: (c) {
          provider.setColor(c);
        },
      ),
    );
  }

  void _openBrushSizePopover(
      BuildContext context, PaintingProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _BrushSizePanel(
        color: provider.isEraser
            ? Colors.grey.shade500
            : provider.selectedColor,
        value: provider.brushSize,
        onChanged: (v) => provider.setBrushSize(v),
      ),
    );
  }
}

// ── Yardımcı Widget'lar ─────────────────────────────────────────────────────

class _ToolDef {
  final BrushType type;
  final String label;
  final _ArtToolKind kind;
  const _ToolDef(this.type, this.label, this.kind);
}

enum _ArtToolKind { pencil, crayon, marker, brush, highlighter, spray, eraser }

class _MiniIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;
  final String? tooltip;
  final Widget? child;
  const _MiniIconButton({
    required this.icon,
    required this.onTap,
    this.enabled = true,
    this.tooltip,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final btn = GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        opacity: enabled ? 1 : 0.35,
        duration: const Duration(milliseconds: 180),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: child ??
              Icon(icon, size: 20, color: const Color(0xFF5C5C7A)),
        ),
      ),
    );
    return tooltip != null ? Tooltip(message: tooltip!, child: btn) : btn;
  }
}

class _CircularColorButton extends StatelessWidget {
  final Color color;
  final VoidCallback onTap;
  const _CircularColorButton({required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isWhite = color == Colors.white;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 62,
        height: 62,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(isWhite ? 0.1 : 0.45),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: isWhite ? const Color(0xFFE0E0E8) : Colors.white,
              width: 3,
            ),
          ),
          child: Align(
            alignment: Alignment.bottomRight,
            child: Container(
              margin: const EdgeInsets.all(2),
              width: 16,
              height: 16,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: Color(0x22000000),
                      blurRadius: 3,
                      offset: Offset(0, 1)),
                ],
              ),
              child: const Icon(Icons.palette_rounded,
                  size: 11, color: Color(0xFF5C5C7A)),
            ),
          ),
        ),
      ),
    );
  }
}

class _ArtToolChip extends StatelessWidget {
  final _ToolDef def;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _ArtToolChip({
    required this.def,
    required this.color,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final accent = def.kind == _ArtToolKind.eraser ? Colors.grey.shade500 : color;
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutBack,
        width: 68,
        height: 62,
        decoration: BoxDecoration(
          color: selected ? accent.withOpacity(0.14) : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.center,
        child: Transform.rotate(
          angle: selected ? -0.15 : -0.35,
          child: SizedBox(
            width: 54,
            height: 54,
            child: CustomPaint(
              painter: _ArtToolPainter(kind: def.kind, color: accent),
            ),
          ),
        ),
      ),
    );
  }
}

class _ArtToolPainter extends CustomPainter {
  final _ArtToolKind kind;
  final Color color;
  _ArtToolPainter({required this.kind, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final shaft = Paint()..color = color;
    final dark = Paint()..color = const Color(0xFF3D3D5C);
    final wood = Paint()..color = const Color(0xFFF5CBA7);
    final tip = Paint()..color = const Color(0xFF3D3D5C);

    switch (kind) {
      case _ArtToolKind.pencil:
        // Uzun ince kurşun kalem
        final body = RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.30, h * 0.15, w * 0.20, h * 0.55),
            const Radius.circular(4));
        canvas.drawRRect(body, shaft);
        // ahşap uç
        final tri = Path()
          ..moveTo(w * 0.30, h * 0.70)
          ..lineTo(w * 0.50, h * 0.70)
          ..lineTo(w * 0.40, h * 0.90)
          ..close();
        canvas.drawPath(tri, wood);
        // grafit uç
        final tip2 = Path()
          ..moveTo(w * 0.37, h * 0.83)
          ..lineTo(w * 0.43, h * 0.83)
          ..lineTo(w * 0.40, h * 0.92)
          ..close();
        canvas.drawPath(tip2, tip);
        // silgi
        canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(w * 0.30, h * 0.08, w * 0.20, h * 0.10),
              const Radius.circular(3)),
          Paint()..color = const Color(0xFFFFB3B3),
        );
        break;
      case _ArtToolKind.crayon:
        // Kalın pastel — yuvarlak kağıt sargı
        final body = RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.26, h * 0.20, w * 0.28, h * 0.55),
            const Radius.circular(8));
        canvas.drawRRect(body, shaft);
        // sargı bantları
        canvas.drawRect(
            Rect.fromLTWH(w * 0.26, h * 0.30, w * 0.28, h * 0.04),
            Paint()..color = Colors.white.withOpacity(0.7));
        canvas.drawRect(
            Rect.fromLTWH(w * 0.26, h * 0.60, w * 0.28, h * 0.04),
            Paint()..color = Colors.white.withOpacity(0.7));
        // konik uç
        final tri = Path()
          ..moveTo(w * 0.26, h * 0.75)
          ..lineTo(w * 0.54, h * 0.75)
          ..lineTo(w * 0.40, h * 0.95)
          ..close();
        canvas.drawPath(tri, shaft);
        break;
      case _ArtToolKind.marker:
        // Keçeli kalem
        final body = RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.28, h * 0.20, w * 0.24, h * 0.50),
            const Radius.circular(6));
        canvas.drawRRect(body, shaft);
        // kapak halka
        canvas.drawRect(
            Rect.fromLTWH(w * 0.28, h * 0.68, w * 0.24, h * 0.04), dark);
        // konik uç
        final tri = Path()
          ..moveTo(w * 0.30, h * 0.72)
          ..lineTo(w * 0.50, h * 0.72)
          ..lineTo(w * 0.40, h * 0.93)
          ..close();
        canvas.drawPath(tri, dark);
        break;
      case _ArtToolKind.brush:
        // Fırça — sap + metal bilezik + kıllar
        canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(w * 0.32, h * 0.05, w * 0.16, h * 0.50),
              const Radius.circular(6)),
          Paint()..color = const Color(0xFFC4956A),
        );
        canvas.drawRect(
            Rect.fromLTWH(w * 0.30, h * 0.52, w * 0.20, h * 0.08),
            Paint()..color = const Color(0xFFB8B8C8));
        // kıllar — damla şekli
        final bristle = Path()
          ..moveTo(w * 0.30, h * 0.60)
          ..lineTo(w * 0.50, h * 0.60)
          ..quadraticBezierTo(w * 0.55, h * 0.80, w * 0.40, h * 0.96)
          ..quadraticBezierTo(w * 0.25, h * 0.80, w * 0.30, h * 0.60)
          ..close();
        canvas.drawPath(bristle, shaft);
        break;
      case _ArtToolKind.highlighter:
        // Fosforlu — geniş şişkin gövde, eğik uç
        final body = RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.22, h * 0.20, w * 0.36, h * 0.50),
            const Radius.circular(10));
        canvas.drawRRect(body, shaft);
        // eğik uç
        final tri = Path()
          ..moveTo(w * 0.22, h * 0.70)
          ..lineTo(w * 0.58, h * 0.70)
          ..lineTo(w * 0.52, h * 0.92)
          ..lineTo(w * 0.28, h * 0.92)
          ..close();
        canvas.drawPath(tri, Paint()..color = color.withOpacity(0.85));
        break;
      case _ArtToolKind.spray:
        // Sprey şişe
        canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(w * 0.28, h * 0.30, w * 0.28, h * 0.50),
              const Radius.circular(8)),
          shaft,
        );
        // nozul / kapak
        canvas.drawRect(
            Rect.fromLTWH(w * 0.34, h * 0.18, w * 0.16, h * 0.14), dark);
        canvas.drawRect(
            Rect.fromLTWH(w * 0.50, h * 0.22, w * 0.10, h * 0.06), dark);
        // sprey noktaları
        for (final p in [
          Offset(w * 0.72, h * 0.20),
          Offset(w * 0.80, h * 0.28),
          Offset(w * 0.75, h * 0.34),
          Offset(w * 0.68, h * 0.30),
        ]) {
          canvas.drawCircle(p, 1.6, Paint()..color = color);
        }
        break;
      case _ArtToolKind.eraser:
        // Silgi — pembe/mavi iki tonlu blok
        canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(w * 0.18, h * 0.32, w * 0.55, h * 0.35),
              const Radius.circular(8)),
          Paint()..color = const Color(0xFFFFB3B3),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(w * 0.18, h * 0.32, w * 0.55, h * 0.12),
              const Radius.circular(8)),
          Paint()..color = const Color(0xFF74B9FF),
        );
        break;
    }
  }

  @override
  bool shouldRepaint(_ArtToolPainter old) =>
      old.kind != kind || old.color != color;
}

class _BrushSizeDot extends StatelessWidget {
  final Color color;
  final double size;
  const _BrushSizeDot({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    // 6..40 aralığını 6..22 pixel'e eşle
    final d = (6 + (size / 40).clamp(0, 1) * 16).toDouble();
    return Container(
      width: d,
      height: d,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _CompactDoneButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CompactDoneButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6BCB77), Color(0xFF2EC4B6)],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6BCB77).withOpacity(0.45),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: const [
            Icon(Icons.check_rounded, color: Colors.white, size: 34),
            Positioned(
              top: 8,
              right: 10,
              child: Icon(Icons.auto_awesome,
                  color: Color(0xFFFFF3B0), size: 14),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Renk Seçici Panel ───────────────────────────────────────────────────────

class _ColorPickerPanel extends StatefulWidget {
  final Color selected;
  final ValueChanged<Color> onSelected;
  const _ColorPickerPanel({required this.selected, required this.onSelected});

  @override
  State<_ColorPickerPanel> createState() => _ColorPickerPanelState();
}

class _ColorPickerPanelState extends State<_ColorPickerPanel> {
  int _mode = 0; // 0: grid, 1: spectrum
  late Color _current = widget.selected;

  static const List<Color> _grid = [
    Color(0xFFFF5A5A), Color(0xFFFF8C42), Color(0xFFFFD166), Color(0xFFB6E33B),
    Color(0xFF6BCB77), Color(0xFF2EC4B6), Color(0xFF60D0E4), Color(0xFF74B9FF),
    Color(0xFF4D96FF), Color(0xFF1E3A8A), Color(0xFFA78BFA), Color(0xFFC084FC),
    Color(0xFFF472B6), Color(0xFFFF7A9C), Color(0xFF8B5E3C), Color(0xFFF5CBA7),
    Color(0xFFFFB3B3), Color(0xFF94A3B8), Color(0xFF3D3D5C), Color(0xFFFFFFFF),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E8),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 14),
            // Mod anahtarı
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F3F8),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _modeTab('Renkler', 0),
                  _modeTab('Spektrum', 1),
                ],
              ),
            ),
            const SizedBox(height: 18),
            if (_mode == 0)
              _buildGrid()
            else
              _buildSpectrum(),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _modeTab(String label, int index) {
    final active = _mode == index;
    return GestureDetector(
      onTap: () => setState(() => _mode = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: active
                ? AppTheme.textDark
                : const Color(0xFF8B8BA5),
          ),
        ),
      ),
    );
  }

  Widget _buildGrid() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final c in _grid)
          GestureDetector(
            onTap: () {
              setState(() => _current = c);
              widget.onSelected(c);
              Navigator.pop(context);
            },
            child: _swatch(c, _current == c),
          ),
      ],
    );
  }

  Widget _swatch(Color c, bool selected) {
    final isWhite = c == Colors.white;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutBack,
      width: selected ? 52 : 44,
      height: selected ? 52 : 44,
      decoration: BoxDecoration(
        color: c,
        shape: BoxShape.circle,
        border: Border.all(
          color: selected
              ? const Color(0xFF3D3D5C)
              : (isWhite ? const Color(0xFFE0E0E8) : Colors.white),
          width: selected ? 3 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: c.withOpacity(isWhite ? 0.1 : 0.35),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: selected
          ? Icon(Icons.check_rounded,
              size: 22,
              color: isWhite ? const Color(0xFF3D3D5C) : Colors.white)
          : null,
    );
  }

  Widget _buildSpectrum() {
    return Column(
      children: [
        _SpectrumBar(
          current: _current,
          onChanged: (c) {
            setState(() => _current = c);
            widget.onSelected(c);
          },
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _current,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: _current.withOpacity(0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.textDark,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 22, vertical: 12),
              ),
              child: Text('Tamam',
                  style: GoogleFonts.nunito(fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ],
    );
  }
}

class _SpectrumBar extends StatefulWidget {
  final Color current;
  final ValueChanged<Color> onChanged;
  const _SpectrumBar({required this.current, required this.onChanged});

  @override
  State<_SpectrumBar> createState() => _SpectrumBarState();
}

class _SpectrumBarState extends State<_SpectrumBar> {
  double _hue = 0;
  double _lightness = 0.5;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Ton (hue) barı
        _buildBar(
          gradient: const LinearGradient(colors: [
            Color(0xFFFF0000),
            Color(0xFFFFFF00),
            Color(0xFF00FF00),
            Color(0xFF00FFFF),
            Color(0xFF0000FF),
            Color(0xFFFF00FF),
            Color(0xFFFF0000),
          ]),
          value: _hue / 360,
          onChanged: (v) {
            setState(() => _hue = v * 360);
            _emit();
          },
        ),
        const SizedBox(height: 14),
        // Açıklık barı
        _buildBar(
          gradient: LinearGradient(colors: [
            Colors.black,
            HSLColor.fromAHSL(1, _hue, 1, 0.5).toColor(),
            Colors.white,
          ]),
          value: _lightness,
          onChanged: (v) {
            setState(() => _lightness = v);
            _emit();
          },
        ),
      ],
    );
  }

  void _emit() {
    final c = HSLColor.fromAHSL(1, _hue, 1, _lightness.clamp(0.05, 0.95))
        .toColor();
    widget.onChanged(c);
  }

  Widget _buildBar({
    required Gradient gradient,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      return GestureDetector(
        onPanDown: (d) => onChanged((d.localPosition.dx / w).clamp(0, 1)),
        onPanUpdate: (d) => onChanged((d.localPosition.dx / w).clamp(0, 1)),
        child: SizedBox(
          height: 28,
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              Container(
                height: 18,
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: (value.clamp(0, 1) * w) - 12,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: const Color(0xFF3D3D5C), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.18),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

// ── Fırça Kalınlığı Panel ───────────────────────────────────────────────────

class _BrushSizePanel extends StatefulWidget {
  final Color color;
  final double value;
  final ValueChanged<double> onChanged;
  const _BrushSizePanel({
    required this.color,
    required this.value,
    required this.onChanged,
  });

  @override
  State<_BrushSizePanel> createState() => _BrushSizePanelState();
}

class _BrushSizePanelState extends State<_BrushSizePanel> {
  late double _value = widget.value.clamp(2, 40).toDouble();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E8),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 16),
            Text('Kalınlık',
                style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textDark)),
            const SizedBox(height: 20),
            // canlı önizleme
            SizedBox(
              height: 56,
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 90),
                  width: _value * 1.2 + 4,
                  height: _value * 1.2 + 4,
                  decoration:
                      BoxDecoration(color: widget.color, shape: BoxShape.circle),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                      color: widget.color, shape: BoxShape.circle),
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: widget.color,
                      inactiveTrackColor: widget.color.withOpacity(0.2),
                      thumbColor: widget.color,
                      overlayColor: widget.color.withOpacity(0.15),
                      trackHeight: 6,
                    ),
                    child: Slider(
                      min: 2,
                      max: 40,
                      value: _value,
                      onChanged: (v) {
                        setState(() => _value = v);
                        widget.onChanged(v);
                      },
                    ),
                  ),
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                      color: widget.color, shape: BoxShape.circle),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
