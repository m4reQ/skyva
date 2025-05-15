import 'package:flutter/material.dart';
import 'package:localstorage/localstorage.dart';

class LivePageUpperText extends StatefulWidget {
  final TextStyle? textStyle;
  final String userName;

  const LivePageUpperText({super.key, required this.userName, this.textStyle});

  @override
  State<StatefulWidget> createState() => LivePageUpperTextState();
}

class LivePageUpperTextState extends State<LivePageUpperText> {
  TextEditingController textEditingController = TextEditingController();

  late String userName;

  @override
  void initState() {
    super.initState();

    userName = widget.userName;
  }

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        minimumSize: Size.zero,
      ),
      onPressed: () {
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                content: TextField(
                  controller: textEditingController,
                  decoration: InputDecoration(hintText: 'What\'s your name?'),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text('CANCEL'),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        userName = textEditingController.text;
                        localStorage.setItem(
                          'username',
                          textEditingController.text,
                        );
                      });
                      Navigator.pop(context);
                    },
                    child: Text('OK'),
                  ),
                ],
              ),
        );
      },
      child: Text('Hi, $userName \u{1F44B}', style: widget.textStyle),
    );
  }
}
