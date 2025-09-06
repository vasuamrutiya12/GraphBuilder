import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui';

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
    // Draw all edges to ensure complete connectivity
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

    // Create curved path with enhanced curve calculation
    final path = _createEnhancedBezierPath(edge.startPoint, edge.endPoint, edge.curveIntensity);
    
    // Calculate path metrics for gradient
    final pathMetric = path.computeMetrics().first;
    
    // Create professional gradient shader along the curve
    final gradient = LinearGradient(
      colors: [
        edge.parentColor.withOpacity(isHighlighted ? 1.0 : 0.9),
        Color.lerp(edge.parentColor, edge.childColor, 0.3)?.withOpacity(isHighlighted ? 0.95 : 0.8) ?? edge.parentColor,
        Color.lerp(edge.parentColor, edge.childColor, 0.7)?.withOpacity(isHighlighted ? 0.9 : 0.7) ?? edge.childColor,
        edge.childColor.withOpacity(isHighlighted ? 1.0 : 0.8),
      ],
      stops: const [0.0, 0.3, 0.7, 1.0],
    );

    // Draw professional edge with enhanced styling
    _drawProfessionalEdge(canvas, path, pathMetric, gradient, edge, isHighlighted);
    
    // Draw animated glow effect
    _drawAnimatedGlowEffect(canvas, path, edge, isHighlighted);
    
    // Draw enhanced arrowhead
    _drawEnhancedArrowhead(canvas, pathMetric, edge, isHighlighted);
  }

  /// Smart Bézier path creation with intelligent routing to prevent crossings
  Path _createEnhancedBezierPath(Offset start, Offset end, double curveIntensity) {
    final path = Path();
    path.moveTo(start.dx, start.dy);
    
    // Calculate distances and angles for better curve control
    final verticalDistance = (end.dy - start.dy).abs();
    final horizontalDistance = (end.dx - start.dx).abs();
    final totalDistance = math.sqrt(verticalDistance * verticalDistance + horizontalDistance * horizontalDistance);
    
    // Smart routing: determine curve direction to avoid crossings
    final isLeftToRight = end.dx > start.dx;
    final curveDirection = isLeftToRight ? 1.0 : -1.0;
    
    // Enhanced curve intensity calculation with smart routing
    final baseCurveIntensity = curveIntensity * 0.8;
    final distanceFactor = math.min(totalDistance / 300.0, 1.5);
    final adjustedCurveIntensity = baseCurveIntensity * distanceFactor * curveDirection;
    
    // Calculate control points for smooth, professional curves with smart routing
    final midX = (start.dx + end.dx) / 2;
    final controlY = start.dy + verticalDistance * 0.5 + adjustedCurveIntensity;
    
    // Smart control points that curve away from potential crossings
    final controlPoint1 = Offset(
      start.dx + (midX - start.dx) * 0.5 + adjustedCurveIntensity * 0.2,
      start.dy + adjustedCurveIntensity * 0.3,
    );
    final controlPoint2 = Offset(
      midX + (end.dx - midX) * 0.5 + adjustedCurveIntensity * 0.1,
      controlY - adjustedCurveIntensity * 0.2,
    );
    
    path.cubicTo(
      controlPoint1.dx, controlPoint1.dy,
      controlPoint2.dx, controlPoint2.dy,
      end.dx, end.dy,
    );
    
    return path;
  }


  /// Professional edge drawing with enhanced styling and animations
  void _drawProfessionalEdge(
    Canvas canvas, 
    Path path, 
    PathMetric pathMetric, 
    LinearGradient gradient, 
    EdgeData edge,
    bool isHighlighted
  ) {
    final pathLength = pathMetric.length;
    final segments = (pathLength / 3).ceil(); // More segments for smoother appearance
    
    // Draw main edge with variable width and gradient
    for (int i = 0; i < segments; i++) {
      final t1 = i / segments;
      final t2 = (i + 1) / segments;
      
      final distance1 = t1 * pathLength;
      final distance2 = t2 * pathLength;
      
      final point1 = pathMetric.getTangentForOffset(distance1)?.position;
      final point2 = pathMetric.getTangentForOffset(distance2)?.position;
      
      if (point1 != null && point2 != null) {
        // Enhanced variable width calculation
        final width1 = _calculateEnhancedWidth(t1, edge.maxWidth, edge.minWidth, isHighlighted);
        final width2 = _calculateEnhancedWidth(t2, edge.maxWidth, edge.minWidth, isHighlighted);
        
        // Professional color interpolation with animation
        final animatedT = (t1 + animationValue * 0.1) % 1.0;
        final color = Color.lerp(edge.parentColor, edge.childColor, animatedT) ?? edge.parentColor;
        
        // Create gradient shader for this segment
        final segmentGradient = LinearGradient(
          colors: [
            color.withOpacity(isHighlighted ? 0.95 : 0.8),
            color.withOpacity(isHighlighted ? 0.85 : 0.6),
          ],
          stops: const [0.0, 1.0],
        );
        
        final segmentPaint = Paint()
          ..shader = segmentGradient.createShader(Rect.fromPoints(point1, point2))
          ..style = PaintingStyle.stroke
          ..strokeWidth = (width1 + width2) / 2
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
        
        canvas.drawLine(point1, point2, segmentPaint);
      }
    }
  }


  /// Enhanced width calculation with animation and professional styling
  double _calculateEnhancedWidth(double t, double maxWidth, double minWidth, bool isHighlighted) {
    // Add subtle animation to width
    final animatedT = (t + animationValue * 0.05) % 1.0;
    final baseWidth = maxWidth - (maxWidth - minWidth) * animatedT;
    
    // Add pulsing effect for highlighted edges
    final pulseFactor = isHighlighted ? 1.0 + math.sin(animationValue * 4) * 0.1 : 1.0;
    
    return baseWidth * pulseFactor * (isHighlighted ? 1.4 : 1.0);
  }


  /// Animated glow effect with professional styling
  void _drawAnimatedGlowEffect(Canvas canvas, Path path, EdgeData edge, bool isHighlighted) {
    if (!isHighlighted) return;
    
    // Create animated glow with pulsing effect
    final pulseIntensity = 0.3 + math.sin(animationValue * 6) * 0.2;
    final glowColor = edge.parentColor.withOpacity(pulseIntensity);
    
    // Multiple glow layers for professional effect
    final glowLayers = [
      {'width': edge.maxWidth * 3.0, 'opacity': 0.4, 'blur': 12.0},
      {'width': edge.maxWidth * 2.0, 'opacity': 0.6, 'blur': 8.0},
      {'width': edge.maxWidth * 1.5, 'opacity': 0.8, 'blur': 4.0},
    ];
    
    for (final layer in glowLayers) {
      final glowPaint = Paint()
        ..color = glowColor.withOpacity(layer['opacity'] as double)
        ..style = PaintingStyle.stroke
        ..strokeWidth = layer['width'] as double
        ..strokeCap = StrokeCap.round
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, layer['blur'] as double);
      
      canvas.drawPath(path, glowPaint);
    }
  }


  /// Enhanced arrowhead with professional styling and animations
  void _drawEnhancedArrowhead(Canvas canvas, PathMetric pathMetric, EdgeData edge, bool isHighlighted) {
    final pathLength = pathMetric.length;
    final arrowPosition = pathLength * 0.88; // Position arrow closer to the end
    
    final tangent = pathMetric.getTangentForOffset(arrowPosition);
    if (tangent == null) return;
    
    final position = tangent.position;
    final angle = tangent.angle;
    
    // Create enhanced arrowhead path
    final arrowPath = Path();
    final baseArrowSize = isHighlighted ? 14.0 : 12.0;
    
    // Add animation to arrowhead size
    final animatedSize = baseArrowSize * (1.0 + math.sin(animationValue * 8) * 0.1);
    
    // Arrow points with better proportions
    final tip = Offset(position.dx, position.dy);
    final left = Offset(
      position.dx - animatedSize * math.cos(angle - 0.4),
      position.dy - animatedSize * math.sin(angle - 0.4),
    );
    final right = Offset(
      position.dx - animatedSize * math.cos(angle + 0.4),
      position.dy - animatedSize * math.sin(angle + 0.4),
    );
    
    arrowPath.moveTo(tip.dx, tip.dy);
    arrowPath.lineTo(left.dx, left.dy);
    arrowPath.lineTo(right.dx, right.dy);
    arrowPath.close();
    
    // Create gradient for arrowhead
    final arrowGradient = RadialGradient(
      colors: [
        edge.childColor.withOpacity(isHighlighted ? 1.0 : 0.9),
        edge.childColor.withOpacity(isHighlighted ? 0.8 : 0.6),
      ],
      stops: const [0.0, 1.0],
    );
    
    // Draw arrowhead with gradient
    final arrowPaint = Paint()
      ..shader = arrowGradient.createShader(Rect.fromCircle(center: tip, radius: animatedSize))
      ..style = PaintingStyle.fill;
    
    canvas.drawPath(arrowPath, arrowPaint);
    
    // Add professional glow to arrowhead
    if (isHighlighted) {
      final glowPaint = Paint()
        ..color = edge.childColor.withOpacity(0.5 + math.sin(animationValue * 6) * 0.2)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      
      canvas.drawPath(arrowPath, glowPaint);
    }
    
    // Add outline for better definition
    final outlinePaint = Paint()
      ..color = edge.childColor.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    canvas.drawPath(arrowPath, outlinePaint);
  }


  /// Enhanced particle animation with professional effects
  void _drawFlowingParticles(Canvas canvas, EdgeData edge) {
    final path = _createEnhancedBezierPath(edge.startPoint, edge.endPoint, edge.curveIntensity);
    final pathMetric = path.computeMetrics().first;
    final pathLength = pathMetric.length;
    
    final isHighlighted = edge.parentId == hoveredNodeId || 
                         edge.childId == hoveredNodeId ||
                         edge.parentId == activeNodeId ||
                         edge.childId == activeNodeId;
    
    // Enhanced particle count for highlighted edges
    final particleCount = isHighlighted ? edge.particleCount * 2 : edge.particleCount;
    
    // Draw multiple particles along the path
    for (int i = 0; i < particleCount; i++) {
      final baseOffset = i / particleCount;
      final animatedOffset = (baseOffset + animationValue * edge.particleSpeed) % 1.0;
      final distance = animatedOffset * pathLength;
      
      final position = pathMetric.getTangentForOffset(distance)?.position;
      if (position == null) continue;
      
      // Enhanced particle properties with animation
      final baseSize = isHighlighted ? 3.0 : 2.0;
      final particleSize = baseSize + math.sin(animationValue * 6 + i * 0.5) * 1.5;
      final opacity = math.sin(animatedOffset * math.pi) * (isHighlighted ? 1.0 : 0.8);
      
      // Enhanced color based on position along path
      final particleColor = Color.lerp(
        edge.parentColor, 
        edge.childColor, 
        animatedOffset
      ) ?? edge.parentColor;
      
      // Create gradient for particles
      final particleGradient = RadialGradient(
        colors: [
          particleColor.withOpacity(opacity),
          particleColor.withOpacity(opacity * 0.3),
        ],
        stops: const [0.0, 1.0],
      );
      
      final particlePaint = Paint()
        ..shader = particleGradient.createShader(Rect.fromCircle(center: position, radius: particleSize))
        ..style = PaintingStyle.fill;
      
      // Draw enhanced particle with multiple glow layers
      final glowLayers = [
        {'radius': particleSize * 3, 'opacity': opacity * 0.2, 'blur': 8.0},
        {'radius': particleSize * 2, 'opacity': opacity * 0.4, 'blur': 4.0},
      ];
      
      for (final layer in glowLayers) {
        final glowPaint = Paint()
          ..color = particleColor.withOpacity(layer['opacity'] as double)
          ..style = PaintingStyle.fill
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, layer['blur'] as double);
        
        canvas.drawCircle(position, layer['radius'] as double, glowPaint);
      }
      
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
    this.curveIntensity = 60.0,
    this.maxWidth = 6.0,
    this.minWidth = 3.0,
    this.particleCount = 5,
    this.particleSpeed = 0.6,
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