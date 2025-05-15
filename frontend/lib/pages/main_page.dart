import 'package:flutter/material.dart';
import 'package:frontend/widgets/navigation_bar.dart';

class MainPage extends StatefulWidget {
  final List<Widget> views;
  final int initialViewIndex;
  final double viewWidthFactor;
  final double bottomPaddingHeightfactor;
  final int viewSwitchDurationMs;

  const MainPage({
    super.key,
    required this.views,
    required this.viewWidthFactor,
    this.initialViewIndex = 0,
    required this.bottomPaddingHeightfactor,
    required this.viewSwitchDurationMs,
  });

  @override
  State<StatefulWidget> createState() => MainPageState();
}

class MainPageState extends State<MainPage> {
  late Widget currentView;

  void _setCurrentView(int index) {
    setState(() {
      currentView = widget.views[index];
    });
  }

  @override
  void initState() {
    super.initState();
    _setCurrentView(widget.initialViewIndex);
  }

  @override
  Widget build(BuildContext context) {
    final mediaQueryData = MediaQueryData.fromView(View.of(context));
    final mediaQuery = MediaQuery.of(context);
    return Container(
      padding: EdgeInsets.only(
        top: mediaQueryData.padding.top + 0.01 * mediaQuery.size.height,
        bottom: mediaQueryData.padding.bottom,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Color(0xFFD7EDEE)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: FractionallySizedBox(
            widthFactor: widget.viewWidthFactor,
            child: Padding(
              padding: EdgeInsets.only(
                bottom:
                    MediaQuery.of(context).size.width *
                    widget.bottomPaddingHeightfactor,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: Duration(
                        milliseconds: widget.viewSwitchDurationMs,
                      ),
                      transitionBuilder:
                          (child, animation) => SlideTransition(
                            position: Tween(
                              begin: Offset(-1.0, 0.0),
                              end: const Offset(0.0, 0.0),
                            ).animate(animation),
                            child: FadeTransition(
                              opacity: animation,
                              child: child,
                            ),
                          ),
                      child: currentView,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(
                      top: mediaQuery.size.height * 0.01,
                    ),
                    child: SkyvaNavigationBar(
                      heightFactor: 0.08,
                      onButtonClick: _setCurrentView,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
