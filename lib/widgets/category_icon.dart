import 'package:flutter/material.dart';
import '../models/drawing.dart';

class CategoryIcon extends StatelessWidget {
  final DrawingCategory category;
  final double size;
  final bool showBackground;

  const CategoryIcon({super.key, required this.category, this.size = 40, this.showBackground = true});

  static Color colorOf(DrawingCategory cat) {
    switch (cat) {
      case DrawingCategory.hayvanlar:
        return const Color(0xFFFF8A65);
      case DrawingCategory.ciftlik:
        return const Color(0xFFFF9800);
      case DrawingCategory.ormanSafari:
        return const Color(0xFF388E3C);
      case DrawingCategory.deniz:
        return const Color(0xFF0288D1);
      case DrawingCategory.dinozorlar:
        return const Color(0xFF00ACC1);
      case DrawingCategory.bocekler:
        return const Color(0xFF8BC34A);
      case DrawingCategory.uzay:
        return const Color(0xFF5E35B1);
      case DrawingCategory.araclar:
        return const Color(0xFFFF5722);
      case DrawingCategory.insaat:
        return const Color(0xFFFDD835);
      case DrawingCategory.fantezi:
        return const Color(0xFFAB47BC);
      case DrawingCategory.masallar:
        return const Color(0xFFE91E63);
      case DrawingCategory.robotlar:
        return const Color(0xFF1E88E5);
      case DrawingCategory.doga:
        return const Color(0xFF00897B);
      case DrawingCategory.mevsimler:
        return const Color(0xFFF9A825);
      case DrawingCategory.yiyecekler:
        return const Color(0xFFE53935);
      case DrawingCategory.spor:
        return const Color(0xFFD81B60);
      case DrawingCategory.muzikSanat:
        return const Color(0xFF8E24AA);
      case DrawingCategory.kampSeyahat:
        return const Color(0xFF6D4C41);
      case DrawingCategory.sehirler:
        return const Color(0xFF9E9E9E);
      case DrawingCategory.harflerSayilar:
        return const Color(0xFF3949AB);
      case DrawingCategory.evYasam:
        return const Color(0xFF8D6E63);
      case DrawingCategory.kawaii:
        return const Color(0xFFF06292);
      case DrawingCategory.mandala:
        return const Color(0xFF9575CD);
      case DrawingCategory.sekiller:
        return const Color(0xFF29B6F6);
      case DrawingCategory.manzara:
        return const Color(0xFF66BB6A);
    }
  }

  static Color bgOf(DrawingCategory cat) {
    switch (cat) {
      case DrawingCategory.hayvanlar:
        return const Color(0xFFFFE0D0);
      case DrawingCategory.ciftlik:
        return const Color(0xFFFFF3E0);
      case DrawingCategory.ormanSafari:
        return const Color(0xFFE0F2E1);
      case DrawingCategory.deniz:
        return const Color(0xFFE1F5FE);
      case DrawingCategory.dinozorlar:
        return const Color(0xFFE0F7FA);
      case DrawingCategory.bocekler:
        return const Color(0xFFF1F8E9);
      case DrawingCategory.uzay:
        return const Color(0xFFEDE7F6);
      case DrawingCategory.araclar:
        return const Color(0xFFFBE9E7);
      case DrawingCategory.insaat:
        return const Color(0xFFFFFDE7);
      case DrawingCategory.fantezi:
        return const Color(0xFFF3E5F5);
      case DrawingCategory.masallar:
        return const Color(0xFFFCE4EC);
      case DrawingCategory.robotlar:
        return const Color(0xFFE3F2FD);
      case DrawingCategory.doga:
        return const Color(0xFFE0F2F1);
      case DrawingCategory.mevsimler:
        return const Color(0xFFFFF8E1);
      case DrawingCategory.yiyecekler:
        return const Color(0xFFFFEBEE);
      case DrawingCategory.spor:
        return const Color(0xFFFFEBF5);
      case DrawingCategory.muzikSanat:
        return const Color(0xFFF8E7FF);
      case DrawingCategory.kampSeyahat:
        return const Color(0xFFEFEBE9);
      case DrawingCategory.sehirler:
        return const Color(0xFFF5F5F5);
      case DrawingCategory.harflerSayilar:
        return const Color(0xFFE8EAF6);
      case DrawingCategory.evYasam:
        return const Color(0xFFF1EBE9);
      case DrawingCategory.kawaii:
        return const Color(0xFFFDE7EF);
      case DrawingCategory.mandala:
        return const Color(0xFFEDE9F7);
      case DrawingCategory.sekiller:
        return const Color(0xFFE3F4FD);
      case DrawingCategory.manzara:
        return const Color(0xFFE9F6EA);
    }
  }

  static IconData iconOf(DrawingCategory cat) {
    switch (cat) {
      case DrawingCategory.hayvanlar:
        return Icons.pets;
      case DrawingCategory.ciftlik:
        return Icons.agriculture;
      case DrawingCategory.ormanSafari:
        return Icons.forest;
      case DrawingCategory.deniz:
        return Icons.waves;
      case DrawingCategory.dinozorlar:
        return Icons.egg_alt;
      case DrawingCategory.bocekler:
        return Icons.emoji_nature;
      case DrawingCategory.uzay:
        return Icons.rocket_launch;
      case DrawingCategory.araclar:
        return Icons.directions_car;
      case DrawingCategory.insaat:
        return Icons.construction;
      case DrawingCategory.fantezi:
        return Icons.castle;
      case DrawingCategory.masallar:
        return Icons.auto_stories;
      case DrawingCategory.robotlar:
        return Icons.smart_toy;
      case DrawingCategory.doga:
        return Icons.local_florist;
      case DrawingCategory.mevsimler:
        return Icons.celebration;
      case DrawingCategory.yiyecekler:
        return Icons.icecream;
      case DrawingCategory.spor:
        return Icons.sports_soccer;
      case DrawingCategory.muzikSanat:
        return Icons.music_note;
      case DrawingCategory.kampSeyahat:
        return Icons.explore;
      case DrawingCategory.sehirler:
        return Icons.location_city;
      case DrawingCategory.harflerSayilar:
        return Icons.abc;
      case DrawingCategory.evYasam:
        return Icons.chair;
      case DrawingCategory.kawaii:
        return Icons.favorite;
      case DrawingCategory.mandala:
        return Icons.blur_circular;
      case DrawingCategory.sekiller:
        return Icons.category;
      case DrawingCategory.manzara:
        return Icons.landscape;
    }
  }

  @override
  Widget build(BuildContext context) {
    final icon = Icon(iconOf(category), size: size * 0.62, color: colorOf(category));
    if (!showBackground) {
      return SizedBox(width: size, height: size, child: Center(child: icon));
    }
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bgOf(category),
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: icon,
    );
  }
}
