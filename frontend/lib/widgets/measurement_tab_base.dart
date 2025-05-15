import 'package:flutter/material.dart';

class MeasurementTabBase extends StatelessWidget {
  final Widget? child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;

  const MeasurementTabBase({
    super.key,
    this.child,
    this.padding,
    required this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: Color(0xFFEAE7E7)),
        color: Colors.white,
      ),
      padding: padding,
      child: Center(child: child),
    );
  }
}
