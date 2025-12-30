"""
Skeleton loader widget for loading states.

Provides visual feedback during data loading with subtle shimmer animation.
"""
import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';

class SkeletonLoader extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  
  const SkeletonLoader({
    Key? key,
    required this.width,
    required this.height,
    this.borderRadius,
  }) : super(key: key);
  
  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
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
    
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    // Respect reduced motion preference
    final shouldReduceMotion = MediaQuery.of(context).disableAnimations;
    
    if (shouldReduceMotion) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
          color: AppColors.surfaceVariant,
        ),
      );
    }
    
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value, 0),
              colors: [
                AppColors.surfaceVariant,
                AppColors.border,
                AppColors.surfaceVariant,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}

/// Skeleton loader for trip card
class TripCardSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonLoader(width: double.infinity, height: 20),
            SizedBox(height: 8),
            SkeletonLoader(width: 150, height: 16),
            SizedBox(height: 16),
            Row(
              children: [
                SkeletonLoader(width: 80, height: 12),
                SizedBox(width: 16),
                SkeletonLoader(width: 80, height: 12),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton loader for message list
class MessageListSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 5,
      padding: EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final isMe = index % 3 == 0;  // Alternate alignment
        
        return Padding(
          padding: EdgeInsets.only(bottom: 16),
          child: Row(
            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!isMe) ...[
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.surfaceVariant,
                ),
                SizedBox(width: 8),
              ],
              Container(
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonLoader(width: 100, height: 14),
                    SizedBox(height: 4),
                    SkeletonLoader(width: 200, height: 12),
                  ],
                ),
              ),
              if (isMe) ...[
                SizedBox(width: 8),
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.surfaceVariant,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

