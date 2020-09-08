package com.innokit.aws_video_plugin;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.content.Context;
import android.graphics.SurfaceTexture;
import android.net.Uri;
import android.os.Handler;
import android.util.Log;
import android.view.Surface;
import android.view.TextureView;
import android.view.View;

import androidx.annotation.NonNull;


import com.amazonaws.ivs.player.Cue;
import com.amazonaws.ivs.player.Player;
import com.amazonaws.ivs.player.PlayerException;
import com.amazonaws.ivs.player.Quality;

import java.net.CookieHandler;
import java.net.CookieManager;
import java.net.CookiePolicy;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.Map;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.plugin.platform.PlatformView;
import io.flutter.view.TextureRegistry;

class FlutterVideoView implements PlatformView, MethodChannel.MethodCallHandler {


    private Activity activity;
    private FlutterPlugin.FlutterPluginBinding flutterPluginBinding;
    private MethodChannel methodChannel;
    private QueuingEventSink eventSink;
    private EventChannel eventChannel;
    PlayerListener listener;
    private final Context context;

    Player player;
    private TextureView textureView;
    private boolean playerDisposed;


    public FlutterVideoView(Context context,FlutterPlugin.FlutterPluginBinding flutterPluginBinding, Activity activity, int id) {
        this.playerDisposed = false;

        this.context = context;
        this.activity = activity;
        this.flutterPluginBinding = flutterPluginBinding;

        eventSink = new QueuingEventSink();
        eventChannel = new EventChannel(flutterPluginBinding.getBinaryMessenger(), "flutter_video_plugin/getVideoEvents_" + id);
        eventChannel.setStreamHandler(
                new EventChannel.StreamHandler() {
                    @Override
                    public void onListen(Object o, EventChannel.EventSink sink) {
                        eventSink.setDelegate(sink);
                    }
                    @Override
                    public void onCancel(Object o) {
                        eventSink.setDelegate(null);
                    }
                }
        );
        Log.e("TEST","FlutterVideoView init");
        if (player == null) {
            player = Player.Factory.create(activity);
            player.setAutoQualityMode(true);
            listener = new PlayerListener();
        }

        TextureRegistry textures = flutterPluginBinding.getTextureRegistry();
        TextureRegistry.SurfaceTextureEntry textureEntry = textures.createSurfaceTexture();
        textureView = new TextureView(context);
        textureView.setSurfaceTexture(textureEntry.surfaceTexture());
        textureView.setSurfaceTextureListener(new TextureView.SurfaceTextureListener() {

            boolean wasPaused = false;
            @Override
            public void onSurfaceTextureAvailable(SurfaceTexture surface, int width, int height) {

                player.setSurface(new Surface(textureView.getSurfaceTexture()));
                Log.e("TEST","onSurfaceTextureAvailable");
                textureView.forceLayout();
//                if (wasPaused) {
//                    player.play();
//                    wasPaused = false;
//                }
            }

            @Override
            public void onSurfaceTextureSizeChanged(SurfaceTexture surface, int width, int height) {

            }

            @Override
            public boolean onSurfaceTextureDestroyed(SurfaceTexture surface) {

                Log.e("TEST","onSurfaceTextureDestroyed");
//                if( player!=null ){
//                    if (playerDisposed) {
//                        player.pause();
//                        player.release();
//                        player=null;
//                    } else {
//                        player.pause();
//                        wasPaused = true;
//
//                    }
//                }
                return true;
            }

            @Override
            public void onSurfaceTextureUpdated(SurfaceTexture surface) {

            }

        });

        methodChannel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "flutter_video_plugin/getVideoView_" + id);
        methodChannel.setMethodCallHandler(this);
    }

    @Override
    public View getView() {
        return textureView;
    }

    @Override
    public void dispose() {
        Log.e("TEST","dispose()"+player);
        handler.removeCallbacks(runnable);
        if(player!=null ){
            player.pause();
            player.release();
            player=null;
        }
        playerDisposed = true;
    }

    private Handler handler = new Handler();
    private String qualityName;
    Runnable runnable = new Runnable() {
        @Override
        public void run() {

            if( player != null && eventSink!=null ){
                Map<String, Object> event = new HashMap<>();
                event.put("name", "bandwidth");
                event.put("value", player.getBandwidthEstimate());
                eventSink.success(event);
            }
            if( qualityName==null && player!=null && player.getBandwidthEstimate()!=-1 &&
                    player.getQuality()!=null && player.getQualities().size()>1 ){
                Iterator iterator=player.getQualities().iterator();
                while(iterator.hasNext()) {
                    Quality quality=(Quality)iterator.next();
                    if( quality.getBitrate() < player.getBandwidthEstimate() ){
                        if( !quality.getName().equals(player.getQuality().getName()) ){
                            player.setQuality(quality,true);
                        }
                        break ;
                    }
                }
            }
            handler.postDelayed(this,5000);
        }
    };


    // Suppress WrongThread warnings from IntelliJ / Android Studio, because it looks like the advice
    // is wrong and actually breaks the library.
    @SuppressLint("WrongThread")
    @Override
    public void onMethodCall(MethodCall methodCall, @NonNull MethodChannel.Result result) {
        switch (methodCall.method) {
            case "initialize":
                if (textureView == null) {
                    textureView = new TextureView(context);
                }


                handler.removeCallbacks(runnable);
                handler.post(runnable);

                Log.e("TEST","player="+player);
                qualityName = null;
                player.removeListener(listener);
                player.addListener(listener);
                textureView.forceLayout();
                textureView.setFitsSystemWindows(true);
                player.setSurface(new Surface(textureView.getSurfaceTexture()));
                player.setAutoQualityMode(true);
                player.setLiveLowLatencyEnabled(true);
                player.setRebufferToLive(true);

                String initStreamURL = methodCall.argument("url");
                Log.e("TEST","url="+initStreamURL);
                player.load(Uri.parse(initStreamURL));




                //player.play();
                result.success(null);
                break;
            case "dispose":
                this.dispose();
                break;
            case "setPlaybackState":

                String playbackState = methodCall.argument("playbackState");
                if (playbackState == null) result.success(null);

                switch (playbackState) {
                    case "play":
                        textureView.forceLayout();
                        player.play();
                        break;
                    case "pause":
                        player.pause();
                        break;
                }
                result.success(null);
                break;

            case "setVolume":
                int volume = 100;
                volume =  methodCall.argument("volume");
                player.setVolume(volume);
                result.success(null);
                break;
            case "setQuality":
                qualityName =  methodCall.argument("name");

                if( qualityName.equalsIgnoreCase("Auto") ){
                    qualityName = null;
                } else {
                    Iterator iterator=player.getQualities().iterator();
                    while(iterator.hasNext()) {
                        Quality quality=(Quality)iterator.next();
                        if( quality.getName().equals(qualityName) ){
                            player.setQuality(quality);
                            break ;
                        }
                    }
                }
                Log.e("TEST","qualityName="+qualityName);
                result.success(null);
                break;

        }
    }


    public class PlayerListener extends Player.Listener{
        @Override
        public void onCue(@NonNull Cue cue) {
            Log.e("TEST","Cue");
        }

        @Override
        public void onDurationChanged(long duration) {
            Log.e("TEST","onDurationChange");
            if (eventSink == null) return ;
//            Map<String, Object> event = new HashMap<>();
//            event.put("event", "duration");
//            event.put("duration", duration);
//            eventSink.success(event);

        }

        @Override
        public void onStateChanged(@NonNull Player.State state) {
            if( state == Player.State.READY ){
                player.play();

                if( eventSink!=null ){
                    String qualities = "";
                    Iterator iterator=player.getQualities().iterator();
                    while(iterator.hasNext()) {
                        Quality quality=(Quality)iterator.next();
                        qualities += quality.getName()+":"+quality.getBitrate()+"#";
                    }
                    qualities = qualities.substring(0,qualities.length()-1);
                    Map<String, Object> event = new HashMap<>();
                    event.put("name", "setQuality");
                    event.put("value", qualities);
                    eventSink.success(event);

                }


                Log.e("TEST","Size="+player.getQualities().size());
            }

            if (eventSink == null) return ;
            Map<String, Object> event = new HashMap<>();
            switch (state) {
                case BUFFERING:
                    event.put("name", "buffering");
                    eventSink.success(event);
                    break;
                case READY:
                    event.put("name", "ready");
                    eventSink.success(event);

                    break;
                case IDLE:
                    event.put("name", "idle");
                    eventSink.success(event);
                    break;
                case PLAYING:
                    event.put("name", "playing");
                    eventSink.success(event);
                    break;
            }
        }

        @Override
        public void onError(@NonNull PlayerException e) {
            eventSink.error("error", "error.", e);
        }

        @Override
        public void onRebuffering() {

        }

        @Override
        public void onSeekCompleted(long l) {

        }

        @Override
        public void onVideoSizeChanged(int width, int height) {
            if (eventSink == null) return ;
            Map<String, Object> event = new HashMap<>();
            event.put("name", "videoSize");
            event.put("width", width);
            event.put("height", height);
            eventSink.success(event);
        }

        @Override
        public void onQualityChanged(@NonNull Quality quality) {
            if (eventSink == null) return ;
            Map<String, Object> event = new HashMap<>();
            event.put("name", "quality");
            event.put("quality",quality.getName());
            Log.e("TEST","quality="+quality.toString());
            eventSink.success(event);
        }
    }
}
