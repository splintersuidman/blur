#include <Foundation/Foundation.h>

bool ResetWallpaperOnAllSpaces(const char *WallpaperFile)
{
    bool Success = true;

    NSArray<NSScreen *> *Screens = [NSScreen screens];

    for (int i = 0; i < [Screens count]; ++i)
    {
        NSScreen *Screen = Screens[i];
        NSWorkspace *Workspace = [NSWorkspace sharedWorkspace];
        NSMutableDictionary *Options = [[Workspace desktopImageOptionsForScreen:Screen] mutableCopy];
        [Options setObject:[NSNumber numberWithInt:NSImageScaleProportionallyUpOrDown]
            forKey:NSWorkspaceDesktopImageScalingKey];
        [Options setObject:[NSNumber numberWithBool:YES] forKey:NSWorkspaceDesktopImageAllowClippingKey];
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
