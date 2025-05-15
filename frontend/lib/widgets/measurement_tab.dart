import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

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

class MeasurementTab extends StatelessWidget {
  final String imageAssetName;
  final String headerText;
  final String valueText;
  final double padding;
  final bool expanded;
  final double headerFontSize;
  final double valueFontSize;
  final double imageHeight;

  const MeasurementTab({
    super.key,
    required this.imageAssetName,
    required this.imageHeight,
    required this.headerText,
    required this.valueText,
    required this.padding,
    this.expanded = true,
    this.headerFontSize = 10,
    this.valueFontSize = 14,
  });

  @override
  Widget build(BuildContext context) {
    final inner = MeasurementTabBase(
      borderRadius: 18,
      padding: EdgeInsets.all(padding),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SvgPicture.asset(
            imageAssetName,
            height: imageHeight,
            alignment: Alignment.center,
          ),
          Padding(
            padding: EdgeInsets.only(left: 5.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              children: [
                Text(
                  headerText,
                  style: TextStyle(
                    color: Color(0xFF8FBCBE),
                    fontSize: headerFontSize,
                  ),
                ),
                Text(valueText, style: TextStyle(fontSize: valueFontSize)),
              ],
            ),
          ),
        ],
      ),
    );
    return expanded ? Expanded(child: inner) : inner;
  }
}

class TemperatureMeasurementTab extends StatelessWidget {
  final String headerText;
  final String valueText;
  final double padding;
  final num temperatureValue;
  final double headerFontSize;
  final double valueFontSize;
  final double imageHeight;

  const TemperatureMeasurementTab({
    super.key,
    required this.imageHeight,
    required this.headerText,
    required this.valueText,
    required this.padding,
    required this.temperatureValue,
    this.headerFontSize = 10,
    this.valueFontSize = 14,
  });

  @override
  Widget build(BuildContext context) {
    return MeasurementTabBase(
      borderRadius: 18,
      padding: EdgeInsets.all(padding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SvgPicture.asset(
                'assets/temperature_icon.svg',
                alignment: Alignment.center,
                height: imageHeight,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.max,
                children: [
                  Text(
                    headerText,
                    style: TextStyle(
                      color: Color(0xFF8FBCBE),
                      fontSize: headerFontSize,
                    ),
                  ),
                  Text(valueText, style: TextStyle(fontSize: valueFontSize)),
                ],
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(
              right: MediaQuery.of(context).size.width * 0.1,
            ),
            child: switch (temperatureValue) {
              > 30.0 => SvgPicture.asset(
                'assets/icons/temp_high_icon.svg',
                height: imageHeight * 0.75,
              ),
              > 10.0 => SvgPicture.asset(
                'assets/icons/temp_medium_icon.svg',
                height: imageHeight * 0.75,
              ),
              _ => SvgPicture.asset(
                'assets/icons/temp_low_icon.svg',
                height: imageHeight * 0.75,
              ),
            },
          ),
        ],
      ),
    );
  }
}
