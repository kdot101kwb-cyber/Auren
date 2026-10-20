import 'package:flutter/material.dart';

/// Visual foundations for the AUREN Nebula experience.
/// Keep the palette restrained so content remains the focus and mid-range
/// devices do not need expensive blur or animation effects.
abstract final class AurenNebulaTokens {
  static const Color midnight = Color(0xFF090B16);
  static const Color surface = Color(0xFF131729);
  static const Color elevatedSurface = Color(0xFF1A2036);
  static const Color violet = Color(0xFF9B8CFF);
  static const Color electricBlue = Color(0xFF6DDCFF);
  static const Color orchid = Color(0xFFE28CFF);
  static const Color outline = Color(0xFF292E49);
  static const Color lightCanvas = Color(0xFFF5F6FC);

  static const LinearGradient signatureGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [violet, electricBlue, orchid],
  );

  static RoundedRectangleBorder get cardShape => RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: outline),
      );

  static const Duration quickMotion = Duration(milliseconds: 180);
  static const Duration standardMotion = Duration(milliseconds: 260);
}
