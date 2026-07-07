import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// svgData alanına göre doğru görüntüleyiciyi seçer:
/// .png asset → Image, asset yolu → SvgPicture.asset, aksi halde inline SVG.
class DrawingImage extends StatelessWidget {
  final String source;
  final BoxFit fit;

  const DrawingImage({super.key, required this.source, this.fit = BoxFit.contain});

  @override
  Widget build(BuildContext context) {
    if (source.endsWith('.png')) {
      return Image.asset(source, fit: fit);
    }
    if (source.startsWith('assets/')) {
      return SvgPicture.asset(source, fit: fit);
    }
    return SvgPicture.string(source, fit: fit);
  }
}
