#import <libactivator/libactivator.h>
#import <UIKit/UIKit.h>
#import "ASAlert.h"

@interface ASControlPanel : NSObject <LAListener, ASAlertDelegate> {
	NSData *smallIconData;
}
+ (instancetype)sharedInstance;
- (void)load;
- (void)unload;
@end
