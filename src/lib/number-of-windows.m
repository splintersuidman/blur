#include <Foundation/Foundation.h>
#include <Cocoa/Cocoa.h>

int NumberOfWindowsOnSpace(void)
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
