import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:frontend/measurements.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class MeasurementsPlot extends StatefulWidget {
  final String currentMeasurementType;

  const MeasurementsPlot({super.key, required this.currentMeasurementType});

  @override
  State<StatefulWidget> createState() => MeasurementsPlotState();
}

class MeasurementsPlotState extends State<MeasurementsPlot> {
  static const dataPeriodTypes = ['Hour', 'Day', 'Month'];

  MeasurementsService? measurementsService;
  var currentDataPeriod = dataPeriodTypes.first;

  @override
  Widget build(BuildContext context) {
    measurementsService ??= context.watch<MeasurementsService>();

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.3,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(43),
          border: Border.all(color: Color(0xFFEAE7E7)),
          gradient: LinearGradient(
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
            colors: const [Colors.white, Color(0xFFE0FAFF)],
            stops: const [0.66, 0.84],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.08),
        child: FutureBuilder(
          future: measurementsService!.fetchMeasurements(10),
          builder:
              (context, snapshot) =>
                  snapshot.hasData
                      ? Stack(
                        children: [
                          LineChart(
                            LineChartData(
                              gridData: FlGridData(show: false),
                              titlesData: FlTitlesData(
                                rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                leftTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      final datetime = DateTime(value.toInt());

                                      return Text(
                                        switch (currentDataPeriod) {
                                          'Day' || 'Hour' => DateFormat(
                                            'Hm',
                                          ).format(datetime),
                                          'Month' => DateFormat(
                                            'MMM d',
                                          ).format(datetime),
                                          _ => 'lol won\'t happen',
                                        },
                                        style: const TextStyle(
                                          fontFamily: 'Salsa',
                                          fontSize: 12.0,
                                          color: Color(0xFFA7A7A7),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              borderData: FlBorderData(show: false),
                              lineBarsData: [
                                LineChartBarData(
                                  isCurved: true,
                                  color: const Color(0xFFA4CED6),
                                  barWidth: 1.5,
                                  dotData: const FlDotData(show: false),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: const [
                                        Color(0xFFCBF7FF),
                                        Colors.white,
                                      ],
                                      stops: const [0.15, 1.0],
                                    ),
                                  ),
                                  spots:
                                      snapshot.data!
                                          .map(
                                            (measurement) => FlSpot(
                                              measurement
                                                  .timestamp
                                                  .millisecondsSinceEpoch
                                                  .toDouble(),
                                              switch (widget
                                                  .currentMeasurementType) {
                                                'particle_concentration' =>
                                                  measurement
                                                      .particleConcentration,
                                                'temperature' =>
                                                  measurement.temperature,
                                                'humidity' =>
                                                  measurement.humidity,
                                                'co2_concentration' =>
                                                  measurement.co2Concentration,
                                                'tvoc_concentration' =>
                                                  measurement.tvocConcentration,
                                                _ => 0.0,
                                              }.toDouble(),
                                            ),
                                          )
                                          .toList(),
                                ),
                              ],
                            ),
                          ),
                          Align(
                            alignment: Alignment.topRight,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(color: Color(0xFFEAE7E7)),
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(
                                      0xFF5E5E5E,
                                    ).withValues(alpha: 0.25),
                                    blurRadius: 6,
                                    offset: Offset(2, 2),
                                  ),
                                ],
                              ),
                              child: DropdownButton(
                                underline: Container(),
                                icon: SvgPicture.asset(
                                  'assets/icons/dropdown_button_icon.svg',
                                ),
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                isDense: true,
                                elevation: 2,
                                value: currentDataPeriod,
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      currentDataPeriod = value;
                                    });
                                  }
                                },
                                items:
                                    dataPeriodTypes
                                        .map(
                                          (value) => DropdownMenuItem(
                                            value: value,
                                            child: Text(value),
                                          ),
                                        )
                                        .toList(),
                              ),
                            ),
                          ),
                        ],
                      )
                      : const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF8FBCBE),
                        ),
                      ),
        ),
      ),
    );
  }
}
