#import <libactivator/libactivator.h>
#import <UIKit/UIKit.h>

typedef void (^ASActivatorListenerEventHandler) (LAEvent *event, BOOL abortEventCalled);

@interface ASActivatorListener : NSObject <LAListener> {
	NSData *smallIconData;
}
@property (nonatomic, strong) ASActivatorListenerEventHandler eventHandler;
+ (instancetype)sharedInstance;
- (void)load;
- (void)unload;
@end
