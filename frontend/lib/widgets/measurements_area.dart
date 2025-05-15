import 'package:flutter/material.dart';
import 'package:frontend/measurements.dart';
import 'package:frontend/widgets/measurement_tab.dart';

class MeasurementsArea extends StatelessWidget {
  final (double, double) outerPadding;
  final double innerSpacing;

  final Measurements measurements;

  const MeasurementsArea({
    super.key,
    required this.outerPadding,
    required this.innerSpacing,
    required this.measurements,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final smallImageHeight = size.height * 0.06;
    final measurementTabPadding = size.width * 0.01;

    return MeasurementTabBase(
      padding: EdgeInsets.symmetric(
        horizontal: outerPadding.$1,
        vertical: outerPadding.$2,
      ),
      borderRadius: 25,
      child: Column(
        spacing: innerSpacing,
        children: [
          Row(
            spacing: innerSpacing,
            children: [
              MeasurementTab(
                headerText: 'PM1.0',
                valueText: '${measurements.particleConcentration} ppm',
                padding: measurementTabPadding,
                imageAssetName: 'assets/pm_icon.svg',
                imageHeight: smallImageHeight,
              ),
              MeasurementTab(
                headerText: 'Humidity',
                valueText: '${measurements.humidity} %',
                padding: measurementTabPadding,
                imageAssetName: 'assets/humidity_icon.svg',
                imageHeight: smallImageHeight,
              ),
            ],
          ),
          Row(
            spacing: innerSpacing,
            children: [
              MeasurementTab(
                headerText: 'VOCs',
                valueText: '${measurements.tvocConcentration} ppb',
                padding: measurementTabPadding,
                imageAssetName: 'assets/vocs_icon.svg',
                imageHeight: smallImageHeight,
              ),
              MeasurementTab(
                headerText: 'CO2',
                valueText: '${measurements.co2Concentration} ppm',
                padding: measurementTabPadding,
                imageAssetName: 'assets/co2_icon.svg',
                imageHeight: smallImageHeight,
              ),
            ],
          ),
          TemperatureMeasurementTab(
            headerText: 'Temperature',
            valueText: '${measurements.temperature} \u00B0C',
            padding: measurementTabPadding,
            temperatureValue: measurements.temperature,
            imageHeight: smallImageHeight * 2,
            headerFontSize: 16,
            valueFontSize: 20,
          ),
        ],
      ),
    );
  }
}
