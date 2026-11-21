import 'package:flutter/material.dart';
import 'package:scamshield/core/l10n/l10n.dart';
import 'package:scamshield/core/network/failure.dart';
import 'package:scamshield/core/theme/app_colors.dart';
import 'package:scamshield/core/widgets/big_button.dart';

String failureMessage(AppLocalizations l, Object error) => switch (error) {
      NetworkFailure() => l.errorNetwork,
      ServerFailure() => l.errorServer,
      InvalidInputFailure() => l.errorInvalid,
      _ => l.errorUnknown,
    };

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              error is NetworkFailure ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
              size: 72,
              color: AppColors.danger,
            ),
            const SizedBox(height: 16),
            Text(failureMessage(l, error), textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 24),
            BigButton(label: l.retry, icon: Icons.refresh_rounded, onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}