import 'package:flutter/material.dart';

/// A tinted, rounded surface that ripples when tapped (#66).
///
/// Replaces the `GestureDetector` + `Container(decoration: …)` pattern used
/// for tappable banners: same look, but with Material ink feedback and
/// button semantics, so it behaves like the cards next to it.
class TappableTile extends StatelessWidget {
  final VoidCallback? onTap;
  final Color? color;
  final Color? borderColor;
  final double radius;
  final EdgeInsetsGeometry padding;
  final Widget child;

  const TappableTile({
    super.key,
    required this.onTap,
    required this.child,
    this.color,
    this.borderColor,
    this.radius = 12,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: borderColor == null
          ? BorderSide.none
          : BorderSide(color: borderColor!),
    );
    return Semantics(
      button: onTap != null,
      child: Material(
        color: color ?? Colors.transparent,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          customBorder: shape,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
