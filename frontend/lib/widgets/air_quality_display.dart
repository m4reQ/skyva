import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class AirQualityDisplay extends StatefulWidget {
  final TextStyle textStyle;
  final num airQualityIndex;
  final String airQualityIndexClassification;

  const AirQualityDisplay({
    super.key,
    required this.textStyle,
    required this.airQualityIndex,
    required this.airQualityIndexClassification,
  });

  @override
  State<StatefulWidget> createState() => AirQualityDisplayState();
}

class AirQualityDisplayState extends State<AirQualityDisplay> {
  final _arrowImageKey = GlobalKey();

  num _lerp(num a, num b, num t) => (a * (1.0 - t) + b * t);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Image.asset('assets/quality_meter.png'),
            Transform.translate(
              offset: Offset(
                _lerp(0.0, -7.5, widget.airQualityIndex).toDouble(),
                (math.sin(widget.airQualityIndex * math.pi).abs() * 4.5) - 1.0,
              ),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Transform.rotate(
                  angle: (math.pi * widget.airQualityIndex) - math.pi / 2,
                  alignment: Alignment.bottomCenter,
                  child: SvgPicture.asset(
                    'assets/arrow.svg',
                    key: _arrowImageKey,
                  ),
                ),
              ),
            ),
          ],
        ),
        Text(widget.airQualityIndexClassification, style: widget.textStyle),
      ],
    );
  }
}
