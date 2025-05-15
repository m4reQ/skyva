import 'package:flutter/material.dart';
import 'package:frontend/widgets/last_data_update.dart';
import 'package:frontend/widgets/measurements_plot.dart';
import 'package:frontend/widgets/plot_page_header.dart';
import 'package:frontend/widgets/plot_selector_bar.dart';

class PlotView extends StatefulWidget {
  const PlotView({super.key});

  @override
  State<StatefulWidget> createState() => PlotViewState();
}

class PlotViewState extends State<PlotView> {
  String currentMeasurementType = 'particle_concentration';

  @override
  Widget build(BuildContext context) {
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
        Text(
          'Are you still here? \u{1F525}',
          style: defaultTextStyle.copyWith(fontSize: 16.0, color: Colors.black),
        ),
        PlotPageHeader(textStyle: textStyleLarger),
        PlotSelectorBar(
          textStyle: defaultTextStyle,
          buttonBackgroundAnimationDuration: 200,
          measurementTypeChanged:
              (type) => setState(() {
                currentMeasurementType = type;
              }),
        ),
        MeasurementsPlot(currentMeasurementType: currentMeasurementType),
        LastDataUpdate(),
      ],
    );
  }
}
