import Flutter
import UIKit
import AmazonIVSPlayer

public class SwiftAwsVideoPlugin: NSObject, FlutterPlugin {
    
    private var factory: VLCViewFactory
    public init(with registrar: FlutterPluginRegistrar) {
        self.factory = VLCViewFactory(withRegistrar: registrar)
        registrar.register(factory, withId: "flutter_video_plugin/getVideoView")
    }
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        registrar.addApplicationDelegate(SwiftAwsVideoPlugin(with: registrar))
    }
    
}


public class VLCView: NSObject, FlutterPlatformView {
    
    
    private var registrar: FlutterPluginRegistrar
    private var channel: FlutterMethodChannel
    private var eventChannel: FlutterEventChannel
    private var player: IVSPlayer
    private var playerView: IVSPlayerView
    private var eventChannelHandler: VLCPlayerEventStreamHandler
    private var aspectSet = false
    
    
    
    public init(withFrame frame: CGRect, withRegistrar registrar: FlutterPluginRegistrar, withId id: Int64){
        self.registrar = registrar
        self.playerView = IVSPlayerView()
        //self.hostedView.addSubview(self.playerView)
        self.player = IVSPlayer()
        self.channel = FlutterMethodChannel(name: "flutter_video_plugin/getVideoView_\(id)", binaryMessenger: registrar.messenger())
        self.eventChannel = FlutterEventChannel(name: "flutter_video_plugin/getVideoEvents_\(id)", binaryMessenger: registrar.messenger())
        self.eventChannelHandler = VLCPlayerEventStreamHandler()
    }
    
    public func view() -> UIView {
        channel.setMethodCallHandler({
            [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            
            guard let self = self else { return }
            
            if let arguments = call.arguments as? Dictionary<String,Any>
            {
                switch(FlutterMethodCallOption(rawValue: call.method)){
                case .initialize:
                    
                    guard let  urlString = arguments["url"] as? String, let url = URL(string: urlString) else {
                        result(FlutterError(code: "500",
                                            message: "Url is need to initialization",
                                            details: nil)
                        )
                        return
                    }
                    
                    self.player.load(url)
                    self.playerView.player = self.player;
                    self.player.delegate = self.eventChannelHandler
                    result(nil)
                    return
                case .setPlaybackState:
                    let playbackState = arguments["playbackState"] as? String
                    
                    if (playbackState == "play") {
                        self.player.play()
                    } else if (playbackState == "pause") {
                        self.player.pause()
                    }
                    result(nil)
                    return
                case .dispose:
                    //self.player.remo()
                    return

                case .setVolume:
                    let setVolume = arguments["volume"] as? Float
                    self.player.volume = setVolume ?? 100.0
                    result(nil)
                    return

                default:
                    result(FlutterMethodNotImplemented)
                    return
                }
            } else {
                result(FlutterMethodNotImplemented)
                return
            }
            
        })
        
        eventChannel.setStreamHandler(eventChannelHandler)
        return playerView
        
    }
    
    
    
}

class VLCPlayerEventStreamHandler:NSObject, FlutterStreamHandler, IVSPlayer.Delegate {
    
    private var eventSink: FlutterEventSink?
    
    
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }
    
    func player(_ player: IVSPlayer, didChangeState state: IVSPlayer.State) {
        if state == .ready {
            player.play()
        }
        guard let eventSink = self.eventSink else { return }
        if state == .buffering {
            eventSink(["name": "buffering"])
        } else if state == .ready {
            eventSink(["name": "ready"])
        } else if state == .idle {
            eventSink(["name": "idle"])
        } else if state == .playing {
            eventSink(["name": "playing"])
        }
    }
    
    func player(_ player: IVSPlayer, didFailWithError error: Error) {
        guard let eventSink = self.eventSink else { return }
        eventSink(FlutterError(code: "500",
                               message: "Player State got an error",
                               details: nil)
        )
    }
    func player(_ player: IVSPlayer, didChangeQuality quality: IVSQuality?) {
        guard let eventSink = self.eventSink else { return }
        eventSink([
            "name": "quality",
            "quality": quality?.name
        ])
    }
    
    func player(_ player: IVSPlayer, didChangeVideoSize videoSize: CGSize) {
        guard let eventSink = self.eventSink else { return }
        eventSink([
            "name": "videoSize",
            "width": videoSize.width,
            "height": videoSize.height
        ])
    }
    
    

    
    
    
    /*
    func mediaPlayerStateChanged(_ aNotification: Notification?) {
        
        guard let eventSink = self.eventSink else { return }
        
        let player = aNotification?.object as? VLCMediaPlayer
        let media = player?.media
        let tracks: [Any] = media?.tracksInformation ?? [""]  //[Any]
        var track:NSDictionary
        
        var ratio = Float(0.0)
        var height = 0
        var width =  0
        
        //subtitle
        let audioCount =  player?.numberOfAudioTracks ?? 0
        let activeAudioTracks =  player?.audioChannel ?? 0
        let spuCount =  player?.numberOfSubtitlesTracks ?? 0
        let activeSpu = player?.currentVideoSubTitleIndex ?? 0
        
        
        if player?.currentVideoTrackIndex != -1 {
            if (player?.currentVideoTrackIndex) != nil {
                track =  tracks[0] as! NSDictionary
                height = (track["height"] as? Int ) ?? 0
                width = (track["width"] as? Int) ?? 0
                
                if height != 0 && width != 0  {
                    ratio = Float(width / height)
                }
                
            }
            
        }
        
        switch player?.state {
            
        case .esAdded, .buffering, .opening:
            return
        case .playing:
            eventSink([
                "name": "buffering",
                "value": NSNumber(value: false)
            ])
            if let value = media?.length.value {
                eventSink([
                    "name": "playing",
                    "value": NSNumber(value: true),
                    "ratio": NSNumber(value: ratio),
                    "height": height,
                    "width": width,
                    "length": value,
                    "audioCount": audioCount,
                    "activeAudioTracks": activeAudioTracks,
                    "spuCount": spuCount,
                    "activeSpu": activeSpu
                    
                ])
            }
            return
        case .ended:
            eventSink([
                "name": "ended"
            ])
            eventSink([
                "name": "playing",
                "value": NSNumber(value: false),
                "reason": "EndReached"
            ])
            return
        case .error:
            eventSink(FlutterError(code: "500",
                                   message: "Player State got an error",
                                   details: nil)
            )
            
            return
            
        case .paused, .stopped:
            eventSink([
                "name": "buffering",
                "value": NSNumber(value: false)
            ])
            eventSink([
                "name": "playing",
                "value": NSNumber(value: false)
            ])
            return
        default:
            break
        }
 
        
    }
    
    func mediaPlayerTimeChanged(_ aNotification: Notification!) {
        
        let player = aNotification?.object as? VLCMediaPlayer
        
        if let value = player?.time.value {
            eventSink?([
                "name": "timeChanged",
                "value": value,
                "speed": NSNumber(value: player?.rate ?? 1.0)
            ])
        }
        
        
    }
 */
}


public class VLCViewFactory: NSObject, FlutterPlatformViewFactory {
    
    private var registrar: FlutterPluginRegistrar?
    
    public init(withRegistrar registrar: FlutterPluginRegistrar){
        super.init()
        self.registrar = registrar
    }
    
    public func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
        //Can pass args if necessary for intialization. For now default to empty Rect.
        //let dictionary =  args as! Dictionary<String, Double>
        return VLCView(withFrame: CGRect(x: 0, y: 0, width:  0, height:  0), withRegistrar: registrar!,withId: viewId)
    }
    
    public func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec(readerWriter: FlutterStandardReaderWriter())
    }
}


enum FlutterMethodCallOption :String {
    case initialize = "initialize"
    case setPlaybackState = "setPlaybackState"
    case dispose = "dispose"
    case changeURL = "changeURL"
    case getSnapshot = "getSnapshot"
    case setPlaybackSpeed = "setPlaybackSpeed"
    case setTime = "setTime"
    case setVolume = "setVolume"
    case changeSound = "changeSound"
    case changeSubtitle = "changeSubtitle"
    case addSubtitle = "addSubtitle"
}
