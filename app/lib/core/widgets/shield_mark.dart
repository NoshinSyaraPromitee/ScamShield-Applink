import 'package:flutter/material.dart';
import 'package:scamshield/core/theme/app_colors.dart';

class ShieldMark extends StatelessWidget {
  const ShieldMark({super.key, this.size = 52});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: AppColors.neel, borderRadius: BorderRadius.circular(size * 0.3)),
      child: Icon(Icons.shield_rounded, color: Colors.white, size: size * 0.58),
    );
  }
}