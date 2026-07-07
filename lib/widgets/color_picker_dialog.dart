import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// iOS Markup tarzı renk seçici — Grid ve Spektrum sekmeleri.
class ColorPickerDialog extends StatefulWidget {
  final Color initialColor;

  const ColorPickerDialog({super.key, required this.initialColor});

  static Future<Color?> show(BuildContext context, Color initialColor) {
    return showModalBottomSheet<Color>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ColorPickerDialog(initialColor: initialColor),
    );
  }

  @override
  State<ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<ColorPickerDialog> {
  int _tab = 0; // 0: Grid, 1: Spektrum
  late Color _color;

  @override
  void initState() {
    super.initState();
    _color = widget.initialColor;
  }

  void _pick(Color c) => setState(() => _color = c);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F5FA),
        borderRadius: BorderRadius.circular(28),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Başlık
            Row(
              children: [
                // Seçili renk önizlemesi
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _color,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: Colors.black12),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Renkler',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                        fontSize: 19, fontWeight: FontWeight.w800),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context, _color),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE8E5EE),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded,
                        size: 20, color: Color(0xFF5C5C7A)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Sekmeler
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: const Color(0xFFE8E5EE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _SegBtn(
                    label: 'Grid',
                    selected: _tab == 0,
                    onTap: () => setState(() => _tab = 0),
                  ),
                  _SegBtn(
                    label: 'Spektrum',
                    selected: _tab == 1,
                    onTap: () => setState(() => _tab = 1),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 320,
              child: _tab == 0
                  ? _GridPicker(selected: _color, onPick: _pick)
                  : _SpectrumPicker(selected: _color, onPick: _pick),
            ),
          ],
        ),
      ),
    );
  }
}

class _SegBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SegBtn(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: selected
                ? const [BoxShadow(color: Colors.black12, blurRadius: 4)]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: selected ? const Color(0xFF2D2D3A) : const Color(0xFF8888AA),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Grid — iOS tarzı kesintisiz renk ızgarası ────────────────────────────────

class _GridPicker extends StatelessWidget {
  final Color selected;
  final ValueChanged<Color> onPick;

  const _GridPicker({required this.selected, required this.onPick});

  static const int _cols = 12;
  static const int _rows = 10;

  static Color _cellColor(int row, int col) {
    if (row == 0) {
      // Üst sıra: beyazdan siyaha gri tonları
      final t = col / (_cols - 1);
      final v = (1 - t);
      return Color.fromARGB(
          255, (v * 255).round(), (v * 255).round(), (v * 255).round());
    }
    final hue = col / _cols * 360;
    final t = (row - 1) / (_rows - 2); // 0 = koyu, 1 = açık? iOS: üst koyu, alt açık
    // Üst sıralar koyu, alt sıralar pastel.
    final lightness = 0.15 + t * 0.75;
    return HSLColor.fromAHSL(1, hue, 0.9, lightness).toColor();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final cellW = constraints.maxWidth / _cols;
      final cellH = constraints.maxHeight / _rows;

      void handle(Offset local) {
        final col = (local.dx / cellW).floor().clamp(0, _cols - 1);
        final row = (local.dy / cellH).floor().clamp(0, _rows - 1);
        onPick(_cellColor(row, col));
      }

      return GestureDetector(
        onPanDown: (d) => handle(d.localPosition),
        onPanUpdate: (d) => handle(d.localPosition),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CustomPaint(
            size: Size(constraints.maxWidth, constraints.maxHeight),
            painter: _GridPainter(selected: selected),
          ),
        ),
      );
    });
  }
}

class _GridPainter extends CustomPainter {
  final Color selected;

  const _GridPainter({required this.selected});

  @override
  void paint(Canvas canvas, Size size) {
    final cellW = size.width / _GridPicker._cols;
    final cellH = size.height / _GridPicker._rows;
    final paint = Paint()..style = PaintingStyle.fill;
    Rect? selectedRect;

    for (int r = 0; r < _GridPicker._rows; r++) {
      for (int c = 0; c < _GridPicker._cols; c++) {
        final color = _GridPicker._cellColor(r, c);
        // +0.5: hücreler arasında beyaz çizgi kalmasın
        final rect = Rect.fromLTWH(
            c * cellW, r * cellH, cellW + 0.5, cellH + 0.5);
        canvas.drawRect(rect, paint..color = color);
        if (color.toARGB32() == selected.toARGB32()) {
          selectedRect = Rect.fromLTWH(c * cellW, r * cellH, cellW, cellH);
        }
      }
    }

    if (selectedRect != null) {
      canvas.drawRect(
        selectedRect.deflate(1.5),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = Colors.white,
      );
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => old.selected != selected;
}

// ── Spektrum — iOS tarzı tam alan seçici ─────────────────────────────────────
// Dikey eksen: renk tonu (hue). Yatay eksen: solda beyaz → ortada saf renk →
// sağda siyah.

class _SpectrumPicker extends StatelessWidget {
  final Color selected;
  final ValueChanged<Color> onPick;

  const _SpectrumPicker({required this.selected, required this.onPick});

  static Color _colorAt(double x, double y) {
    final hue = (y * 360).clamp(0.0, 359.9);
    if (x <= 0.5) {
      final sat = (x * 2).clamp(0.0, 1.0);
      return HSVColor.fromAHSV(1, hue, sat, 1).toColor();
    }
    final value = (1 - (x - 0.5) * 2).clamp(0.0, 1.0);
    return HSVColor.fromAHSV(1, hue, 1, value).toColor();
  }

  static Offset _positionOf(Color color) {
    final hsv = HSVColor.fromColor(color);
    final y = hsv.hue / 360;
    double x;
    if (hsv.value >= 0.999) {
      x = hsv.saturation / 2;
    } else {
      x = 0.5 + (1 - hsv.value) / 2;
    }
    return Offset(x, y);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final size = Size(constraints.maxWidth, constraints.maxHeight);

      void handle(Offset local) {
        final x = (local.dx / size.width).clamp(0.0, 1.0);
        final y = (local.dy / size.height).clamp(0.0, 1.0);
        onPick(_colorAt(x, y));
      }

      final pos = _positionOf(selected);

      return GestureDetector(
        onPanDown: (d) => handle(d.localPosition),
        onPanUpdate: (d) => handle(d.localPosition),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              const CustomPaint(painter: _SpectrumPainter()),
              Positioned(
                left: pos.dx * size.width - 12,
                top: pos.dy * size.height - 12,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: const [
                      BoxShadow(color: Colors.black38, blurRadius: 4)
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

class _SpectrumPainter extends CustomPainter {
  const _SpectrumPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Dikey renk tonu geçişi
    const hueColors = [
      Color(0xFFFF0000),
      Color(0xFFFFFF00),
      Color(0xFF00FF00),
      Color(0xFF00FFFF),
      Color(0xFF0000FF),
      Color(0xFFFF00FF),
      Color(0xFFFF0000),
    ];
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: hueColors,
        ).createShader(rect),
    );

    // Sol yarı: beyaza doğru
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          colors: [Colors.white, Color(0x00FFFFFF)],
          stops: [0.0, 0.5],
        ).createShader(rect),
    );

    // Sağ yarı: siyaha doğru
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0x00000000), Colors.black],
          stops: [0.5, 1.0],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_SpectrumPainter old) => false;
}
