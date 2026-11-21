import 'package:flutter/material.dart';
import 'package:scamshield/core/l10n/l10n.dart';
import 'package:shimmer/shimmer.dart';

const _base = Color(0xFFDCE1EE);
const _highlight = Color(0xFFF6F8FC);

Widget _block({double? width, required double height, double radius = 20, bool circle = false}) {
  return Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: Colors.white,
      shape: circle ? BoxShape.circle : BoxShape.rectangle,
      borderRadius: circle ? null : BorderRadius.circular(radius),
    ),
  );
}

/// Placeholder cards while a list loads. Safe to put inside another ListView.
class ListShimmer extends StatelessWidget {
  const ListShimmer({super.key, this.count = 3, this.itemHeight = 120, this.padding = const EdgeInsets.all(20)});

  final int count;
  final double itemHeight;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: context.l10n.loading,
      child: Padding(
        padding: padding,
        child: Shimmer.fromColors(
          baseColor: _base,
          highlightColor: _highlight,
          child: Column(
            children: [
              for (var i = 0; i < count; i++)
                Padding(padding: const EdgeInsets.only(bottom: 16), child: _block(height: itemHeight, radius: 24)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Same shape as the result screen, so nothing jumps when the answer arrives.
class ResultShimmer extends StatelessWidget {
  const ResultShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: context.l10n.loading,
      child: Shimmer.fromColors(
        baseColor: _base,
        highlightColor: _highlight,
        child: ListView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            Center(child: _block(width: 190, height: 190, circle: true)),
            const SizedBox(height: 20),
            Center(child: _block(width: 260, height: 30, radius: 12)),
            const SizedBox(height: 20),
            _block(height: 44, radius: 22),
            const SizedBox(height: 24),
            _block(height: 150),
            const SizedBox(height: 16),
            _block(height: 56),
            const SizedBox(height: 12),
            _block(height: 56),
          ],
        ),
      ),
    );
  }
}