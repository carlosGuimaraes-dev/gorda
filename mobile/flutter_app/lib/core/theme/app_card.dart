import 'package:flutter/material.dart';

import '../design/design_theme.dart';
import '../design/design_tokens.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return DsCard(
      padding: padding ?? const EdgeInsets.all(DsSpaceTokens.space4),
      child: child,
    );
  }
}
