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
        left: false,
        right: false,
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth <= 480;
            final toolbarWidth = isCompact ? 56.0 : 88.0;
            final outerPadding = EdgeInsets.fromLTRB(
              isCompact ? 4 : 12,
              isCompact ? 6 : 10,
              isCompact ? 4 : 10,
              isCompact ? 4 : 8,
            );

            // Dikey/dar ekran (telefon): tuval üstte tüm alanı doldurur,
            // kalemler altta yatay şeritte dizilir.
            final isPortraitPhone = constraints.maxWidth < 600 &&
                constraints.maxHeight > constraints.maxWidth;
            if (isPortraitPhone) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(6, 6, 6, 0),
                child: Column(
                  children: [
                    Expanded(
                      child: _PaintingCanvas(
                        drawing: drawing,
                        boundaryKey: canvasKey,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _HorizontalArtToolbar(
                      onComplete: () => _complete(context),
                      onBack: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              );
            }

            // Geniş/yatay ekran: solda tuval, sağda dikey araç çubuğu.
            return Padding(
              padding: outerPadding,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _PaintingCanvas(
                      drawing: drawing,
                      boundaryKey: canvasKey,
                    ),
                  ),
                  SizedBox(width: isCompact ? 4 : 8),
                  SizedBox(
                    width: toolbarWidth,
                    child: _VerticalArtToolbar(
                      viewportWidth: constraints.maxWidth,
                      viewportHeight: constraints.maxHeight,
                      onComplete: () => _complete(context),
                      onBack: () => Navigator.of(context).pop(),
                      drawingName: drawing.name,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PaintingCanvas extends StatelessWidget {
  final Drawing drawing;
  final GlobalKey boundaryKey;

  const _PaintingCanvas({
    required this.drawing,
    required this.boundaryKey,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PaintingProvider>();
    return LayoutBuilder(
      builder: (context, constraints) {
        // Tuval alanı doldurur; kare resmin aşırı bozulmaması için oran
        // [0.72, 1.4] aralığına sıkıştırılır. Telefon/tablette tam dolu,
        // çok geniş PC ekranında ortalanır.
        final available = constraints.maxWidth / constraints.maxHeight;
        final aspect = available.clamp(0.62, 1.4);
        final cornerRadius = constraints.maxWidth < 320 ? 16.0 : 24.0;

        return Center(
          child: AspectRatio(
            aspectRatio: aspect,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(cornerRadius),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.055),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(cornerRadius),
                child: RepaintBoundary(
                  key: boundaryKey,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanStart: (d) => provider.startStroke(d.localPosition),
                    onPanUpdate: (d) => provider.continueStroke(d.localPosition),
                    onPanEnd: (_) => provider.endStroke(),
                    child: ColoredBox(
                      color: Colors.white,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          DrawingImage(
                            source: drawing.svgData,
                            fit: BoxFit.fill,
                          ),
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
      },
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

class _VerticalArtToolbar extends StatelessWidget {
  final VoidCallback onComplete;
  final VoidCallback onBack;
  final String drawingName;
  final double viewportWidth;
  final double viewportHeight;

  const _VerticalArtToolbar({
    required this.onComplete,
    required this.onBack,
    required this.drawingName,
    required this.viewportWidth,
    required this.viewportHeight,
  });

  static const _tools = <_ToolDef>[
    _ToolDef(BrushType.keceli, 'Marker', _ArtToolKind.marker),
    _ToolDef(BrushType.firca, 'Fırça', _ArtToolKind.brush),
    _ToolDef(BrushType.pastel, 'Mum Boya', _ArtToolKind.crayon),
    _ToolDef(BrushType.kursun, 'Kurşun Kalem', _ArtToolKind.pencil),
    _ToolDef(BrushType.tukenmez, 'Kuru Boya', _ArtToolKind.coloredPencil),
    _ToolDef(BrushType.fosforlu, 'Fosforlu', _ArtToolKind.highlighter),
    _ToolDef(BrushType.sprey, 'Sprey', _ArtToolKind.spray),
    _ToolDef(BrushType.silgi, 'Silgi', _ArtToolKind.eraser),
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PaintingProvider>();
    final isCompact = viewportWidth <= 480;
    final toolbarWidth = isCompact ? 56.0 : 88.0;
    final toolTarget = isCompact ? 40.0 : 64.0;
    final colorTarget = isCompact ? 44.0 : 60.0;
    final itemGap = isCompact ? 4.0 : 6.0;
    final safeBottom = MediaQuery.of(context).padding.bottom;

    return SizedBox(
      width: toolbarWidth,
      child: Column(
        children: [
          _MiniIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            tooltip: 'Geri',
            onTap: onBack,
            size: isCompact ? 36 : 44,
            iconColor: const Color(0xFF8B5CF6),
          ),
          SizedBox(height: isCompact ? 10 : 12),
          Tooltip(
            message: 'Renkler',
            waitDuration: const Duration(milliseconds: 150),
            child: _CircularColorButton(
              color: provider.selectedColor,
              onTap: () => _openColorPicker(context, provider),
              size: colorTarget,
            ),
          ),
          SizedBox(height: isCompact ? 10 : 12),
          Expanded(
            child: ScrollConfiguration(
              behavior: const _NoGlowScrollBehavior(),
              child: SingleChildScrollView(
                padding: EdgeInsets.only(bottom: isCompact ? 8 : 10),
                child: Column(
                  children: [
                    for (final t in _tools)
                      Padding(
                        padding: EdgeInsets.only(bottom: itemGap),
                        child: _ArtToolChip(
                          def: t,
                          color: provider.selectedColor,
                          selected: provider.selectedBrush == t.type,
                          onTap: () => provider.setBrush(t.type),
                          onLongPress: () =>
                              _openBrushSizePopover(context, provider),
                          size: toolTarget,
                          compact: isCompact,
                        ),
                      ),
                    SizedBox(height: isCompact ? 2 : 4),
                    _MiniIconButton(
                      icon: Icons.tune_rounded,
                      tooltip: 'Fırça Boyutu',
                      onTap: () => _openBrushSizePopover(context, provider),
                      size: isCompact ? 36 : 44,
                      child: _BrushSizeIcon(
                        color: provider.isEraser
                            ? Colors.grey.shade500
                            : provider.selectedColor,
                        size: provider.brushSize,
                      ),
                    ),
                    SizedBox(height: itemGap),
                    _MiniIconButton(
                      icon: Icons.undo_rounded,
                      tooltip: 'Geri Al',
                      enabled: provider.canUndo,
                      onTap: provider.undo,
                      size: isCompact ? 36 : 44,
                    ),
                    SizedBox(height: itemGap),
                    _MiniIconButton(
                      icon: Icons.redo_rounded,
                      tooltip: 'Yinele',
                      enabled: provider.canRedo,
                      onTap: provider.redo,
                      size: isCompact ? 36 : 44,
                    ),
                    SizedBox(height: itemGap),
                    _MiniIconButton(
                      icon: Icons.delete_outline_rounded,
                      tooltip: 'Temizle',
                      enabled: provider.canUndo,
                      onTap: () => _confirmReset(context, provider),
                      size: isCompact ? 36 : 44,
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: isCompact ? 6 : 8),
          Padding(
            padding: EdgeInsets.only(bottom: math.max(2, safeBottom * 0.35)),
            child: _CompactDoneButton(
              onTap: onComplete,
              compact: isCompact,
            ),
          ),
        ],
      ),
    );
  }

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
            style:
                GoogleFonts.nunito(fontSize: 15, color: const Color(0xFF6B6B8A))),
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
        color:
            provider.isEraser ? Colors.grey.shade500 : provider.selectedColor,
        value: provider.brushSize,
        onChanged: (v) => provider.setBrushSize(v),
      ),
    );
  }

class _ToolDef {
  final BrushType type;
  final String label;
  final _ArtToolKind kind;
  const _ToolDef(this.type, this.label, this.kind);
}

// ── Alt yatay araç şeridi (dikey telefon ekranı) ─────────────────────────────

class _HorizontalArtToolbar extends StatelessWidget {
  final VoidCallback onComplete;
  final VoidCallback onBack;

  const _HorizontalArtToolbar({
    required this.onComplete,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PaintingProvider>();
    final safeBottom = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: math.max(4, safeBottom * 0.5)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Üst sıra: kalemler yatay kaydırılabilir
          SizedBox(
            height: 64,
            child: ScrollConfiguration(
              behavior: const _NoGlowScrollBehavior(),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                children: [
                  for (final t in _VerticalArtToolbar._tools)
                    Padding(
                      padding: const EdgeInsets.only(right: 5),
                      child: _ArtToolChip(
                        def: t,
                        color: provider.selectedColor,
                        selected: provider.selectedBrush == t.type,
                        onTap: () => provider.setBrush(t.type),
                        onLongPress: () =>
                            _openBrushSizePopover(context, provider),
                        size: 58,
                        compact: true,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          // Alt sıra: geri, renk, boyut, geri al/yinele/temizle, bitti
          Row(
            children: [
              _MiniIconButton(
                icon: Icons.arrow_back_ios_new_rounded,
                tooltip: 'Geri',
                onTap: onBack,
                size: 40,
                iconColor: const Color(0xFF8B5CF6),
              ),
              const SizedBox(width: 6),
              _CircularColorButton(
                color: provider.selectedColor,
                onTap: () => _openColorPicker(context, provider),
                size: 44,
              ),
              const SizedBox(width: 6),
              _MiniIconButton(
                icon: Icons.tune_rounded,
                tooltip: 'Fırça Boyutu',
                onTap: () => _openBrushSizePopover(context, provider),
                size: 40,
                child: _BrushSizeIcon(
                  color: provider.isEraser
                      ? Colors.grey.shade500
                      : provider.selectedColor,
                  size: provider.brushSize,
                ),
              ),
              const Spacer(),
              _MiniIconButton(
                icon: Icons.undo_rounded,
                tooltip: 'Geri Al',
                enabled: provider.canUndo,
                onTap: provider.undo,
                size: 40,
              ),
              const SizedBox(width: 4),
              _MiniIconButton(
                icon: Icons.redo_rounded,
                tooltip: 'Yinele',
                enabled: provider.canRedo,
                onTap: provider.redo,
                size: 40,
              ),
              const SizedBox(width: 4),
              _MiniIconButton(
                icon: Icons.delete_outline_rounded,
                tooltip: 'Temizle',
                enabled: provider.canUndo,
                onTap: () => _confirmReset(context, provider),
                size: 40,
              ),
              const Spacer(),
              _CompactDoneButton(onTap: onComplete, compact: true),
            ],
          ),
        ],
      ),
    );
  }
}

enum _ArtToolKind {
  pencil,
  coloredPencil,
  crayon,
  marker,
  brush,
  highlighter,
  spray,
  eraser,
}

class _MiniIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;
  final String? tooltip;
  final Widget? child;
  final double size;
  final Color iconColor;

  const _MiniIconButton({
    required this.icon,
    required this.onTap,
    this.enabled = true,
    this.tooltip,
    this.child,
    this.size = 44,
    this.iconColor = const Color(0xFF5C5C7A),
  });

  @override
  Widget build(BuildContext context) {
    final btn = Semantics(
      button: true,
      enabled: enabled,
      label: tooltip,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: AnimatedOpacity(
          opacity: enabled ? 1 : 0.35,
          duration: const Duration(milliseconds: 180),
          child: Container(
            width: size,
            height: size,
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
            child: child ?? Icon(icon, size: size * 0.45, color: iconColor),
          ),
        ),
      ),
    );
    return tooltip != null ? Tooltip(message: tooltip!, child: btn) : btn;
  }
}

class _CircularColorButton extends StatelessWidget {
  final Color color;
  final VoidCallback onTap;
  final double size;

  const _CircularColorButton({
    required this.color,
    required this.onTap,
    this.size = 60,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = size * 0.54;
    return Semantics(
      button: true,
      label: 'Renkler',
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedScale(
                scale: 1,
                duration: const Duration(milliseconds: 180),
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const SweepGradient(
                      colors: [
                        Color(0xFFFF5A5A),
                        Color(0xFFFFC53D),
                        Color(0xFF6BCB77),
                        Color(0xFF4D96FF),
                        Color(0xFFA78BFA),
                        Color(0xFFFF7A9C),
                        Color(0xFFFF5A5A),
                      ],
                    ),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.85),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.24),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
              ),
              CustomPaint(
                size: Size.square(iconSize),
                painter: _ColorfulPaletteIconPainter(),
              ),
            ],
          ),
        ),
      ),
    );

  }
}

class _ColorfulPaletteIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.34;
    final palette = Path()
      ..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r));
    palette.fillType = PathFillType.evenOdd;
    palette.addOval(Rect.fromCircle(
      center: Offset(cx + r * 0.62, cy + r * 0.18),
      radius: r * 0.22,
    ));

    canvas.drawPath(palette, Paint()..color = const Color(0xFFF7D19B));
    canvas.drawPath(
      palette,
      Paint()
        ..color = const Color(0xFFF0B77E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.08,
    );

    final dots = <Color, Offset>{
      const Color(0xFFFF5A5A): Offset(cx - r * 0.46, cy - r * 0.30),
      const Color(0xFFFFD166): Offset(cx - r * 0.02, cy - r * 0.52),
      const Color(0xFF6BCB77): Offset(cx + r * 0.36, cy - r * 0.22),
      const Color(0xFF4D96FF): Offset(cx - r * 0.48, cy + r * 0.18),
      const Color(0xFFA78BFA): Offset(cx - r * 0.06, cy + r * 0.12),
    };
    dots.forEach((dotColor, pos) {
      canvas.drawCircle(pos, r * 0.16, Paint()..color = dotColor);
    });


  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ArtToolChip extends StatelessWidget {
  final _ToolDef def;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final double size;
  final bool compact;

  const _ArtToolChip({
    required this.def,
    required this.color,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
    this.size = 64,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent = def.kind == _ArtToolKind.eraser ? Colors.grey.shade500 : color;
    final highlightColor = selected
        ? accent.withOpacity(compact ? 0.22 : 0.18)
        : Colors.white.withOpacity(compact ? 0.88 : 0.94);

    return Tooltip(
      message: def.label,
      waitDuration: const Duration(milliseconds: 150),
      child: Semantics(
        button: true,
        selected: selected,
        label: def.label,
        child: GestureDetector(
          onTap: onTap,
          onLongPress: onLongPress,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutBack,
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: highlightColor,
              borderRadius: BorderRadius.circular(compact ? 15 : 18),
              border: Border.all(
                color: selected
                    ? accent.withOpacity(0.34)
                    : const Color(0xFFEDEAF6),
                width: selected ? 1.8 : 1.1,
              ),
              boxShadow: [
                BoxShadow(
                  color: accent.withOpacity(selected ? 0.18 : 0.05),
                  blurRadius: compact ? 7 : 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: AnimatedScale(
              scale: selected ? 1.08 : 1.0,
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutBack,
              child: Padding(
                padding: EdgeInsets.all(compact ? 3 : 4),
                child: _TintableToolIcon(
                  kind: def.kind,
                  color: accent,
                ),
              ),
            ),
          ),
        ),
      ),
    );

  }
}

class _TintableToolIcon extends StatelessWidget {
  final _ArtToolKind kind;
  final Color color;

  const _TintableToolIcon({required this.kind, required this.color});

  @override
  Widget build(BuildContext context) {
    final stem = switch (kind) {
      _ArtToolKind.pencil => 'tool_pencil',
      _ArtToolKind.coloredPencil => 'tool_colored_pencil',
      _ArtToolKind.crayon => 'tool_crayon',
      _ArtToolKind.marker => 'tool_marker',
      _ArtToolKind.brush => 'tool_brush',
      _ArtToolKind.highlighter => 'tool_highlighter',
      _ArtToolKind.spray => 'tool_spray',
      _ArtToolKind.eraser => 'tool_eraser',
    };

    if (kind == _ArtToolKind.eraser) {
      return Image.asset(
        'assets/tools/${stem}_base.png',
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        Image.asset(
          'assets/tools/${stem}_base.png',
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
        ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (rect) => LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              color.withOpacity(0.92),
              color,
            ],
          ).createShader(rect),
          child: Image.asset(
            'assets/tools/${stem}_mask.png',
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        ),
      ],
    );
  }
}

class _BrushSizeIcon extends StatelessWidget {
  final Color color;
  final double size;
  const _BrushSizeIcon({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    final t = (size / 40).clamp(0.0, 1.0);
    final active = t < 0.34 ? 0 : (t < 0.67 ? 1 : 2);
    final baseColor = color;
    Color dotColor(int i) => i == active ? baseColor : baseColor.withOpacity(0.32);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _dot(3.0, dotColor(0)),
        const SizedBox(width: 2),
        _dot(5.0, dotColor(1)),
        const SizedBox(width: 2),
        _dot(8.0, dotColor(2)),
      ],
    );
  }

  Widget _dot(double d, Color c) => Container(
        width: d,
        height: d,
        decoration: BoxDecoration(color: c, shape: BoxShape.circle),
      );
}

class _CompactDoneButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool compact;

  const _CompactDoneButton({required this.onTap, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final size = compact ? 56.0 : 64.0;
    return Semantics(
      button: true,
      label: 'Tamam',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF6BCB77), Color(0xFF2EC4B6)],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6BCB77).withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(Icons.check_rounded, color: Colors.white, size: compact ? 30 : 34),
              Positioned(
                top: compact ? 7 : 8,
                right: compact ? 9 : 10,
                child: Icon(Icons.auto_awesome,
                    color: const Color(0xFFFFF3B0), size: compact ? 12 : 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ColorPickerPanel extends StatefulWidget {
  final Color selected;
  final ValueChanged<Color> onSelected;
  const _ColorPickerPanel({required this.selected, required this.onSelected});

  @override
  State<_ColorPickerPanel> createState() => _ColorPickerPanelState();
}

class _ColorPickerPanelState extends State<_ColorPickerPanel> {
  int _mode = 0;
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
            if (_mode == 0) _buildGrid() else _buildSpectrum(),
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
            color: active ? AppTheme.textDark : const Color(0xFF8B8BA5),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
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
                  decoration:
                      BoxDecoration(color: widget.color, shape: BoxShape.circle),
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
                  decoration:
                      BoxDecoration(color: widget.color, shape: BoxShape.circle),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NoGlowScrollBehavior extends ScrollBehavior {
  const _NoGlowScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}
