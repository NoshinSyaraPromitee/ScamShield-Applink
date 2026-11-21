import 'package:flutter/material.dart';
import 'package:scamshield/core/l10n/l10n.dart';
import 'package:scamshield/features/scan/presentation/widgets/risk_style.dart';

class ReasonTile extends StatelessWidget {
  const ReasonTile({super.key, required this.code, required this.style});

  final String code;
  final RiskStyle style;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: style.soft, shape: BoxShape.circle),
            child: Icon(reasonIcon(code), color: style.color, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(reasonText(context.l10n, code), style: Theme.of(context).textTheme.bodyLarge),
            ),
          ),
        ],
      ),
    );
  }
}