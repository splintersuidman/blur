#ifndef APPLE_LIBS_INCLUDED
#define APPLE_LIBS_INCLUDED

@import AppKit;
#include <Foundation/Foundation.h>
#include <Cocoa/Cocoa.h>

#endif
#include <unistd.h>

int SetWallpaper(const char *NormalCStringPathToFile, char *NormalCStringMode)
{
    if (access(NormalCStringPathToFile, F_OK) == -1)
        return 1;

    // Convert the C types to the Objective-C types...
    NSString *Mode = [NSString stringWithCString:NormalCStringMode encoding:[NSString defaultCStringEncoding]];
    NSString *PathToFile = [NSString stringWithCString:NormalCStringPathToFile encoding:[NSString defaultCStringEncoding]];

    NSWorkspace *Workspace = [NSWorkspace sharedWorkspace];
    // NSScreen *Screen = [NSScreen screens].firstObject;
    NSScreen *Screen = [NSScreen mainScreen];
    NSMutableDictionary *Options = [[Workspace desktopImageOptionsForScreen:Screen] mutableCopy];

    if ([Mode isEqualToString: @"fill"])
    {
        [Options setObject:[NSNumber numberWithInt:NSImageScaleProportionallyUpOrDown] forKey:NSWorkspaceDesktopImageScalingKey];
        [Options setObject:[NSNumber numberWithBool:YES] forKey:NSWorkspaceDesktopImageAllowClippingKey];
    }

    if ([Mode isEqualToString: @"fit"])
    {
        [Options setObject:[NSNumber numberWithInt:NSImageScaleProportionallyUpOrDown] forKey:NSWorkspaceDesktopImageScalingKey];
        [Options setObject:[NSNumber numberWithBool:NO] forKey:NSWorkspaceDesktopImageAllowClippingKey];
    }

    if ([Mode isEqualToString: @"stretch"])
    {
        [Options setObject:[NSNumber numberWithInt:NSImageScaleAxesIndependently] forKey:NSWorkspaceDesktopImageScalingKey];
        [Options setObject:[NSNumber numberWithBool:YES] forKey:NSWorkspaceDesktopImageAllowClippingKey];
    }

    if ([Mode isEqualToString: @"center"])
    {
        [Options setObject:[NSNumber numberWithInt:NSImageScaleNone] forKey:NSWorkspaceDesktopImageScalingKey];
        [Options setObject:[NSNumber numberWithBool:NO] forKey:NSWorkspaceDesktopImageAllowClippingKey];
    }

    NSError *Error;

    bool Success = [Workspace
        setDesktopImageURL:[NSURL fileURLWithPath:PathToFile]
        forScreen:Screen
        options:Options
        error:&Error];

    if (!Success)
    {
        return 1;
    }

    return 0;
}
