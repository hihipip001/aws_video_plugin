
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

enum PlayingState { BUFFERING, READY, IDLE, PLAYING, ERROR }
enum AwsFit { FitWidth, FitHeight, FitFill, FitContain }


class Size {
  final int width;
  final int height;
  static const zero = const Size(0, 0);
  const Size(int width, int height)
      : this.width = width,
        this.height = height;
}

class AWSPlayer extends StatefulWidget {
  final AwsFit fit;
  final String url;
  final Widget placeholder;
  final AWSPlayerController controller;

  const AWSPlayer({
    Key key,
    @required this.controller,
    @required this.url,
    this.fit = AwsFit.FitFill,
    this.placeholder,
  });

  @override
  _AWSPlayerState createState() => _AWSPlayerState();
}

class _AWSPlayerState extends State<AWSPlayer>
    with AutomaticKeepAliveClientMixin {
  AWSPlayerController _controller;
  int videoRenderId;
  bool playerInitialized = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
  }

  //計算寬度
  double videoWidth = 1280;
  double videoHeight = 720;
  Rect _getRect(AwsFit fit,constraints){
    double viewWidth = constraints.maxWidth;
    double viewHeight = constraints.maxHeight;
    Rect pos;
    if( fit == AwsFit.FitWidth ){
      double height = videoWidth * viewHeight / viewWidth;
      double dy = (height - videoHeight ) / 2;
      pos = Rect.fromLTWH(0, dy, viewWidth , viewHeight - 2*dy);
    } else if( fit == AwsFit.FitHeight ){
      double width = videoHeight * viewWidth / viewHeight;
      double dx = (width - videoWidth ) / 2;
      pos = Rect.fromLTWH(dx, 0, viewWidth - 2*dx , viewHeight );
    } else if( fit == AwsFit.FitContain ){
      if( viewWidth>=viewHeight )
        return _getRect(AwsFit.FitHeight,constraints);
      else
        return _getRect(AwsFit.FitWidth,constraints);
    } else {
      pos = Rect.fromLTWH(0, 0, viewWidth , viewHeight);
    }
    return pos;
  }

  //品質的下拉式選單
  _itemList(){
    return DropdownButton(
      underline: Container() ,
      isExpanded : true,
      isDense : true,
      iconSize: 24,
      elevation : 0,
      items: widget.controller.qualityModeItems,
      onChanged: (value) {
        setState(() {
          widget.controller.selectQualityMode = value;
          widget.controller.setQuality();
        });
      },
      value: widget.controller.selectQualityMode,
    );
  }

  //下面列表
  _buildItem({width}){
    return Offstage(
      offstage: _hidePlayControl,
      child: AnimatedOpacity(
        // 加入透明度动画
        opacity: _playControlOpacity,
        duration: Duration(milliseconds: 300),
        child: Container(
          width: width,
          height: 60,
          alignment: Alignment.center,
          color:Colors.black26,
          child: Row(
            children: [
              _buildQualitySelect(),
              _buildNowQuality(),
              _buildBandwidth(),
              _buildPlayState(),
            ],
          ),
        )
      )
    );
  }
  //視訊選擇
  _buildQualitySelect() {
    return Container(
      margin: EdgeInsets.fromLTRB(20, 5, 0, 5),
      padding: EdgeInsets.only(left: 10, top: 8, bottom: 8),
      width: 150,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
            color: Colors.white,
            width: 1.0
        ),
      ),
      child: _itemList(),
    );
  }
  _buildNowQuality(){
    return Container(
      margin: EdgeInsets.fromLTRB(20, 0, 0, 0),
      child:Text(widget.controller.qualityName,style:TextStyle(fontSize: 16,color:Colors.white)),
    );
  }
  _buildBandwidth(){
    return Container(
      margin: EdgeInsets.fromLTRB(20, 0, 0, 0),
      child:Text(sizeFormat(widget.controller.bandwidth),style:TextStyle(fontSize: 16,color:Colors.white)),
    );
  }
  String sizeFormat(int size) {
    if( size == -1 ) return '';
    String result = ( size / (1024*1024) ).toStringAsFixed(2);
    return '${result}MB';
  }
  _buildPlayState(){
    return Container(
      margin: EdgeInsets.fromLTRB(20, 0, 0, 0),
      child:Text(widget.controller.playingState.toString(),style:TextStyle(fontSize: 16,color:Colors.white)),
    );
  }


  _buildReloadBtnWidget(){
    if( widget.controller.playingState!=null && widget.controller.playingState==PlayingState.ERROR ){
      return  Center(
        child:GestureDetector(
          onTap: () async{
            await _controller._initialize(
              widget.url,
            );
          },
          child: Icon(Icons.play_circle_outline,size:150,color:Colors.blueAccent),
        ),
      );
    }
    return Container();

  }


  bool _hidePlayControl = true;
  double _playControlOpacity = 0;
  Timer _timer;
  void _togglePlayControl() {
    setState(() {
      if (_hidePlayControl) {
        _hidePlayControl = false;
        _playControlOpacity = 1;
        _startPlayControlTimer();
      } else {
        /// 如果显示就隐藏
        if (_timer != null) _timer.cancel();
        _playControlOpacity = 0;
        Future.delayed(Duration(milliseconds: 500)).whenComplete(() {
          _hidePlayControl = true; // 延迟500ms(透明度动画结束)后，隐藏
        });
      }
    });
  }
  void _startPlayControlTimer() {
    if (_timer != null) _timer.cancel();
    _timer = Timer(Duration(seconds: 10), () {
      setState(() {
        _playControlOpacity = 0;
        Future.delayed(Duration(milliseconds: 500)).whenComplete(() {
          _hidePlayControl = true;
        });
      });
    });
  }





    @override
  Widget build(BuildContext context) {
    super.build(context);
    return LayoutBuilder(builder: (ctx, constraints){
      return Stack(
        children: [
          widget.placeholder ?? Container(),
          Positioned.fromRect(
              rect: _getRect(widget.fit,constraints),
              child: Container(
                child: Offstage(
                  offstage: !playerInitialized,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: (){
                      _togglePlayControl();
                    },
                    child: _createPlatformView()
                  ),
                )
              )),
          Positioned(
            bottom: 0,left:0,
            child:  _buildItem(width:constraints.maxWidth)
          ),
          _buildReloadBtnWidget(),
        ],
      );
    });
  }



  Widget _createPlatformView() {
    if (Platform.isIOS) {
      return UiKitView(
          viewType: "flutter_video_plugin/getVideoAWSView",
          hitTestBehavior: PlatformViewHitTestBehavior.transparent,
          onPlatformViewCreated: _onPlatformViewCreated);
    } else if (Platform.isAndroid) {
      return AndroidView(
          viewType: "flutter_video_plugin/getVideoAWSView",
          hitTestBehavior: PlatformViewHitTestBehavior.transparent,
          onPlatformViewCreated: _onPlatformViewCreated);
    }

    throw new Exception(
        "flutter_aws_plugin has not been implemented on your platform.");
  }

  void _onPlatformViewCreated(int id) async {
    _controller = widget.controller;
    _controller.registerChannels(id);

    _controller.addListener(() {
      if (!mounted) return;
      if (playerInitialized != _controller.initialized)
        setState(() {
          playerInitialized = _controller.initialized;
        });
    });

    if (_controller.hasClients) {
      await _controller._initialize(
        widget.url,
      );
    }


  }

  @override
  void deactivate() {
    _controller.dispose();
    playerInitialized = false;
    super.deactivate();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class AWSPlayerController {
  MethodChannel _methodChannel;
  EventChannel _eventChannel;

  VoidCallback _onInit;
  List<VoidCallback> _eventHandlers;

  bool hasClients = false;

  bool get initialized => _initialized;
  bool _initialized = false;

  PlayingState get playingState => _playingState;
  PlayingState _playingState;

  int _position;
  Duration get position =>
      _position != null ? new Duration(milliseconds: _position) : Duration.zero;

  int _duration;
  Duration get duration =>
      _duration != null ? new Duration(milliseconds: _duration) : Duration.zero;

  Size get size => _size != null ? _size : Size.zero;
  Size _size;

  String _qualityName;
  String get qualityName => _qualityName != null ? _qualityName : 'UnKnown';

  int _bandwidth;
  int get bandwidth => _bandwidth != null ? _bandwidth : -1;

  //品質選擇
  List<QualityMode> qualityMode = [];
  List<DropdownMenuItem> qualityModeItems = [];
  int selectQualityMode = 0;



  AWSPlayerController(
      {VoidCallback onInit}) {
    _onInit = onInit;
    _eventHandlers = new List();
  }

  void registerChannels(int id) {
    _methodChannel = MethodChannel("flutter_video_plugin/getVideoAWSView_$id");
    _eventChannel = EventChannel("flutter_video_plugin/getVideoAWSEvents_$id");
    hasClients = true;
  }

  void addListener(VoidCallback listener) {
    _eventHandlers.add(listener);
  }

  void removeListener(VoidCallback listener) {
    _eventHandlers.remove(listener);
  }

  void clearListeners() {
    _eventHandlers.clear();
  }

  void _fireEventHandlers() {
    _eventHandlers.forEach((handler) => handler());
  }

  Future<void> _initialize(String url) async {
    await _methodChannel.invokeMethod("initialize", {
      'url': url,
    });
    _position = 0;

    _eventChannel.receiveBroadcastStream().listen((event) {
      switch (event['name']) {
        case 'duration':
          if (event['duration'] != null) _duration = event['duration'];
          _fireEventHandlers();
          break;
        case 'buffering':
          _playingState = PlayingState.BUFFERING;
          _fireEventHandlers();
          break;
        case 'ready':
          _playingState = PlayingState.READY;
          _fireEventHandlers();
          break;
        case 'idle':
          _playingState = PlayingState.IDLE;
          _fireEventHandlers();
          break;
        case 'playing':
          _playingState = PlayingState.PLAYING;
          _fireEventHandlers();
          break;
        case 'quality':
          _qualityName = event['quality'];
          _fireEventHandlers();
          break;
        case 'setQuality': //設定有多少瀏覽品質
          String _value = event['value'];
          qualityMode = [];
          qualityModeItems = [];
          qualityMode.add(QualityMode('Auto', -1));
          qualityModeItems.add(DropdownMenuItem(value: 0,child: Text("Auto",),));
          int i=1;
          for( var obj in _value.split('#') ){
            var name = obj.split(':')[0];
            qualityMode.add(QualityMode(name, int.parse(obj.split(':')[1])));
            qualityModeItems.add(DropdownMenuItem(value: i++,child: Text(name,),));
          }
          print("qua=${qualityMode.length}");

          _fireEventHandlers();
          break;
        case 'bandwidth':

          _bandwidth = event['value'];
          _fireEventHandlers();
          break;
        case 'videoSize':
          print('width=${event['width']}');
          print('height=${event['height']}');
          _fireEventHandlers();
          break;
      }
    }).onError((e) {
      _playingState = PlayingState.ERROR;
      _fireEventHandlers();
    });

    _initialized = true;
    _fireEventHandlers();
    _onInit();
  }

  Future<void> setQuality() async {
    QualityMode quality = qualityMode[selectQualityMode];
    await _methodChannel
        .invokeMethod("setQuality", {'name': quality.name});
  }


  Future<void> play() async {
    await _methodChannel
        .invokeMethod("setPlaybackState", {'playbackState': 'play'});
  }

  Future<void> pause() async {
    await _methodChannel
        .invokeMethod("setPlaybackState", {'playbackState': 'pause'});
  }



  Future<void> setVolume(int volume) async {
    await _methodChannel.invokeMethod("setVolume", {'volume': volume});
  }


  void dispose() {
    _methodChannel.invokeMethod("dispose", {'close': true});
  }

}



/*
import 'dart:async';

import 'package:flutter/services.dart';

class AwsVideoPlugin {
  static const MethodChannel _channel =
      const MethodChannel('aws_video_plugin');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }
}
*/



class QualityMode{
  String name;
  int bandwidth;
  QualityMode(this.name,this.bandwidth);
}








