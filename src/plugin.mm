#include <stdlib.h>
#include <string.h>
#include <time.h>

#include "../chunkwm/src/api/plugin_api.h"
#include "../chunkwm/src/common/accessibility/application.h"
#include "../chunkwm/src/common/accessibility/display.h"
#include "../chunkwm/src/common/accessibility/window.h"
#include "../chunkwm/src/common/config/cvar.h"
#include "../chunkwm/src/common/config/tokenize.h"
#include "../chunkwm/src/common/ipc/daemon.h"

#include "../chunkwm/src/common/accessibility/display.mm"
#include "../chunkwm/src/common/config/cvar.cpp"
#include "../chunkwm/src/common/config/tokenize.cpp"
#include "../chunkwm/src/common/ipc/daemon.cpp"

#include "lib/blurwallpaper.h"
#include "lib/number-of-windows.mm"
#include "lib/set-wallpaper.m"
#include "lib/get-wallpaper.m"
#include "lib/reset-wallpaper.m"

#define internal static

internal const char *PluginName = "blur";
internal const char *PluginVersion = "0.2.1";
internal chunkwm_api API;

internal bool DoBlur = true;
internal float BlurRange = 0.0;
internal float BlurSigma = 0.0;
internal char *TmpWallpaperPath = NULL;

internal const char *HelpMessage =
"blur by splintah\n\
https://github.com/splintah/blur\n\n\
Variables. Set these in your cunkwmrc with `chunkc set <name> <value>'\n\
  wallpaper (path):\n\
    Path to your wallpaper.\n\
    Default: path to your current wallpaper.\n\
    This is the 'global' wallpaper.\n\
  <space>_wallpaper (path):\n\
    Path to a wallpaper.\n\
    This wallpaper will be used on space <space>.\n\
  wallpaper_blur (float):\n\
    Changes the blur intensity.\n\
    Default: 0.0 (imagemagick selects a suitable value when 0.0 is used).\n\
  wallpaper_mode (`fill', `fit', `stretch' or `center'):\n\
    The way a wallpaper is displayed. Default: `fill'.\n\
  wallpaper_tmp_path (path): \n\
    Where to store the blurred wallpaper. Default: `/tmp/'.\n\n\
Runtime commands. Run these with `chunkc blur::<command>'\n\
  wallpaper (path):\n\
    Set the wallpaper path while running chunkwm.\n\
  enable:\n\
    Enable blurring. Blurring is enabled by default.\n\
  disable:\n\
    Disable blurring.\n\
    Every desktop will get its wallpaper specified with <space>_wallpaper, but not blurred.\n\
  reset:\n\
    Reset wallpaper on all spaces.\n\
    The wallpaper will be set to the wallpaper specified with `chunkc set wallpaper'.\n\
    This also disables blurring.\n\
";

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
    else if (StringsAreEqual(Payload->Command, "enable"))
    {
        DoBlur = true;
        WriteToSocket("Enabled blur.\n", Payload->SockFD);
    }
    else if (StringsAreEqual(Payload->Command, "disable"))
    {
        DoBlur = false;
        WriteToSocket("Disabled blur.\n", Payload->SockFD);
    }
    else if (StringsAreEqual(Payload->Command, "help"))
    {
        WriteToSocket(HelpMessage, Payload->SockFD);
    }
    else if (StringsAreEqual(Payload->Command, "reset"))
    {
        DoBlur = false;
        ResetWallpaperOnAllSpaces(CVarStringValue("wallpaper"), CVarStringValue("wallpaper_mode"));

        WriteToSocket("Disabled blur.\n", Payload->SockFD);
        WriteToSocket("Reset wallpaper on all screens.\n", Payload->SockFD);
    }
}

internal bool
GetSpaceAndDesktopId(macos_space **SpaceDest, unsigned *IdDest)
{
    macos_space *ActiveSpace;
    bool Result = AXLibActiveSpace(&ActiveSpace);

    if (!Result)
        return false;

    unsigned DesktopId = 1;
    Result = AXLibCGSSpaceIDToDesktopID(ActiveSpace->Id, NULL, &DesktopId);

    if (!Result)
        return false;

    *SpaceDest = ActiveSpace;
    *IdDest = DesktopId;
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
        macos_space *Space;
        unsigned DesktopId = 1;
        bool Result = GetSpaceAndDesktopId(&Space, &DesktopId);
        if (!Result)
            return false;

        if (Space->Type != kCGSSpaceUser)
            return true;

        int NumberOfWindows = NumberOfWindowsOnSpace(Space->Id);
        bool Blurred = NumberOfWindows > 0 && DoBlur;

        SetWallpaper(GetWallpaperPath(DesktopId, Blurred), CVarStringValue("wallpaper_mode"));

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
    TmpWallpaperPath = CVarStringValue("wallpaper_tmp_path");

    DeleteImages();

    return true;
}

PLUGIN_VOID_FUNC(PluginDeInit)
{
    ResetWallpaperOnAllSpaces(CVarStringValue("wallpaper"), CVarStringValue("wallpaper_mode"));
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

