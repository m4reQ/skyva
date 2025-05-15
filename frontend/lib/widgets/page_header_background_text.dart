import 'package:flutter/material.dart';

class PageHeaderBackgroundText extends StatelessWidget {
  final String text;
  final TextStyle? textStyle;

  const PageHeaderBackgroundText({
    super.key,
    required this.text,
    required this.textStyle,
  });

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(25),
      color: const Color(0xFF8FBCBE),
    ),
    padding: EdgeInsets.symmetric(horizontal: 7.0),
    child: Text(
      text,
      style: textStyle?.copyWith(color: Colors.white, height: 1.5),
    ),
  );
}
