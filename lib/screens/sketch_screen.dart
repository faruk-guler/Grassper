import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import '../providers/note_provider.dart';
import '../core/constants.dart';
import '../core/strings.dart';
import '../models/note_model.dart';
import 'note_editor.dart';
import 'package:uuid/uuid.dart';

class SketchScreen extends StatefulWidget {
  final Note? note;
  const SketchScreen({super.key, this.note});

  @override
  State<SketchScreen> createState() => _SketchScreenState();
}

class _SketchScreenState extends State<SketchScreen> {
  final GlobalKey _repaintKey = GlobalKey();
  List<DrawingPoint?> _points = [];
  Color _selectedColor = Colors.black;
  double _strokeWidth = 5.0;

  @override
  void initState() {
    super.initState();
    if (widget.note?.drawingData != null) {
      _loadDrawingData();
    }
  }

  void _loadDrawingData() {
    try {
      final List<dynamic> decoded = jsonDecode(widget.note!.drawingData!);
      setState(() {
        _points = decoded.map((p) {
          if (p == null) return null;
          return DrawingPoint(
            offset: Offset(p['dx'], p['dy']),
            paint: Paint()
              ..color = Color(p['color'])
              ..strokeCap = StrokeCap.round
              ..strokeWidth = p['width'],
          );
        }).toList();
      });
    } catch (e) {
      debugPrint('Error loading drawing data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (isDark && _selectedColor == Colors.black) {
      _selectedColor = Colors.white;
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _saveAndExit();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _saveAndExit(),
          ),
          title: Text(AppStrings.isTr ? 'Çizim Yap' : 'Sketch'),
          actions: [
            IconButton(
              icon: const Icon(Icons.undo),
              onPressed: () {
                setState(() {
                  if (_points.isNotEmpty) {
                    int lastNullIndex = _points.lastIndexOf(null);
                    if (lastNullIndex == _points.length - 1) {
                      _points.removeLast();
                      lastNullIndex = _points.lastIndexOf(null);
                    }
                    _points.removeRange(lastNullIndex + 1, _points.length);
                  }
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => setState(() => _points.clear()),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: RepaintBoundary(
                key: _repaintKey,
                child: Container(
                  color: isDark ? Colors.grey[900] : Colors.white,
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      setState(() {
                        _points.add(DrawingPoint(
                          offset: details.localPosition,
                          paint: Paint()
                            ..color = _selectedColor
                            ..strokeCap = StrokeCap.round
                            ..strokeWidth = _strokeWidth,
                        ));
                      });
                    },
                    onPanEnd: (details) {
                      setState(() => _points.add(null));
                    },
                    child: CustomPaint(
                      painter: SketchPainter(points: _points),
                      size: Size.infinite,
                    ),
                  ),
                ),
              ),
            ),
            _buildToolBar(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildToolBar(bool isDark) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      color: isDark ? Colors.black26 : Colors.grey[200],
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.brush, size: 20),
              Expanded(
                child: Slider(
                  value: _strokeWidth,
                  min: 1.0,
                  max: 50.0,
                  onChanged: (val) => setState(() => _strokeWidth = val),
                  activeColor: _selectedColor,
                ),
              ),
              Text(_strokeWidth.toStringAsFixed(0)),
            ],
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildColorCircle(Colors.black),
                _buildColorCircle(Colors.white),
                _buildColorCircle(Colors.red),
                _buildColorCircle(Colors.green),
                _buildColorCircle(Colors.blue),
                _buildColorCircle(Colors.yellow),
                _buildColorCircle(Colors.orange),
                _buildColorCircle(Colors.purple),
                _buildColorCircle(Colors.brown),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    Icons.cleaning_services,
                    color: _selectedColor == (isDark ? Colors.grey[900] : Colors.white)
                        ? theme.primaryColor
                        : (isDark ? Colors.white54 : Colors.black54),
                    size: _selectedColor == (isDark ? Colors.grey[900] : Colors.white) ? 28 : 24,
                  ),
                  onPressed: () {
                    setState(() => _selectedColor = isDark ? Colors.grey[900]! : Colors.white);
                  },
                  tooltip: AppStrings.isTr ? 'Silgi' : 'Eraser',
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorCircle(Color color) {
    final theme = Theme.of(context);
    bool isSelected = _selectedColor == color;
    return GestureDetector(
      onTap: () => setState(() => _selectedColor = color),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? theme.primaryColor : Colors.grey.withOpacity(0.5),
            width: isSelected ? 3 : 1,
          ),
        ),
      ),
    );
  }

  Future<void> _saveAndExit({bool isAutoSave = false}) async {
    if (_points.isEmpty) {
      if (mounted) Navigator.pop(context);
      return;
    }

    try {
      RenderRepaintBoundary boundary =
          _repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage();
      var byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      var pngBytes = byteData!.buffer.asUint8List();
      String base64String = base64Encode(pngBytes);

      final drawingData = jsonEncode(_points.map((p) {
        if (p == null) return null;
        return {
          'dx': p.offset.dx,
          'dy': p.offset.dy,
          'color': p.paint.color.value,
          'width': p.paint.strokeWidth,
        };
      }).toList());

      final provider = Provider.of<NoteProvider>(context, listen: false);

      if (widget.note != null) {
        widget.note!.imageBase64 = base64String;
        widget.note!.drawingData = drawingData;
        widget.note!.updatedAt = DateTime.now().millisecondsSinceEpoch;
        await provider.saveNote(widget.note!);
      } else {
        final now = DateTime.now().millisecondsSinceEpoch;
        final newNote = Note(
          id: const Uuid().v4(),
          title: '',
          content: '',
          imageBase64: base64String,
          drawingData: drawingData,
          updatedAt: now,
          createdAt: now,
        );
        await provider.saveNote(newNote); // Kalıcı kaydı yap
      }

      if (mounted && !isAutoSave) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('Error saving sketch: $e');
      if (mounted && !isAutoSave) Navigator.pop(context);
    }
  }
}

class DrawingPoint {
  Offset offset;
  Paint paint;
  DrawingPoint({required this.offset, required this.paint});
}

class SketchPainter extends CustomPainter {
  final List<DrawingPoint?> points;
  SketchPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!.offset, points[i + 1]!.offset, points[i]!.paint);
      } else if (points[i] != null && points[i + 1] == null) {
        canvas.drawCircle(points[i]!.offset, points[i]!.paint.strokeWidth / 2, points[i]!.paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant SketchPainter oldDelegate) => true;
}
