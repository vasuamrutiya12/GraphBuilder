import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/node.dart';
import '../providers/graph_provider.dart';

class TreeVisualizer extends StatefulWidget {
  const TreeVisualizer({super.key});

  @override
  State<TreeVisualizer> createState() => _TreeVisualizerState();
}

class _TreeVisualizerState extends State<TreeVisualizer> {
  late TransformationController _transformationController;
  bool _showZoomControls = false;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GraphProvider>(
      builder: (context, graphProvider, child) {
        if (graphProvider.root == null) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.account_tree, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
              'No graph to display',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return Stack(
          children: [
            // Main graph view
            InteractiveViewer(
          transformationController: _transformationController,
          minScale: 0.1,
              maxScale: 4.0,
          constrained: false,
              onInteractionStart: (details) {
                setState(() {
                  _showZoomControls = true;
                });
              },
              onInteractionEnd: (details) {
                Future.delayed(const Duration(seconds: 2), () {
                  if (mounted) {
                    setState(() {
                      _showZoomControls = false;
                    });
                  }
                });
              },
          child: Container(
            width: double.infinity,
            height: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.surface,
                      Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                    ],
                  ),
                ),
                child: _buildSimpleTree(graphProvider),
              ),
            ),
            // Zoom controls
            if (_showZoomControls)
              Positioned(
                top: 16,
                right: 16,
                child: AnimatedOpacity(
                  opacity: _showZoomControls ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () => _zoomIn(),
                          icon: const Icon(Icons.zoom_in),
                          tooltip: 'Zoom In',
                        ),
                        IconButton(
                          onPressed: () => _zoomOut(),
                          icon: const Icon(Icons.zoom_out),
                          tooltip: 'Zoom Out',
                        ),
                        IconButton(
                          onPressed: () => _resetZoom(),
                          icon: const Icon(Icons.center_focus_strong),
                          tooltip: 'Reset Zoom',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            // Graph info overlay
            Positioned(
              bottom: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Graph Info',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Nodes: ${_getTotalNodeCount(graphProvider.root!)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      'Depth: ${_getMaxDepth(graphProvider.root!)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      'Active: ${graphProvider.activeNode?.label ?? "None"}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _zoomIn() {
    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    final newScale = (currentScale * 1.2).clamp(0.1, 4.0);
    _transformationController.value = Matrix4.identity()..scale(newScale);
  }

  void _zoomOut() {
    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    final newScale = (currentScale / 1.2).clamp(0.1, 4.0);
    _transformationController.value = Matrix4.identity()..scale(newScale);
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
  }

  int _getTotalNodeCount(Node root) {
    int count = 1;
    for (Node child in root.children) {
      count += _getTotalNodeCount(child);
    }
    return count;
  }

  int _getMaxDepth(Node root) {
    if (root.children.isEmpty) return root.depth;
    
    int maxChildDepth = root.depth;
    for (Node child in root.children) {
      maxChildDepth = maxChildDepth > _getMaxDepth(child) ? maxChildDepth : _getMaxDepth(child);
    }
    return maxChildDepth;
  }

  Widget _buildSimpleTree(GraphProvider graphProvider) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _buildNodeWidget(graphProvider.root!, graphProvider),
            const SizedBox(height: 20),
            if (graphProvider.root!.children.isNotEmpty)
              _buildChildrenWidgets(graphProvider.root!, graphProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildNodeWidget(Node node, GraphProvider graphProvider) {
    final isActive = node.id == graphProvider.activeNode?.id;
    
    return GestureDetector(
      onTap: () => graphProvider.selectNode(node.id),
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isActive ? Colors.blue : Colors.grey.shade300,
          border: Border.all(
            color: isActive ? Colors.blue.shade700 : Colors.grey.shade600,
            width: isActive ? 3.0 : 2.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6.0,
              spreadRadius: 1.0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                node.label,
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.black,
                  fontSize: 20,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              if (node.depth > 0)
                Text(
                  'D${node.depth}',
                  style: TextStyle(
                    color: isActive ? Colors.white70 : Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChildrenWidgets(Node parent, GraphProvider graphProvider) {
    if (parent.children.isEmpty) return const SizedBox.shrink();
    
    return Column(
      children: [
        // Draw line from parent to children
        Container(
          height: 2,
          width: parent.children.length * 100.0,
          color: Colors.grey.withOpacity(0.5),
        ),
        const SizedBox(height: 20),
        // Draw children in a row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: parent.children.map((child) {
            return Column(
              children: [
                _buildNodeWidget(child, graphProvider),
                const SizedBox(height: 20),
                if (child.children.isNotEmpty)
                  _buildChildrenWidgets(child, graphProvider),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

}

