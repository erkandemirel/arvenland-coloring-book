import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/drawing.dart';
import '../theme/app_theme.dart';
import '../widgets/category_icon.dart';
import '../widgets/drawing_card.dart';
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
              _buildAppBar(context),
              const SizedBox(height: 8),
              _buildTitle(context),
              const SizedBox(height: 12),
              Expanded(child: _buildDrawingGrid(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: CategoryIcon.colorOf(category).withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 20,
                color: CategoryIcon.colorOf(category),
              ),
            ),
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
                Text(
                  category.emoji,
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 8),
                Text(
                  category.label,
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: CategoryIcon.colorOf(category),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hadi boyayalım! 🖍️',
            style: GoogleFonts.nunito(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${drawings.length} eğlenceli resim seni bekliyor',
            style: GoogleFonts.nunito(
              fontSize: 14,
              color: const Color(0xFF8888AA),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawingGrid(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: GridView.builder(
        padding: const EdgeInsets.only(bottom: 20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.85,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: drawings.length,
        itemBuilder: (context, index) {
          final drawing = drawings[index];
          return DrawingCard(
            drawing: drawing,
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
