import 'package:flutter/material.dart';
import '../../constants/automation_colors.dart';

class AutomationCardSkeleton extends StatefulWidget {
  const AutomationCardSkeleton({super.key});
  
  @override
  State<AutomationCardSkeleton> createState() => _AutomationCardSkeletonState();
}

class _AutomationCardSkeletonState extends State<AutomationCardSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    
    _animation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Card(
      color: AutomationColors.cardInactive,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
                   child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(8),
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _SkeletonBox(
                      width: 80,
                      height: 24,
                      opacity: _animation.value,
                    ),
                    const Spacer(),
                    _SkeletonBox(
                      width: 51,
                      height: 31,
                      opacity: _animation.value,
                      borderRadius: 16,
                    ),
                  ],
                ),
                                 const SizedBox(height: 4),
                 _SkeletonBox(
                   width: double.infinity,
                   height: 9,
                   opacity: _animation.value,
                 ),
                 const SizedBox(height: 1),
                 _SkeletonBox(
                   width: 120,
                   height: 7,
                   opacity: _animation.value,
                 ),
                 const SizedBox(height: 1),
                 _SkeletonBox(
                   width: 70,
                   height: 6,
                   opacity: _animation.value,
                 ),
                const Spacer(),
                Row(
                  children: [
                    _SkeletonBox(
                      width: 60,
                      height: 20,
                      opacity: _animation.value,
                      borderRadius: 12,
                    ),
                    const SizedBox(width: 8),
                    _SkeletonBox(
                      width: 40,
                      height: 20,
                      opacity: _animation.value,
                      borderRadius: 12,
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double opacity;
  final double borderRadius;
  
  const _SkeletonBox({
    required this.width,
    required this.height,
    required this.opacity,
    this.borderRadius = 4,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(opacity * 0.3),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}