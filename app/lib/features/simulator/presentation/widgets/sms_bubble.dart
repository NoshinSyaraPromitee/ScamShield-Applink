import 'package:flutter/material.dart';
import 'package:scamshield/core/l10n/l10n.dart';
import 'package:scamshield/core/theme/app_colors.dart';

class SmsBubble extends StatelessWidget {
  const SmsBubble({super.key, required this.sender, required this.body});

  final String sender;
  final String body;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.l10n.simPracticeLabel, style: text.bodySmall?.copyWith(color: AppColors.neel, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        Row(
          children: [
            const CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.neelSoft,
              child: Icon(Icons.person_rounded, color: AppColors.neel),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(sender, style: text.titleMedium)),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.paper,
            border: Border.all(color: AppColors.line, width: 2),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(24),
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
          ),
          child: Text(body, style: text.bodyLarge),
        ),
      ],
    );
  }
}