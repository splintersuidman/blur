#include "../../chunkwm/src/common/accessibility/application.h"
#include "../../chunkwm/src/common/accessibility/window.h"
#include "../../chunkwm/src/common/misc/carbon.h"

#include "../../chunkwm/src/common/accessibility/application.cpp"
#include "../../chunkwm/src/common/accessibility/window.cpp"
#include "../../chunkwm/src/common/accessibility/observer.cpp"
#include "../../chunkwm/src/common/misc/carbon.cpp"
#include "../../chunkwm/src/common/misc/workspace.mm"
#include "../../chunkwm/src/common/accessibility/element.cpp"

int NumberOfWindowsOnSpace(CGSSpaceID SpaceId)
{
    int NumberOfWindows = 0;

    std::vector<macos_application *> ApplicationList = AXLibRunningProcesses(Process_Policy_Regular);

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
