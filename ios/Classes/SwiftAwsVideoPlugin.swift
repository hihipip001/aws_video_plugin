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
        self.eventChannelHandler = VLCPlayerEventStreamHandler(player:self.player)
         print("platformView init");
    }
    
    public func view() -> UIView {
        channel.setMethodCallHandler({
            [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            
            guard let self = self else { return }
            
            print(call.arguments);
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
                    self.playerView.player = self.player
                    self.player.autoQualityMode = false
                    self.player.setLiveLowLatencyEnabled(true)
                    self.player.delegate = self.eventChannelHandler
                    self.eventChannelHandler.setQuality(qualityName:nil)
                    
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
                    self.player.pause()
                    self.eventChannelHandler.dispose()
                    result(nil)
                    //self.player.remo()
                    return
                case .setQuality:
                    let qualityName = arguments["name"] as? String
                    if qualityName == "Auto" {
                        self.eventChannelHandler.setQuality(qualityName:nil)
                    } else {
                        self.eventChannelHandler.setQuality(qualityName:qualityName)
                    }
                    result(nil)
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
    
    public var eventSink: FlutterEventSink?
    public var player:IVSPlayer?
    public var qualityName:String?
    private var timer:Timer = Timer()
    
    init(player:IVSPlayer) {
        super.init()
        self.player = player
        self.timer = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(self.timerAction), userInfo: nil, repeats: true)
    }
    
    @objc func timerAction() {
        
        print("timerAction");
        guard let eventSink = self.eventSink else { return }
        guard let player = self.player else { return }
        eventSink(["name": "bandwidth","value": player.bandwidthEstimate])
        guard let quality = player.quality else { return }

        if qualityName != nil && player.qualities.count > 1 {
            for obj in player.qualities {
                if obj.bitrate < player.bandwidthEstimate {
                    if quality.name != obj.name {
                        player.quality = obj
                    }
                   break
                }
                //print(obj.bitrate)
                //print(obj.name)
            }
        }
        
    }
    func dispose(){
        self.timer.invalidate()
    }
    func setQuality(qualityName:String?){
        self.qualityName = qualityName
        guard let player = self.player else { return }
        if self.qualityName != nil {
            for obj in player.qualities {
                if self.qualityName == obj.name {
                    player.quality = obj
                }
            }
        }
    }
    
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
            if let eventSink = self.eventSink {
                var qualities = ""
                guard let mainPlayer = self.player else { return }
                for obj in mainPlayer.qualities {
                    qualities += "\(obj.name):\(obj.bitrate)#"
                }
                print(qualities)
                let range = qualities.startIndex..<qualities.index(before:qualities.endIndex)
                eventSink(["name": "setQuality","value": qualities[range]])
            }
            
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
    case setQuality = "setQuality"

}
