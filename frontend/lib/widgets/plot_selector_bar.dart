import 'package:flutter/material.dart';

class PlotSelectorButton extends StatelessWidget {
  final String text;
  final TextStyle? textStyle;
  final GlobalKey textKey;
  final bool isSelected;
  final void Function() onClick;

  const PlotSelectorButton({
    super.key,
    required this.textKey,
    required this.text,
    required this.onClick,
    required this.isSelected,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) => TextButton(
    style: TextButton.styleFrom(
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      minimumSize: Size.zero,
    ),
    onPressed: onClick,
    child: Text(
      text,
      key: textKey,
      style:
          isSelected
              ? textStyle?.copyWith(color: Color(0xFF78B1C4))
              : textStyle,
    ),
  );
}

class PlotSelectorBar extends StatefulWidget {
  final TextStyle? textStyle;
  final int buttonBackgroundAnimationDuration;
  final void Function(String) measurementTypeChanged;

  const PlotSelectorBar({
    super.key,
    this.textStyle,
    required this.buttonBackgroundAnimationDuration,
    required this.measurementTypeChanged,
  });

  @override
  State<StatefulWidget> createState() => PlotSelectorBarState();
}

class PlotSelectorBarState extends State<PlotSelectorBar> {
  static const measurementTypeMap = {
    0: 'particle_concentration',
    1: 'humidity',
    2: 'tvoc_concentration',
    3: 'co2_concentration',
    4: 'temperature',
  };

  final buttonKeys = List<GlobalKey>.generate(5, (_) => GlobalKey());
  final innerTextKeys = List<GlobalKey>.generate(5, (_) => GlobalKey());

  var currentButtonIndex = 0;
  var currentButtonWidth = 0.0;
  var currentButtonHeight = 0.0;
  var currentTextWidth = 0.0;
  var currentButtonLeft = 0.0;
  var currentButtonRight = 0.0;

  void _onButtonClick(int nextButtonIndex) {
    widget.measurementTypeChanged(measurementTypeMap[nextButtonIndex]!);
    setState(() {
      currentButtonIndex = nextButtonIndex;
    });

    final buttonBox =
        buttonKeys[nextButtonIndex].currentContext?.findRenderObject()
            as RenderBox?;
    final innerTextBox =
        innerTextKeys[nextButtonIndex].currentContext?.findRenderObject()
            as RenderBox?;

    if (buttonBox != null && innerTextBox != null) {
      final buttonOffset = buttonBox.localToGlobal(Offset.zero);

      setState(() {
        currentButtonWidth = buttonBox.size.width;
        currentButtonHeight = buttonBox.size.height;
        currentButtonLeft = buttonOffset.dx;
        currentButtonRight = buttonOffset.dx + buttonBox.size.width;
        currentTextWidth = innerTextBox.size.width;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(25),
      border: Border.all(color: Color(0xFFEAE7E7)),
      color: Colors.white,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.25),
          blurRadius: 10,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: Padding(
      padding: EdgeInsets.symmetric(
        vertical: MediaQuery.of(context).size.height * 0.02,
      ),
      child: Stack(
        children: [
          AnimatedPositioned(
            duration: Duration(
              milliseconds: widget.buttonBackgroundAnimationDuration,
            ),
            curve: Curves.easeOut,
            left: currentButtonLeft - currentButtonHeight / 2 - 3.0,
            width: currentButtonWidth,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25.0),
                color: const Color(0xFFD7F6FC),
              ),
              width: currentButtonWidth,
              height: currentButtonHeight,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              PlotSelectorButton(
                key: buttonKeys[0],
                textKey: innerTextKeys[0],
                text: 'PM1.0',
                textStyle: widget.textStyle,
                isSelected: (currentButtonIndex == 0),
                onClick: () {
                  _onButtonClick(0);
                },
              ),
              PlotSelectorButton(
                key: buttonKeys[1],
                textKey: innerTextKeys[1],
                text: 'RH',
                textStyle: widget.textStyle,
                isSelected: (currentButtonIndex == 1),
                onClick: () {
                  _onButtonClick(1);
                },
              ),
              PlotSelectorButton(
                key: buttonKeys[2],
                textKey: innerTextKeys[2],
                text: 'VOCs',
                textStyle: widget.textStyle,
                isSelected: (currentButtonIndex == 2),
                onClick: () {
                  _onButtonClick(2);
                },
              ),
              PlotSelectorButton(
                key: buttonKeys[3],
                textKey: innerTextKeys[3],
                text: 'CO2',
                textStyle: widget.textStyle,
                isSelected: (currentButtonIndex == 3),
                onClick: () {
                  _onButtonClick(3);
                },
              ),
              PlotSelectorButton(
                key: buttonKeys[4],
                textKey: innerTextKeys[4],
                text: 'Temp',
                textStyle: widget.textStyle,
                isSelected: (currentButtonIndex == 4),
                onClick: () {
                  _onButtonClick(4);
                },
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
