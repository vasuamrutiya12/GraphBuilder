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
      return isActive ? const Color(0xFFFFD700) : const Color(0xFFFFE55C); // Bright gold
    }
    
    final colors = [
      const Color(0xFFFF8C00), // Vibrant orange - Depth 1 (parents)
      const Color(0xFFFF4500), // Deep red - Depth 2 (intermediate)
      const Color(0xFF8A2BE2), // Rich purple - Depth 3 (leaves)
      const Color(0xFF00CED1), // Cyan - Depth 4 (highlights)
      const Color(0xFF4169E1), // Royal blue - Depth 5+
    ];
    
    final colorIndex = math.min(depth - 1, colors.length - 1);
    final baseColor = depth > 0 ? colors[colorIndex] : const Color(0xFF8A2BE2);
    
    if (isActive) {
      return const Color(0xFF00E5FF); // Glowing cyan for active nodes
    }
    
    return baseColor;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive design based on screen size
        final isMobile = constraints.maxWidth < 768;
        final isTablet = constraints.maxWidth >= 768 && constraints.maxWidth < 1024;
        final isDesktop = constraints.maxWidth >= 1024;
        
    return Consumer<GraphProvider>(
      builder: (context, graphProvider, child) {
        if (graphProvider.root == null) {
          return _buildEmptyState();
        }

            // Force rebuild when graph structure changes
            return Stack(
            children: [
              // Animated gradient background
              _buildAnimatedBackground(),
                // Interactive graph view with responsive scaling
                _buildResponsiveGraph(graphProvider, isMobile, isTablet, isDesktop),
                // Mini-map overlay (desktop only)
                if (isDesktop) _buildMiniMap(graphProvider),
              // Node info tooltip
              if (_hoveredNodeId != null)
                _buildNodeTooltip(graphProvider),
                // Zoom controls
                _buildZoomControls(),
            ],
            );
          },
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

  /// Builds responsive graph with adaptive scaling
  Widget _buildResponsiveGraph(GraphProvider graphProvider, bool isMobile, bool isTablet, bool isDesktop) {
    // Adjust scale limits based on device type
    final minScale = isMobile ? 0.5 : 0.3;
    final maxScale = isMobile ? 2.0 : 3.0;
    
        return InteractiveViewer(
          transformationController: _transformationController,
      minScale: minScale,
      maxScale: maxScale,
      child: SizedBox(
          width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
          child: Stack(
            children: [
              // Draw edges first (behind nodes)
              _buildEdgeLayer(graphProvider),
            // Draw nodes positioned absolutely with responsive scaling
            _buildPositionedNodes(graphProvider, isMobile, isTablet, isDesktop),
          ],
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

  /// Builds all nodes positioned absolutely based on calculated positions
  /// Builds positioned nodes with responsive scaling and auto-fit
  Widget _buildPositionedNodes(GraphProvider graphProvider, [bool isMobile = false, bool isTablet = false, bool isDesktop = true]) {
    final nodePositions = <String, Offset>{};
    final screenSize = MediaQuery.of(context).size;
    
    // Responsive root position based on device type
    final rootY = isMobile ? 100.0 : 120.0;
    final rootPosition = Offset(screenSize.width / 2, rootY);
    
    // Calculate positions for all nodes using improved layout
    _calculateAdvancedLayout(graphProvider.root!, nodePositions, rootPosition, 0);
    
    // Calculate optimal scale to fit all nodes on screen
    final optimalScale = _calculateOptimalScale(nodePositions, screenSize.width, screenSize.height);
    
    // Apply auto-scaling if nodes don't fit on screen
    if (optimalScale < 1.0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final currentScale = _transformationController.value.getMaxScaleOnAxis();
        if (currentScale > optimalScale) {
          _transformationController.value = Matrix4.identity()..scale(optimalScale);
        }
      });
    }
    
    // Create positioned widgets for all nodes
    final positionedNodes = <Widget>[];
    
    for (final node in graphProvider.getAllNodes()) {
      final position = nodePositions[node.id];
      if (position == null) continue;
      
      // Center the node properly (accounting for node size)
      final nodeSize = node.id == graphProvider.activeNode?.id ? 140.0 : 120.0;
      final halfSize = nodeSize / 2;
      
      positionedNodes.add(
        Positioned(
          left: position.dx - halfSize,
          top: position.dy - halfSize,
          child: _buildPositionedNode(node, graphProvider),
        ),
      );
    }
    
    return Stack(children: positionedNodes);
  }

  /// Builds zoom controls for the graph
  Widget _buildZoomControls() {
    return Positioned(
      bottom: 20,
      left: 20,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.black.withOpacity(0.7),
              Colors.black.withOpacity(0.5),
            ],
          ),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: const Color(0xFF00E5FF).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
      children: [
            _buildZoomButton(
              icon: Icons.zoom_in,
              onPressed: () => _zoomIn(),
              tooltip: 'Zoom In',
            ),
            Container(
              width: 1,
              height: 40,
              color: const Color(0xFF00E5FF).withOpacity(0.3),
            ),
            _buildZoomButton(
              icon: Icons.zoom_out,
              onPressed: () => _zoomOut(),
              tooltip: 'Zoom Out',
            ),
            Container(
              width: 1,
              height: 40,
              color: const Color(0xFF00E5FF).withOpacity(0.3),
            ),
            _buildZoomButton(
              icon: Icons.center_focus_strong,
              onPressed: () => _resetZoom(),
              tooltip: 'Reset View',
            ),
          ],
        ),
      ),
    );
  }

  /// Builds individual zoom control button
  Widget _buildZoomButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF00E5FF).withOpacity(0.1),
                const Color(0xFF0091EA).withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF00E5FF).withOpacity(0.8),
            size: 20,
          ),
        ),
      ),
    );
  }

  /// Zooms in the graph
  void _zoomIn() {
    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    final newScale = (currentScale * 1.2).clamp(0.3, 3.0);
    _transformationController.value = Matrix4.identity()..scale(newScale);
  }

  /// Zooms out the graph
  void _zoomOut() {
    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    final newScale = (currentScale / 1.2).clamp(0.3, 3.0);
    _transformationController.value = Matrix4.identity()..scale(newScale);
  }

  /// Resets zoom to default
  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
  }

  /// Builds a single positioned node with enhanced animations and styling
  Widget _buildPositionedNode(Node node, GraphProvider graphProvider) {
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
              child: _buildEnhancedNodeContent(node, nodeColor, isActive, isRoot, isHovered),
            ),
          ),
        );
      },
    );
  }

  List<EdgeData> _calculateEdgeData(GraphProvider graphProvider) {
    final edges = <EdgeData>[];
    final nodePositions = <String, Offset>{};
    
    // Calculate node positions using advanced layout algorithm
    final screenSize = MediaQuery.of(context).size;
    final rootPosition = Offset(screenSize.width / 2, 150); // Perfectly centered horizontally
    _calculateAdvancedLayout(graphProvider.root!, nodePositions, rootPosition, 0);
    
    // Generate edges for ALL parent-child relationships
    // This ensures every node (except root) has an edge to its parent
    _generateAllEdges(graphProvider, edges, nodePositions);
    
    return edges;
  }

  /// Advanced layout algorithm that prevents subtree overlap and centers children around parents
  void _calculateAdvancedLayout(Node node, Map<String, Offset> positions, Offset position, int level) {
    positions[node.id] = position;
    
    if (node.children.isNotEmpty) {
      final screenWidth = MediaQuery.of(context).size.width;
      final screenHeight = MediaQuery.of(context).size.height;
      
      // Improved vertical spacing with better level-based scaling
      final baseVerticalSpacing = 200.0;
      final verticalSpacing = math.max(180.0, baseVerticalSpacing - (level * 20.0));
      
      // Calculate the width needed for each subtree with improved spacing
      final subtreeWidths = <double>[];
      for (final child in node.children) {
        final subtreeWidth = _calculateSubtreeWidth(child, level + 1);
        subtreeWidths.add(subtreeWidth);
      }
      
      // Improved spacing calculation to prevent overlaps
      final minNodeSpacing = 160.0; // Minimum gap between adjacent nodes
      final totalSubtreeWidth = subtreeWidths.fold(0.0, (sum, width) => sum + width);
      final totalSpacing = (node.children.length - 1) * minNodeSpacing;
      final totalRequiredWidth = totalSubtreeWidth + totalSpacing;
      
      // Better responsive scaling with viewport awareness
      final availableWidth = screenWidth - 240; // Account for padding and margins
      final scaleFactor = totalRequiredWidth > availableWidth ? 
          math.max(0.6, availableWidth / totalRequiredWidth) : 1.0;
      
      // Apply scaling to widths and spacing
      final scaledSubtreeWidths = subtreeWidths.map((w) => w * scaleFactor).toList();
      final scaledSpacing = minNodeSpacing * scaleFactor;
      final scaledTotalWidth = scaledSubtreeWidths.fold(0.0, (sum, width) => sum + width) + 
          (node.children.length - 1) * scaledSpacing;
      
      // Center all children around the parent
      final startX = position.dx - scaledTotalWidth / 2;
      final childY = position.dy + verticalSpacing;
      
      // Position each child with proper centering and spacing
      double currentX = startX;
      for (int i = 0; i < node.children.length; i++) {
        final child = node.children[i];
        final subtreeWidth = scaledSubtreeWidths[i];
        
        // Center the child within its allocated subtree width
        final childX = currentX + subtreeWidth / 2;
        final childPosition = Offset(childX, childY);
        
        // Ensure the position is within screen bounds
        final boundedPosition = _ensureWithinBounds(childPosition, screenWidth, screenHeight);
        
        // Recursively position the child and its subtree
        _calculateAdvancedLayout(child, positions, boundedPosition, level + 1);
        
        // Move to next subtree position
        currentX += subtreeWidth + scaledSpacing;
      }
    }
  }

  /// Calculates the width needed for a subtree to prevent overlap
  double _calculateSubtreeWidth(Node node, int level) {
    const baseNodeWidth = 140.0; // Increased base width to account for node size + margin
    
    if (node.children.isEmpty) {
      return baseNodeWidth; // Base width for leaf nodes
    }
    
    // Calculate width needed for all children recursively
    double totalChildrenWidth = 0.0;
    for (final child in node.children) {
      totalChildrenWidth += _calculateSubtreeWidth(child, level + 1);
    }
    
    // Add proper spacing between children to prevent overlaps
    final minSpacing = 160.0; // Increased spacing for better separation
    final totalSpacing = (node.children.length - 1) * minSpacing;
    final childrenTotalWidth = totalChildrenWidth + totalSpacing;
    
    // Return the maximum of node width and children width
    // This ensures parent is wide enough to accommodate all children
    return math.max(baseNodeWidth, childrenTotalWidth);
  }


  /// Ensures position is within screen bounds with proper margins
  Offset _ensureWithinBounds(Offset position, double screenWidth, double screenHeight) {
    const margin = 80.0; // Margin from screen edges
    
    final boundedX = position.dx.clamp(margin, screenWidth - margin);
    final boundedY = position.dy.clamp(margin, screenHeight - margin);
    
    return Offset(boundedX, boundedY);
  }
  
  /// Calculates optimal scale to fit all nodes on screen
  double _calculateOptimalScale(Map<String, Offset> positions, double screenWidth, double screenHeight) {
    if (positions.isEmpty) return 1.0;
    
    // Find the bounding box of all nodes
    double minX = double.infinity;
    double maxX = double.negativeInfinity;
    double minY = double.infinity;
    double maxY = double.negativeInfinity;
    
    for (final position in positions.values) {
      minX = math.min(minX, position.dx);
      maxX = math.max(maxX, position.dx);
      minY = math.min(minY, position.dy);
      maxY = math.max(maxY, position.dy);
    }
    
    // Add padding for node sizes
    const nodePadding = 100.0;
    final contentWidth = (maxX - minX) + (nodePadding * 2);
    final contentHeight = (maxY - minY) + (nodePadding * 2);
    
    // Calculate scale to fit content with margins
    const screenMargin = 100.0;
    final availableWidth = screenWidth - (screenMargin * 2);
    final availableHeight = screenHeight - (screenMargin * 2);
    
    final scaleX = contentWidth > availableWidth ? availableWidth / contentWidth : 1.0;
    final scaleY = contentHeight > availableHeight ? availableHeight / contentHeight : 1.0;
    
    // Use the smaller scale to ensure everything fits
    return math.min(scaleX, scaleY).clamp(0.3, 2.0);
  }

  /// Generates edges for ALL parent-child relationships in the graph
  /// This ensures every node (except root) has an edge connecting it to its parent
  void _generateAllEdges(GraphProvider graphProvider, List<EdgeData> edges, Map<String, Offset> positions) {
    final allNodes = graphProvider.getAllNodes();
    int connectedNodes = 0;
    
    for (final node in allNodes) {
      // Skip root node (it has no parent)
      if (node.parent == null) {
        connectedNodes++; // Root is considered "connected" (it's the source)
        continue;
      }
      
      final parentPosition = positions[node.parent!.id];
      final childPosition = positions[node.id];
      
      if (parentPosition == null || childPosition == null) {
        // Log missing positions for debugging
        print('Warning: Missing position for node ${node.id} or parent ${node.parent!.id}');
        continue;
      }
      
      // Calculate curve intensity based on horizontal distance and depth
      final horizontalDistance = (childPosition.dx - parentPosition.dx).abs();
      final depthFactor = node.depth * 0.1;
      final curveIntensity = math.min(horizontalDistance * 0.4 + depthFactor * 20, 100.0);
      
      // Create edge from parent to child with enhanced positioning
      edges.add(EdgeData(
        parentId: node.parent!.id,
        childId: node.id,
        startPoint: Offset(parentPosition.dx, parentPosition.dy + 80), // Better offset from node center
        endPoint: Offset(childPosition.dx, childPosition.dy - 80),
        parentColor: _getNodeColorByDepth(node.parent!.depth, false, node.parent!.parent == null),
        childColor: _getNodeColorByDepth(node.depth, false, false),
        curveIntensity: curveIntensity,
        maxWidth: 8.0, // Increased for more professional look
        minWidth: 4.0, // Increased for better visibility
        particleCount: 6, // More particles for better animation
        particleSpeed: 0.7, // Faster animation
      ));
      
      connectedNodes++;
    }
    
    // Debug: Verify all nodes are connected
    if (connectedNodes != allNodes.length) {
      print('Warning: Not all nodes are connected. Connected: $connectedNodes, Total: ${allNodes.length}');
    } else {
      print('✅ All ${allNodes.length} nodes are properly connected with edges');
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

  /// Enhanced node content with glowing gradients and depth-based colors
  Widget _buildEnhancedNodeContent(Node node, Color nodeColor, bool isActive, bool isRoot, bool isHovered) {
    return SizedBox(
                width: isActive ? 140 : 120,
                height: isActive ? 140 : 120,
      child: DecoratedBox(
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
            // Outer glow - enhanced for better visibility
                    BoxShadow(
              color: nodeColor.withOpacity(isActive ? 0.8 : 0.4),
              blurRadius: isActive ? 40.0 : 25.0,
              spreadRadius: isActive ? 12.0 : 6.0,
                    ),
                    // Inner shadow for 3D effect
                    BoxShadow(
              color: Colors.white.withOpacity(0.2),
              blurRadius: 15.0,
              spreadRadius: -8.0,
              offset: const Offset(-8, -8),
                    ),
                    // Bottom shadow
                    BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 20.0,
              spreadRadius: 3.0,
              offset: const Offset(0, 10),
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
                          color: Colors.black.withOpacity(0.7),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                          ),
                          if (node.depth > 0) ...[
                            const SizedBox(height: 6),
                    Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10, 
                                vertical: 4
                              ),
                      child: DecoratedBox(
                              decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                            color: Colors.white.withOpacity(0.4),
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
                child: SizedBox(
                          width: 28,
                          height: 28,
                  child: DecoratedBox(
                          decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: nodeColor,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
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
                      ),
                  ],
                ),
              ),
    );
  }

  /// Legacy method - kept for backward compatibility
  Widget _buildEnhancedNode(Node node, GraphProvider graphProvider) {
    final isActive = node.id == graphProvider.activeNode?.id;
    final isRoot = node.parent == null;
    final isHovered = _hoveredNodeId == node.id;
    final nodeColor = _getNodeColorByDepth(node.depth, isActive, isRoot);
    
    return _buildEnhancedNodeContent(node, nodeColor, isActive, isRoot, isHovered);
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
      child: SizedBox(
        width: 250,
        height: 180,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.black.withOpacity(0.8),
                Colors.black.withOpacity(0.6),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF00E5FF).withOpacity(0.4),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00E5FF).withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            children: [
              // Mini-map header
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF00E5FF).withOpacity(0.2),
                      const Color(0xFF0091EA).withOpacity(0.1),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(14),
                    topRight: Radius.circular(14),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.map_outlined,
                      color: const Color(0xFF00E5FF),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Graph Overview',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              // Mini-map content
              Expanded(
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
            ],
          ),
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
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: DecoratedBox(
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