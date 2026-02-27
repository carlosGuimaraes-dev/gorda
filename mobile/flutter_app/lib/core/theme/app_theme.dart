import 'package:flutter/material.dart';

import '../design/design_theme.dart';
import '../design/design_tokens.dart';

class AppThemeTokens {
  static const Color background = DsColorTokens.surfaceSection;
  static const Color cardBackground = DsColorTokens.surfaceCard;
  static const Color primary = DsColorTokens.actionPrimary;
  static const Color primaryText = DsColorTokens.textPrimary;
  static const Color secondaryText = DsColorTokens.textSecondary;
  static const Color fieldBackground = DsColorTokens.surfaceSubtle;
  static const double cornerRadius = DsRadiusTokens.radiusXl;
}

ThemeData buildAppTheme() {
  return buildDesignTheme();
}
