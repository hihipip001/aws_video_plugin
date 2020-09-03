
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

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

class VlcPlayer extends StatefulWidget {
  final AwsFit fit;
  final List<String> options;
  final String url;
  final Widget placeholder;
  final VlcPlayerController controller;

  const VlcPlayer({
    Key key,
    @required this.controller,
    @required this.url,
    this.fit = AwsFit.FitFill,
    this.options,
    this.placeholder,
  });

  @override
  _VlcPlayerState createState() => _VlcPlayerState();
}

class _VlcPlayerState extends State<VlcPlayer>
    with AutomaticKeepAliveClientMixin {
  VlcPlayerController _controller;
  int videoRenderId;
  bool playerInitialized = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
  }


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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return LayoutBuilder(builder: (ctx, constraints){
      return Stack(
        children: [
          Positioned.fromRect(
              rect: _getRect(widget.fit,constraints),
              child: Container(
                child: Offstage(
                  offstage: !playerInitialized,
                  child: _createPlatformView(),
                )
              )),
        ],
      );
    });
      /*
    return AspectRatio(
      aspectRatio: widget.aspectRatio,
      child: Stack(
        children: <Widget>[
          Offstage(
              offstage: playerInitialized,
              child: widget.placeholder ?? Container()),
          Offstage(
            offstage: !playerInitialized,
            child: _createPlatformView(),
          ),
        ],
      ),
    );

     */
  }

  Widget _createPlatformView() {
    if (Platform.isIOS) {
      return UiKitView(
          viewType: "flutter_video_plugin/getVideoView",
          hitTestBehavior: PlatformViewHitTestBehavior.transparent,
          onPlatformViewCreated: _onPlatformViewCreated);
    } else if (Platform.isAndroid) {
      return AndroidView(
          viewType: "flutter_video_plugin/getVideoView",
          hitTestBehavior: PlatformViewHitTestBehavior.transparent,
          onPlatformViewCreated: _onPlatformViewCreated);
    }

    throw new Exception(
        "flutter_vlc_plugin has not been implemented on your platform.");
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

    // Once the controller has clients registered, we're good to register
    // with LibVLC on the platform side.
    if (_controller.hasClients) {
      await _controller._initialize(
        widget.url,
        widget.options,
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

class VlcPlayerController {
  MethodChannel _methodChannel;
  EventChannel _eventChannel;

  int get audioCount => _audioCount;
  int _audioCount = 1;

  VoidCallback _onInit;
  List<VoidCallback> _eventHandlers;

  bool hasClients = false;

  /// Whether or not the player is initialized.
  /// This is set to true when the player has loaded a URL.
  bool get initialized => _initialized;
  bool _initialized = false;

  PlayingState get playingState => _playingState;
  PlayingState _playingState;

  int _position;
  Duration get position =>
      _position != null ? new Duration(milliseconds: _position) : Duration.zero;

  /// The total duration of the content, counted in milliseconds. This is as it
  /// is returned by LibVLC.
  int _duration;
  Duration get duration =>
      _duration != null ? new Duration(milliseconds: _duration) : Duration.zero;

  /// This is the dimensions of the content (height and width) as returned by LibVLC.
  ///
  /// Returns [Size.zero] when the size is null
  /// (i.e. the player is uninitialized.)
  Size get size => _size != null ? _size : Size.zero;
  Size _size;

  String _qualityName;
  String get qualityName =>
      _qualityName != null ? _qualityName : 'UnKnown';



  VlcPlayerController(
      {VoidCallback onInit}) {
    _onInit = onInit;
    _eventHandlers = new List();
  }

  void registerChannels(int id) {
    _methodChannel = MethodChannel("flutter_video_plugin/getVideoView_$id");
    _eventChannel = EventChannel("flutter_video_plugin/getVideoEvents_$id");
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

  Future<void> _initialize(String url,
      [List<String> options]) async {

    await _methodChannel.invokeMethod("initialize", {
      'url': url,
      'options': options ?? []
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
    _methodChannel.invokeMethod("dispose");
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