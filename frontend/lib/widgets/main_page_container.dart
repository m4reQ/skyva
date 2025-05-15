import 'package:flutter/material.dart';

class MainPageContainerWidget extends StatelessWidget {
  final double widthFactor;
  final double heightFactor;
  final double padding;
  final double radius;
  final Widget? child;

  const MainPageContainerWidget({
    super.key,
    this.padding = 0,
    this.radius = 0,
    this.child,
    required this.widthFactor,
    required this.heightFactor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Color(0xFFEAE7E7)),
        color: Colors.white,
      ),
      padding: EdgeInsets.all(padding),
      width: MediaQuery.of(context).size.width * widthFactor,
      height: MediaQuery.of(context).size.height * heightFactor,
      alignment: Alignment.center,
      child: child,
    );
  }
}
