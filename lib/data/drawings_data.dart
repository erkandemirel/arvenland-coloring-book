import '../models/drawing.dart';

/// Bir kategori için sıralı numaralı asset serisi üretir.
List<Drawing> _series({
  required String folder,
  required DrawingCategory category,
  required int count,
  required String emoji,
  required String funFact,
}) {
  return List.generate(count, (i) {
    final n = (i + 1).toString().padLeft(2, '0');
    return Drawing(
      id: '${folder}_$n',
      name: '${category.label} $n',
      category: category,
      svgData: 'assets/coloring/drawings/$folder/${folder}_$n.png',
      funFact: funFact,
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
    funFact: 'Hayvanların her biri farklı bir süper yeteneğe sahiptir!',
  ),
  ..._series(
    folder: 'bocekler',
    category: DrawingCategory.bocekler,
    count: 24,
    emoji: '🦋',
    funFact: 'Kelebekler tatları ayaklarıyla algılar!',
  ),
  ..._series(
    folder: 'doga',
    category: DrawingCategory.doga,
    count: 24,
    emoji: '🌸',
    funFact: 'Bitkiler güneş ışığından kendi yemeğini yapar!',
  ),
  ..._series(
    folder: 'yiyecekler',
    category: DrawingCategory.yiyecekler,
    count: 24,
    emoji: '🍎',
    funFact: 'Meyve ve sebzeler gökkuşağının tüm renklerinde bulunur!',
  ),
  ..._series(
    folder: 'araclar',
    category: DrawingCategory.araclar,
    count: 24,
    emoji: '🚗',
    funFact: 'Canavar kamyonların tekerlekleri bir insandan daha uzundur!',
  ),
  ..._series(
    folder: 'mevsimler',
    category: DrawingCategory.mevsimler,
    count: 24,
    emoji: '❄️',
    funFact: 'Hiçbir kar tanesi bir diğerinin aynısı değildir!',
  ),
  ..._series(
    folder: 'ev_yasam',
    category: DrawingCategory.evYasam,
    count: 24,
    emoji: '🏠',
    funFact: 'Kendi odanı istediğin renklere boyayabilirsin!',  ),
  ..._series(
    folder: 'kawaii',
    category: DrawingCategory.kawaii,
    count: 24,
    emoji: '🧸',
    funFact: '"Kawaii" Japonca "sevimli" demektir!',
  ),
  ..._series(
    folder: 'mandala',
    category: DrawingCategory.mandala,
    count: 24,
    emoji: '🌀',
    funFact: 'Mandala boyamak insanı sakinleştirir ve odaklanmayı artırır!',  ),
  ..._series(
    folder: 'uzay',
    category: DrawingCategory.uzay,
    count: 24,
    emoji: '🚀',
    funFact: 'Uzayda ses duyulmaz, çünkü sesi taşıyacak hava yoktur!',
  ),
  ..._series(
    folder: 'sekiller',
    category: DrawingCategory.sekiller,
    count: 24,
    emoji: '🔷',
    funFact: 'Etrafına bak — her şey şekillerden oluşur!',
  ),
  ..._series(
    folder: 'manzara',
    category: DrawingCategory.manzara,
    count: 24,
    emoji: '🏔️',
    funFact: 'Dağların tepesi yazın bile karla kaplı olabilir!',
  ),
];
