import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/node.dart';
import '../providers/graph_provider.dart';
import 'graph_edge_painter.dart';
import 'dart:math' as math;

class TreeVisualizer extends StatefulWidget {
  const TreeVisualizer({super.key});

  @override
  State<TreeVisualizer> createState() => _TreeVisualizerState();
}

class _TreeVisualizerState extends State<TreeVisualizer> 
    with TickerProviderStateMixin {
  late AnimationController _backgroundAnimationController;
  late AnimationController _pulseAnimationController;
  late Animation<double> _backgroundAnimation;
  late Animation<double> _pulseAnimation;
  
  final TransformationController _transformationController = TransformationController();
  String? _hoveredNodeId;
  final Map<String, AnimationController> _nodeAnimations = {};
  final Map<String, Animation<double>> _scaleAnimations = {};

  @override
  void initState() {
    super.initState();
    
    // Background gradient animation
    _backgroundAnimationController = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    );
    _backgroundAnimation = Tween<double>(begin: 0, end: 1)
        .animate(_backgroundAnimationController);
    _backgroundAnimationController.repeat();
    
    // Active node pulse animation
    _pulseAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1)
        .animate(CurvedAnimation(
          parent: _pulseAnimationController,
          curve: Curves.easeInOut,
        ));
    _pulseAnimationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _backgroundAnimationController.dispose();
    _pulseAnimationController.dispose();
    _transformationController.dispose();
    for (var controller in _nodeAnimations.values) {
      controller.dispose();
    }
    super.dispose();
  }

  AnimationController _getNodeAnimationController(String nodeId) {
    if (!_nodeAnimations.containsKey(nodeId)) {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      );
      _nodeAnimations[nodeId] = controller;
      _scaleAnimations[nodeId] = Tween<double>(begin: 0.0, end: 1.0)
          .animate(CurvedAnimation(
            parent: controller,
            curve: Curves.elasticOut,
          ));
      controller.forward();
    }
    return _nodeAnimations[nodeId]!;
  }

  Color _getNodeColorByDepth(int depth, bool isActive, bool isRoot) {
    if (isRoot) {
      return isActive ? const Color(0xFFFFD700) : const Color(0xFFFFE55C); // Gold
    }
    
    final colors = [
      const Color(0xFFFF6B35), // Orange - Depth 1
      const Color(0xFFFF1744), // Pink - Depth 2  
      const Color(0xFF9C27B0), // Purple - Depth 3
      const Color(0xFF3F51B5), // Indigo - Depth 4
      const Color(0xFF1A237E), // Deep Blue - Depth 5+
    ];
    
    final colorIndex = math.min(depth - 1, colors.length - 1);
    final baseColor = depth > 0 ? colors[colorIndex] : const Color(0xFF9C27B0);
    
    if (isActive) {
      return const Color(0xFF00E5FF); // Glowing cyan for active
    }
    
    return baseColor;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GraphProvider>(
      builder: (context, graphProvider, child) {
        if (graphProvider.root == null) {
          return _buildEmptyState();
        }

        return Container(
          width: double.infinity,
          height: double.infinity,
          child: Stack(
            children: [
              // Animated gradient background
              _buildAnimatedBackground(),
              // Interactive graph view
              _buildInteractiveGraph(graphProvider),
              // Mini-map overlay
              _buildMiniMap(graphProvider),
              // Node info tooltip
              if (_hoveredNodeId != null)
                _buildNodeTooltip(graphProvider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1a1a2e),
            Color(0xFF16213e),
            Color(0xFF0f3460),
          ],
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_tree, size: 64, color: Colors.white24),
            SizedBox(height: 16),
            Text(
              'No graph to display',
              style: TextStyle(fontSize: 18, color: Colors.white54),
            ),
          ],
        ),
            ),
          );
        }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _backgroundAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(
                math.sin(_backgroundAnimation.value * 2 * math.pi) * 0.3,
                math.cos(_backgroundAnimation.value * 2 * math.pi) * 0.3,
              ),
              radius: 1.5,
              colors: [
                const Color(0xFF1a1a2e),
                const Color(0xFF16213e),
                const Color(0xFF0f3460),
                const Color(0xFF533483),
                const Color(0xFF1a1a2e),
              ],
              stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
            ),
          ),
          child: CustomPaint(
            painter: ParticleEffectPainter(_backgroundAnimation.value),
            size: Size.infinite,
          ),
        );
      },
    );
  }

  Widget _buildInteractiveGraph(GraphProvider graphProvider) {
        return InteractiveViewer(
          transformationController: _transformationController,
      minScale: 0.5,
          maxScale: 3.0,
      child: SingleChildScrollView(
          child: Container(
          width: MediaQuery.of(context).size.width,
          padding: const EdgeInsets.all(60.0),
          child: Stack(
            children: [
              // Draw edges first (behind nodes)
              _buildEdgeLayer(graphProvider),
              // Draw nodes on top
              Column(
                children: [
                  _buildEnhancedNodeTree(graphProvider.root!, graphProvider, 0),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEdgeLayer(GraphProvider graphProvider) {
    final edges = _calculateEdgeData(graphProvider);
    
    return Positioned.fill(
      child: CurvedEdgeWidget(
        edges: edges,
        hoveredNodeId: _hoveredNodeId,
        activeNodeId: graphProvider.activeNode?.id,
        showParticles: true,
      ),
    );
  }

  List<EdgeData> _calculateEdgeData(GraphProvider graphProvider) {
    final edges = <EdgeData>[];
    final nodePositions = <String, Offset>{};
    
    // Calculate node positions (this is a simplified version)
    _calculateNodePositions(graphProvider.root!, nodePositions, 
                           Offset(MediaQuery.of(context).size.width / 2, 100), 0);
    
    // Generate edge data
    _generateEdgesForNode(graphProvider.root!, edges, nodePositions, graphProvider);
    
    return edges;
  }

  void _calculateNodePositions(Node node, Map<String, Offset> positions, Offset position, int level) {
    positions[node.id] = position;
    
    if (node.children.isNotEmpty) {
      final childrenWidth = (node.children.length - 1) * 180.0;
      final startX = position.dx - childrenWidth / 2;
      final childY = position.dy + 200.0;
      
      for (int i = 0; i < node.children.length; i++) {
        final childX = startX + i * 180.0;
        final childPosition = Offset(childX, childY);
        _calculateNodePositions(node.children[i], positions, childPosition, level + 1);
      }
    }
  }

  void _generateEdgesForNode(Node node, List<EdgeData> edges, 
                           Map<String, Offset> positions, GraphProvider graphProvider) {
    final parentPosition = positions[node.id];
    if (parentPosition == null) return;
    
    for (final child in node.children) {
      final childPosition = positions[child.id];
      if (childPosition == null) continue;
      
      // Calculate curve intensity based on horizontal distance
      final horizontalDistance = (childPosition.dx - parentPosition.dx).abs();
      final curveIntensity = math.min(horizontalDistance * 0.3, 80.0);
      
      edges.add(EdgeData(
        parentId: node.id,
        childId: child.id,
        startPoint: Offset(parentPosition.dx, parentPosition.dy + 60), // Offset from node center
        endPoint: Offset(childPosition.dx, childPosition.dy - 60),
        parentColor: _getNodeColorByDepth(node.depth, false, node.parent == null),
        childColor: _getNodeColorByDepth(child.depth, false, false),
        curveIntensity: curveIntensity,
        maxWidth: 5.0,
        minWidth: 2.0,
        particleCount: 4,
        particleSpeed: 0.3,
      ));
      
      // Recursively generate edges for children
      _generateEdgesForNode(child, edges, positions, graphProvider);
    }
  }
  Widget _buildEnhancedNodeTree(Node node, GraphProvider graphProvider, int level) {
    return Column(
      children: [
        _buildEnhancedNode(node, graphProvider),
        if (node.children.isNotEmpty) ...[
          const SizedBox(height: 200), // Increased spacing for curved edges
          _buildChildrenRow(node, graphProvider, level + 1),
        ],
      ],
    );
  }

  Widget _buildEnhancedNode(Node node, GraphProvider graphProvider) {
    final isActive = node.id == graphProvider.activeNode?.id;
    final isRoot = node.parent == null;
    final isHovered = _hoveredNodeId == node.id;
    final nodeColor = _getNodeColorByDepth(node.depth, isActive, isRoot);
    
    _getNodeAnimationController(node.id);
    
    return AnimatedBuilder(
      animation: Listenable.merge([
        _scaleAnimations[node.id]!,
        if (isActive) _pulseAnimation,
      ]),
      builder: (context, child) {
        final scale = _scaleAnimations[node.id]!.value;
        final pulseScale = isActive ? _pulseAnimation.value : 1.0;
        final hoverScale = isHovered ? 1.1 : 1.0;
        final finalScale = scale * pulseScale * hoverScale;
        
        return Transform.scale(
          scale: finalScale,
          child: MouseRegion(
            onEnter: (_) => setState(() => _hoveredNodeId = node.id),
            onExit: (_) => setState(() => _hoveredNodeId = null),
            child: GestureDetector(
              onTap: () => graphProvider.selectNode(node.id),
              child: Container(
                width: isActive ? 140 : 120,
                height: isActive ? 140 : 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      nodeColor.withOpacity(0.9),
                      nodeColor,
                      nodeColor.withOpacity(0.7),
                    ],
                    stops: const [0.0, 0.7, 1.0],
                  ),
                  border: Border.all(
                    color: isActive 
                        ? Colors.white.withOpacity(0.8)
                        : nodeColor.withOpacity(0.3),
                    width: isActive ? 4.0 : 2.0,
                  ),
                  boxShadow: [
                    // Outer glow
                    BoxShadow(
                      color: nodeColor.withOpacity(isActive ? 0.6 : 0.3),
                      blurRadius: isActive ? 30.0 : 20.0,
                      spreadRadius: isActive ? 8.0 : 4.0,
                    ),
                    // Inner shadow for 3D effect
                    BoxShadow(
                      color: Colors.white.withOpacity(0.1),
                      blurRadius: 10.0,
                      spreadRadius: -5.0,
                      offset: const Offset(-5, -5),
                    ),
                    // Bottom shadow
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 15.0,
                      spreadRadius: 2.0,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Main content
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            node.label,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isActive ? 32 : 28,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.5),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                          if (node.depth > 0) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10, 
                                vertical: 4
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                'D${node.depth}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Children count badge
                    if (node.children.isNotEmpty)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: nodeColor,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              '${node.children.length}',
                              style: TextStyle(
                                color: nodeColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }


  Widget _buildChildrenRow(Node parent, GraphProvider graphProvider, int level) {
    return Wrap(
      spacing: 180, // Increased spacing for better curve visualization
      runSpacing: 200,
      alignment: WrapAlignment.center,
      children: parent.children.map((child) {
        return _buildEnhancedNodeTree(child, graphProvider, level);
      }).toList(),
    );
  }

  Widget _buildMiniMap(GraphProvider graphProvider) {
    return Positioned(
      top: 20,
      right: 20,
      child: Container(
        width: 200,
        height: 150,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              // Mini graph representation
              Center(
                child: Text(
                  'Mini Map\n${graphProvider.getAllNodes().length} nodes',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNodeTooltip(GraphProvider graphProvider) {
    final hoveredNode = graphProvider.getAllNodes()
        .firstWhere((node) => node.id == _hoveredNodeId);
    
    return Positioned(
      top: 100,
      left: 20,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _getNodeColorByDepth(
              hoveredNode.depth, 
              false, 
              hoveredNode.parent == null
            ).withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Node ${hoveredNode.label}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Depth: ${hoveredNode.depth}',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            Text(
              'Children: ${hoveredNode.children.length}',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            if (hoveredNode.parent != null)
              Text(
                'Parent: ${hoveredNode.parent!.label}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
          ],
        ),
      ),
    );
  }
}


class ParticleEffectPainter extends CustomPainter {
  final double animationValue;

  ParticleEffectPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Flowing particles along edges
    for (int i = 0; i < 30; i++) {
      final progress = (animationValue + i / 30.0) % 1.0;
      final x = size.width * progress;
      final y = size.height * 0.5 + 
          math.sin(progress * 4 * math.pi + i) * 50;
      
      final opacity = math.sin(progress * math.pi) * 0.3;
      paint.color = Colors.cyan.withOpacity(opacity);
      
      canvas.drawCircle(
        Offset(x, y),
        2.0 + math.sin(progress * 2 * math.pi) * 1.0,
        paint,
      );
    }

    // Ambient particles
    for (int i = 0; i < 50; i++) {
      final x = (size.width * (i / 50.0) + animationValue * 100) % size.width;
      final y = (size.height * (i / 50.0) + animationValue * 30) % size.height;
      final radius = 1.0 + (i % 3) * 0.5;
      final opacity = 0.1 + (i % 5) * 0.02;
      
      paint.color = Colors.white.withOpacity(opacity);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}