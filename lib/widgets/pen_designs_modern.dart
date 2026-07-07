// YEDEK: Modern (iOS Markup tarzı) kalem tasarımları.
// Boyama ekranında tekrar kullanmak istersek _PenPainter yerine
// ModernPenPainter kullanmak yeterli.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/stroke.dart';

/// Her fırça tipini dikey (uç yukarıda), Markup tarzı gerçekçi kalem olarak çizer.
class ModernPenPainter extends CustomPainter {
  final BrushType brush;
  final Color color;

  const ModernPenPainter({required this.brush, required this.color});

  static const _body = Color(0xFFF4F2F5);
  static const _bodyEdge = Color(0xFFD8D4DC);

  void _drawBody(Canvas canvas, Size size, double topY,
      {double inset = 0.14}) {
    final w = size.width;
    final rect = Rect.fromLTWH(w * inset, topY, w * (1 - inset * 2), size.height - topY);
    final rrect = RRect.fromRectAndCorners(
      rect,
      topLeft: const Radius.circular(4),
      topRight: const Radius.circular(4),
    );
    canvas.drawRRect(rrect, Paint()..color = _body);
    canvas.drawRRect(
        rrect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = _bodyEdge);
    // Sol tarafta hafif gölge şeridi
    canvas.drawRect(
      Rect.fromLTWH(w * inset + 1, topY + 2, w * 0.10, size.height - topY - 2),
      Paint()..color = Colors.black.withValues(alpha: 0.04),
    );
  }

  void _drawBand(Canvas canvas, Size size, double y, double bandH,
      {double inset = 0.14}) {
    final w = size.width;
    canvas.drawRect(
      Rect.fromLTWH(w * inset, y, w * (1 - inset * 2), bandH),
      Paint()..color = color,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final fill = Paint()..style = PaintingStyle.fill;

    switch (brush) {
      case BrushType.kursun:
        // Sivri konik uç (renkli) + gövde + renk bandı
        _drawBody(canvas, size, h * 0.22);
        canvas.drawPath(
          Path()
            ..moveTo(w / 2, 0)
            ..lineTo(w * 0.14, h * 0.22)
            ..lineTo(w * 0.86, h * 0.22)
            ..close(),
          fill..color = const Color(0xFFEED9B8),
        );
        canvas.drawPath(
          Path()
            ..moveTo(w / 2, 0)
            ..lineTo(w * 0.38, h * 0.075)
            ..lineTo(w * 0.62, h * 0.075)
            ..close(),
          fill..color = color,
        );
        _drawBand(canvas, size, h * 0.24, h * 0.05);
        break;

      case BrushType.keceli:
        // Yuvarlak keçe uç + tombul gövde + renk bandı
        _drawBody(canvas, size, h * 0.18, inset: 0.08);
        canvas.drawPath(
          Path()
            ..moveTo(w * 0.40, h * 0.02)
            ..quadraticBezierTo(w / 2, -h * 0.015, w * 0.60, h * 0.02)
            ..lineTo(w * 0.70, h * 0.18)
            ..lineTo(w * 0.30, h * 0.18)
            ..close(),
          fill..color = color,
        );
        _drawBand(canvas, size, h * 0.62, h * 0.16, inset: 0.08);
        break;

      case BrushType.firca:
        // Kıl demeti (renkli) + metal bilezik + sap
        _drawBody(canvas, size, h * 0.34, inset: 0.20);
        canvas.drawPath(
          Path()
            ..moveTo(w / 2, 0)
            ..quadraticBezierTo(w * 0.20, h * 0.10, w * 0.30, h * 0.26)
            ..lineTo(w * 0.70, h * 0.26)
            ..quadraticBezierTo(w * 0.80, h * 0.10, w / 2, 0)
            ..close(),
          fill..color = color,
        );
        canvas.drawRect(
          Rect.fromLTWH(w * 0.26, h * 0.26, w * 0.48, h * 0.09),
          fill..color = const Color(0xFFC3CFD8),
        );
        break;

      case BrushType.pastel:
        // Tamamı renkli mum boya + kağıt sargı
        canvas.drawPath(
          Path()
            ..moveTo(w / 2, 0)
            ..lineTo(w * 0.22, h * 0.14)
            ..lineTo(w * 0.78, h * 0.14)
            ..close(),
          fill..color = color,
        );
        canvas.drawRect(
            Rect.fromLTWH(w * 0.22, h * 0.14, w * 0.56, h * 0.86),
            fill..color = color);
        // Kağıt sargı
        canvas.drawRect(
          Rect.fromLTWH(w * 0.22, h * 0.40, w * 0.56, h * 0.34),
          fill..color = Colors.white.withValues(alpha: 0.65),
        );
        canvas.drawLine(
          Offset(w * 0.22, h * 0.40),
          Offset(w * 0.78, h * 0.40),
          Paint()
            ..color = Colors.black.withValues(alpha: 0.1)
            ..strokeWidth = 1,
        );
        break;

      case BrushType.tukenmez:
        // İnce metal uç + zarif gövde + ince renk bandı
        _drawBody(canvas, size, h * 0.20, inset: 0.18);
        canvas.drawPath(
          Path()
            ..moveTo(w / 2, 0)
            ..lineTo(w * 0.44, h * 0.07)
            ..lineTo(w * 0.40, h * 0.20)
            ..lineTo(w * 0.60, h * 0.20)
            ..lineTo(w * 0.56, h * 0.07)
            ..close(),
          fill..color = const Color(0xFFAEBEC9),
        );
        canvas.drawRect(
          Rect.fromLTWH(w * 0.18, h * 0.52, w * 0.64, h * 0.045),
          fill..color = color,
        );
        break;

      case BrushType.fosforlu:
        // Geniş kesik uç (yarı saydam renk) + geniş gövde
        _drawBody(canvas, size, h * 0.16, inset: 0.05);
        canvas.drawPath(
          Path()
            ..moveTo(w * 0.24, h * 0.015)
            ..lineTo(w * 0.76, h * 0.06)
            ..lineTo(w * 0.82, h * 0.16)
            ..lineTo(w * 0.18, h * 0.16)
            ..close(),
          fill..color = color.withValues(alpha: 0.85),
        );
        _drawBand(canvas, size, h * 0.60, h * 0.18, inset: 0.05);
        break;

      case BrushType.sprey:
        // Sprey kutusu: püskürtme başlığı + renkli etiketli gövde
        final rnd = math.Random(3);
        final dot = Paint()..color = color.withValues(alpha: 0.65);
        for (int i = 0; i < 7; i++) {
          canvas.drawCircle(
            Offset(w * (0.30 + rnd.nextDouble() * 0.4),
                h * 0.02 + rnd.nextDouble() * h * 0.05),
            0.8 + rnd.nextDouble(),
            dot,
          );
        }
        canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(w * 0.42, h * 0.09, w * 0.16, h * 0.07),
              const Radius.circular(1.5)),
          fill..color = const Color(0xFF8B98A3),
        );
        canvas.drawRect(
          Rect.fromLTWH(w * 0.30, h * 0.16, w * 0.40, h * 0.06),
          fill..color = const Color(0xFFC3CFD8),
        );
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            Rect.fromLTWH(w * 0.16, h * 0.22, w * 0.68, h * 0.78),
            topLeft: const Radius.circular(5),
            topRight: const Radius.circular(5),
          ),
          fill..color = _body,
        );
        // Renkli etiket
        canvas.drawRect(
          Rect.fromLTWH(w * 0.16, h * 0.42, w * 0.68, h * 0.34),
          fill..color = color,
        );
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            Rect.fromLTWH(w * 0.16, h * 0.22, w * 0.68, h * 0.78),
            topLeft: const Radius.circular(5),
            topRight: const Radius.circular(5),
          ),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1
            ..color = _bodyEdge,
        );
        break;

      case BrushType.silgi:
        // Markup tarzı silgi: pembe kafa + beyaz gövde
        canvas.drawPath(
          Path()
            ..moveTo(w * 0.24, h * 0.16)
            ..quadraticBezierTo(w / 2, -h * 0.04, w * 0.76, h * 0.16)
            ..lineTo(w * 0.76, h * 0.30)
            ..lineTo(w * 0.24, h * 0.30)
            ..close(),
          fill..color = const Color(0xFFF48A9B),
        );
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            Rect.fromLTWH(w * 0.20, h * 0.30, w * 0.60, h * 0.70),
            topLeft: const Radius.circular(3),
            topRight: const Radius.circular(3),
          ),
          fill..color = _body,
        );
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            Rect.fromLTWH(w * 0.20, h * 0.30, w * 0.60, h * 0.70),
            topLeft: const Radius.circular(3),
            topRight: const Radius.circular(3),
          ),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1
            ..color = _bodyEdge,
        );
        break;
    }
  }

  @override
  bool shouldRepaint(ModernPenPainter old) =>
      old.brush != brush || old.color != color;
}

