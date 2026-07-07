import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/drawing.dart';
import 'category_icon.dart';
import 'drawing_image.dart';

class DrawingCard extends StatelessWidget {
  final Drawing drawing;
  final VoidCallback onTap;

  const DrawingCard({super.key, required this.drawing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(6),
                child: DrawingImage(source: drawing.svgData),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              color: const Color(0xFFFAF8FF),
              child: Row(
                children: [
                  CategoryIcon(category: drawing.category, size: 28, showBackground: true),
                  const Spacer(),
                  Text(
                    drawing.category.label,
                    style: GoogleFonts.nunito(
                      color: const Color(0xFF8888AA),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
