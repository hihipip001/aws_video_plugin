import 'dart:async';
import 'dart:typed_data';

import 'package:aws_video_plugin/aws_video_plugin.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


class VideoWidget extends StatefulWidget {
  VideoWidget({Key key}):super(key:key);
  @override
  _VideoWidgetState createState() => _VideoWidgetState();
}

class _VideoWidgetState extends State<VideoWidget> {

  AWSPlayerController _videoViewController;
  String qualityName = '';
  String state = '';
  int bandwidth = -1;

  @override
  void initState() {
    _videoViewController = new AWSPlayerController(onInit: () {
      _videoViewController.play();
    });
    _videoViewController.addListener(() {
      if( _videoViewController == null ) return ;
      qualityName = _videoViewController.qualityName;
      state = _videoViewController.playingState.toString();
      bandwidth = _videoViewController.bandwidth;
      if(mounted) setState(() {});
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
    return _buildVideo();
  }


  _buildVideo(){
    return Column(
      children: [
        Container(
            width: 500,
            height: 300,
            color:Colors.red,
            alignment: Alignment.center,
            child:_buildMyWidget()
        ),

        GestureDetector(
          onTap: (){
            _toggleFullScreen();
          },child:Icon(Icons.event,size:54),
        )
      ],
    );
    return Container(
      height: 200,
      width: 200,
      color:Colors.red,
      alignment: Alignment.center,
      child:_buildMyWidget()
    );

    return Stack(
      children: [
        _buildMyWidget(),
//        Column(
//          children: [
//            Text(qualityName,style:TextStyle(fontSize: 40,color:Colors.red)),
//            Text(state,style:TextStyle(fontSize: 40,color:Colors.red)),
//            Text('$bandwidth',style:TextStyle(fontSize: 40,color:Colors.red)),
//          ],
//        )
      ],
    );



  }
  bool get _isFullScreen => MediaQuery.of(context).orientation == Orientation.landscape;
  void _toggleFullScreen() {
    setState(() {
      if (_isFullScreen) {
        ///显示状态栏，与底部虚拟操作按钮
        SystemChrome.setEnabledSystemUIOverlays(
            [SystemUiOverlay.top, SystemUiOverlay.bottom]);
        SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      } else {
        SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft]);
        SystemChrome.setEnabledSystemUIOverlays([]);
      }

    });
  }

  _buildMyWidget(){
    return AWSPlayer(
      url:
      //"rtmp://114.34.136.103/live/user3",
      //"https://multiplatform-f.akamaihd.net/i/multi/will/bunny/big_buck_bunny_,640x360_400,640x360_700,640x360_1000,950x540_1500,.f4v.csmil/master.m3u8",
      "https://ai.casttalk.me:8888/hls/user3.m3u8",
      //"https://fcc3ddae59ed.us-west-2.playback.live-video.net/api/video/v1/us-west-2.893648527354.channel.DmumNckWFTqz.m3u8",
      // "https://032ec9cda8db.us-east-1.playback.live-video.net/api/video/v1/us-east-1.270263555070.channel.nUdevTkpfffI.m3u8?token=eyJhbGciOiJFUzM4NCIsInR5cCI6IkpXVCJ9.eyJhd3M6Y2hhbm5lbC1hcm4iOiJhcm46YXdzOml2czp1cy1lYXN0LTE6MjcwMjYzNTU1MDcwOmNoYW5uZWwvblVkZXZUa3BmZmZJIiwiYXdzOmFjY2Vzcy1jb250cm9sLWFsbG93LW9yaWdpbiI6IjEwLjEwLjEwLjEwIiwiZXhwIjoxNTk5MjM5MDMzfQ.j8XRZC6ezG_XBdh8GjuOcDuaMyz2NYnxbb2CdCJ8iLorUKsNC32JVmExl-pFAkFW2ZBQ9eUSJQ4mlJt0iWewV-D7sPVu3MAL2U0qmzXZcqMrt3gLkODGDNK5TfA_HIzO",
      controller: _videoViewController,
      fit: AwsFit.FitContain,
      placeholder: Center(
        child: Container(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[CircularProgressIndicator()],
          ),
        )
      ),
    );
  }
}
