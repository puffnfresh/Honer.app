#import "BorderView.h"

@implementation BorderView

const CGFloat RADIUS = 2;

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    NSColor *color = [NSUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] dataForKey:@"color"]];
    CGFloat size = [[NSUserDefaults standardUserDefaults] doubleForKey:@"size"];
    
    NSRect innerRect = [self cleanRect:dirtyRect size:size];
    NSBezierPath *border = [NSBezierPath bezierPathWithRoundedRect:innerRect xRadius:RADIUS yRadius:RADIUS];
    
    [border setLineWidth:size];
    [color set];
    
    [border stroke];
}

- (NSRect)cleanRect:(NSRect)dirtyRect size:(CGFloat)size
{
    return NSInsetRect(dirtyRect, size / 2, size / 2);
}

- (IBAction)updateColor:(id)sender
{
    [self display];
    [[self window] orderFront:sender];
}

- (IBAction)updateWidth:(id)sender
{
    [self display];
    [[self window] orderFront:sender];
}

@end
