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
import '../widgets/color_picker_dialog.dart';
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
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
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
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFFE53935),
              elevation: 0,
              side: const BorderSide(color: Color(0xFFE4E2EA)),
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
      backgroundColor: AppTheme.bgStart,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        shadowColor: Colors.black12,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(drawing.emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Text(
              drawing.category.label,
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
            icon: const Icon(Icons.info_outline_rounded,
                color: Color(0xFF8A8AA3), size: 24),
            onPressed: () => InfoDialog.show(context, drawing),
            tooltip: 'Eğlenceli bilgi',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _PaintingCanvas(
                      drawing: drawing, boundaryKey: canvasKey),
                ),
                const _PenPanel(),
              ],
            ),
          ),
          _BottomToolbar(
            onComplete: () => _complete(context),
            onReset: () => _confirmReset(context),
          ),
        ],
      ),
    );
  }
}

// ── Canvas ──────────────────────────────────────────────────────────────────

class _PaintingCanvas extends StatelessWidget {
  final Drawing drawing;
  final GlobalKey boundaryKey;

  const _PaintingCanvas({required this.drawing, required this.boundaryKey});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PaintingProvider>();

    // Resim alanı doldurur; ama kare resmin aşırı esneyip bozulmaması için
    // tuval oranı [0.72, 1.4] aralığına sıkıştırılır. Telefonda tam dolu
    // kalır, geniş PC ekranında ortalanır.
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
              child: ClipRect(
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
                        // Boyalar resmin üstünde ama multiply modunda: beyaz
                        // alanlar renklenir, siyah çizgiler görünür kalır.
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

    // Tuval sınırları dışına çizim yapılmasın.
    canvas.clipRect(Offset.zero & size);
    // Katmanı multiply ile birleştir: boyalar çizgilerin altında kalmış gibi
    // görünür, silgi (beyaz) katman içinde normal çalışır.
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
    // Üç hafif kaymış geçişle dokulu pastel görünümü.
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
      final shifted =
          stroke.points.map((p) => p.translate(dx, dy)).toList();
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

// ── Sağ Kalem Paneli — kalemler yatay, dizilim dikey ─────────────────────────

class _PenPanel extends StatelessWidget {
  const _PenPanel();

  static const _brushes = [
    BrushType.kursun,
    BrushType.keceli,
    BrushType.firca,
    BrushType.pastel,
    BrushType.tukenmez,
    BrushType.fosforlu,
    BrushType.sprey,
    BrushType.silgi,
  ];

  Future<void> _pickColor(BuildContext context) async {
    final provider = context.read<PaintingProvider>();
    final color = await ColorPickerDialog.show(context, provider.selectedColor);
    if (color != null) provider.setColor(color);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PaintingProvider>();

    return Container(
      width: 96,
      decoration: const BoxDecoration(
        color: Color(0xFFFAF8FF),
        border: Border(left: BorderSide(color: Color(0xFFEEE8F0), width: 1)),
      ),
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 10),
        children: [
          // Renk seçim düğmesi — gökkuşağı halkalı
          Center(
            child: GestureDetector(
              onTap: () => _pickColor(context),
              child: Container(
                width: 44,
                height: 44,
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(
                    colors: [
                      Color(0xFFFF0000),
                      Color(0xFFFFFF00),
                      Color(0xFF00FF00),
                      Color(0xFF00FFFF),
                      Color(0xFF0000FF),
                      Color(0xFFFF00FF),
                      Color(0xFFFF0000),
                    ],
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: provider.selectedColor,
                    border: Border.all(color: Colors.white, width: 2.5),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Divider(height: 12, indent: 12, endIndent: 12,
              color: Color(0xFFEEE8F0)),
          ..._brushes.map((brush) => _PenItem(
                brush: brush,
                color: provider.selectedColor,
                isSelected: provider.selectedBrush == brush,
                onTap: () => provider.setBrush(brush),
              )),
        ],
      ),
    );
  }
}

/// Tek bir yatay kalem (uç solda) — seçiliyken sola, tuvale doğru kayar.
class _PenItem extends StatelessWidget {
  final BrushType brush;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _PenItem({
    required this.brush,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final penColor = brush == BrushType.silgi ? Colors.grey.shade400 : color;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: 44,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              left: isSelected ? 4 : 22,
              top: 5,
              child: Tooltip(
                message: brush.label,
                // Dikey kalemi 90° döndürüp yatay hale getir; uç solda kalır.
                child: RotatedBox(
                  quarterTurns: 3,
                  child: CustomPaint(
                    size: const Size(34, 92),
                    painter: _PenPainter(brush: brush, color: penColor),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Her fırça tipini çocuk kitabı tarzında — tombul, kalın konturlu ve
/// sevimli — dikey (uç yukarıda) çizer.
class _PenPainter extends CustomPainter {
  final BrushType brush;
  final Color color;

  const _PenPainter({required this.brush, required this.color});

  static const _ink = Color(0xFF4A4A66);

  Paint get _fill => Paint()..style = PaintingStyle.fill;

  Paint get _line => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.4
    ..color = _ink
    ..strokeJoin = StrokeJoin.round
    ..strokeCap = StrokeCap.round;

  // Gövdeye çizgi film parlaması: ince beyaz şerit.
  void _shine(Canvas canvas, Size size, double topY, double inset) {
    final w = size.width;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * (inset + 0.06), topY + 8, w * 0.10, size.height - topY - 18),
        const Radius.circular(3),
      ),
      _fill..color = Colors.white.withValues(alpha: 0.5),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    switch (brush) {
      case BrushType.kursun:
        // Tombul kurşun kalem: büyük üçgen uç, çizgili gövde
        final body = RRect.fromRectAndCorners(
          Rect.fromLTWH(w * 0.14, h * 0.26, w * 0.72, h * 0.74),
          bottomLeft: const Radius.circular(8),
          bottomRight: const Radius.circular(8),
        );
        canvas.drawRRect(body, _fill..color = color);
        _shine(canvas, size, h * 0.26, 0.14);
        // Ahşap uç
        final tip = Path()
          ..moveTo(w / 2, h * 0.02)
          ..lineTo(w * 0.14, h * 0.26)
          ..lineTo(w * 0.86, h * 0.26)
          ..close();
        canvas.drawPath(tip, _fill..color = const Color(0xFFF6DFB8));
        // Kurşun ucu
        canvas.drawPath(
          Path()
            ..moveTo(w / 2, h * 0.02)
            ..lineTo(w * 0.40, h * 0.10)
            ..lineTo(w * 0.60, h * 0.10)
            ..close(),
          _fill..color = _ink,
        );
        canvas.drawPath(tip, _line);
        canvas.drawRRect(body, _line);
        break;

      case BrushType.keceli:
        // Tombul keçeli: kubbe uç + şişko gövde + bant
        final body = RRect.fromRectAndCorners(
          Rect.fromLTWH(w * 0.10, h * 0.22, w * 0.80, h * 0.78),
          topLeft: const Radius.circular(6),
          topRight: const Radius.circular(6),
          bottomLeft: const Radius.circular(10),
          bottomRight: const Radius.circular(10),
        );
        canvas.drawRRect(body, _fill..color = Colors.white);
        canvas.drawRect(
            Rect.fromLTWH(w * 0.10, h * 0.30, w * 0.80, h * 0.26),
            _fill..color = color);
        _shine(canvas, size, h * 0.60, 0.10);
        // Kubbe uç
        final dome = Path()
          ..moveTo(w * 0.34, h * 0.22)
          ..quadraticBezierTo(w * 0.34, h * 0.03, w / 2, h * 0.03)
          ..quadraticBezierTo(w * 0.66, h * 0.03, w * 0.66, h * 0.22)
          ..close();
        canvas.drawPath(dome, _fill..color = color);
        canvas.drawPath(dome, _line);
        canvas.drawRRect(body, _line);
        break;

      case BrushType.firca:
        // Yumuşacık damla kıl + altın bilezik + tombul sap
        final blob = Path()
          ..moveTo(w / 2, h * 0.02)
          ..quadraticBezierTo(w * 0.16, h * 0.16, w * 0.24, h * 0.30)
          ..lineTo(w * 0.76, h * 0.30)
          ..quadraticBezierTo(w * 0.84, h * 0.16, w / 2, h * 0.02)
          ..close();
        canvas.drawPath(blob, _fill..color = color);
        canvas.drawPath(blob, _line);
        final band = Rect.fromLTWH(w * 0.22, h * 0.30, w * 0.56, h * 0.10);
        canvas.drawRect(band, _fill..color = const Color(0xFFFFD166));
        canvas.drawRect(band, _line);
        final handle = RRect.fromRectAndCorners(
          Rect.fromLTWH(w * 0.28, h * 0.40, w * 0.44, h * 0.60),
          bottomLeft: const Radius.circular(12),
          bottomRight: const Radius.circular(12),
        );
        canvas.drawRRect(handle, _fill..color = const Color(0xFFE8A468));
        _shine(canvas, size, h * 0.42, 0.30);
        canvas.drawRRect(handle, _line);
        break;

      case BrushType.pastel:
        // Klasik mum boya: yuvarlak uç + sargı bandı
        final crayon = Path()
          ..moveTo(w * 0.20, h * 0.18)
          ..quadraticBezierTo(w * 0.20, h * 0.10, w * 0.34, h * 0.08)
          ..lineTo(w * 0.44, h * 0.02)
          ..quadraticBezierTo(w / 2, 0, w * 0.56, h * 0.02)
          ..lineTo(w * 0.66, h * 0.08)
          ..quadraticBezierTo(w * 0.80, h * 0.10, w * 0.80, h * 0.18)
          ..lineTo(w * 0.80, h)
          ..lineTo(w * 0.20, h)
          ..close();
        canvas.drawPath(crayon, _fill..color = color);
        _shine(canvas, size, h * 0.20, 0.20);
        final wrapRect = Rect.fromLTWH(w * 0.20, h * 0.42, w * 0.60, h * 0.32);
        canvas.drawRect(wrapRect, _fill..color = Colors.white.withValues(alpha: 0.75));
        canvas.drawLine(Offset(w * 0.20, h * 0.42), Offset(w * 0.80, h * 0.42), _line);
        canvas.drawLine(Offset(w * 0.20, h * 0.74), Offset(w * 0.80, h * 0.74), _line);
        canvas.drawOval(
            Rect.fromCenter(center: Offset(w / 2, h * 0.58), width: w * 0.34, height: h * 0.14),
            _line..strokeWidth = 1.8);
        canvas.drawPath(crayon, _line..strokeWidth = 2.4);
        break;

      case BrushType.tukenmez:
        // Sevimli tükenmez: sivri uç + ince gövde + tıklama düğmesi
        final body = RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.28, h * 0.20, w * 0.44, h * 0.70),
          const Radius.circular(8),
        );
        canvas.drawRRect(body, _fill..color = Colors.white);
        canvas.drawRect(
            Rect.fromLTWH(w * 0.28, h * 0.44, w * 0.44, h * 0.18),
            _fill..color = color);
        final tip = Path()
          ..moveTo(w / 2, h * 0.02)
          ..lineTo(w * 0.36, h * 0.20)
          ..lineTo(w * 0.64, h * 0.20)
          ..close();
        canvas.drawPath(tip, _fill..color = color);
        canvas.drawPath(tip, _line);
        canvas.drawRRect(body, _line);
        final btn = RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.38, h * 0.90, w * 0.24, h * 0.08),
          const Radius.circular(4),
        );
        canvas.drawRRect(btn, _fill..color = color);
        canvas.drawRRect(btn, _line);
        break;

      case BrushType.fosforlu:
        // Tombul fosforlu: geniş kesik uç
        final body = RRect.fromRectAndCorners(
          Rect.fromLTWH(w * 0.06, h * 0.20, w * 0.88, h * 0.80),
          topLeft: const Radius.circular(4),
          topRight: const Radius.circular(4),
          bottomLeft: const Radius.circular(12),
          bottomRight: const Radius.circular(12),
        );
        canvas.drawRRect(body, _fill..color = Colors.white);
        canvas.drawRect(
            Rect.fromLTWH(w * 0.06, h * 0.52, w * 0.88, h * 0.28),
            _fill..color = color);
        _shine(canvas, size, h * 0.24, 0.06);
        final chisel = Path()
          ..moveTo(w * 0.26, h * 0.03)
          ..lineTo(w * 0.74, h * 0.09)
          ..lineTo(w * 0.80, h * 0.20)
          ..lineTo(w * 0.20, h * 0.20)
          ..close();
        canvas.drawPath(chisel, _fill..color = color.withValues(alpha: 0.85));
        canvas.drawPath(chisel, _line);
        canvas.drawRRect(body, _line);
        break;

      case BrushType.sprey:
        // Çizgi film sprey kutusu: puf puf noktalar + kubbe kapak
        final rnd = math.Random(5);
        final dot = Paint()..color = color.withValues(alpha: 0.7);
        for (int i = 0; i < 6; i++) {
          canvas.drawCircle(
            Offset(w * (0.25 + rnd.nextDouble() * 0.5), h * 0.01 + rnd.nextDouble() * h * 0.05),
            1.2 + rnd.nextDouble() * 1.4,
            dot,
          );
        }
        final nozzle = RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.40, h * 0.08, w * 0.20, h * 0.08),
          const Radius.circular(3),
        );
        canvas.drawRRect(nozzle, _fill..color = _ink);
        final cap = Path()
          ..moveTo(w * 0.22, h * 0.24)
          ..quadraticBezierTo(w * 0.24, h * 0.14, w / 2, h * 0.14)
          ..quadraticBezierTo(w * 0.76, h * 0.14, w * 0.78, h * 0.24)
          ..close();
        canvas.drawPath(cap, _fill..color = const Color(0xFFCFD8E0));
        canvas.drawPath(cap, _line);
        final can = RRect.fromRectAndCorners(
          Rect.fromLTWH(w * 0.18, h * 0.24, w * 0.64, h * 0.76),
          bottomLeft: const Radius.circular(10),
          bottomRight: const Radius.circular(10),
        );
        canvas.drawRRect(can, _fill..color = Colors.white);
        canvas.drawRect(
            Rect.fromLTWH(w * 0.18, h * 0.42, w * 0.64, h * 0.36),
            _fill..color = color);
        _shine(canvas, size, h * 0.28, 0.18);
        canvas.drawRRect(can, _line);
        break;

      case BrushType.silgi:
        // Tombul silgi: pembe kubbe kafa + beyaz gövde
        final head = Path()
          ..moveTo(w * 0.14, h * 0.34)
          ..lineTo(w * 0.14, h * 0.22)
          ..quadraticBezierTo(w * 0.14, h * 0.04, w / 2, h * 0.04)
          ..quadraticBezierTo(w * 0.86, h * 0.04, w * 0.86, h * 0.22)
          ..lineTo(w * 0.86, h * 0.34)
          ..close();
        canvas.drawPath(head, _fill..color = const Color(0xFFF799AC));
        canvas.drawPath(head, _line);
        final body = RRect.fromRectAndCorners(
          Rect.fromLTWH(w * 0.14, h * 0.34, w * 0.72, h * 0.62),
          bottomLeft: const Radius.circular(10),
          bottomRight: const Radius.circular(10),
        );
        canvas.drawRRect(body, _fill..color = Colors.white);
        _shine(canvas, size, h * 0.38, 0.14);
        canvas.drawRRect(body, _line);
        break;
    }
  }

  @override
  bool shouldRepaint(_PenPainter old) =>
      old.brush != brush || old.color != color;
}

// ── Alt Araç Çubuğu ─────────────────────────────────────────────────────────

class _BottomToolbar extends StatelessWidget {
  final VoidCallback onComplete;
  final VoidCallback onReset;

  const _BottomToolbar({required this.onComplete, required this.onReset});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PaintingProvider>();
    final activeColor = provider.isEraser
        ? Colors.grey.shade400
        : provider.selectedColor;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2))
        ],
      ),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.brush_rounded, size: 18,
                  color: activeColor.withValues(alpha: 0.8)),
              const SizedBox(width: 8),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: activeColor,
                    thumbColor: activeColor,
                    overlayColor: activeColor.withValues(alpha: 0.15),
                    inactiveTrackColor: Colors.grey.shade200,
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                  ),
                  child: Slider(
                    value: provider.brushSize,
                    min: 4,
                    max: 40,
                    onChanged: provider.setBrushSize,
                  ),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: provider.brushSize.clamp(8, 28),
                height: provider.brushSize.clamp(8, 28),
                decoration: BoxDecoration(
                  color: activeColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: activeColor.withValues(alpha: 0.4),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _ToolBtn(
                icon: Icons.undo_rounded,
                label: 'Geri Al',
                color: const Color(0xFF5C5C7A),
                enabled: provider.canUndo,
                onTap: provider.undo,
              ),
              const SizedBox(width: 8),
              _ToolBtn(
                icon: Icons.redo_rounded,
                label: 'Yinele',
                color: const Color(0xFF5C5C7A),
                enabled: provider.canRedo,
                onTap: provider.redo,
              ),
              const SizedBox(width: 8),
              _ToolBtn(
                icon: Icons.delete_outline_rounded,
                label: 'Sıfırla',
                color: const Color(0xFF5C5C7A),
                enabled: provider.canUndo,
                onTap: onReset,
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: onComplete,
                icon: const Icon(Icons.check_rounded, size: 18),
                label: Text('Tamamla',
                    style: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 15)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.textDark,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ToolBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;

  const _ToolBtn({
    required this.icon,
    required this.label,
    required this.color,
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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 2),
              Text(
                label,
                style: GoogleFonts.nunito(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
