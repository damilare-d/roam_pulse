import 'package:flutter/material.dart';

import '../app_spacing.dart';

class RoamPulseCard extends StatelessWidget {
  const RoamPulseCard({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(padding: padding, child: child),
    );
  }
}
