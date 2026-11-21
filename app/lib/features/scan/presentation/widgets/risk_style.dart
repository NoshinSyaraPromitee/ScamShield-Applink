import 'package:flutter/material.dart';
import 'package:scamshield/core/l10n/l10n.dart';
import 'package:scamshield/core/theme/app_colors.dart';
import 'package:scamshield/features/scan/domain/entities/scan_result.dart';

class RiskStyle {
  const RiskStyle({required this.color, required this.deep, required this.soft, required this.icon});

  final Color color;
  final Color deep;
  final Color soft;
  final IconData icon;

  static RiskStyle of(RiskLevel risk) => switch (risk) {
        RiskLevel.high => const RiskStyle(
            color: AppColors.danger, deep: AppColors.dangerDeep, soft: AppColors.dangerSoft, icon: Icons.gpp_bad_rounded),
        RiskLevel.medium => const RiskStyle(
            color: AppColors.caution, deep: AppColors.cautionDeep, soft: AppColors.cautionSoft, icon: Icons.report_rounded),
        RiskLevel.low || RiskLevel.none => const RiskStyle(
            color: AppColors.safe, deep: AppColors.safe, soft: AppColors.safeSoft, icon: Icons.verified_user_rounded),
      };
}

extension RiskText on RiskLevel {
  String title(AppLocalizations l) => switch (this) {
        RiskLevel.high => l.riskHigh,
        RiskLevel.medium => l.riskMedium,
        RiskLevel.low => l.riskLow,
        RiskLevel.none => l.riskNone,
      };

  String body(AppLocalizations l) => switch (this) {
        RiskLevel.high => l.riskHighBody,
        RiskLevel.medium => l.riskMediumBody,
        RiskLevel.low => l.riskLowBody,
        RiskLevel.none => l.riskNoneBody,
      };

  String advice(AppLocalizations l) => switch (this) {
        RiskLevel.high => l.adviceHigh,
        RiskLevel.medium => l.adviceMedium,
        RiskLevel.low || RiskLevel.none => l.adviceSafe,
      };
}

String reasonText(AppLocalizations l, String code) => switch (code) {
      'urgency' => l.reasonUrgency,
      'asks_secret' => l.reasonAsksSecret,
      'unofficial_link' => l.reasonUnofficialLink,
      'too_good' => l.reasonTooGood,
      'pay_fast' => l.reasonPayFast,
      'personal_number' => l.reasonPersonalNumber,
      _ => l.reasonGeneric,
    };

IconData reasonIcon(String code) => switch (code) {
      'urgency' => Icons.timer_rounded,
      'asks_secret' => Icons.password_rounded,
      'unofficial_link' => Icons.link_off_rounded,
      'too_good' => Icons.card_giftcard_rounded,
      'pay_fast' => Icons.payments_rounded,
      'personal_number' => Icons.phone_disabled_rounded,
      _ => Icons.flag_rounded,
    };