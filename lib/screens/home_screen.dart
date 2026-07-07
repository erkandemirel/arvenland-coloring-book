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
  @override
  Widget build(BuildContext context) {
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
              const SizedBox(height: 8),
              _buildWelcomeText(),
              const SizedBox(height: 16),
              Expanded(child: _buildCategoryCarousel()),
              const SizedBox(height: 12),
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
                  color: Color(0x22FF6B6B),
                  blurRadius: 10,
                  offset: Offset(0, 4),
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
          Expanded(
            child: _buildArvenlandTitle(),
          ),
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

  Widget _buildCategoryCarousel() {
    // Aktif kategorileri çizim verisinden çıkar.
    final activeCategories = DrawingCategory.values
        .where((cat) => allDrawings.any((d) => d.category == cat))
        .toList();

    return PageView.builder(
      controller: PageController(viewportFraction: 0.78),
      padEnds: true,
      itemCount: activeCategories.length,
      itemBuilder: (context, index) {
        final category = activeCategories[index];
        return _CategoryCard(
          category: category,
          onTap: () => _openCategory(category),
        );
      },
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
    final bgColor = CategoryIcon.bgOf(category);
    final accentColor = CategoryIcon.colorOf(category);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: accentColor.withOpacity(0.25),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
          border: Border.all(
            color: Colors.white.withOpacity(0.6),
            width: 4,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Image.asset(
                    CategoryCover.pathOf(category),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.75),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(28),
                  ),
                ),
                child: Text(
                  category.label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
