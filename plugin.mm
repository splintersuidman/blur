@import AppKit;
#include <Cocoa/Cocoa.h>
#include <Foundation/Foundation.h>
#include <stdlib.h>
#include <string.h>
#include <sqlite3.h>

#include "../../api/plugin_api.h"
#include "../../common/accessibility/application.h"
#include "../../common/accessibility/window.h"
#include "../../common/config/cvar.h"

#include "../../common/config/cvar.cpp"

#include "blurwallpaper.h"

#define internal static

internal const char *PluginName = "blur";
internal const char *PluginVersion = "0.1.0";
internal chunkwm_api API;

internal int SetWallpaper (const char *NormalCStringPathToFile, char *NormalCStringMode);
internal char *GetPathToWallpaper (void);
internal int NumberOfWindowsOnSpace (void);

internal float Sigma = 0.0;
internal char *CurrentWallpaperPath = NULL;
internal const char *TempWallpaperPath = NULL;
internal char *WallpaperMode = NULL;

inline bool
StringsAreEqual(const char *A, const char *B)
{
    bool Result = (strcmp(A, B) == 0);
    return Result;
}

/*
 * NOTE(koekeishiya):
 * parameter: const char *Node
 * parameter: void *Data
 * return: bool
 * */
PLUGIN_MAIN_FUNC(PluginMain)
{
    if (StringsAreEqual(Node, "chunkwm_export_application_launched") ||
        StringsAreEqual(Node, "chunkwm_export_application_activated") ||
        StringsAreEqual(Node, "chunkwm_export_application_unhidden") ||
        StringsAreEqual(Node, "chunkwm_export_window_created") ||
        StringsAreEqual(Node, "chunkwm_export_window_deminimize"))
    {
        SetWallpaper(TempWallpaperPath, WallpaperMode);

        return true;
    }
    else if (
        StringsAreEqual(Node, "chunkwm_export_application_terminated") ||
        StringsAreEqual(Node, "chunkwm_export_application_deactivated") ||
        StringsAreEqual(Node, "chunkwm_export_application_hidden") ||
        StringsAreEqual(Node, "chunkwm_export_space_changed") ||
        StringsAreEqual(Node, "chunkwm_export_window_destroyed") ||
        StringsAreEqual(Node, "chunkwm_export_window_minimized"))
    {
        int NumberOfWindows = NumberOfWindowsOnSpace();
        fprintf(stderr, "Number of windows: %d\n", NumberOfWindows);
        if (NumberOfWindows == 0)
        {
            SetWallpaper(CurrentWallpaperPath, WallpaperMode);
        }
        else
        {
            SetWallpaper(TempWallpaperPath, WallpaperMode);
        }

        return true;
    }

    return false;
}

/*
 * NOTE(koekeishiya):
 * parameter: chunkwm_api ChunkwmAPI
 * return: bool -> true if startup succeeded
 */
PLUGIN_BOOL_FUNC(PluginInit)
{
    API = ChunkwmAPI;
    BeginCVars(&API);
    CreateCVar("wallpaper", GetPathToWallpaper());
    CreateCVar("wallpaper_blur", (float) 0.0);
    CreateCVar("wallpaper_mode", (char *) "fill");
    CreateCVar("wallpaper_tmp_file", (char *) "/tmp/chunkwm-tmp-blur.jpg");

    CurrentWallpaperPath = CVarStringValue("wallpaper");
    Sigma = CVarFloatingPointValue("wallpaper_blur");
    WallpaperMode = CVarStringValue("wallpaper_mode");
    TempWallpaperPath = CVarStringValue("wallpaper_tmp_file");

    BlurWallpaper(CurrentWallpaperPath, TempWallpaperPath, (double) Sigma);

    // Set wallpaper
    int NumberOfWindows = NumberOfWindowsOnSpace();
    if (NumberOfWindows == 0)
        SetWallpaper(CurrentWallpaperPath, WallpaperMode);
    else
        SetWallpaper(TempWallpaperPath, WallpaperMode);

    return true;
}

PLUGIN_VOID_FUNC(PluginDeInit)
{
    unlink(TempWallpaperPath);
}

// NOTE(koekeishiya): Enable to manually trigger ABI mismatch
#if 0
#undef CHUNKWM_PLUGIN_API_VERSION
#define CHUNKWM_PLUGIN_API_VERSION 0
#endif

// NOTE(koekeishiya): Initialize plugin function pointers.
CHUNKWM_PLUGIN_VTABLE(PluginInit, PluginDeInit, PluginMain)

// NOTE(koekeishiya): Subscribe to ChunkWM events!
chunkwm_plugin_export Subscriptions[] =
{
    chunkwm_export_application_terminated,
    chunkwm_export_application_launched,
    chunkwm_export_application_activated,
    chunkwm_export_application_deactivated,
    chunkwm_export_application_hidden,
    chunkwm_export_application_unhidden,
    chunkwm_export_window_created,
    chunkwm_export_window_destroyed,
    chunkwm_export_space_changed,
    chunkwm_export_window_minimized,
    chunkwm_export_window_deminimized,
};
CHUNKWM_PLUGIN_SUBSCRIBE(Subscriptions)

// NOTE(koekeishiya): Generate plugin
CHUNKWM_PLUGIN(PluginName, PluginVersion);

internal int
SetWallpaper (const char *NormalCStringPathToFile, char *NormalCStringMode)
{
    // Convert the C types to the Objective-C types...
    NSString *Mode = [NSString stringWithCString:NormalCStringMode encoding:[NSString defaultCStringEncoding]];
    NSString *PathToFile = [NSString stringWithCString:NormalCStringPathToFile encoding:[NSString defaultCStringEncoding]];

    NSWorkspace *Workspace = [NSWorkspace sharedWorkspace];
    NSScreen *Screen = [NSScreen screens].firstObject;
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

internal char *
GetPathToWallpaper (void)
{
    char *PathToFile = NULL;

    NSWorkspace *Workspace = [NSWorkspace sharedWorkspace];
    NSScreen *Screen = [NSScreen screens].firstObject;

    NSString *Path = [Workspace desktopImageURLForScreen:Screen].path;
    BOOL IsDir;
    NSFileManager *FileManager = [NSFileManager defaultManager];

    // check if file is a directory
    [FileManager fileExistsAtPath:Path isDirectory:&IsDir];

    // if directory, check db
    if (IsDir)
    {
        NSArray *Dirs = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
        NSString *DatabasePath = [Dirs[0] stringByAppendingPathComponent:@"Dock/desktoppicture.db"];
        sqlite3 *Database;

        if (sqlite3_open(DatabasePath.UTF8String, &Database) == SQLITE_OK)
        {
            sqlite3_stmt *Statement;
            const char *SQL = "SELECT * FROM data";

            if (sqlite3_prepare_v2(Database, SQL, -1, &Statement, nil) == SQLITE_OK)
            {
                NSString *File;
                while (sqlite3_step(Statement) == SQLITE_ROW)
                {
                    File = @((char *)sqlite3_column_text(Statement, 0));
                }

                // printf("%s/%s\n", Path.UTF8String, File.UTF8String);
                PathToFile = (char *) malloc(
                    sizeof(char) * strlen(Path.UTF8String) +
                    sizeof(char) * strlen(File.UTF8String) +
                    sizeof(char) * 1);
                sprintf(PathToFile, "%s/%s", Path.UTF8String, File.UTF8String);
                // printf("%s\n", PathToFile);
                sqlite3_finalize(Statement);
            }

            sqlite3_close(Database);
        }
    }
    else
    {
        PathToFile = (char *) malloc(sizeof(char) * strlen(Path.UTF8String));
        sprintf(PathToFile, "%s", Path.UTF8String);
        // printf("%s\n", PathToFile);
    }
    return PathToFile;
}

internal int
NumberOfWindowsOnSpace (void)
{
    CFArrayRef windowListArray = CGWindowListCreate(kCGWindowListOptionOnScreenOnly|kCGWindowListExcludeDesktopElements, kCGNullWindowID);
    NSArray *Windows = CFBridgingRelease(CGWindowListCreateDescriptionFromArray(windowListArray));

    int NumberOfWindows = 0;

    for (NSDictionary *Window in Windows)
    {
        /* NOTE(splintah): I guess windows with a WindowLayer of 0 are windows
        we want to count */
        if ([(NSNumber *) Window[(__bridge NSString *) kCGWindowLayer] intValue] == 0)
        {
            NumberOfWindows++;
        }
    }

    return NumberOfWindows;
}
