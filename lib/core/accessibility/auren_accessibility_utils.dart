import 'dart:math' as math;

/// Shared helpers for accessible presentation; widgets should still expose
/// Semantics labels and use FocusTraversalGroup for keyboard traversal.
class AurenAccessibilityUtils {
  const AurenAccessibilityUtils._();

  static double boundedTextScale(double requested,
      {double min = 0.8, double max = 2.0}) {
    if (!requested.isFinite) return 1.0;
    final safeMin = min.isFinite ? min.clamp(0.5, 3.0).toDouble() : 0.8;
    final safeMax = max.isFinite
        ? max.clamp(safeMin, 4.0).toDouble()
        : math.max(2.0, safeMin);
    return requested.clamp(safeMin, safeMax).toDouble();
  }

  static double contrastRatio(int foregroundArgb, int backgroundArgb) {
    final foreground = _luminance(foregroundArgb);
    final background = _luminance(backgroundArgb);
    final lighter = math.max(foreground, background);
    final darker = math.min(foreground, background);
    return (lighter + 0.05) / (darker + 0.05);
  }

  static bool meetsAa(int foregroundArgb, int backgroundArgb,
          {bool largeText = false}) =>
      contrastRatio(foregroundArgb, backgroundArgb) >=
      (largeText ? 3.0 : 4.5);

  static double _luminance(int argb) {
    double channel(int shift) {
      final value = ((argb >> shift) & 0xff) / 255.0;
      return value <= 0.04045
          ? value / 12.92
          : math.pow((value + 0.055) / 1.055, 2.4).toDouble();
    }

    return 0.2126 * channel(16) + 0.7152 * channel(8) + 0.0722 * channel(0);
  }
}
