#include <stdlib.h>
#include <string.h>
#include <time.h>

#include "../../api/plugin_api.h"
#include "../../common/accessibility/application.h"
#include "../../common/accessibility/window.h"
#include "../../common/config/cvar.h"

#include "../../common/config/cvar.cpp"

#include "blurwallpaper.h"
#include "number-of-windows.m"
#include "get-wallpaper.m"
#include "set-wallpaper.m"

#define internal static

internal const char *PluginName = "blur";
internal const char *PluginVersion = "0.1.2";
internal chunkwm_api API;

internal float BlurSigma = 0.0;
internal char *CurrentWallpaperPath = NULL;
internal char *TempWallpaperPath = NULL;
internal char *WallpaperMode = NULL;

inline bool
StringsAreEqual(const char *A, const char *B)
{
    bool Result = (strcmp(A, B) == 0);
    return Result;
}

internal char *
RandomString(int Length)
{
    char *Random = (char *) malloc(sizeof(char) * (Length + 1));

    srand(time(NULL));

    for (int i = 0; i < Length; i++)
    {
        Random[i] = 'A' + (rand() % 26);
    }

    Random[Length] = '\0';

    return Random;
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
        StringsAreEqual(Node, "chunkwm_export_window_deminimize"))
    {
        SetWallpaper(TempWallpaperPath, WallpaperMode);

        return true;
    }
    else if (
        StringsAreEqual(Node, "chunkwm_export_application_launched") ||
        StringsAreEqual(Node, "chunkwm_export_application_terminated") ||
        StringsAreEqual(Node, "chunkwm_export_application_deactivated") ||
        StringsAreEqual(Node, "chunkwm_export_application_hidden") ||
        StringsAreEqual(Node, "chunkwm_export_space_changed") ||
        StringsAreEqual(Node, "chunkwm_export_window_destroyed") ||
        StringsAreEqual(Node, "chunkwm_export_window_minimized"))
    {
        int NumberOfWindows = NumberOfWindowsOnSpace();
        if (NumberOfWindows == 0)
            SetWallpaper(CurrentWallpaperPath, WallpaperMode);
        else
            SetWallpaper(TempWallpaperPath, WallpaperMode);

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
    CreateCVar("wallpaper_blur", BlurSigma);
    CreateCVar("wallpaper_mode", (char *) "fill");
    CreateCVar("wallpaper_tmp_path", (char *) "/tmp/");

    CurrentWallpaperPath = CVarStringValue("wallpaper");
    BlurSigma = CVarFloatingPointValue("wallpaper_blur");
    WallpaperMode = CVarStringValue("wallpaper_mode");

    TempWallpaperPath = (char *) malloc(sizeof(char) *(
        strlen(CVarStringValue("wallpaper_tmp_path")) +
        strlen("/chunkwm-blur-.jpg") +
        6 + 1));

    sprintf(TempWallpaperPath,
        "%s/chunkwm-blur-%s.jpg",
        CVarStringValue("wallpaper_tmp_path"),
        RandomString(6));

    system("rm -f /tmp/chunkwm-blur*.jpg");
    BlurWallpaper(CurrentWallpaperPath, TempWallpaperPath, (double) BlurSigma);

    int NumberOfWindows = NumberOfWindowsOnSpace();
    if (NumberOfWindows == 0)
        SetWallpaper(CurrentWallpaperPath, WallpaperMode);
    else
        SetWallpaper(TempWallpaperPath, WallpaperMode);

    return true;
}

PLUGIN_VOID_FUNC(PluginDeInit)
{
    SetWallpaper(CurrentWallpaperPath, WallpaperMode);
    system("rm -f /tmp/chunkwm-blur*.jpg");
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

