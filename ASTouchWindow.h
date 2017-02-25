#import <UIKit/UIKit.h>
#import "Asphaleia.h"
@class ASTouchWindow;

typedef void (^ASTouchWindowTouchBlockedEvent) (ASTouchWindow *touchWindow, BOOL blockedTouch);

@interface ASTouchWindow : UIWindow {
	BOOL touchedOutside;
}
@property (assign) SBIconView *viewToAllowTouchIn;
@property (nonatomic, strong) ASTouchWindowTouchBlockedEvent handler;
- (void)blockTouchesAllowingTouchInView:(SBIconView *)touchView touchBlockedHandler:(ASTouchWindowTouchBlockedEvent)handler;
@end
