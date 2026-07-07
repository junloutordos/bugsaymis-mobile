import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme.dart';

class ShimmerCard extends StatelessWidget {
  final double height;
  const ShimmerCard({super.key, this.height = 110});

  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
        baseColor: AppColors.border,
        highlightColor: AppColors.borderLight,
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      );
}

class ShimmerList extends StatelessWidget {
  final int count;
  final double itemHeight;
  const ShimmerList({super.key, this.count = 3, this.itemHeight = 110});

  @override
  Widget build(BuildContext context) => ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        itemCount: count,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: ShimmerCard(height: itemHeight),
        ),
      );
}

class ShimmerRow extends StatelessWidget {
  final double width;
  final double height;
  const ShimmerRow({super.key, required this.width, this.height = 14});

  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
        baseColor: AppColors.border,
        highlightColor: AppColors.borderLight,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
}
