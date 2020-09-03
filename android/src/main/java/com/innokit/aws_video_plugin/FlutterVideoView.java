package com.innokit.aws_video_plugin;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.content.Context;
import android.graphics.SurfaceTexture;
import android.net.Uri;
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

    // Silences player log output.
    private static final boolean DISABLE_LOG_OUTPUT = true;
    private static final int HW_ACCELERATION_AUTOMATIC = -1;
    private static final int HW_ACCELERATION_DISABLED = 0;
    private static final int HW_ACCELERATION_DECODING = 1;
    private static final int HW_ACCELERATION_FULL = 2;

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
                Log.e("TEST","AAAAAAAAAAAAAAAA");
                textureView.forceLayout();
                if (wasPaused) {
                    player.play();
                    wasPaused = false;
                }
            }

            @Override
            public void onSurfaceTextureSizeChanged(SurfaceTexture surface, int width, int height) {

            }

            @Override
            public boolean onSurfaceTextureDestroyed(SurfaceTexture surface) {
                if( player!=null ){
                    if (playerDisposed) {
                        player.pause();
                        player.release();
                        player=null;
                    } else {
                        player.pause();
                        wasPaused = true;

                    }
                }
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
        player.pause();
        player.release();
        player=null;
        playerDisposed = true;
    }


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

                player.removeListener(listener);
                player.addListener(listener);
                textureView.forceLayout();
                textureView.setFitsSystemWindows(true);
                player.setSurface(new Surface(textureView.getSurfaceTexture()));

                String initStreamURL = methodCall.argument("url");
                Log.e("TEST","url="+initStreamURL);
                player.load(Uri.parse(initStreamURL));
                player.play();
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


        }
    }
/*
    @Override
    public void onLoadingChanged(boolean isLoading) {
        HashMap<String, Object> event = new HashMap<>();
        event.put("name", "buffering");
        event.put("value", false);
        eventSink.success(event);
    }

    @Override
    public void onPlayerStateChanged(boolean playWhenReady, int playbackState) {
        if (playbackState == Player.STATE_READY) {
//            if (!setInitialized()) {
//                HashMap<String, Object> event = new HashMap<>();
//                event.put("name", "buffering");
//                event.put("value", false);
//                eventSink.success(event);
//            }
        } else if (playbackState == Player.STATE_ENDED) {
            if (eventSink != null) {
                Map<String, Object> event = new HashMap<>();
                event.put("event", "completed");
                eventSink.success(event);
            }
        } else if (playbackState == Player.STATE_BUFFERING) {
            if (eventSink != null) {
                HashMap<String, Object> event = new HashMap<>();
                event.put("name", "buffering");
                event.put("value", false);
                eventSink.success(event);
            }



        }
    }

    @Override
    public void onVideoSizeChanged(int width, int height, int unappliedRotationDegrees, float pixelWidthHeightRatio) {
//        this.width = width;
//        this.height = height;
//        setInitialized();
    }

*/

    public class PlayerListener extends Player.Listener{
        @Override
        public void onCue(@NonNull Cue cue) {

        }

        @Override
        public void onDurationChanged(long duration) {
            if (eventSink == null) return ;
//            Map<String, Object> event = new HashMap<>();
//            event.put("event", "duration");
//            event.put("duration", duration);
//
//            eventSink.success(event);

        }

        @Override
        public void onStateChanged(@NonNull Player.State state) {
            if( state == Player.State.READY ){
                player.play();
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
            event.put("event", "videoSize");
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
            eventSink.success(event);
        }
    }
}
