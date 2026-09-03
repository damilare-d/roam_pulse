import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../app_spacing.dart';
import '../app_typography.dart';

/// A generic status tone — deliberately not tied to any feature's state
/// enum (e.g. connectivity). Feature packages map their own domain state
/// to a tone; this package stays domain-agnostic.
enum StatusTone { positive, warning, negative, neutral }

extension on StatusTone {
  Color get color => switch (this) {
    StatusTone.positive => AppColors.positive,
    StatusTone.warning => AppColors.warning,
    StatusTone.negative => AppColors.negative,
    StatusTone.neutral => AppColors.neutral,
  };
}

/// A small dot + label, e.g. "● Connected". The building block behind the
/// dashboard's connection-state row in docs/PRODUCT_DISCOVERY.md.
class StatusIndicator extends StatelessWidget {
  const StatusIndicator({required this.label, required this.tone, super.key});

  final String label;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: tone.color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(label, style: AppTypography.label.copyWith(color: tone.color)),
      ],
    );
  }
}
