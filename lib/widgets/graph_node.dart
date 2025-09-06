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
      end: 1.2,
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

  void _onHover(bool isHovering) {
    if (isHovering) {
      _scaleController.forward();
    } else {
      _scaleController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isActive = widget.isActive;
    
    final activeColor = widget.activeColor ?? theme.colorScheme.primary;
    final inactiveColor = widget.inactiveColor ?? theme.colorScheme.surface;
    
    return GestureDetector(
      onTap: _handleTap,
      child: MouseRegion(
        onEnter: (_) => _onHover(true),
        onExit: (_) => _onHover(false),
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
                  // Enhanced ripple effect with neon glow
                  if (ripple > 0)
                    SizedBox(
                      width: widget.size * (1 + ripple * 0.8),
                      height: widget.size * (1 + ripple * 0.8),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              activeColor.withOpacity(0.6 * (1 - ripple)),
                              activeColor.withOpacity(0.2 * (1 - ripple)),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.7, 1.0],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: activeColor.withOpacity(0.4 * (1 - ripple)),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                    ),
                  ),
                // Main node with enhanced styling
                SizedBox(
                  width: widget.size,
                  height: widget.size,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: isActive
                            ? [
                                activeColor,
                                activeColor.withOpacity(0.8),
                                activeColor.withOpacity(0.6),
                              ]
                            : [
                                inactiveColor,
                                inactiveColor.withOpacity(0.8),
                                inactiveColor.withOpacity(0.6),
                              ],
                        stops: const [0.0, 0.6, 1.0],
                      ),
                      border: Border.all(
                        color: isActive 
                          ? activeColor.withOpacity(0.9)
                          : theme.colorScheme.outline.withOpacity(0.6),
                        width: isActive ? 3.0 : 2.0,
                      ),
                      boxShadow: [
                        if (isActive) ...[
                          BoxShadow(
                            color: activeColor.withOpacity(0.6),
                            blurRadius: 20.0,
                            spreadRadius: 5.0,
                          ),
                          BoxShadow(
                            color: activeColor.withOpacity(0.3),
                            blurRadius: 40.0,
                            spreadRadius: 10.0,
                          ),
                        ],
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8.0,
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
                            widget.node.label,
                            style: TextStyle(
                              color: isActive 
                                ? Colors.white
                                : Colors.white.withOpacity(0.9),
                              fontSize: widget.size * 0.25,
                              fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                              shadows: isActive ? [
                                Shadow(
                                  color: activeColor.withOpacity(0.8),
                                  blurRadius: 10,
                                ),
                                Shadow(
                                  color: activeColor.withOpacity(0.4),
                                  blurRadius: 20,
                                ),
                              ] : null,
                            ),
                          ),
                          if (widget.node.depth > 0)
                            Text(
                              'D${widget.node.depth}',
                              style: TextStyle(
                                color: isActive 
                                  ? Colors.white.withOpacity(0.8)
                                  : Colors.white.withOpacity(0.6),
                                fontSize: widget.size * 0.15,
                                fontWeight: FontWeight.w400,
                                shadows: isActive ? [
                                  Shadow(
                                    color: activeColor.withOpacity(0.6),
                                    blurRadius: 8,
                                  ),
                                ] : null,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Active indicator
                if (isActive)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: SizedBox(
                      width: 12,
                      height: 12,
                      child: DecoratedBox(
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
                  ),
              ],
            ),
          );
        },
      ),
    ),
    );
  }
}
