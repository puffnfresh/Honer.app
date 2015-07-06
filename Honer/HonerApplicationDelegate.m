#import "HonerApplicationDelegate.h"

@implementation HonerApplicationDelegate

+ (void)initialize
{
    NSData *defaultColor = [NSArchiver archivedDataWithRootObject:[NSColor redColor]];
    CGFloat defaultSize = 5;
    CGFloat defaultAlpha = 0;
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setObject:defaultColor forKey:@"color"];
    [dict setObject:[NSNumber numberWithDouble:defaultSize] forKey:@"size"];
    [dict setObject:[NSNumber numberWithDouble:defaultAlpha] forKey:@"transparency"];
    [[NSUserDefaults standardUserDefaults] registerDefaults:dict];
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    self.preferenceWindow.level = NSPopUpMenuWindowLevel;
    
    NSDictionary *options = @{(__bridge id)kAXTrustedCheckOptionPrompt: @YES};
    BOOL accessibilityEnabled = AXIsProcessTrustedWithOptions((__bridge CFDictionaryRef)options);
    
    if(!accessibilityEnabled) {
        // Exit
        return [NSApp performSelector:@selector(terminate:) withObject:nil afterDelay:0.0];
    }
    
    self.statusBar = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    self.statusBar.image = [[NSImage alloc] initWithContentsOfFile: [[NSBundle mainBundle] pathForResource: @"icon-statusitem" ofType: @"pdf"]];
    self.statusBar.highlightMode = YES;
    self.statusBar.menu = self.statusBarMenu;
    
    NSNotificationCenter *center =  [[NSWorkspace sharedWorkspace] notificationCenter];
    [center addObserver:self selector:@selector(onDeactivate:) name:NSWorkspaceDidDeactivateApplicationNotification object:nil];
}

- (void)onDeactivate:(NSNotification*)event
{
    [self updateWindow];
}

- (void)updateWindow
{
    if(!suspended)
    {
        AXUIElementRef window;
        pid_t pid = [self getFrontPID];
        [self detachNotifications];
        [self getProcessWindow:pid window:&window];
        
        if(window == NULL) {
            [self hideWindow];
        } else {
            [self copyWindow:window];
        }
        
        [self attachNotifications:pid];
    }
    else{
        [self hideWindow];
    }
}


- (IBAction)suspendProgram:(id)sender
{
    if(suspended){
        suspended = false;
        [sender setTitle:@"Suspend"];
    }
    else{
        suspended = true;
        [self hideWindow];
        [sender setTitle:@"Resume"];
        
    }
}


- (pid_t)getFrontPID
{
    pid_t pid;
    ProcessSerialNumber psn = {0, kNoProcess};
    GetFrontProcess(&psn);
    GetProcessPID(&psn, &pid);
    return pid;
}

- (void)detachNotifications
{
    if(axObserver == NULL) {
        return;
    }
    
    AXObserverRemoveNotification(axObserver, axApplication, kAXWindowMiniaturizedNotification);
    AXObserverRemoveNotification(axObserver, axApplication, kAXWindowMovedNotification);
    AXObserverRemoveNotification(axObserver, axApplication, kAXWindowResizedNotification);
    AXObserverRemoveNotification(axObserver, axApplication, kAXFocusedWindowChangedNotification);
    CFRunLoopRemoveSource([[NSRunLoop currentRunLoop] getCFRunLoop], AXObserverGetRunLoopSource(axObserver), kCFRunLoopDefaultMode);
    
    CFRelease(axObserver);
    axObserver = NULL;
    CFRelease(axApplication);
    axApplication = NULL;
}

- (void)attachNotifications:(pid_t)pid
{
    AXObserverCreate(pid, updateCallback, &axObserver);
    AXObserverAddNotification(axObserver, axApplication, kAXWindowMiniaturizedNotification, (__bridge void *)(self));
    AXObserverAddNotification(axObserver, axApplication, kAXWindowMovedNotification, (__bridge void *)(self));
    AXObserverAddNotification(axObserver, axApplication, kAXWindowResizedNotification, (__bridge void *)(self));
    AXObserverAddNotification(axObserver, axApplication, kAXFocusedWindowChangedNotification, (__bridge void *)(self));
    CFRunLoopAddSource([[NSRunLoop currentRunLoop] getCFRunLoop], AXObserverGetRunLoopSource(axObserver), kCFRunLoopDefaultMode);
}

- (void)hideWindow
{
    [self.window setFrame:NSZeroRect display:NO animate:NO];
}

void updateCallback(AXObserverRef observer, AXUIElementRef element, CFStringRef notificationName, void *data)
{
    HonerApplicationDelegate *delegate = (__bridge HonerApplicationDelegate *)data;
    [delegate updateWindow];
}

- (void)copyWindow:(AXUIElementRef)window
{
    CGPoint position = [self getWindowPosition:window];
    CGSize size = [self getWindowSize:window];
    
    NSRect frame = [self.window frame];
    frame.origin = [self toOrigin:position size:size];
    frame.size = size;
    [self.window setFrame:frame display:YES animate:NO];
    
    [self.window orderFront:nil];
}

- (CGPoint)toOrigin:(CGPoint)point size:(CGSize)size
{
    CGFloat screenHeight = [[[NSScreen screens] objectAtIndex:0] frame].size.height;
    return CGPointMake(point.x, screenHeight - size.height - point.y);
}

- (CGPoint)getWindowPosition:(AXUIElementRef)window
{
    AXValueRef valueRef;
    CGPoint pos;
    
    AXUIElementCopyAttributeValue(window, kAXPositionAttribute, (const void **)&valueRef);
    AXValueGetValue(valueRef, kAXValueCGPointType, &pos);
    CFRelease(valueRef);
    
    return pos;
}

- (CGSize)getWindowSize:(AXUIElementRef)window
{
    AXValueRef valueRef;
    CGSize size;
    
    AXUIElementCopyAttributeValue(window, kAXSizeAttribute, (const void **)&valueRef);
    AXValueGetValue(valueRef, kAXValueCGSizeType, &size);
    CFRelease(valueRef);
    
    return size;
}

- (void)getProcessWindow:(pid_t)pid window:(AXUIElementRef *)window
{
    axApplication = AXUIElementCreateApplication(pid);
    
    CFBooleanRef boolRef;
    AXUIElementCopyAttributeValue(axApplication, kAXHiddenAttribute, (const void **)&boolRef);
    if(boolRef == NULL || CFBooleanGetValue(boolRef)) {
        *window = NULL;
    } else {
        AXUIElementCopyAttributeValue(axApplication, kAXFocusedWindowAttribute, (const void **)window);
    }
}

@end
