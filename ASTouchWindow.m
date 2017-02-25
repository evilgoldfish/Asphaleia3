#import "ASTouchWindow.h"

@implementation ASTouchWindow

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    CGRect frame = [self.viewToAllowTouchIn.superview convertRect:self.viewToAllowTouchIn.frame toView:self];
    if (!CGRectContainsPoint(frame, point)) {
        self.handler(self, YES);
        return YES;
    }
    return NO;
}

- (instancetype)initWithFrame:(CGRect)aRect {
    self = [super initWithFrame:aRect];
    if (self) {
        self.windowLevel = UIWindowLevelAlert;
        [self setHidden:NO];
        [self setAlpha:1.0];
        [self setBackgroundColor:[UIColor clearColor]];
    }

    return self;
}

- (void)blockTouchesAllowingTouchInView:(SBIconView *)touchView touchBlockedHandler:(ASTouchWindowTouchBlockedEvent)handler {
    self.viewToAllowTouchIn = touchView;
    self.handler = [handler copy];
    [self makeKeyAndVisible];
}

@end
