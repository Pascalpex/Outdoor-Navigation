//
//  Generated file. Do not edit.
//

// clang-format off

#import "GeneratedPluginRegistrant.h"

#if __has_include(<location/LocationPlugin.h>)
#import <location/LocationPlugin.h>
#else
@import location;
#endif

#if __has_include(<outdoor_navigation/GnssPlugin.h>)
#import <outdoor_navigation/GnssPlugin.h>
#else
@import outdoor_navigation;
#endif

@implementation GeneratedPluginRegistrant

+ (void)registerWithRegistry:(NSObject<FlutterPluginRegistry>*)registry {
  [LocationPlugin registerWithRegistrar:[registry registrarForPlugin:@"LocationPlugin"]];
  [GnssPlugin registerWithRegistrar:[registry registrarForPlugin:@"GnssPlugin"]];
}

@end
