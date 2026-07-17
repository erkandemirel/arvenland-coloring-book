import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/drawing.dart';
import '../theme/app_theme.dart';
import '../widgets/app_background.dart';
import '../widgets/category_icon.dart';
import '../widgets/drawing_image.dart';
import 'painting_screen.dart';

class CategoryDetailScreen extends StatelessWidget {
  final DrawingCategory category;
  final List<Drawing> drawings;

  const CategoryDetailScreen({
    super.key,
    required this.category,
    required this.drawings,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildAppBar(context),
              const SizedBox(height: 14),
              _buildTitle(),
              const SizedBox(height: 14),
              Expanded(child: _buildDrawingGrid(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final accent = CategoryIcon.colorOf(category);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 16, 0),
      child: Row(
        children: [
          _CircleIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            color: const Color(0xFF8B5CF6),
            onTap: () => Navigator.of(context).pop(),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: CategoryIcon.bgOf(category),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(category.emoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text(
                  category.label,
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: accent,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static const _titleColors = [
    AppTheme.primary,        // H
    Color(0xFFFFA24C),       // a
    AppTheme.accent,         // d
    AppTheme.success,        // i
    AppTheme.secondary,      // ' '
    AppTheme.secondary,      // b
    AppTheme.lavender,       // o
    AppTheme.pink,           // y
    AppTheme.primary,        // a
    Color(0xFFFFA24C),       // l
    AppTheme.success,        // ı
    AppTheme.lavender,       // m
    AppTheme.pink,           // !
  ];

  Widget _buildTitle() {
    const text = 'Hadi boyayalım!';
    final baseStyle = GoogleFonts.nunito(
      fontSize: 28,
      fontWeight: FontWeight.w900,
      letterSpacing: 0.3,
      shadows: const [
        Shadow(
          color: Color(0x1AFF7A59),
          blurRadius: 8,
          offset: Offset(0, 2),
        ),
      ],
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    children: List.generate(text.length, (i) {
                      return TextSpan(
                        text: text[i],
                        style: baseStyle.copyWith(
                          color: _titleColors[i % _titleColors.length],
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${drawings.length} eğlenceli resim seni bekliyor',
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Image.asset(
            'assets/categories/icon_palette.png',
            width: 62,
            height: 62,
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }

  Widget _buildDrawingGrid(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: GridView.builder(
        padding: const EdgeInsets.only(bottom: 24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.92,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
        ),
        itemCount: drawings.length,
        itemBuilder: (context, index) {
          final drawing = drawings[index];
          return _CleanDrawingCard(
            drawing: drawing,
            index: index + 1,
            onTap: () => _openPainting(context, drawing),
          );
        },
      ),
    );
  }

  void _openPainting(BuildContext context, Drawing drawing) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PaintingScreen(drawing: drawing),
      ),
    );
  }
}

class _CleanDrawingCard extends StatelessWidget {
  final Drawing drawing;
  final int index;
  final VoidCallback onTap;

  const _CleanDrawingCard({
    required this.drawing,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(10),
                child: DrawingImage(source: drawing.svgData, fit: BoxFit.contain),
              ),
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$index',
                    style: GoogleFonts.nunito(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF8B5CF6),
                    ),
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

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _CircleIconButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }
}
