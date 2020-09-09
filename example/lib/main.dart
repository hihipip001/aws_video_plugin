import 'dart:async';
import 'dart:typed_data';

import 'package:aws_video_plugin/aws_video_plugin.dart';
import 'package:aws_video_plugin_example/video_widget.dart';
import 'package:flutter/material.dart';



void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(home: MyAppScaffold());
  }
}

class MyAppScaffold extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => MyAppScaffoldState();
}

class MyAppScaffoldState extends State<MyAppScaffold> {
  bool isVideo = true;

  @override
  void initState() {


    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: null,
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.camera),
        onPressed: (){
          setState(() {
            isVideo = !isVideo;
          });
        },
      ),
      body: Center(
        child: isVideo ? VideoWidget(key:Key('${DateTime.now().millisecondsSinceEpoch}')) : Text('Test'),
      ),
    );
  }






}
