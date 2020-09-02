package com.innokit.aws_video_plugin;

import android.app.Activity;
import android.content.Context;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.plugin.common.StandardMessageCodec;
import io.flutter.plugin.platform.PlatformView;
import io.flutter.plugin.platform.PlatformViewFactory;
import io.flutter.view.FlutterNativeView;

class FlutterVideoViewFactory extends PlatformViewFactory {
    PluginRegistry.Registrar registrar;
    BinaryMessenger messenger;
    private Activity activity;
    private FlutterPlugin.FlutterPluginBinding flutterPluginBinding;

    public FlutterVideoViewFactory(Activity activity,FlutterPlugin.FlutterPluginBinding flutterPluginBinding) {
        super(StandardMessageCodec.INSTANCE);
        this.activity = activity;
        this.flutterPluginBinding = flutterPluginBinding;
    }

    @Override
    public PlatformView create(Context context, int viewId, Object args) {
        final FlutterVideoView videoView = new FlutterVideoView(context,flutterPluginBinding, activity, viewId );
        return videoView;
    }



    /*
    @Override
    public PlatformView create(Context context, int i, Object o) {

        if( activity!=null ){

        }

        final FlutterVideoView videoView = new FlutterVideoView(context, registrar, messenger, i);

        registrar.addViewDestroyListener(
                new PluginRegistry.ViewDestroyListener() {
                    @Override
                    public boolean onViewDestroy(FlutterNativeView view) {
                        videoView.dispose();
                        return false; // We are not interested in assuming ownership of the NativeView.
                    }
                }
        );

        return videoView;
    }
     */
}
