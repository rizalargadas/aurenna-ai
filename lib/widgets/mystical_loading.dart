import 'package:flutter/material.dart';
import '../config/theme.dart';

class MysticalLoading extends StatefulWidget {
  final String message;
  final double size;

  const MysticalLoading({
    super.key,
    this.message = 'Checking in with the universe...',
    this.size = 50,
  });

  @override
  State<MysticalLoading> createState() => _MysticalLoadingState();
}

class _MysticalLoadingState extends State<MysticalLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotation;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _rotation = Tween<double>(
      begin: 0,
      end: 2 * 3.14159,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));

    _pulse = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate available space for text
        final availableHeight = constraints.maxHeight;
        final circleHeight = widget.size * 1.2; // Account for scaling
        final spacingHeight = 16; // Reduced spacing
        final textHeight = availableHeight - circleHeight - spacingHeight;
        
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _rotation.value,
                  child: Transform.scale(
                    scale: _pulse.value,
                    child: Container(
                      width: widget.size,
                      height: widget.size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const RadialGradient(
                          colors: [
                            AurennaTheme.electricViolet,
                            AurennaTheme.stardustPurple,
                            AurennaTheme.cosmicPurple,
                          ],
                          stops: [0.0, 0.5, 1.0],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AurennaTheme.electricViolet.withValues(alpha: 0.4),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '✦',
                          style: TextStyle(
                            fontSize: widget.size * 0.5,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            SizedBox(height: spacingHeight.toDouble()),

            if (textHeight > 20) // Only show text if there's enough space
              Flexible(
                child: Text(
                  widget.message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AurennaTheme.textSecondary,
                    fontStyle: FontStyle.italic,
                    fontSize: textHeight > 40 ? 14 : 12, // Responsive font size
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        );
      },
    );
  }
}
