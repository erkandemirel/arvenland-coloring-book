import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/drawings_data.dart';
import '../models/drawing.dart';
import '../theme/app_theme.dart';
import '../widgets/category_cover.dart';
import '../widgets/category_icon.dart';
import 'category_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pageController = PageController(viewportFraction: 0.82);
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      final page = _pageController.page?.round() ?? 0;
      if (page != _currentPage) setState(() => _currentPage = page);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<DrawingCategory> get _activeCategories => DrawingCategory.values
      .where((cat) => allDrawings.any((d) => d.category == cat))
      .toList();

  @override
  Widget build(BuildContext context) {
    final categories = _activeCategories;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.bgStart, AppTheme.bgEnd],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const SizedBox(height: 4),
              _buildWelcomeText(),
              const SizedBox(height: 12),
              Expanded(child: _buildCarousel(categories)),
              const SizedBox(height: 8),
              _buildDots(categories.length),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x22A78BFA),
                  blurRadius: 12,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.asset(
                'assets/categories/app_icon.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(child: _buildArvenlandTitle()),
        ],
      ),
    );
  }

  static const _titleColors = [
    Color(0xFFFF6B6B),
    Color(0xFFFF8C42),
    Color(0xFF6BCB77),
    Color(0xFFA78BFA),
    Color(0xFF74B9FF),
    Color(0xFFFFD166),
    Color(0xFFC084FC),
    Color(0xFF4D96FF),
    Color(0xFFFF8C42),
  ];

  Widget _buildArvenlandTitle() {
    const letters = 'Arvenland';
    final style = GoogleFonts.nunito(
      fontSize: 32,
      fontWeight: FontWeight.w900,
      letterSpacing: 0.5,
    );
    return RichText(
      text: TextSpan(
        children: List.generate(letters.length, (i) {
          return TextSpan(
            text: letters[i],
            style: style.copyWith(color: _titleColors[i]),
          );
        }),
      ),
    );
  }

  Widget _buildWelcomeText() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        'Bir kategori seç, renkleri keşfet! 🎨',
        style: GoogleFonts.nunito(
          fontSize: 16,
          color: const Color(0xFF8B5CF6),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildCarousel(List<DrawingCategory> categories) {
    return PageView.builder(
      controller: _pageController,
      padEnds: true,
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return AnimatedBuilder(
          animation: _pageController,
          builder: (context, child) {
            double delta = 0;
            if (_pageController.position.haveDimensions) {
              delta = (_pageController.page ?? 0) - index;
            }
            final scale = (1 - (delta.abs() * 0.08)).clamp(0.9, 1.0);
            return Transform.scale(scale: scale, child: child);
          },
          child: _CategoryCard(
            category: category,
            onTap: () => _openCategory(category),
          ),
        );
      },
    );
  }

  Widget _buildDots(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 22 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active
                ? const Color(0xFF8B5CF6)
                : const Color(0xFFD5D5E4),
            borderRadius: BorderRadius.circular(6),
          ),
        );
      }),
    );
  }

  void _openCategory(DrawingCategory category) {
    final drawings = allDrawings.where((d) => d.category == category).toList();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CategoryDetailScreen(
          category: category,
          drawings: drawings,
        ),
      ),
    );
  }
}

// ── Kategori Kartı ───────────────────────────────────────────────────────────

class _CategoryCard extends StatelessWidget {
  final DrawingCategory category;
  final VoidCallback onTap;

  const _CategoryCard({required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Kategori adı zaten resmin içinde — kart, gölge veya alt etiket yok.
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
        child: Image.asset(
          CategoryCover.pathOf(category),
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
