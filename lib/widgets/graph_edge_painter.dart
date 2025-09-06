import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/node.dart';

class GraphEdgePainter extends CustomPainter {
  final List<EdgeData> edges;
  final double animationValue;
  final String? hoveredNodeId;
  final String? activeNodeId;
  final bool showParticles;

  GraphEdgePainter({
    required this.edges,
    required this.animationValue,
    this.hoveredNodeId,
    this.activeNodeId,
    this.showParticles = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final edge in edges) {
      _drawCurvedEdge(canvas, edge);
      if (showParticles) {
        _drawFlowingParticles(canvas, edge);
      }
    }
  }

  void _drawCurvedEdge(Canvas canvas, EdgeData edge) {
    final isHighlighted = edge.parentId == hoveredNodeId || 
                         edge.childId == hoveredNodeId ||
                         edge.parentId == activeNodeId ||
                         edge.childId == activeNodeId;

    // Create curved path
    final path = _createBezierPath(edge.startPoint, edge.endPoint, edge.curveIntensity);
    
    // Calculate path metrics for gradient
    final pathMetric = path.computeMetrics().first;
    final pathLength = pathMetric.length;
    
    // Create gradient shader along the curve
    final gradient = LinearGradient(
      colors: [
        edge.parentColor.withOpacity(isHighlighted ? 1.0 : 0.8),
        edge.childColor.withOpacity(isHighlighted ? 1.0 : 0.6),
      ],
      stops: const [0.0, 1.0],
    );

    // Main edge paint with variable width
    final edgePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Draw the edge with gradient and variable width
    _drawVariableWidthPath(canvas, path, pathMetric, gradient, edge, isHighlighted);
    
    // Draw glowing effect if highlighted
    if (isHighlighted) {
      _drawGlowEffect(canvas, path, edge);
    }
    
    // Draw arrowhead
    _drawArrowhead(canvas, pathMetric, edge, isHighlighted);
  }

  Path _createBezierPath(Offset start, Offset end, double curveIntensity) {
    final path = Path();
    path.moveTo(start.dx, start.dy);
    
    // Calculate control points for smooth curve
    final midX = (start.dx + end.dx) / 2;
    final controlY = start.dy + (end.dy - start.dy) * 0.3 + curveIntensity;
    
    // Use quadratic Bézier for smooth, natural curves
    path.quadraticBezierTo(midX, controlY, end.dx, end.dy);
    
    return path;
  }

  void _drawVariableWidthPath(
    Canvas canvas, 
    Path path, 
    PathMetric pathMetric, 
    LinearGradient gradient, 
    EdgeData edge,
    bool isHighlighted
  ) {
    final pathLength = pathMetric.length;
    final segments = (pathLength / 5).ceil(); // Smooth segments
    
    for (int i = 0; i < segments; i++) {
      final t1 = i / segments;
      final t2 = (i + 1) / segments;
      
      final distance1 = t1 * pathLength;
      final distance2 = t2 * pathLength;
      
      final point1 = pathMetric.getTangentForOffset(distance1)?.position;
      final point2 = pathMetric.getTangentForOffset(distance2)?.position;
      
      if (point1 != null && point2 != null) {
        // Variable width: thicker at parent, thinner at child
        final width1 = _calculateWidth(t1, edge.maxWidth, edge.minWidth, isHighlighted);
        final width2 = _calculateWidth(t2, edge.maxWidth, edge.minWidth, isHighlighted);
        
        // Color interpolation
        final color = Color.lerp(edge.parentColor, edge.childColor, t1) ?? edge.parentColor;
        
        final segmentPaint = Paint()
          ..color = color.withOpacity(isHighlighted ? 0.9 : 0.7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = (width1 + width2) / 2
          ..strokeCap = StrokeCap.round;
        
        canvas.drawLine(point1, point2, segmentPaint);
      }
    }
  }

  double _calculateWidth(double t, double maxWidth, double minWidth, bool isHighlighted) {
    final baseWidth = maxWidth - (maxWidth - minWidth) * t;
    return isHighlighted ? baseWidth * 1.3 : baseWidth;
  }

  void _drawGlowEffect(Canvas canvas, Path path, EdgeData edge) {
    final glowPaint = Paint()
      ..color = edge.parentColor.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = edge.maxWidth * 2.5
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    
    canvas.drawPath(path, glowPaint);
  }

  void _drawArrowhead(Canvas canvas, PathMetric pathMetric, EdgeData edge, bool isHighlighted) {
    final pathLength = pathMetric.length;
    final arrowPosition = pathLength * 0.85; // Position arrow before the end
    
    final tangent = pathMetric.getTangentForOffset(arrowPosition);
    if (tangent == null) return;
    
    final position = tangent.position;
    final angle = tangent.angle;
    
    // Create arrowhead path
    final arrowPath = Path();
    final arrowSize = isHighlighted ? 12.0 : 10.0;
    
    // Arrow points
    final tip = Offset(position.dx, position.dy);
    final left = Offset(
      position.dx - arrowSize * math.cos(angle - 0.5),
      position.dy - arrowSize * math.sin(angle - 0.5),
    );
    final right = Offset(
      position.dx - arrowSize * math.cos(angle + 0.5),
      position.dy - arrowSize * math.sin(angle + 0.5),
    );
    
    arrowPath.moveTo(tip.dx, tip.dy);
    arrowPath.lineTo(left.dx, left.dy);
    arrowPath.lineTo(right.dx, right.dy);
    arrowPath.close();
    
    // Draw arrowhead with gradient
    final arrowPaint = Paint()
      ..color = edge.childColor.withOpacity(isHighlighted ? 1.0 : 0.8)
      ..style = PaintingStyle.fill;
    
    canvas.drawPath(arrowPath, arrowPaint);
    
    // Add glow to arrowhead if highlighted
    if (isHighlighted) {
      final glowPaint = Paint()
        ..color = edge.childColor.withOpacity(0.4)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      
      canvas.drawPath(arrowPath, glowPaint);
    }
  }

  void _drawFlowingParticles(Canvas canvas, EdgeData edge) {
    final path = _createBezierPath(edge.startPoint, edge.endPoint, edge.curveIntensity);
    final pathMetric = path.computeMetrics().first;
    final pathLength = pathMetric.length;
    
    // Draw multiple particles along the path
    for (int i = 0; i < edge.particleCount; i++) {
      final baseOffset = i / edge.particleCount;
      final animatedOffset = (baseOffset + animationValue * edge.particleSpeed) % 1.0;
      final distance = animatedOffset * pathLength;
      
      final position = pathMetric.getTangentForOffset(distance)?.position;
      if (position == null) continue;
      
      // Particle properties
      final particleSize = 2.0 + math.sin(animationValue * 4 + i) * 1.0;
      final opacity = math.sin(animatedOffset * math.pi) * 0.8;
      
      // Color based on position along path
      final particleColor = Color.lerp(
        edge.parentColor, 
        edge.childColor, 
        animatedOffset
      ) ?? edge.parentColor;
      
      final particlePaint = Paint()
        ..color = particleColor.withOpacity(opacity)
        ..style = PaintingStyle.fill;
      
      // Draw particle with glow
      final glowPaint = Paint()
        ..color = particleColor.withOpacity(opacity * 0.3)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      
      canvas.drawCircle(position, particleSize * 2, glowPaint);
      canvas.drawCircle(position, particleSize, particlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is! GraphEdgePainter ||
           oldDelegate.animationValue != animationValue ||
           oldDelegate.hoveredNodeId != hoveredNodeId ||
           oldDelegate.activeNodeId != activeNodeId ||
           oldDelegate.edges.length != edges.length;
  }
}

class EdgeData {
  final String parentId;
  final String childId;
  final Offset startPoint;
  final Offset endPoint;
  final Color parentColor;
  final Color childColor;
  final double curveIntensity;
  final double maxWidth;
  final double minWidth;
  final int particleCount;
  final double particleSpeed;

  EdgeData({
    required this.parentId,
    required this.childId,
    required this.startPoint,
    required this.endPoint,
    required this.parentColor,
    required this.childColor,
    this.curveIntensity = 50.0,
    this.maxWidth = 4.0,
    this.minWidth = 2.0,
    this.particleCount = 3,
    this.particleSpeed = 0.5,
  });
}

class CurvedEdgeWidget extends StatefulWidget {
  final List<EdgeData> edges;
  final String? hoveredNodeId;
  final String? activeNodeId;
  final bool showParticles;

  const CurvedEdgeWidget({
    super.key,
    required this.edges,
    this.hoveredNodeId,
    this.activeNodeId,
    this.showParticles = true,
  });

  @override
  State<CurvedEdgeWidget> createState() => _CurvedEdgeWidgetState();
}

class _CurvedEdgeWidgetState extends State<CurvedEdgeWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.linear),
    );
    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          painter: GraphEdgePainter(
            edges: widget.edges,
            animationValue: _animation.value,
            hoveredNodeId: widget.hoveredNodeId,
            activeNodeId: widget.activeNodeId,
            showParticles: widget.showParticles,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}