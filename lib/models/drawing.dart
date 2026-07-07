enum DrawingCategory {
  hayvanlar,
  ciftlik,
  ormanSafari,
  deniz,
  dinozorlar,
  bocekler,
  uzay,
  araclar,
  insaat,
  fantezi,
  masallar,
  robotlar,
  doga,
  mevsimler,
  yiyecekler,
  spor,
  muzikSanat,
  kampSeyahat,
  sehirler,
  harflerSayilar,
  evYasam,
  kawaii,
  mandala,
  sekiller,
  manzara,
}

extension DrawingCategoryExt on DrawingCategory {
  String get label {
    switch (this) {
      case DrawingCategory.hayvanlar:
        return 'Hayvanlar';
      case DrawingCategory.ciftlik:
        return 'Çiftlik';
      case DrawingCategory.ormanSafari:
        return 'Orman & Safari';
      case DrawingCategory.deniz:
        return 'Deniz';
      case DrawingCategory.dinozorlar:
        return 'Dinozorlar';
      case DrawingCategory.bocekler:
        return 'Böcekler';
      case DrawingCategory.uzay:
        return 'Uzay';
      case DrawingCategory.araclar:
        return 'Araçlar';
      case DrawingCategory.insaat:
        return 'İnşaat';
      case DrawingCategory.fantezi:
        return 'Fantezi';
      case DrawingCategory.masallar:
        return 'Masallar';
      case DrawingCategory.robotlar:
        return 'Robotlar';
      case DrawingCategory.doga:
        return 'Doğa';
      case DrawingCategory.mevsimler:
        return 'Mevsimler';
      case DrawingCategory.yiyecekler:
        return 'Yiyecekler';
      case DrawingCategory.spor:
        return 'Spor';
      case DrawingCategory.muzikSanat:
        return 'Müzik & Sanat';
      case DrawingCategory.kampSeyahat:
        return 'Kamp & Seyahat';
      case DrawingCategory.sehirler:
        return 'Şehirler';
      case DrawingCategory.harflerSayilar:
        return 'Harfler & Sayılar';
      case DrawingCategory.evYasam:
        return 'Ev & Yaşam';
      case DrawingCategory.kawaii:
        return 'Sevimli';
      case DrawingCategory.mandala:
        return 'Mandala & Desen';
      case DrawingCategory.sekiller:
        return 'Şekiller';
      case DrawingCategory.manzara:
        return 'Manzara';
    }
  }

  String get emoji {
    switch (this) {
      case DrawingCategory.hayvanlar:
        return '🐾';
      case DrawingCategory.ciftlik:
        return '🐄';
      case DrawingCategory.ormanSafari:
        return '🦁';
      case DrawingCategory.deniz:
        return '🐠';
      case DrawingCategory.dinozorlar:
        return '🦕';
      case DrawingCategory.bocekler:
        return '🦋';
      case DrawingCategory.uzay:
        return '🚀';
      case DrawingCategory.araclar:
        return '🚗';
      case DrawingCategory.insaat:
        return '🏗️';
      case DrawingCategory.fantezi:
        return '🐉';
      case DrawingCategory.masallar:
        return '👸';
      case DrawingCategory.robotlar:
        return '🤖';
      case DrawingCategory.doga:
        return '🌸';
      case DrawingCategory.mevsimler:
        return '🍂';
      case DrawingCategory.yiyecekler:
        return '🍎';
      case DrawingCategory.spor:
        return '⚽';
      case DrawingCategory.muzikSanat:
        return '🎵';
      case DrawingCategory.kampSeyahat:
        return '⛺';
      case DrawingCategory.sehirler:
        return '🏙️';
      case DrawingCategory.harflerSayilar:
        return '🔤';
      case DrawingCategory.evYasam:
        return '🏠';
      case DrawingCategory.kawaii:
        return '🧸';
      case DrawingCategory.mandala:
        return '🌀';
      case DrawingCategory.sekiller:
        return '🔷';
      case DrawingCategory.manzara:
        return '🏔️';
    }
  }
}

class Drawing {
  final String id;
  final String name;
  final DrawingCategory category;
  final String svgData;
  final String funFact;
  final String emoji;

  const Drawing({
    required this.id,
    required this.name,
    required this.category,
    required this.svgData,
    required this.funFact,
    required this.emoji,
  });
}
