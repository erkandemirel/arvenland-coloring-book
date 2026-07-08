import '../models/drawing.dart';

/// Bir kategori için sıralı numaralı asset serisi üretir.
List<Drawing> _series({
  required String folder,
  required DrawingCategory category,
  required int count,
  required String emoji,
}) {
  return List.generate(count, (i) {
    final n = (i + 1).toString().padLeft(2, '0');
    return Drawing(
      id: '${folder}_$n',
      name: '${category.label} ${i + 1}',
      category: category,
      svgData: 'assets/coloring/drawings/$folder/${folder}_$n.png',
      emoji: emoji,
    );
  });
}

final List<Drawing> allDrawings = [
  ..._series(
    folder: 'hayvanlar',
    category: DrawingCategory.hayvanlar,
    count: 24,
    emoji: '🐾',
  ),
  ..._series(
    folder: 'bocekler',
    category: DrawingCategory.bocekler,
    count: 24,
    emoji: '🦋',
  ),
  ..._series(
    folder: 'doga',
    category: DrawingCategory.doga,
    count: 24,
    emoji: '🌸',
  ),
  ..._series(
    folder: 'yiyecekler',
    category: DrawingCategory.yiyecekler,
    count: 24,
    emoji: '🍎',
  ),
  ..._series(
    folder: 'araclar',
    category: DrawingCategory.araclar,
    count: 24,
    emoji: '🚗',
  ),
  ..._series(
    folder: 'mevsimler',
    category: DrawingCategory.mevsimler,
    count: 24,
    emoji: '❄️',
  ),
  ..._series(
    folder: 'ev_yasam',
    category: DrawingCategory.evYasam,
    count: 24,
    emoji: '🏠',
  ),
  ..._series(
    folder: 'kawaii',
    category: DrawingCategory.kawaii,
    count: 24,
    emoji: '🧸',
  ),
  ..._series(
    folder: 'mandala',
    category: DrawingCategory.mandala,
    count: 24,
    emoji: '🌀',
  ),
  ..._series(
    folder: 'uzay',
    category: DrawingCategory.uzay,
    count: 24,
    emoji: '🚀',
  ),
  ..._series(
    folder: 'sekiller',
    category: DrawingCategory.sekiller,
    count: 24,
    emoji: '🔷',
  ),
  ..._series(
    folder: 'manzara',
    category: DrawingCategory.manzara,
    count: 24,
    emoji: '🏔️',
  ),
];
