import 'package:flutter/material.dart';
import 'package:frontend/widgets/bottom_container.dart';
import 'package:localstorage/localstorage.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    var defaultTextStyle = TextStyle(fontFamily: 'Salsa', color: Colors.white);
    var mediaQuery = MediaQuery.of(context);

    return Stack(
      children: [
        Image.asset(
          'assets/homepage_bg.png',
          fit: BoxFit.cover,
          height: double.infinity,
          width: double.infinity,
          alignment: Alignment.center,
        ),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Welcome to Skyva!',
                style: defaultTextStyle.copyWith(fontSize: 35.0),
              ),
              Padding(
                padding: EdgeInsets.only(bottom: mediaQuery.size.height * 0.05),
              ),
            ],
          ),
        ),
        Center(
          child: FractionallySizedBox(
            widthFactor: 0.9,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              spacing: 10.0,
              children: [
                Text(
                  'Breathe Easy, Live Smart.',
                  style: defaultTextStyle.copyWith(fontSize: 23.0),
                ),
                Text(
                  'Track air quality, temperature, humidity\nand CO\u2082 in real time, wherever you are.',
                  style: defaultTextStyle.copyWith(fontSize: 14.0),
                  textAlign: TextAlign.center,
                ),
                TextButton(
                  onPressed: () {
                    localStorage.setItem('isNextRun', 'true');
                    Navigator.pushReplacementNamed(context, 'main');
                  },
                  child: BottomContainer(
                    color: const Color(0xFF87AC85),
                    child: Text(
                      'Let\'s check!',
                      style: defaultTextStyle.copyWith(fontSize: 16.0),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(
                    bottom: mediaQuery.size.height * 0.025,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
