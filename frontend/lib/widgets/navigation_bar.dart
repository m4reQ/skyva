import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class NavigationBarButton extends StatelessWidget {
  final Widget image;
  final Color iconColor;
  final double buttonWidth;
  final double buttonHeight;
  final double padding;
  final void Function() onClicked;

  const NavigationBarButton({
    super.key,
    required this.image,
    required this.onClicked,
    required this.iconColor,
    required this.buttonWidth,
    required this.buttonHeight,
    required this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      onPressed: onClicked,
      icon: Container(
        width: buttonWidth,
        height: buttonHeight,
        padding: EdgeInsets.symmetric(vertical: padding),
        child: ShaderMask(
          child: image,
          shaderCallback:
              (bounds) => LinearGradient(
                colors: [iconColor, iconColor],
              ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
        ),
      ),
    );
  }
}

class SkyvaNavigationBar extends StatefulWidget {
  final double heightFactor;
  final void Function(int) onButtonClick;

  const SkyvaNavigationBar({
    super.key,
    required this.heightFactor,
    required this.onButtonClick,
  });

  @override
  State<StatefulWidget> createState() => SkyvaNavigationBarState();
}

class SkyvaNavigationBarState extends State<SkyvaNavigationBar> {
  static const buttonPadding = 3.0;
  static const bgActiveColor = Color(0xFF8FBCBE);
  static const iconActiveColor = Colors.white;
  static const iconInactiveColor = Color(0xFF525050);
  static const buttonAnimationTimeMs = 200;

  var currentPageIndex = 0;
  var buttonBgLeft = 0.0;
  var buttonBgWidth = 0.0;
  var buttonBgHeight = 0.0;
  final buttonKeys = List<GlobalKey>.generate(3, (_) => GlobalKey());

  void adjustButtonBackground(int buttonIndex) {
    final context = buttonKeys[buttonIndex].currentContext;
    if (context != null) {
      final box = context.findRenderObject() as RenderBox;
      final offset = box.localToGlobal(Offset.zero);
      setState(() {
        buttonBgLeft = offset.dx;
        buttonBgWidth = box.size.width;
        buttonBgHeight = box.size.height;
      });
    }
  }

  void _onButtonClick(int selectedButtonIndex) {
    widget.onButtonClick(selectedButtonIndex);
    adjustButtonBackground(selectedButtonIndex);

    setState(() {
      currentPageIndex = selectedButtonIndex;
    });
  }

  @override
  void initState() {
    super.initState();
    adjustButtonBackground(0);
  }

  @override
  Widget build(BuildContext context) {
    final availableSize = MediaQuery.of(context).size;
    final buttonWidth = availableSize.width * 0.2;
    final buttonHeight = availableSize.height * 0.05;
    final buttonsSpacing = availableSize.width * 0.05;

    return Container(
      height: availableSize.height * widget.heightFactor,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25.0),
        color: Colors.white,
      ),
      child: Stack(
        alignment: AlignmentDirectional.centerStart,
        children: [
          AnimatedPositioned(
            duration: Duration(milliseconds: buttonAnimationTimeMs),
            curve: Curves.easeOut,
            left: buttonBgLeft - buttonBgHeight / 2 + buttonPadding,
            width: buttonBgWidth,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25.0),
                color: bgActiveColor,
              ),
              width: buttonWidth,
              height: buttonHeight,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: buttonsSpacing,
            children: [
              NavigationBarButton(
                key: buttonKeys[0],
                padding: buttonPadding,
                buttonWidth: buttonWidth,
                buttonHeight: buttonHeight,
                image: SvgPicture.asset(
                  'assets/icons/live_page_button_icon.svg',
                ),
                onClicked: () => _onButtonClick(0),
                iconColor:
                    currentPageIndex == 0 ? iconActiveColor : iconInactiveColor,
              ),
              NavigationBarButton(
                key: buttonKeys[1],
                padding: buttonPadding,
                buttonWidth: buttonWidth,
                buttonHeight: buttonHeight,
                image: SvgPicture.asset(
                  'assets/icons/plot_page_button_icon.svg',
                ),
                onClicked: () => _onButtonClick(1),
                iconColor:
                    currentPageIndex == 1 ? iconActiveColor : iconInactiveColor,
              ),
              NavigationBarButton(
                key: buttonKeys[2],
                padding: buttonPadding,
                buttonWidth: buttonWidth,
                buttonHeight: buttonHeight,
                image: SvgPicture.asset(
                  'assets/icons/devices_page_button_icon.svg',
                ),
                onClicked: () => _onButtonClick(2),
                iconColor:
                    currentPageIndex == 2 ? iconActiveColor : iconInactiveColor,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
