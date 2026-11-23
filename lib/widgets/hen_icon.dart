import 'package:flutter/material.dart';

/// The app's hen mark as an icon (#64).
///
/// Sizes and tints itself from the ambient [IconTheme] like a regular
/// [Icon], so it can stand in for one anywhere — use it instead of
/// `Icons.pets`, whose paw print isn't a bird.
class HenIcon extends StatelessWidget {
  final double? size;
  final Color? color;

  const HenIcon({super.key, this.size, this.color});

  @override
  Widget build(BuildContext context) {
    final iconTheme = IconTheme.of(context);
    final s = size ?? iconTheme.size ?? 24;
    return Image.asset(
      'assets/icons/cute_hen.png',
      width: s,
      height: s,
      color: color ?? iconTheme.color,
      excludeFromSemantics: true,
    );
  }
}
