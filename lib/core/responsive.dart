import 'package:flutter/material.dart';

abstract final class AppBreakpoints {
  static const compact = 600.0;
  static const medium = 840.0;
  static const expanded = 1200.0;
}

class Responsive {
  static double width(BuildContext context) => MediaQuery.sizeOf(context).width;
  static bool isCompact(BuildContext context) =>
      width(context) < AppBreakpoints.compact;
  static bool isMedium(BuildContext context) =>
      width(context) >= AppBreakpoints.medium;
  static bool isExpanded(BuildContext context) =>
      width(context) >= AppBreakpoints.expanded;

  static EdgeInsets listPadding(
    BuildContext context, {
    double maxWidth = 1100,
  }) {
    final screenWidth = width(context);
    final gutter = screenWidth < AppBreakpoints.compact ? 16.0 : 24.0;
    final horizontal = screenWidth > maxWidth
        ? (screenWidth - maxWidth) / 2 + gutter
        : gutter;
    return EdgeInsets.fromLTRB(horizontal, 20, horizontal, 96);
  }

  static int columns(
    BuildContext context, {
    int compact = 1,
    int medium = 2,
    int expanded = 3,
  }) {
    final screenWidth = width(context);
    if (screenWidth >= AppBreakpoints.expanded) return expanded;
    if (screenWidth >= AppBreakpoints.compact) return medium;
    return compact;
  }
}

class ResponsiveCenter extends StatelessWidget {
  const ResponsiveCenter({super.key, required this.child, this.maxWidth = 900});
  final Widget child;
  final double maxWidth;
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    ),
  );
}
