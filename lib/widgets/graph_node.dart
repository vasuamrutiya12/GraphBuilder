import 'package:flutter/material.dart';
import '../models/node.dart';

class GraphNode extends StatefulWidget {
  final Node node;
  final bool isActive;
  final VoidCallback onTap;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;

  const GraphNode({
    super.key,
    required this.node,
    required this.isActive,
    required this.onTap,
    this.size = 60.0,
    this.activeColor,
    this.inactiveColor,
  });

  @override
  State<GraphNode> createState() => _GraphNodeState();
}

class _GraphNodeState extends State<GraphNode>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _pulseController;
  late AnimationController _rippleController;
  
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rippleAnimation;

  @override
  void initState() {
    super.initState();
    
    // Scale animation for selection
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    // Pulse animation for active state
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.08,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Ripple animation for tap feedback
    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _rippleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rippleController,
      curve: Curves.easeOut,
    ));

    if (widget.isActive) {
      _scaleController.forward();
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(GraphNode oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _scaleController.forward();
        _pulseController.repeat(reverse: true);
      } else {
        _scaleController.reverse();
        _pulseController.stop();
        _pulseController.reset();
      }
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _pulseController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  void _handleTap() {
    _rippleController.forward().then((_) {
      _rippleController.reset();
    });
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isActive = widget.isActive;
    
    final activeColor = widget.activeColor ?? theme.colorScheme.primary;
    final inactiveColor = widget.inactiveColor ?? theme.colorScheme.surface;
    
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([_scaleAnimation, _pulseAnimation, _rippleAnimation]),
        builder: (context, child) {
          final scale = isActive ? _scaleAnimation.value : 1.0;
          final pulse = isActive ? _pulseAnimation.value : 1.0;
          final ripple = _rippleAnimation.value;
          
          return Transform.scale(
            scale: scale * pulse,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Ripple effect
                if (ripple > 0)
                  Container(
                    width: widget.size * (1 + ripple * 0.5),
                    height: widget.size * (1 + ripple * 0.5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: activeColor.withOpacity(0.3 * (1 - ripple)),
                    ),
                  ),
                // Main node
                Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isActive
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              activeColor,
                              activeColor.withOpacity(0.8),
                            ],
                          )
                        : null,
                    color: isActive ? null : inactiveColor,
                    border: Border.all(
                      color: isActive 
                        ? activeColor.withOpacity(0.9)
                        : theme.colorScheme.outline.withOpacity(0.6),
                      width: isActive ? 3.0 : 2.0,
                    ),
                    boxShadow: [
                      if (isActive)
                        BoxShadow(
                          color: activeColor.withOpacity(0.4),
                          blurRadius: 12.0,
                          spreadRadius: 3.0,
                        ),
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
                          widget.node.label,
                          style: TextStyle(
                            color: isActive 
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurface,
                            fontSize: widget.size * 0.25,
                            fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                          ),
                        ),
                        if (widget.node.depth > 0)
                          Text(
                            'D${widget.node.depth}',
                            style: TextStyle(
                              color: isActive 
                                ? theme.colorScheme.onPrimary.withOpacity(0.7)
                                : theme.colorScheme.onSurface.withOpacity(0.5),
                              fontSize: widget.size * 0.15,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                // Active indicator
                if (isActive)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.colorScheme.onPrimary,
                        border: Border.all(
                          color: activeColor,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
