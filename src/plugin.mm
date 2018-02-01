#include <stdlib.h>
#include <string.h>
#include <sqlite3.h>
#include <MagickWand/MagickWand.h>

#include "../chunkwm/src/api/plugin_api.h"

#include "../chunkwm/src/common/accessibility/application.cpp"
#include "../chunkwm/src/common/accessibility/display.mm"
#include "../chunkwm/src/common/accessibility/element.cpp"
#include "../chunkwm/src/common/accessibility/observer.cpp"
#include "../chunkwm/src/common/accessibility/window.cpp"
#include "../chunkwm/src/common/config/cvar.cpp"
#include "../chunkwm/src/common/config/tokenize.cpp"
#include "../chunkwm/src/common/ipc/daemon.cpp"
#include "../chunkwm/src/common/misc/carbon.cpp"
#include "../chunkwm/src/common/misc/workspace.mm"

#define internal static

bool ResetWallpaperOnAllSpaces(const char *WallpaperFile, const char *Mode);
int SetWallpaper(const char *NormalCStringPathToFile, const char *Mode);
int NumberOfWindowsOnSpace(CGSSpaceID SpaceId);
int BlurWallpaper(const char *Input, const char *Output, double Range, double Sigma);
char *GetPathToWallpaper(void);

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
    if (StringsAreEqual(Node, "chunkwm_daemon_command"))
    {
        CommandHandler(Data);
    }
    else
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

    chunkwm_export_display_changed,
    chunkwm_export_space_changed,
};
CHUNKWM_PLUGIN_SUBSCRIBE(Subscriptions)

// NOTE(koekeishiya): Generate plugin
CHUNKWM_PLUGIN(PluginName, PluginVersion);

void SetOptionsForMode(NSMutableDictionary **Options, const char *Mode)
{
    if (strcmp(Mode, "fill") == 0)
    {
        [*Options setObject:[NSNumber numberWithInt:NSImageScaleProportionallyUpOrDown]
            forKey:NSWorkspaceDesktopImageScalingKey];
        [*Options setObject:[NSNumber numberWithBool:YES]
            forKey:NSWorkspaceDesktopImageAllowClippingKey];
    }

    if (strcmp(Mode, "fit") == 0)
    {
        [*Options setObject:[NSNumber numberWithInt:NSImageScaleProportionallyUpOrDown]
            forKey:NSWorkspaceDesktopImageScalingKey];
        [*Options setObject:[NSNumber numberWithBool:NO]
            forKey:NSWorkspaceDesktopImageAllowClippingKey];
    }

    if (strcmp(Mode, "stretch") == 0)
    {
        [*Options setObject:[NSNumber numberWithInt:NSImageScaleAxesIndependently]
            forKey:NSWorkspaceDesktopImageScalingKey];
        [*Options setObject:[NSNumber numberWithBool:YES]
            forKey:NSWorkspaceDesktopImageAllowClippingKey];
    }

    if (strcmp(Mode, "center") == 0)
    {
        [*Options setObject:[NSNumber numberWithInt:NSImageScaleNone]
            forKey:NSWorkspaceDesktopImageScalingKey];
        [*Options setObject:[NSNumber numberWithBool:NO]
            forKey:NSWorkspaceDesktopImageAllowClippingKey];
    }
}

bool ResetWallpaperOnAllSpaces(const char *WallpaperFile, const char *Mode)
{
    bool Success = true;

    NSArray<NSScreen *> *Screens = [NSScreen screens];

    for (int i = 0; i < [Screens count]; ++i)
    {
        NSScreen *Screen = Screens[i];
        NSWorkspace *Workspace = [NSWorkspace sharedWorkspace];
        NSMutableDictionary *Options = [[Workspace desktopImageOptionsForScreen:Screen]
            mutableCopy];

        SetOptionsForMode(&Options, Mode);

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

int SetWallpaper(const char *NormalCStringPathToFile, const char *Mode)
{
    if (access(NormalCStringPathToFile, F_OK) == -1)
        return 1;

    // Convert the C type to the Objective-C type...
    NSString *PathToFile = [NSString
        stringWithCString:NormalCStringPathToFile
        encoding:[NSString defaultCStringEncoding]];

    NSWorkspace *Workspace = [NSWorkspace sharedWorkspace];
    NSScreen *Screen = [NSScreen mainScreen];
    NSMutableDictionary *Options = [[Workspace desktopImageOptionsForScreen:Screen] mutableCopy];

    SetOptionsForMode(&Options, Mode);

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

int NumberOfWindowsOnSpace(CGSSpaceID SpaceId)
{
    int NumberOfWindows = 0;

    std::vector<macos_application *> ApplicationList =
        AXLibRunningProcesses(Process_Policy_Regular);

    for (int i = 0; i < ApplicationList.size(); ++i)
    {
        macos_window **WindowList = AXLibWindowListForApplication(ApplicationList[i]);
        if (!WindowList)
            continue;

        macos_window *Window;
        while ((Window = *WindowList++))
        {
            if (AXLibSpaceHasWindow(SpaceId, Window->Id) && !AXLibIsWindowMinimized(Window->Ref))
                NumberOfWindows++;
        }
    }

    return NumberOfWindows;
}

int BlurWallpaper(const char *Input, const char *Output, double Range, double Sigma)
{
    MagickWandGenesis();
    MagickWand *Wand = NewMagickWand();

    MagickBooleanType Status = MagickReadImage(Wand, Input);
    if (Status == MagickFalse)
    {
        fprintf(stderr, "blur: could not find image\n");
        return 1;
    }

    Status = MagickBlurImage(Wand, Range, Sigma);
    if (Status == MagickFalse)
    {
        fprintf(stderr, "blur: could not blur image\n");
        return 2;
    }

    Status = MagickWriteImage(Wand, Output);
    if (Status == MagickFalse)
    {
        fprintf(stderr, "blur: could not write image\n");
        return 3;
    }

    return 0;
}

char *GetPathToWallpaper(void)
{
    char *PathToFile = NULL;

    NSWorkspace *Workspace = [NSWorkspace sharedWorkspace];
    NSScreen *Screen = [NSScreen screens].firstObject;

    NSString *Path = [Workspace desktopImageURLForScreen:Screen].path;
    BOOL IsDir;
    NSFileManager *FileManager = [NSFileManager defaultManager];

    // Check if file is a directory.
    [FileManager fileExistsAtPath:Path isDirectory:&IsDir];

    // If directory, check db.
    if (IsDir)
    {
        NSArray *Dirs = NSSearchPathForDirectoriesInDomains(
            NSApplicationSupportDirectory,
            NSUserDomainMask,
            YES);
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
                    File = @((char *) sqlite3_column_text(Statement, 0));
                }

                PathToFile = (char *) malloc(
                    sizeof(char) * strlen(Path.UTF8String)
                    + sizeof(char) * strlen(File.UTF8String)
                    + sizeof(char) * 1);
                sprintf(PathToFile, "%s/%s", Path.UTF8String, File.UTF8String);
                sqlite3_finalize(Statement);
            }

            sqlite3_close(Database);
        }
    }
    else
    {
        PathToFile = (char *) malloc(sizeof(char) * strlen(Path.UTF8String));
        sprintf(PathToFile, "%s", Path.UTF8String);
    }
    return PathToFile;
}
