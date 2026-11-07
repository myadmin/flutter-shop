import 'package:flutter/material.dart';

class HmHot extends StatefulWidget {
  HmHot({Key? key}) : super(key: key);

  @override
  _HmHotState createState() => _HmHotState();
}

class _HmHotState extends State<HmHot> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      color: Colors.red,
      alignment: Alignment.center,
      child: Text('爆款推荐', style: TextStyle(fontSize: 20, color: Colors.white)),
    );
  }
}
