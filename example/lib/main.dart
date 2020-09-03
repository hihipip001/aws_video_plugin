import 'dart:async';
import 'dart:typed_data';

import 'package:aws_video_plugin/aws_video_plugin.dart';
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
  Uint8List image;

  VlcPlayerController _videoViewController;
  bool isPlaying = true;
  String qualityName = '';
  String state = '';

  @override
  void initState() {
    _videoViewController = new VlcPlayerController(onInit: () {
      _videoViewController.play();
    });
    _videoViewController.addListener(() {
      if( _videoViewController == null ) return ;
      qualityName = _videoViewController.qualityName;
      state = _videoViewController.playingState.toString();

      print("qualityName=${_videoViewController.qualityName}");
      print("_controller.playingState=${_videoViewController.duration}");
      print("_controller.playingState=${_videoViewController.playingState}");
      setState(() {});
    });



//    Timer.periodic(Duration(seconds: 1), (Timer timer) {
//      String state = _videoViewController2.playingState.toString();
//      if (this.mounted) {
//        setState(() {
//          if (state == "PlayingState.PLAYING" &&
//              sliderValue < _videoViewController2.duration.inSeconds) {
//            sliderValue = _videoViewController2.position.inSeconds.toDouble();
//          }
//        });
//      }
//    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: const Text('Plugin example app'),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.camera),
        onPressed: null,
      ),
      body: Center(
        child: _buildVideo(),
      ),
    );
  }




  _buildVideo(){
    return Stack(
      children: [
        _buildMyWidget(),
        Column(
          children: [
            Text(qualityName,style:TextStyle(fontSize: 50,color:Colors.red)),
            Text(state,style:TextStyle(fontSize: 50,color:Colors.red)),
          ],
        )
      ],
    );



  }

  _buildMyWidget(){
    return VlcPlayer(
      url:
      //"rtmp://114.34.136.103/live/user3",
      "https://ai.casttalk.me:8888/hls/user3.m3u8",
      //"https://fcc3ddae59ed.us-west-2.playback.live-video.net/api/video/v1/us-west-2.893648527354.channel.DmumNckWFTqz.m3u8",
     // "https://032ec9cda8db.us-east-1.playback.live-video.net/api/video/v1/us-east-1.270263555070.channel.nUdevTkpfffI.m3u8?token=eyJhbGciOiJFUzM4NCIsInR5cCI6IkpXVCJ9.eyJhd3M6Y2hhbm5lbC1hcm4iOiJhcm46YXdzOml2czp1cy1lYXN0LTE6MjcwMjYzNTU1MDcwOmNoYW5uZWwvblVkZXZUa3BmZmZJIiwiYXdzOmFjY2Vzcy1jb250cm9sLWFsbG93LW9yaWdpbiI6IjEwLjEwLjEwLjEwIiwiZXhwIjoxNTk5MjM5MDMzfQ.j8XRZC6ezG_XBdh8GjuOcDuaMyz2NYnxbb2CdCJ8iLorUKsNC32JVmExl-pFAkFW2ZBQ9eUSJQ4mlJt0iWewV-D7sPVu3MAL2U0qmzXZcqMrt3gLkODGDNK5TfA_HIzO",
      controller: _videoViewController,
      fit: AwsFit.FitWidth,
      // Play with vlc options
      options: [
        '--quiet',
        '--no-drop-late-frames',
        '--no-skip-frames',
        '--rtsp-tcp'
      ],
      placeholder: Container(
        height: 250.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[CircularProgressIndicator()],
        ),
      ),
    );
  }











}
