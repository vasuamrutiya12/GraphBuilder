import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/node.dart';
import '../providers/graph_provider.dart';

class TreeVisualizer extends StatefulWidget {
  const TreeVisualizer({super.key});

  @override
  State<TreeVisualizer> createState() => _TreeVisualizerState();
}

class _TreeVisualizerState extends State<TreeVisualizer> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_animationController);
    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
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

        return Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1a1a2e),
                const Color(0xFF16213e),
                const Color(0xFF0f3460),
                const Color(0xFF533483),
              ],
              stops: const [0.0, 0.3, 0.7, 1.0],
            ),
          ),
          child: Stack(
            children: [
              // Animated background particles
              _buildAnimatedBackground(),
              // Main tree content
              _buildSimpleTree(graphProvider),
            ],
          ),
        );
      },
    );
  }



  Widget _buildSimpleTree(GraphProvider graphProvider) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          children: [
            _buildNodeWidget(graphProvider.root!, graphProvider),
            const SizedBox(height: 40),
            if (graphProvider.root!.children.isNotEmpty)
              _buildChildrenWidgets(graphProvider.root!, graphProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildNodeWidget(Node node, GraphProvider graphProvider) {
    final isActive = node.id == graphProvider.activeNode?.id;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: GestureDetector(
        onTap: () {
          print('Tapped node: ${node.label}');
          graphProvider.selectNode(node.id);
        },
        child: Container(
          width: isActive ? 120 : 100,
          height: isActive ? 120 : 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isActive 
                ? [
                    Colors.blue.shade400,
                    Colors.blue.shade600,
                    Colors.blue.shade800,
                  ]
                : [
                    Colors.purple.shade300,
                    Colors.purple.shade500,
                    Colors.purple.shade700,
                  ],
            ),
            border: Border.all(
              color: isActive ? Colors.blue.shade200 : Colors.purple.shade200,
              width: isActive ? 4.0 : 2.0,
            ),
            boxShadow: [
              BoxShadow(
                color: (isActive ? Colors.blue : Colors.purple).withOpacity(0.4),
                blurRadius: isActive ? 20.0 : 15.0,
                spreadRadius: isActive ? 5.0 : 3.0,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10.0,
                spreadRadius: 2.0,
                offset: const Offset(0, 4),
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
                    color: Colors.white,
                    fontSize: isActive ? 28 : 24,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                if (node.depth > 0) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'D${node.depth}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChildrenWidgets(Node parent, GraphProvider graphProvider) {
    if (parent.children.isEmpty) return const SizedBox.shrink();
    
    return Column(
      children: [
        const SizedBox(height: 30),
        // Draw connecting lines
        _buildConnectingLines(parent.children.length),
        const SizedBox(height: 30),
        // Draw children in a row
        Wrap(
          spacing: 40,
          runSpacing: 40,
          alignment: WrapAlignment.center,
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

  Widget _buildConnectingLines(int childCount) {
    if (childCount <= 1) return const SizedBox.shrink();
    
    return Container(
      height: 2,
      width: (childCount - 1) * 40.0 + 100.0,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.withOpacity(0.3),
            Colors.blue.withOpacity(0.6),
            Colors.purple.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(1),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          painter: ParticlePainter(_animation.value),
          size: Size.infinite,
        );
      },
    );
  }
}

class ParticlePainter extends CustomPainter {
  final double animationValue;

  ParticlePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    // Draw floating particles
    for (int i = 0; i < 20; i++) {
      final x = (size.width * (i / 20.0) + animationValue * 100) % size.width;
      final y = (size.height * (i / 20.0) + animationValue * 50) % size.height;
      final radius = 2.0 + (i % 3);
      
      canvas.drawCircle(
        Offset(x, y),
        radius,
        paint..color = Colors.white.withOpacity(0.05 + (i % 3) * 0.02),
      );
    }

    // Draw connecting lines between particles
    paint.color = Colors.blue.withOpacity(0.1);
    paint.strokeWidth = 1;
    paint.style = PaintingStyle.stroke;

    for (int i = 0; i < 20; i += 2) {
      final x1 = (size.width * (i / 20.0) + animationValue * 100) % size.width;
      final y1 = (size.height * (i / 20.0) + animationValue * 50) % size.height;
      final x2 = (size.width * ((i + 1) / 20.0) + animationValue * 100) % size.width;
      final y2 = (size.height * ((i + 1) / 20.0) + animationValue * 50) % size.height;
      
      final distance = (Offset(x1, y1) - Offset(x2, y2)).distance;
      if (distance < 150) {
        canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;

}

