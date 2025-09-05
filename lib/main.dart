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
      appBar: AppBar(
        title: const Text('Graph Builder'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1a1a2e).withOpacity(0.9),
                const Color(0xFF16213e).withOpacity(0.9),
              ],
            ),
          ),
        ),
        foregroundColor: Colors.white,
        actions: [
          Consumer<GraphProvider>(
            builder: (context, graphProvider, child) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Undo button
                  IconButton(
                    onPressed: graphProvider.canUndo() ? graphProvider.undo : null,
                    icon: const Icon(Icons.undo),
                    tooltip: 'Undo',
                  ),
                  // Redo button
                  IconButton(
                    onPressed: graphProvider.canRedo() ? graphProvider.redo : null,
                    icon: const Icon(Icons.redo),
                    tooltip: 'Redo',
                  ),
                  // Reset button
                  IconButton(
                    onPressed: () => _showResetDialog(context, graphProvider),
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Reset Graph',
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer<GraphProvider>(
        builder: (context, graphProvider, child) {
          return Column(
            children: [
              // Status bar
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF1a1a2e).withOpacity(0.8),
                      const Color(0xFF16213e).withOpacity(0.8),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Active Node: ${graphProvider.activeNode?.label ?? "None"}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            Text(
                      'Next ID: ${graphProvider.nextNodeId}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
            ),
          ],
        ),
      ),
              // Graph visualization
              Expanded(
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  child: const TreeVisualizer(),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: Consumer<GraphProvider>(
        builder: (context, graphProvider, child) {
          final canAddChild = graphProvider.activeNode != null &&
              graphProvider.activeNode!.depth < graphProvider.maxDepth;
          
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Delete button
              if (graphProvider.activeNode != null)
                ScaleTransition(
                  scale: _fabAnimation,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFFFF1744),
                          const Color(0xFFD50000),
                          const Color(0xFFB71C1C),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF1744).withOpacity(0.4),
                          blurRadius: 20,
                          spreadRadius: 5,
                          offset: const Offset(0, 5),
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 10,
                          spreadRadius: 2,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: FloatingActionButton(
                      heroTag: "delete",
                      onPressed: () => _showDeleteDialog(context, graphProvider),
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      child: const Icon(Icons.delete, color: Colors.white),
                      tooltip: 'Delete Active Node',
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              // Add child button
              ScaleTransition(
                scale: _fabAnimation,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: canAddChild
                          ? [
                              const Color(0xFF00E5FF),
                              const Color(0xFF00B0FF),
                              const Color(0xFF0091EA),
                            ]
                          : [
                              const Color(0xFF616161),
                              const Color(0xFF424242),
                              const Color(0xFF212121),
                            ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (canAddChild 
                            ? const Color(0xFF00E5FF) 
                            : const Color(0xFF616161)).withOpacity(0.4),
                        blurRadius: 20,
                        spreadRadius: 5,
                        offset: const Offset(0, 5),
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: FloatingActionButton(
                    heroTag: "add",
                    onPressed: canAddChild
                        ? () => _addChildNode(context, graphProvider)
                        : null,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    child: const Icon(Icons.add, color: Colors.white),
                    tooltip: canAddChild ? 'Add Child Node' : 'Maximum Depth Reached',
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _addChildNode(BuildContext context, GraphProvider graphProvider) {
    final success = graphProvider.addChildToActiveNode();
    if (!success) {
      _showSnackBar(context, 'Cannot add child: Maximum depth reached!');
    } else {
      // Animate the FAB
      _fabAnimationController.reset();
      _fabAnimationController.forward();
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
                Text(
                  'This will also delete $childCount descendant node${childCount == 1 ? '' : 's'}.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
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
      ),
    );
  }
}
