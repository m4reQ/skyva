import 'package:flutter/material.dart';
import 'package:frontend/widgets/page_header_background_text.dart';

class PlotPageHeader extends StatelessWidget {
  final TextStyle? textStyle;

  const PlotPageHeader({super.key, this.textStyle});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Click the ', style: textStyle),
            PageHeaderBackgroundText(text: 'button', textStyle: textStyle),
            Text(' below', style: textStyle),
          ],
        ),
        Text('and check cool graphs', style: textStyle),
      ],
    );
  }
}
