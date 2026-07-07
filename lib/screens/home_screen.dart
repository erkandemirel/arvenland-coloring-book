import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/drawings_data.dart';
import '../models/drawing.dart';
import '../theme/app_theme.dart';
import '../widgets/category_icon.dart';
import '../widgets/drawing_card.dart';
import 'painting_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DrawingCategory? _selectedCategory;
  final ScrollController _gridController = ScrollController();

  @override
  void dispose() {
    _gridController.dispose();
    super.dispose();
  }

  // Filtre değişince grid'i en üste al.
  void _resetScroll() {
    if (_gridController.hasClients) _gridController.jumpTo(0);
  }

  List<Drawing> get _filteredDrawings {
    return allDrawings.where((d) {
      return _selectedCategory == null || d.category == _selectedCategory;
    }).toList();
  }

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
              _buildCategoryFilter(),
              Expanded(child: _buildDrawingGrid()),
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
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBF0),
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x22FF6B6B),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: SizedBox(
                width: 44,
                height: 44,
                child: CustomPaint(painter: _AppIconPainter()),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildArvenlandTitle(),
              Text(
                'Bir resim seç ve boya!',
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  color: const Color(0xFF8B5CF6),
                  fontWeight: FontWeight.w600,
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
    Color(0xFFFF6B6B), // A - ikondaki A harfi rengi
    Color(0xFFFF8C42), // r - araçlar orange
    Color(0xFF6BCB77), // v - green
    Color(0xFFA78BFA), // e - uzay purple
    Color(0xFF74B9FF), // n - deniz blue
    Color(0xFFFFD166), // l - yiyecekler yellow
    Color(0xFFC084FC), // a - harfler violet
    Color(0xFF4D96FF), // n - spor blue
    Color(0xFFFF8C42), // d - orange
  ];

  Widget _buildArvenlandTitle() {
    const letters = 'Arvenland';
    final style = GoogleFonts.nunito(
      fontSize: 28,
      fontWeight: FontWeight.w900,
      letterSpacing: 0.3,
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

  Widget _buildCategoryFilter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kategori',
            style: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF8888AA),
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _CategoryChip(
                  icon: const Icon(Icons.auto_awesome,
                      size: 16, color: Color(0xFF8B5CF6)),
                  label: 'Tümü',
                  isSelected: _selectedCategory == null,
                  selectedColor: const Color(0xFF8B5CF6),
                  onTap: () => setState(() {
                    _selectedCategory = null;
                    _resetScroll();
                  }),
                ),
                ...DrawingCategory.values.map((cat) => Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: _CategoryChip(
                        icon: CategoryIcon(
                            category: cat, size: 22, showBackground: false),
                        label: cat.label,
                        isSelected: _selectedCategory == cat,
                        selectedColor: CategoryIcon.colorOf(cat),
                        onTap: () => setState(() {
                          _selectedCategory = cat;
                          _resetScroll();
                        }),
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawingGrid() {
    final drawings = _filteredDrawings;

    if (drawings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              'Bu filtreye uygun çizim bulunamadı',
              style: GoogleFonts.nunito(
                fontSize: 16,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: GridView.builder(
        controller: _gridController,
        padding: const EdgeInsets.only(bottom: 20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.82,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: drawings.length,
        itemBuilder: (context, index) {
          final drawing = drawings[index];
          return DrawingCard(
            drawing: drawing,
            onTap: () => _openPainting(drawing),
          );
        },
      ),
    );
  }

  void _openPainting(Drawing drawing) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PaintingScreen(drawing: drawing),
      ),
    );
  }
}

// ── Category Chip ─────────────────────────────────────────────────────────────

class _CategoryChip extends StatelessWidget {
  final Widget icon;
  final String label;
  final bool isSelected;
  final Color selectedColor;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.selectedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isSelected ? selectedColor : const Color(0xFF8888AA);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? selectedColor : const Color(0xFFE4E2EA),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.nunito(
                color: textColor,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── App Icon Painter ──────────────────────────────────────────────────────────

class _AppIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final f = Paint()..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(w * .18, h * .22), w * .16,
        f..color = const Color(0xFFFF6B6B).withOpacity(.55));
    canvas.drawCircle(Offset(w * .82, h * .18), w * .13,
        f..color = const Color(0xFF6BCB77).withOpacity(.55));
    canvas.drawCircle(Offset(w * .86, h * .78), w * .14,
        f..color = const Color(0xFF74B9FF).withOpacity(.55));
    canvas.drawCircle(Offset(w * .14, h * .80), w * .12,
        f..color = const Color(0xFFFFD166).withOpacity(.55));
    canvas.drawCircle(Offset(w * .50, h * .12), w * .09,
        f..color = const Color(0xFFF472B6).withOpacity(.55));
    canvas.drawCircle(Offset(w * .88, h * .50), w * .10,
        f..color = const Color(0xFFA78BFA).withOpacity(.45));

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..color = const Color(0xFFFF6B6B)
      ..strokeWidth = w * .16
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(
      Path()
        ..moveTo(w * .18, h * .82)
        ..lineTo(w * .50, h * .12)
        ..lineTo(w * .82, h * .82),
      stroke,
    );
    canvas.drawLine(
        Offset(w * .28, h * .60), Offset(w * .72, h * .60), stroke);

    canvas.drawCircle(
        Offset(w * .82, h * .82), w * .07, f..color = const Color(0xFFFFD166));
    canvas.drawCircle(Offset(w * .18, h * .82), w * .055,
        f..color = const Color(0xFF74B9FF));
  }

  @override
  bool shouldRepaint(_AppIconPainter _) => false;
}
