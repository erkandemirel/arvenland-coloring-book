import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/drawing.dart';

class InfoDialog extends StatelessWidget {
  final Drawing drawing;

  const InfoDialog({super.key, required this.drawing});

  static Future<void> show(BuildContext context, Drawing drawing) {
    return showDialog(
      context: context,
      builder: (_) => InfoDialog(drawing: drawing),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFF9C4), Color(0xFFE3F2FD)],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(drawing.emoji, style: const TextStyle(fontSize: 64)),
            const SizedBox(height: 12),
            Text(
              drawing.name,
              style: GoogleFonts.nunito(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF3D3D5C),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('💡', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      drawing.funFact,
                      style: GoogleFonts.nunito(
                        fontSize: 15,
                        height: 1.6,
                        color: const Color(0xFF5C5C7A),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4FC3F7),
                foregroundColor: Colors.white,
                minimumSize: const Size(120, 44),
              ),
              child: const Text('Harika!'),
            ),
          ],
        ),
      ),
    );
  }
}
