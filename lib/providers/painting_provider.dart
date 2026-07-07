import 'package:flutter/material.dart';
import '../models/stroke.dart';

class PaintingProvider extends ChangeNotifier {
  final List<Stroke> _strokes = [];
  final List<Stroke> _redoStack = [];
  Stroke? _currentStroke;

  // Tamamla butonuyla aynı ton (AppTheme.textDark)
  Color _selectedColor = const Color(0xFF3D3D5C);
  double _brushSize = 18.0;
  BrushType _selectedBrush = BrushType.keceli;

  List<Stroke> get strokes => List.unmodifiable(_strokes);
  Stroke? get currentStroke => _currentStroke;
  Color get selectedColor => _selectedColor;
  double get brushSize => _brushSize;
  BrushType get selectedBrush => _selectedBrush;
  bool get isEraser => _selectedBrush == BrushType.silgi;
  bool get canUndo => _strokes.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  void startStroke(Offset point) {
    _currentStroke = Stroke(
      points: [point],
      color: isEraser ? Colors.white : _selectedColor,
      width: _brushSize,
      brush: _selectedBrush,
    );
    _redoStack.clear();
    notifyListeners();
  }

  void continueStroke(Offset point) {
    if (_currentStroke == null) return;
    _currentStroke = _currentStroke!.addPoint(point);
    notifyListeners();
  }

  void endStroke() {
    if (_currentStroke != null && _currentStroke!.points.isNotEmpty) {
      _strokes.add(_currentStroke!);
      _currentStroke = null;
      notifyListeners();
    }
  }

  void setColor(Color color) {
    _selectedColor = color;
    if (isEraser) _selectedBrush = BrushType.keceli;
    notifyListeners();
  }

  void setBrush(BrushType brush) {
    _selectedBrush = brush;
    notifyListeners();
  }

  void setBrushSize(double size) {
    _brushSize = size;
    notifyListeners();
  }

  void undo() {
    if (_strokes.isNotEmpty) {
      _redoStack.add(_strokes.removeLast());
      notifyListeners();
    }
  }

  void redo() {
    if (_redoStack.isNotEmpty) {
      _strokes.add(_redoStack.removeLast());
      notifyListeners();
    }
  }

  void reset() {
    _strokes.clear();
    _redoStack.clear();
    _currentStroke = null;
    notifyListeners();
  }
}
