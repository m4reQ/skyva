import 'package:flutter/material.dart';

class BottomContainer extends StatelessWidget {
  final Widget? child;
  final Color? color;

  const BottomContainer({super.key, this.child, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      height: MediaQuery.of(context).size.height * 0.08,
      width: MediaQuery.of(context).size.width * 0.9,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        color: color,
      ),
      child: child,
    );
  }
}
