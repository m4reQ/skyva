import 'package:flutter/material.dart';
import 'package:frontend/measurements.dart';
import 'package:frontend/widgets/air_quality_display.dart';
import 'package:frontend/widgets/live_page_header.dart';
import 'package:frontend/widgets/live_page_upper_text.dart';
import 'package:frontend/widgets/measurements_area.dart';
import 'package:localstorage/localstorage.dart';
import 'package:provider/provider.dart';

class LiveView extends StatefulWidget {
  const LiveView({super.key});

  @override
  State<StatefulWidget> createState() => LiveViewState();
}

class LiveViewState extends State<LiveView> {
  bool measurementsCallbackAdded = false;
  Measurements measurements = Measurements.empty();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (!measurementsCallbackAdded) {
      context.watch<MeasurementsService>().registerMeasurementsCallback(
        (measurements) => setState(() {
          this.measurements = measurements;
        }),
      );

      measurementsCallbackAdded = true;
    }

    var defaultTextStyle = TextStyle(
      fontFamily: 'Salsa',
      color: Color(0xFF525050),
    );
    var textStyleLarger = defaultTextStyle.copyWith(fontSize: 32.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      mainAxisSize: MainAxisSize.max,
      children: [
        LivePageUpperText(
          userName: localStorage.getItem('username') ?? 'user',
          textStyle: defaultTextStyle.copyWith(fontSize: 16.0),
        ),
        LivePageHeader(textStyle: textStyleLarger),
        MeasurementsArea(
          outerPadding: (16.0, 10.0),
          innerSpacing: 6.0,
          measurements: measurements,
        ),
        AirQualityDisplay(
          textStyle: defaultTextStyle.copyWith(fontSize: 20.0),
          airQualityIndex: measurements.airQualityIndex,
          airQualityIndexClassification:
              measurements.airQualityIndexClassification,
        ),
      ],
    );
  }
}
