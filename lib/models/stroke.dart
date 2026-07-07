import 'dart:ui';

enum BrushType {
  kursun,
  keceli,
  firca,
  pastel,
  tukenmez,
  fosforlu,
  sprey,
  silgi,
}

extension BrushTypeExt on BrushType {
  String get label {
    switch (this) {
      case BrushType.kursun:
        return 'Kurşun';
      case BrushType.keceli:
        return 'Keçeli';
      case BrushType.firca:
        return 'Fırça';
      case BrushType.pastel:
        return 'Pastel';
      case BrushType.tukenmez:
        return 'Tükenmez';
      case BrushType.fosforlu:
        return 'Fosforlu';
      case BrushType.sprey:
        return 'Sprey';
      case BrushType.silgi:
        return 'Silgi';
    }
  }
}

class Stroke {
  final List<Offset> points;
  final Color color;
  final double width;
  final BrushType brush;

  const Stroke({
    required this.points,
    required this.color,
    required this.width,
    this.brush = BrushType.keceli,
  });

  Stroke addPoint(Offset point) {
    return Stroke(
      points: [...points, point],
      color: color,
      width: width,
      brush: brush,
    );
  }

  /// Sprey gibi rastgelelik içeren fırçalar için kararlı tohum.
  int get seed =>
      points.isEmpty ? 0 : (points.first.dx * 7919 + points.first.dy * 104729).round();
}
