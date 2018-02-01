#include <Foundation/Foundation.h>

bool ResetWallpaperOnAllSpaces(const char *WallpaperFile, const char *Mode)
{
    bool Success = true;

    NSArray<NSScreen *> *Screens = [NSScreen screens];

    for (int i = 0; i < [Screens count]; ++i)
    {
        NSScreen *Screen = Screens[i];
        NSWorkspace *Workspace = [NSWorkspace sharedWorkspace];
        NSMutableDictionary *Options = [[Workspace desktopImageOptionsForScreen:Screen] mutableCopy];

        if (strcmp(Mode, "fill") == 0)
        {
            [Options setObject:[NSNumber numberWithInt:NSImageScaleProportionallyUpOrDown] forKey:NSWorkspaceDesktopImageScalingKey];
            [Options setObject:[NSNumber numberWithBool:YES] forKey:NSWorkspaceDesktopImageAllowClippingKey];
        }

        if (strcmp(Mode, "fit") == 0)
        {
            [Options setObject:[NSNumber numberWithInt:NSImageScaleProportionallyUpOrDown] forKey:NSWorkspaceDesktopImageScalingKey];
            [Options setObject:[NSNumber numberWithBool:NO] forKey:NSWorkspaceDesktopImageAllowClippingKey];
        }

        if (strcmp(Mode, "stretch") == 0)
        {
            [Options setObject:[NSNumber numberWithInt:NSImageScaleAxesIndependently] forKey:NSWorkspaceDesktopImageScalingKey];
            [Options setObject:[NSNumber numberWithBool:YES] forKey:NSWorkspaceDesktopImageAllowClippingKey];
        }

        if (strcmp(Mode, "center") == 0)
        {
            [Options setObject:[NSNumber numberWithInt:NSImageScaleNone] forKey:NSWorkspaceDesktopImageScalingKey];
            [Options setObject:[NSNumber numberWithBool:NO] forKey:NSWorkspaceDesktopImageAllowClippingKey];
        }

        NSError *Error;

        NSString *PathToFile = [NSString
            stringWithCString:WallpaperFile
            encoding:[NSString defaultCStringEncoding]];
        bool Result = [Workspace
            setDesktopImageURL:[NSURL fileURLWithPath:PathToFile]
            forScreen:Screen
            options:Options
            error:&Error];

        if (!Result)
            Success = false;
    }

    return Success;
}
