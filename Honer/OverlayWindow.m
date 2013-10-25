#import "OverlayWindow.h"

@implementation OverlayWindow

- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)style backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag
{
    self = [super initWithContentRect:NSZeroRect styleMask:NSBorderlessWindowMask backing:bufferingType defer:flag];
    
    if ( self ) {
        [self setOpaque:NO];
        [self setBackgroundColor:[NSColor clearColor]];
        [self setLevel:NSPopUpMenuWindowLevel];
        [self setIgnoresMouseEvents:YES];

        [self updateAlpha:nil];
    }
    
    return self;
}

- (IBAction)updateAlpha:(id)sender
{
    NSInteger transparency = [[NSUserDefaults standardUserDefaults] doubleForKey:@"transparency"];
    CGFloat alpha = 1.0 - (transparency * 0.1);
    [self setAlphaValue:alpha];

    [self orderFront:sender];
}

- (void)awakeFromNib
{
}

@end
