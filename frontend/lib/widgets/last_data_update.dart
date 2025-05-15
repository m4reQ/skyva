import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class LastDataUpdate extends StatelessWidget {
  const LastDataUpdate({super.key});

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.25;
    final width = MediaQuery.of(context).size.width * 0.7;
    return Stack(
      alignment: Alignment.center,
      children: [
        Transform.translate(
          offset: Offset(0.0, -(height * 0.025)),
          child: Align(
            alignment: Alignment.centerRight,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Color(0xFFEAE7E7)),
                color: Colors.white,
              ),
              height: height / 2.5,
              width: width,
              alignment: Alignment.center,
              child: Transform.translate(
                offset: Offset(height / 4.8, 0.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Last data update on',
                      style: TextStyle(color: Color(0xFF525050), fontSize: 18),
                    ),
                    Text(
                      'May 15, 2025',
                      style: TextStyle(color: Color(0xFFA4CED6), fontSize: 18),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: SvgPicture.asset(
            'assets/icons/cloud_icon.svg',
            height: height,
          ),
        ),
      ],
    );
  }
}
