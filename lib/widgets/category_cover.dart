import '../models/drawing.dart';

/// Her kategori için kapak resmi yolunu döndürür.
/// Yeni kapak resimleri `assets/categories/` klasöründe olmalıdır.
class CategoryCover {
  static String pathOf(DrawingCategory category) {
    switch (category) {
      case DrawingCategory.hayvanlar:
        return 'assets/categories/category_animals.png';
      case DrawingCategory.bocekler:
        return 'assets/categories/category_insects.png';
      case DrawingCategory.doga:
        return 'assets/categories/category_nature.png';
      case DrawingCategory.yiyecekler:
        return 'assets/categories/category_food.png';
      case DrawingCategory.araclar:
        return 'assets/categories/category_vehicles.png';
      case DrawingCategory.mevsimler:
        return 'assets/categories/category_seasons.png';
      case DrawingCategory.evYasam:
        return 'assets/categories/category_home.png';
      case DrawingCategory.kawaii:
        return 'assets/categories/category_kawaii.png';
      case DrawingCategory.mandala:
        return 'assets/categories/category_mandala.png';
      case DrawingCategory.uzay:
        return 'assets/categories/category_space.png';
      case DrawingCategory.sekiller:
        return 'assets/categories/category_shapes.png';
      case DrawingCategory.manzara:
        return 'assets/categories/category_landscapes.png';
      case DrawingCategory.dinozorlar:
        return 'assets/categories/category_dinosaurs.png';
      default:
        return 'assets/categories/category_kawaii.png';
    }
  }
}
