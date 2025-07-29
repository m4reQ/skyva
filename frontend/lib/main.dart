import 'package:flutter/material.dart';
import 'package:frontend/measurements.dart';
import 'package:frontend/pages/home_page.dart';
import 'package:frontend/pages/main_page.dart';
import 'package:frontend/views/live_view.dart';
import 'package:frontend/views/plot_view.dart';
import 'package:localstorage/localstorage.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initLocalStorage();

  runApp(
    MultiProvider(
      providers: [
        Provider(
          create:
              (_) => MeasurementsService(
                apiHost: '192.168.123.77',
                apiPort: 8000,
                mqttHost: '192.168.123.77',
                mqttPort: 1883,
                mqttClientName: 'SkyvaAppMQTTClient',
              ),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Skyva',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        fontFamily: 'Salsa',
      ),
      initialRoute: localStorage.getItem('isNextRun') == null ? '/' : 'main',
      routes: {
        '/': (_) => const HomePage(),
        'main':
            (_) => const MainPage(
              views: [LiveView(), PlotView(), Text('chuj')],
              viewWidthFactor: 0.9,
              bottomPaddingHeightfactor: 0.02,
              viewSwitchDurationMs: 300,
            ),
      },
    );
  }
}
