import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/graph_provider.dart';
import 'widgets/tree_visualizer.dart';

void main() {
  runApp(const GraphBuilderApp());
}

class GraphBuilderApp extends StatelessWidget {
  const GraphBuilderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => GraphProvider(),
      child: MaterialApp(
        title: 'Graph Builder',
      theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF00E5FF),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          fontFamily: 'Roboto',
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF00E5FF),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          fontFamily: 'Roboto',
        ),
        home: const GraphBuilderHomePage(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class GraphBuilderHomePage extends StatefulWidget {
  const GraphBuilderHomePage({super.key});

  @override
  State<GraphBuilderHomePage> createState() => _GraphBuilderHomePageState();
}

class _GraphBuilderHomePageState extends State<GraphBuilderHomePage>
    with TickerProviderStateMixin {
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeInOut,
    );
    _fabAnimationController.forward();
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F0C29), // Deep space blue
              Color(0xFF24243e), // Dark purple
              Color(0xFF302B63), // Rich purple
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Animated background particles
            _buildAnimatedBackground(),
            // Main content
            Column(
              children: [
                // Futuristic header
                _buildFuturisticHeader(context),
                // Graph visualization area
                Expanded(
                  child: Consumer<GraphProvider>(
                    builder: (context, graphProvider, child) {
                      return graphProvider.root == null
                          ? _buildEmptyState()
                          : const TreeVisualizer();
                    },
                  ),
                ),
              ],
            ),
            // Floating action toolbar
            _buildFloatingToolbar(context),
          ],
        ),
      ),
    );
  }

  /// Builds animated background with floating particles
  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _fabAnimationController,
      builder: (context, child) {
        return CustomPaint(
          painter: BackgroundParticlePainter(_fabAnimationController.value),
          size: Size.infinite,
        );
      },
    );
  }

  /// Builds futuristic header with glassmorphism effect
  Widget _buildFuturisticHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width * 0.05,
        vertical: 20,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // App title with neon effect
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF00E5FF).withOpacity(0.2),
                  const Color(0xFF0091EA).withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: const Color(0xFF00E5FF).withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00E5FF).withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Text(
              'GRAPH BUILDER',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                shadows: [
                  Shadow(
                    color: const Color(0xFF00E5FF).withOpacity(0.5),
                    blurRadius: 10,
                  ),
                ],
              ),
            ),
          ),
          // Action buttons
          Row(
            children: [
              _buildHeaderButton(
                icon: Icons.undo,
                onPressed: () {
                  // Undo functionality
                },
                tooltip: 'Undo',
              ),
              const SizedBox(width: 12),
              _buildHeaderButton(
                icon: Icons.redo,
                onPressed: () {
                  // Redo functionality
                },
                tooltip: 'Redo',
              ),
              const SizedBox(width: 12),
              _buildHeaderButton(
                icon: Icons.refresh,
                onPressed: () {
                  // Reset functionality
                },
                tooltip: 'Reset',
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds header action button with glassmorphism
  Widget _buildHeaderButton({
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
                Colors.white.withOpacity(0.1),
                Colors.white.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: Colors.white.withOpacity(0.8),
            size: 20,
          ),
        ),
      ),
    );
  }

  /// Builds floating toolbar with futuristic design
  Widget _buildFloatingToolbar(BuildContext context) {
    return Consumer<GraphProvider>(
      builder: (context, graphProvider, child) {
        final canAddChild = graphProvider.activeNode != null &&
            graphProvider.activeNode!.depth < graphProvider.maxDepth;
        
        return Positioned(
          bottom: 30,
          right: 30,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.8),
                  Colors.black.withOpacity(0.6),
                ],
              ),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: const Color(0xFF00E5FF).withOpacity(0.3),
                width: 1,
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
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Undo button
                  _buildFloatingButton(
                    icon: Icons.undo,
                    onPressed: graphProvider.canUndo() ? () => graphProvider.undo() : null,
                    gradient: graphProvider.canUndo()
                        ? const LinearGradient(colors: [Color(0xFF9C27B0), Color(0xFF7B1FA2)])
                        : const LinearGradient(colors: [Color(0xFF616161), Color(0xFF424242)]),
                    tooltip: 'Undo',
                  ),
                  const SizedBox(height: 8),
                  // Redo button
                  _buildFloatingButton(
                    icon: Icons.redo,
                    onPressed: graphProvider.canRedo() ? () => graphProvider.redo() : null,
                    gradient: graphProvider.canRedo()
                        ? const LinearGradient(colors: [Color(0xFF9C27B0), Color(0xFF7B1FA2)])
                        : const LinearGradient(colors: [Color(0xFF616161), Color(0xFF424242)]),
                    tooltip: 'Redo',
                  ),
                  const SizedBox(height: 8),
                  // Reset button
                  _buildFloatingButton(
                    icon: Icons.refresh,
                    onPressed: () => _showResetDialog(context, graphProvider),
                    gradient: const LinearGradient(colors: [Color(0xFFFF9800), Color(0xFFF57C00)]),
                    tooltip: 'Reset Graph',
                  ),
                  const SizedBox(height: 8),
                  // Delete button
                  if (graphProvider.activeNode != null)
                    _buildFloatingButton(
                      icon: Icons.delete_outline,
                      onPressed: () => _showDeleteDialog(context, graphProvider),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF1744), Color(0xFFD50000)],
                      ),
                      tooltip: 'Delete Active Node',
                    ),
                  if (graphProvider.activeNode != null) const SizedBox(height: 8),
                  // Add child button
                  _buildFloatingButton(
                    icon: Icons.add,
                    onPressed: canAddChild
                        ? () => _addChildNode(context, graphProvider)
                        : null,
                    gradient: canAddChild
                        ? const LinearGradient(
                            colors: [Color(0xFF00E5FF), Color(0xFF0091EA)],
                          )
                        : const LinearGradient(
                            colors: [Color(0xFF616161), Color(0xFF424242)],
                          ),
                    tooltip: canAddChild ? 'Add Child Node' : 'Maximum Depth Reached',
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Builds individual floating action button
  Widget _buildFloatingButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required LinearGradient gradient,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: ScaleTransition(
        scale: _fabAnimation,
        child: GestureDetector(
          onTap: onPressed,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: gradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: gradient.colors.first.withOpacity(0.4),
                  blurRadius: 15,
                  spreadRadius: 3,
                  offset: const Offset(0, 3),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  spreadRadius: 1,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  /// Builds empty state with futuristic design
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF00E5FF).withOpacity(0.1),
                  const Color(0xFF0091EA).withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: const Color(0xFF00E5FF).withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Icon(
              Icons.account_tree_outlined,
              size: 80,
              color: const Color(0xFF00E5FF).withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 30),
          Text(
            'No Graph to Display',
            style: TextStyle(
              fontSize: 24,
              color: Colors.white.withOpacity(0.8),
              fontWeight: FontWeight.w300,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Create your first node to get started',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.5),
              fontWeight: FontWeight.w300,
            ),
          ),
        ],
      ),
    );
  }

  void _addChildNode(BuildContext context, GraphProvider graphProvider) {
    final success = graphProvider.addChildToActiveNode();
    if (!success) {
      _showSnackBar(context, 'Cannot add child: Maximum depth reached!');
    } else {
      // Animate the FAB with bounce effect
      _fabAnimationController.reset();
      _fabAnimationController.forward();
      
      // Show success feedback
      _showSnackBar(context, 'Child node added successfully!');
    }
  }

  void _showDeleteDialog(BuildContext context, GraphProvider graphProvider) {
    final activeNode = graphProvider.activeNode;
    if (activeNode == null) return;

    final isRoot = activeNode.isRoot;
    final childCount = activeNode.allDescendants.length;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(isRoot ? 'Delete Root Node' : 'Delete Node'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Node: ${activeNode.label}'),
              if (childCount > 0) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.error.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.warning,
                            color: Theme.of(context).colorScheme.error,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Subtree Deletion',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Theme.of(context).colorScheme.error,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This will delete the entire subtree:\n• $childCount descendant node${childCount == 1 ? '' : 's'}\n• All connections will be removed',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (isRoot) ...[
                const SizedBox(height: 8),
                Text(
                  'Deleting the root will reset the entire graph.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                final success = graphProvider.deleteActiveNode();
                if (success) {
                  _showSnackBar(context, 'Node deleted successfully');
                } else {
                  _showSnackBar(context, 'Failed to delete node');
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showResetDialog(BuildContext context, GraphProvider graphProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reset Graph'),
          content: const Text(
            'This will delete all nodes and reset the graph to its initial state. This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                graphProvider.resetGraph();
                _showSnackBar(context, 'Graph reset successfully');
              },
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Reset', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1a1a2e).withOpacity(0.9),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}

/// Background particle painter for animated background
class BackgroundParticlePainter extends CustomPainter {
  final double animationValue;

  BackgroundParticlePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Draw floating particles
    for (int i = 0; i < 50; i++) {
      final progress = (animationValue + i / 50.0) % 1.0;
      final x = size.width * (i / 50.0 + progress * 0.1) % size.width;
      final y = size.height * (i / 50.0 + progress * 0.05) % size.height;
      final radius = 1.0 + (i % 3) * 0.5;
      final opacity = 0.1 + (i % 5) * 0.02;
      
      paint.color = const Color(0xFF00E5FF).withOpacity(opacity);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }

    // Draw grid lines
    paint.color = const Color(0xFF00E5FF).withOpacity(0.05);
    paint.strokeWidth = 0.5;
    paint.style = PaintingStyle.stroke;

    for (int i = 0; i < 20; i++) {
      final x = size.width * i / 20;
      final y = size.height * i / 20;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
