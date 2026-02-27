import 'dart:ui';

import 'package:flutter/material.dart';

class DsColorTokens {
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF4B5563);
  static const Color textMuted = Color(0xFF9CA3AF);
  static const Color textOnDark = Color(0xFFFFFFFF);
  static const Color textOnBrand = Color(0xFFFFFFFF);

  static const Color surfacePage = Color(0xFFFFFFFF);
  static const Color surfaceSection = Color(0xFFF9FAFB);
  static const Color surfaceCard = Color(0xFFFFFFFF);
  static const Color surfaceSubtle = Color(0xFFF3F4F6);
  static const Color surfaceElevated = Color(0xFFFFFFFF);
  static const Color surfaceGlass = Color.fromRGBO(255, 255, 255, 0.8);
  static const Color surfaceGlassProminent = Color.fromRGBO(255, 255, 255, 0.9);
  static const Color surfaceGlassClear = Color.fromRGBO(255, 255, 255, 0.6);

  static const Color actionPrimary = Color(0xFF533AFD);
  static const Color actionPrimaryHover = Color(0xFF4A34E3);
  static const Color actionPrimaryActive = Color(0xFF422ECA);
  static const Color actionSecondary = Color(0xFFE5E7EB);
  static const Color actionStrong = Color(0xFF1C1C1E);
  static const Color actionStrongHover = Color(0xFF0E0E10);

  static const Color borderDefault = Color(0xFFD1D5DB);
  static const Color borderSubtle = Color(0xFFE5E7EB);
  static const Color borderFocus = Color(0xFF533AFD);

  static const Color statusSuccess = Color(0xFF22C55E);
  static const Color statusWarning = Color(0xFFF97316);
  static const Color statusError = Color(0xFFEF4444);
}

class DsSpaceTokens {
  static const double space1 = 4;
  static const double space2 = 8;
  static const double space3 = 12;
  static const double space4 = 16;
  static const double space6 = 24;
  static const double space8 = 32;
  static const double space12 = 48;
  static const double space16 = 64;
  static const double space20 = 80;
}

class DsTypeTokens {
  static const double textXs = 12;
  static const double textSm = 14;
  static const double textBase = 16;
  static const double textLg = 18;
  static const double textXl = 20;
  static const double text2xl = 24;
  static const double text3xl = 30;
  static const double text4xl = 36;
  static const double text5xl = 48;

  static const FontWeight fontNormal = FontWeight.w400;
  static const FontWeight fontMedium = FontWeight.w500;
  static const FontWeight fontSemibold = FontWeight.w600;
  static const FontWeight fontBold = FontWeight.w700;
}

class DsRadiusTokens {
  static const double radiusSm = 6;
  static const double radiusMd = 8;
  static const double radiusLg = 12;
  static const double radiusXl = 16;
  static const double radius2xl = 24;
  static const double radiusFull = 9999;
}

class DsShadowTokens {
  static const BoxShadow shadowSm = BoxShadow(
    color: Color.fromRGBO(0, 0, 0, 0.05),
    blurRadius: 2,
    offset: Offset(0, 1),
  );

  static const BoxShadow shadowMd = BoxShadow(
    color: Color.fromRGBO(0, 0, 0, 0.10),
    blurRadius: 10,
    offset: Offset(0, 4),
  );

  static const BoxShadow shadowLg = BoxShadow(
    color: Color.fromRGBO(0, 0, 0, 0.10),
    blurRadius: 16,
    offset: Offset(0, 10),
  );

  static const BoxShadow shadowCard = shadowMd;
  static const BoxShadow shadowCardHover = shadowLg;
  static const BoxShadow shadowButtonPrimary = shadowSm;
  static const BoxShadow shadowGlass = BoxShadow(
    color: Color.fromRGBO(0, 0, 0, 0.05),
    blurRadius: 3,
    offset: Offset(0, 1),
  );
}

class DsGlassTokens {
  static const double blurSigmaSm = 5;
  static const double blurSigmaMd = 10;
  static const double blurSigmaLg = 20;
  static const double opacityGlass = 0.8;
}

class DsEffects {
  static ImageFilter blur(double sigma) {
    return ImageFilter.blur(sigmaX: sigma, sigmaY: sigma);
  }
}
