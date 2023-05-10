import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:ui' as ui;

import '../motion_handler.dart';

class IndoorMap extends StatefulWidget {
  final List<Gondola> gondolas;
  final String imagePath;
  final List<Wall> walls;
  final List<WalkablePath> walkablePaths;

  const IndoorMap({
    Key? key,
    required this.gondolas,
    required this.imagePath,
    required this.walls,
    required this.walkablePaths,
  }) : super(key: key);

  Rect getBoundingBox() {
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    for (Wall wall in walls) {
      for (Offset point in wall.points) {
        minX = min(minX, point.dx);
        minY = min(minY, point.dy);
        maxX = max(maxX, point.dx);
        maxY = max(maxY, point.dy);
      }
    }

    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }


  @override
  _IndoorMapState createState() => _IndoorMapState();
}

class _IndoorMapState extends State<IndoorMap> {
  late ui.Image _image;
  late MotionHandler _motionHandler;
  bool _isImageLoaded = false;
  double _scale = 1.0;
  StreamSubscription<UserAccelerometerEvent>? _accelerometerSubscription;
  late Offset _currentPosition = Offset.zero;

  @override
  void initState() {
    super.initState();
    _loadImage();
    Offset startPoint = const Offset(145, 620);
    _accelerometerSubscription = userAccelerometerEvents.listen((event) {
      setState(() {
        _currentPosition = _currentPosition.translate(event.x, event.y);
      });
    });

    _motionHandler = MotionHandler(
      initialPosition: startPoint,
      onPositionChanged: (Offset newPosition) {
        setState(() {
          startPoint = newPosition;
        });
      },
    );

  }

  @override
  void dispose() {
    _motionHandler.dispose();
    _accelerometerSubscription?.cancel();
    super.dispose();
  }


  Future<void> _loadImage() async {
    final data = await rootBundle.load(widget.imagePath);
    final bytes = data.buffer.asUint8List();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    setState(() {
      _image = frame.image;
      _isImageLoaded = true;
    });
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      _scale = _scale * details.scale;
    });
  }

  void _handleTap(TapUpDetails details) {
    for (Gondola gondola in widget.gondolas) {
      if (gondola.hitTest(details.localPosition, _scale)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gondola: ${gondola.name}')),
        );
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isImageLoaded) {
      return Center(
        child: GestureDetector(
          onTapUp: _handleTap,
          onScaleUpdate: _handleScaleUpdate,
          child: CustomPaint(
            painter: _IndoorMapPainter(
              image: _image,
              gondolas: widget.gondolas,
              startPoint: _currentPosition,
              scale: _scale,
            ),
            size: Size.infinite,
          ),
        ),
      );
    } else {
      return const Center(child: CircularProgressIndicator());
    }
  }

}

class _IndoorMapPainter extends CustomPainter {
  final ui.Image image;
  final List<Gondola> gondolas;
  final double scale;
  final Offset startPoint;

  _IndoorMapPainter({
    required this.image,
    required this.gondolas,
    required this.scale,
    required this.startPoint,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawImage(image, Offset.zero, Paint());
    final painter = _IndoorMapPainter(image: image, gondolas: gondolas,
        scale: scale, startPoint: startPoint);
    painter.paint(canvas, size);
  }

  @override
  bool shouldRepaint(covariant _IndoorMapPainter oldDelegate) {
    return oldDelegate.scale != scale;
  }
}

class Node {
  final int x;
  final int y;
  bool walkable;

  Node({
    required this.x,
    required this.y,
    this.walkable = true,
  });

  @override
  String toString() {
    return 'Node(x: $x, y: $y, walkable: $walkable)';
  }
}

class Wall {
  final List<Offset> points;
  late Rect _boundingBox;

  Wall({required this.points}) {
    _calculateBoundingBox();
  }

  Rect get boundingBox => _boundingBox;

  void _calculateBoundingBox() {
    double minX = points[0].dx;
    double maxX = points[0].dx;
    double minY = points[0].dy;
    double maxY = points[0].dy;

    for (final point in points) {
      if (point.dx < minX) minX = point.dx;
      if (point.dx > maxX) maxX = point.dx;
      if (point.dy < minY) minY = point.dy;
      if (point.dy > maxY) maxY = point.dy;
    }

    _boundingBox = Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  bool contains(Offset point) {
    bool inside = false;
    for (int i = 0, j = points.length - 1; i < points.length; j = i++) {
      if (((points[i].dy > point.dy) != (points[j].dy > point.dy)) &&
          (point.dx < (points[j].dx - points[i].dx) *
              (point.dy - points[i].dy) / (points[j].dy - points[i].dy) + points[i].dx)) {
        inside = !inside;
      }
    }
    return inside;
  }
}

class Gondola {
  final String name;
  final Offset position;
  final double width;
  final double height;
  final Color color;

  Gondola({
    required this.name,
    required this.position,
    required this.color,
    this.width = 30,
    this.height = 30,
  });

  bool hitTest(Offset localPosition, double scale) {
    final scaledWidth = width * scale;
    final scaledHeight = height * scale;
    final scaledPosition = position * scale;

    return localPosition.dx >= scaledPosition.dx &&
        localPosition.dx <= scaledPosition.dx + scaledWidth &&
        localPosition.dy >= scaledPosition.dy &&
        localPosition.dy <= scaledPosition.dy + scaledHeight;
  }

  void draw(Canvas canvas, double scale) {
    // You can customize the appearance of the gondola markers here
    // For example, you can use the image property to draw an image on the canvas
    final paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    final circleSize = 20.0 * scale;
    final circleRect = Rect.fromCircle(center: position, radius: circleSize);
    canvas.drawOval(circleRect, paint);

    final textPainter = TextPainter(
      text: TextSpan(
        text: name,
        style: TextStyle(color: Colors.black, fontSize: 14.0 * scale),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      position + Offset(-textPainter.width / 2, -circleSize - textPainter.height),
    );
  }

}


class WalkablePath {
  final List<Offset> points;
  WalkablePath({required this.points});
}
