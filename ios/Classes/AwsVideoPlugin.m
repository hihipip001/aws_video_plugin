#import "AwsVideoPlugin.h"
#if __has_include(<aws_video_plugin/aws_video_plugin-Swift.h>)
#import <aws_video_plugin/aws_video_plugin-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "aws_video_plugin-Swift.h"
#endif

@implementation AwsVideoPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftAwsVideoPlugin registerWithRegistrar:registrar];
}
@end
