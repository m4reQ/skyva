import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:http/http.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MeasurementsService {
  late MqttServerClient _mqttClient;

  final String apiHost;
  final int apiPort;

  List<void Function(Measurements)> mqttMeasurementsCallbacks = [];

  MeasurementsService({
    required this.apiHost,
    required this.apiPort,
    required String mqttHost,
    required int mqttPort,
    required String mqttClientName,
  }) {
    _mqttClient =
        MqttServerClient.withPort(mqttHost, mqttClientName, mqttPort)
          ..keepAlivePeriod = 30
          ..autoReconnect = true
          ..onConnected = (() {
            _mqttClient.subscribe('measurements_public', MqttQos.atLeastOnce);
            _mqttClient.updates?.listen((data) {
              for (var message in data) {
                if (message.topic == 'measurements_public') {
                  final measurements = Measurements.fromJsonString(
                    utf8.decode(
                      (message.payload as MqttPublishMessage).payload.message,
                    ),
                  );

                  for (var callback in mqttMeasurementsCallbacks) {
                    callback(measurements);
                  }
                }
              }
            });
          })
          ..logging(on: true);

    unawaited(
      _mqttClient.connect().onError((e, stacktrace) {
        log('Failed to connect to MQTT server: $e', stackTrace: stacktrace);
        return null;
      }),
    );
  }

  void registerMeasurementsCallback(void Function(Measurements) callback) {
    mqttMeasurementsCallbacks.add(callback);
  }

  void unregisterMeasurementsCallback(void Function(Measurements) callback) {
    mqttMeasurementsCallbacks.remove(callback);
  }

  Future<List<Measurements>> fetchMeasurements(int limit) {
    return get(
      Uri.parse('http://$apiHost:$apiPort/measurements?limit=$limit'),
    ).then(
      (response) =>
          response.statusCode == HttpStatus.ok
              ? Future.value(
                ((jsonDecode(response.body)
                            as Map<String, dynamic>)['measurements']
                        as List<dynamic>)
                    .map((value) => Measurements.fromJson(value))
                    .toList(),
              )
              : Future.error('Failed to fetch measurements list'),
    );
  }
}

class Measurements {
  final DateTime timestamp;
  final num airQualityIndex;
  final String airQualityIndexClassification;
  final num particleConcentration;
  final num temperature;
  final num humidity;
  final num co2Concentration;
  final num tvocConcentration;

  const Measurements({
    required this.timestamp,
    required this.airQualityIndex,
    required this.airQualityIndexClassification,
    required this.particleConcentration,
    required this.temperature,
    required this.humidity,
    required this.co2Concentration,
    required this.tvocConcentration,
  });

  static Measurements empty() => Measurements(
    timestamp: DateTime.now(),
    airQualityIndex: 0.0,
    airQualityIndexClassification: 'Good',
    particleConcentration: 0.0,
    temperature: 0.0,
    humidity: 0.0,
    co2Concentration: 0,
    tvocConcentration: 0,
  );

  static Measurements fromJsonString(String json) =>
      Measurements.fromJson(JsonDecoder().convert(json));

  static Measurements fromJson(dynamic json) => Measurements(
    timestamp:
        json['timestamp'] == null
            ? DateTime.now()
            : DateTime.parse(json['timestamp']),
    airQualityIndex: json['aqi'] ?? 0.0,
    airQualityIndexClassification: json['aqi_classification'] ?? '',
    particleConcentration: json['particle_concentration'] ?? 0.0,
    temperature: json['temperature'] ?? 0.0,
    humidity: json['humidity'] ?? 0.0,
    co2Concentration: json['co2_concentration'] ?? 0,
    tvocConcentration: json['tvoc_concentration'] ?? 0,
  );
}
