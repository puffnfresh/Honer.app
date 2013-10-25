#import <Cocoa/Cocoa.h>
#import "OverlayWindow.h"

@interface HonerApplicationDelegate : NSObject <NSApplicationDelegate>
{
    AXObserverRef axObserver;
    AXUIElementRef axApplication;
}

@property IBOutlet OverlayWindow *window;
@property IBOutlet NSWindow *preferenceWindow;
@property IBOutlet NSMenu *statusBarMenu;
@property NSStatusItem *statusBar;

@end
