#ifndef APPLE_LIBS_INCLUDED
#define APPLE_LIBS_INCLUDED

@import AppKit;
#include <Foundation/Foundation.h>
#include <Cocoa/Cocoa.h>

#endif
#include <sqlite3.h>

char *GetPathToWallpaper (void)
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
