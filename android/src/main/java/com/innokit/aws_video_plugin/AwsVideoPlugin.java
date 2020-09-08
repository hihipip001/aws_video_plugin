package com.innokit.aws_video_plugin;

import androidx.annotation.NonNull;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;

/** AwsVideoPlugin */
public class AwsVideoPlugin implements FlutterPlugin, ActivityAware {
  private FlutterPluginBinding flutterPluginBinding;
  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    this.flutterPluginBinding = flutterPluginBinding;
  }
  public static void registerWith(Registrar registrar) {

  }
  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {

  }
  @Override
  public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
    flutterPluginBinding.getPlatformViewRegistry().registerViewFactory(
            "flutter_video_plugin/getVideoAWSView",
            new FlutterVideoViewFactory(binding.getActivity(),flutterPluginBinding));
  }
  @Override
  public void onDetachedFromActivityForConfigChanges() {
  }
  @Override
  public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
  }

  @Override
  public void onDetachedFromActivity() {

  }
}
