#include <stdlib.h>
#include <string.h>
#include <time.h>

#include "../chunkwm/src/api/plugin_api.h"
#include "../chunkwm/src/common/accessibility/application.h"
#include "../chunkwm/src/common/accessibility/display.h"
#include "../chunkwm/src/common/accessibility/window.h"
#include "../chunkwm/src/common/config/cvar.h"
#include "../chunkwm/src/common/config/tokenize.h"
#include "../chunkwm/src/common/config/cvar.cpp"
#include "../chunkwm/src/common/config/tokenize.cpp"

#include "../chunkwm/src/common/accessibility/display.mm"

#include "lib/blurwallpaper.h"
#include "lib/number-of-windows.m"
#include "lib/set-wallpaper.m"
#include "lib/get-wallpaper.m"

#define internal static

internal const char *PluginName = "blur";
internal const char *PluginVersion = "0.2.0";
internal chunkwm_api API;

internal float BlurRange = 0.0;
internal float BlurSigma = 0.0;
internal char *TmpWallpaperPath = NULL;
internal char *WallpaperMode = NULL;

inline bool
StringsAreEqual(const char *A, const char *B)
{
    bool Result = (strcmp(A, B) == 0);
    return Result;
}

internal void
DeleteImages(void)
{
    char *DeleteCommand = (char *) malloc(sizeof(char) * (
        strlen("rm -f /chunkwm-blur*.jpg") +
        strlen(TmpWallpaperPath)
    ));

    sprintf(DeleteCommand, "rm -f %s/chunkwm-blur*.jpg", TmpWallpaperPath);

    system(DeleteCommand);
}

internal void
CommandHandler(void *Data)
{
    chunkwm_payload *Payload = (chunkwm_payload *) Data;

    if (StringsAreEqual(Payload->Command, "wallpaper"))
    {
        token Token = GetToken(&Payload->Message);

        if (Token.Length > 0)
        {
            UpdateCVar("wallpaper", TokenToString(Token));
        }
    }
}

internal bool
GetDesktopIdAndType(unsigned *IdDest, CGSSpaceType *TypeDest)
{
    CFStringRef DisplayIdentifier = AXLibGetDisplayIdentifierForMainDisplay();
    macos_space *ActiveSpace = AXLibActiveSpace(DisplayIdentifier);

    unsigned DesktopId = 1;
    bool Result = AXLibCGSSpaceIDToDesktopID(ActiveSpace->Id, NULL, &DesktopId);

    if (!Result)
        return false;

    *IdDest = DesktopId;
    *TypeDest = ActiveSpace->Type;
    return true;
}

internal char *
GetWallpaperPath(unsigned DesktopId, bool Blurred)
{
    char *SpaceSpecificRule = (char *) malloc(128);
    snprintf(SpaceSpecificRule, 128, "%d_wallpaper", DesktopId);

    char *WallpaperFile = (char *) malloc(128);
    if (CVarExists(SpaceSpecificRule))
    {
        if (!Blurred)
            return CVarStringValue(SpaceSpecificRule);

        snprintf(WallpaperFile, 128, "%s/chunkwm-blur-%d.jpg", TmpWallpaperPath, DesktopId);

        if (access(WallpaperFile, F_OK) == -1)
        {
            BlurWallpaper(
                CVarStringValue(SpaceSpecificRule),
                WallpaperFile,
                (double) BlurRange,
                (double) BlurSigma
            );
        }
    }
    else
    {
        if (!Blurred)
            return CVarStringValue("wallpaper");

        snprintf(WallpaperFile, 128, "%s/chunkwm-blur-global.jpg", TmpWallpaperPath);

        if (access(WallpaperFile, F_OK) == -1)
        {
            BlurWallpaper(
                CVarStringValue("wallpaper"),
                WallpaperFile,
                (double) BlurRange,
                (double) BlurSigma
            );
        }
    }

    return WallpaperFile;
}

/*
 * NOTE(koekeishiya):
 * parameter: const char *Node
 * parameter: void *Data
 * return: bool
 * */
PLUGIN_MAIN_FUNC(PluginMain)
{
    if (StringsAreEqual(Node, "chunkwm_export_application_activated") ||
        StringsAreEqual(Node, "chunkwm_export_application_unhidden") ||
        StringsAreEqual(Node, "chunkwm_export_window_created") ||
        StringsAreEqual(Node, "chunkwm_export_window_deminimized") ||
        StringsAreEqual(Node, "chunkwm_export_application_launched") ||
        StringsAreEqual(Node, "chunkwm_export_application_terminated") ||
        StringsAreEqual(Node, "chunkwm_export_application_deactivated") ||
        StringsAreEqual(Node, "chunkwm_export_application_hidden") ||
        StringsAreEqual(Node, "chunkwm_export_space_changed") ||
        StringsAreEqual(Node, "chunkwm_export_window_destroyed") ||
        StringsAreEqual(Node, "chunkwm_export_window_minimized"))
    {
        unsigned DesktopId = 1;
        CGSSpaceType DesktopType = 0;
        bool Result = GetDesktopIdAndType(&DesktopId, &DesktopType);
        if (!Result)
            return false;

        if (DesktopType != kCGSSpaceUser)
            return true;

        int NumberOfWindows = NumberOfWindowsOnSpace();
        bool Blurred = NumberOfWindows > 0;

        SetWallpaper(GetWallpaperPath(DesktopId, Blurred), WallpaperMode);

        return true;
    }
    else if (StringsAreEqual(Node, "chunkwm_daemon_command"))
    {
        CommandHandler(Data);
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
    CreateCVar("wallpaper_blur", BlurSigma);
    CreateCVar("wallpaper_mode", (char *) "fill");
    CreateCVar("wallpaper_tmp_path", (char *) "/tmp/");

    BlurSigma = CVarFloatingPointValue("wallpaper_blur");
    WallpaperMode = CVarStringValue("wallpaper_mode");
    TmpWallpaperPath = CVarStringValue("wallpaper_tmp_path");

    DeleteImages();

    return true;
}

PLUGIN_VOID_FUNC(PluginDeInit)
{
    unsigned DesktopId = 1;
    CGSSpaceType DesktopType;
    bool Result = GetDesktopIdAndType(&DesktopId, &DesktopType);
    if (Result)
    {
        SetWallpaper(GetWallpaperPath(DesktopId, false), WallpaperMode);
    }
    DeleteImages();
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
    chunkwm_export_window_minimized,
    chunkwm_export_window_deminimized,

    chunkwm_export_space_changed,
};
CHUNKWM_PLUGIN_SUBSCRIBE(Subscriptions)

// NOTE(koekeishiya): Generate plugin
CHUNKWM_PLUGIN(PluginName, PluginVersion);

