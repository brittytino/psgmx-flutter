import 'package:flutter/material.dart';
import '../theme/app_dimens.dart';

class SkeletonCard extends StatefulWidget {
  final double height;
  final double width;
  const SkeletonCard({super.key, this.height = 100, this.width = double.infinity});

  @override
  State<SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<SkeletonCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
             color: color,
             borderRadius: BorderRadius.circular(AppRadius.md),
             gradient: LinearGradient(
               colors: [color, isDark ? Colors.grey[700]! : Colors.grey[100]!, color],
               stops: const [0.0, 0.5, 1.0],
               begin: Alignment(-1.0 + (_controller.value * 2), 0.0),
               end: Alignment(0.0 + (_controller.value * 2), 0.0),
             )
          ),
        );
      }
    );
  }
}
