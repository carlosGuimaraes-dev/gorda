import 'dart:ui';
import 'package:flutter/material.dart';

import 'design_tokens.dart';

ThemeData buildDesignTheme() {
  const textTheme = TextTheme(
    titleLarge: TextStyle(
      fontSize: DsTypeTokens.textXl,
      fontWeight: DsTypeTokens.fontBold,
      color: DsColorTokens.textPrimary,
    ),
    titleMedium: TextStyle(
      fontSize: DsTypeTokens.textLg,
      fontWeight: DsTypeTokens.fontSemibold,
      color: DsColorTokens.textPrimary,
    ),
    bodyLarge: TextStyle(
      fontSize: DsTypeTokens.textBase,
      fontWeight: DsTypeTokens.fontNormal,
      color: DsColorTokens.textPrimary,
    ),
    bodyMedium: TextStyle(
      fontSize: DsTypeTokens.textSm,
      fontWeight: DsTypeTokens.fontNormal,
      color: DsColorTokens.textSecondary,
    ),
    bodySmall: TextStyle(
      fontSize: DsTypeTokens.textXs,
      fontWeight: DsTypeTokens.fontNormal,
      color: DsColorTokens.textMuted,
    ),
  );

  final colorScheme = ColorScheme.fromSeed(
    seedColor: DsColorTokens.actionPrimary,
    brightness: Brightness.light,
    surface: DsColorTokens.surfacePage,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: DsColorTokens.surfaceSection,
    textTheme: textTheme,
    appBarTheme: const AppBarTheme(
      backgroundColor: DsColorTokens.surfaceSection,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: DsColorTokens.textPrimary,
      titleTextStyle: TextStyle(
        fontSize: DsTypeTokens.textXl,
        fontWeight: DsTypeTokens.fontBold,
        color: DsColorTokens.textPrimary,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: DsColorTokens.surfaceSubtle,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: DsSpaceTokens.space4,
        vertical: DsSpaceTokens.space3,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DsRadiusTokens.radiusXl),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DsRadiusTokens.radiusXl),
        borderSide: const BorderSide(color: DsColorTokens.borderSubtle),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DsRadiusTokens.radiusXl),
        borderSide: const BorderSide(color: DsColorTokens.borderFocus, width: 2),
      ),
      labelStyle: const TextStyle(
        color: DsColorTokens.textSecondary,
        fontSize: DsTypeTokens.textSm,
      ),
      hintStyle: const TextStyle(
        color: DsColorTokens.textMuted,
        fontSize: DsTypeTokens.textSm,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: DsColorTokens.actionPrimary,
        foregroundColor: DsColorTokens.textOnBrand,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DsRadiusTokens.radiusXl),
        ),
      ),
    ),
    cardTheme: CardThemeData(
      color: DsColorTokens.surfaceCard,
      margin: const EdgeInsets.symmetric(
        horizontal: DsSpaceTokens.space3,
        vertical: DsSpaceTokens.space2,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DsRadiusTokens.radiusXl),
      ),
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: DsColorTokens.surfaceElevated,
      indicatorColor: DsColorTokens.surfaceSubtle,
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(
          fontSize: DsTypeTokens.textSm,
          fontWeight: DsTypeTokens.fontSemibold,
        ),
      ),
    ),
  );
}

class DsCard extends StatelessWidget {
  const DsCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(DsSpaceTokens.space4),
    this.margin = const EdgeInsets.symmetric(
      horizontal: DsSpaceTokens.space3,
      vertical: DsSpaceTokens.space2,
    ),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(DsRadiusTokens.radiusXl),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: DsGlassTokens.blurSigmaMd,
            sigmaY: DsGlassTokens.blurSigmaMd,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: DsColorTokens.surfaceGlass,
              borderRadius: BorderRadius.circular(DsRadiusTokens.radiusXl),
              boxShadow: const [DsShadowTokens.shadowGlass],
            ),
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}


class DsPrimaryButton extends StatelessWidget {
  const DsPrimaryButton({
    super.key,
    required this.title,
    required this.onPressed,
    this.isDisabled = false,
    this.leadingIcon,
  });

  final String title;
  final VoidCallback onPressed;
  final bool isDisabled;
  final IconData? leadingIcon;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isDisabled ? 0.5 : 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(DsRadiusTokens.radiusXl),
          gradient: const LinearGradient(
            colors: [
              DsColorTokens.actionPrimary,
              DsColorTokens.actionPrimaryHover,
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: const [DsShadowTokens.shadowButtonPrimary],
        ),
        child: FilledButton(
          onPressed: isDisabled ? null : onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DsRadiusTokens.radiusXl),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (leadingIcon != null) ...[
                Icon(leadingIcon, size: DsTypeTokens.textBase),
                const SizedBox(width: DsSpaceTokens.space2),
              ],
              Text(
                title,
                style: const TextStyle(
                  fontSize: DsTypeTokens.textBase,
                  fontWeight: DsTypeTokens.fontSemibold,
                  color: DsColorTokens.textOnBrand,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DsPrimaryBottomCta extends StatelessWidget {
  const DsPrimaryBottomCta({
    super.key,
    required this.title,
    required this.onPressed,
    this.isDisabled = false,
    this.leadingIcon,
  });

  final String title;
  final VoidCallback onPressed;
  final bool isDisabled;
  final IconData? leadingIcon;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: DsColorTokens.surfaceSection,
      padding: const EdgeInsets.fromLTRB(
        DsSpaceTokens.space3,
        DsSpaceTokens.space3,
        DsSpaceTokens.space3,
        DsSpaceTokens.space2,
      ),
      child: DsPrimaryButton(
        title: title,
        onPressed: onPressed,
        isDisabled: isDisabled,
        leadingIcon: leadingIcon,
      ),
    );
  }
}

class DsStatusPill extends StatelessWidget {
  const DsStatusPill({
    super.key,
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DsSpaceTokens.space2,
        vertical: DsSpaceTokens.space1,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.16),
        borderRadius: BorderRadius.circular(DsRadiusTokens.radiusMd),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: DsTypeTokens.textXs,
          fontWeight: DsTypeTokens.fontSemibold,
          color: color,
        ),
      ),
    );
  }
}

class DsSectionContainer extends StatelessWidget {
  const DsSectionContainer({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: DsColorTokens.textPrimary,
              fontSize: DsTypeTokens.textLg,
              fontWeight: DsTypeTokens.fontSemibold,
            ),
          ),
          const SizedBox(height: DsSpaceTokens.space3),
          ...children,
        ],
      ),
    );
  }
}
