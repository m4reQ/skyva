import 'package:flutter/material.dart';
import 'package:frontend/widgets/page_header_background_text.dart';

class LivePageHeader extends StatelessWidget {
  final TextStyle? textStyle;

  const LivePageHeader({super.key, this.textStyle});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Here\'s your', style: textStyle),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PageHeaderBackgroundText(text: 'air quality', textStyle: textStyle),
            Text(' report', style: textStyle),
          ],
        ),
      ],
    );
  }
}
