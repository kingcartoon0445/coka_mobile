import 'package:coka/shared/widgets/avatar_widget.dart';
// import 'package:coka/shared/widgets/skeleton_box.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonBox({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class DashboardCardsSkeleton extends StatelessWidget {
  const DashboardCardsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 2.15,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: List.generate(
        4,
        (index) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SkeletonBox(
                    width: 20,
                    height: 20,
                    borderRadius: 20,
                  ),
                  SizedBox(width: 4),
                  SkeletonBox(
                    width: 40,
                    height: 16,
                    borderRadius: 4,
                  ),
                ],
              ),
              SizedBox(height: 8),
              SkeletonBox(
                width: 80,
                height: 14,
                borderRadius: 4,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChartSkeleton extends StatelessWidget {
  final double height;

  const ChartSkeleton({
    super.key,
    this.height = 300,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SkeletonBox(height: 24, width: 150),
            const SizedBox(height: 16),
            SkeletonBox(height: height),
          ],
        ),
      ),
    );
  }
}

class UserStatisticsSkeleton extends StatelessWidget {
  const UserStatisticsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SkeletonBox(height: 24, width: 200),
            const SizedBox(height: 16),
            ...List.generate(
              5,
              (index) => const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    AppAvatar(size: 40),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SkeletonBox(height: 16, width: 150),
                          SizedBox(height: 8),
                          SkeletonBox(height: 12, width: 100),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
