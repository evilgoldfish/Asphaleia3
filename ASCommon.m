#import "ASCommon.h"
#include <sys/sysctl.h>
#import "UIAlertView+Blocks.h"
#import "BTTouchIDController.h"

@implementation ASCommon

static ASCommon *sharedCommonObj;

+(ASCommon *)sharedInstance {
    @synchronized(self) {
        if (!sharedCommonObj)
            sharedCommonObj = [[ASCommon alloc] init];
    }

    return sharedCommonObj;
}

-(UIAlertView *)createAppAuthenticationAlertWithIconView:(SBIconView *)iconView dismissedHandler:(ASCommonAuthenticationHandler)handler beginMesaMonitoringBeforeShowing:(BOOL)shouldBeginMonitoringOnWillPresent {
    // need to add customisation to this...
    // icon at the top-centre of the alert
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:iconView.icon.displayName
                   message:@"Scan fingerprint to open."
                   delegate:nil
         cancelButtonTitle:@"Cancel"
         otherButtonTitles:@"Passcode",nil];

    __block BTTouchIDController *controller = [[BTTouchIDController alloc] initWithEventBlock:^void(BTTouchIDController *controller, id monitor, unsigned event) {
        if (event == TouchIDMatched) {
            [alertView dismissWithClickedButtonIndex:-1 animated:YES];
            [controller stopMonitoring];
            handler(NO);
        }
    }];
    alertView.tapBlock = ^(UIAlertView *alertView, NSInteger buttonIndex) {
        [controller stopMonitoring];
        handler(buttonIndex == [alertView cancelButtonIndex]);
    };
    if (beginMesaMonitoringBeforeShowing) {
        alertView.willPresentBlock = ^(UIAlertView *alertView) {
        [controller startMonitoring];
        };
    } else {
        alertView.didPresentBlock = ^(UIAlertView *alertView) {
        [controller startMonitoring];
        };
    }

    //CGAffineTransform moveUp = CGAffineTransformMakeTranslation(0.0, 0.0);
    //[alertView setTransform: moveUp];
    return alertView;
}

-(UIAlertView *)createAuthenticationAlertOfType:(ASAuthenticationAlertType)alertType dismissedHandler:(ASCommonAuthenticationHandler)handler beginMesaMonitoringBeforeShowing:(BOOL)shouldBeginMonitoringOnWillPresent {
    NSString *message;
    switch (alertType) {
        case ASAuthenticationAlertAppArranging:
            message = @"Scan fingerprint to arrange apps.";
            break;
        case ASAuthenticationAlertSwitcher:
            message = @"Scan fingerprint to open app switcher.";
            break;
        default:
            message = @"Scan fingerprint to continue.";
            break;
    }

    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Asphaleia"
                   message:message
                   delegate:nil
         cancelButtonTitle:@"Cancel"
         otherButtonTitles:@"Passcode",nil];

    __block BTTouchIDController *controller = [[BTTouchIDController alloc] initWithEventBlock:^void(BTTouchIDController *controller, id monitor, unsigned event) {
        if (event == TouchIDMatched) {
            [alertView dismissWithClickedButtonIndex:-1 animated:YES];
            [controller stopMonitoring];
            handler(NO);
        }
    }];
    alertView.tapBlock = ^(UIAlertView *alertView, NSInteger buttonIndex) {
        [controller stopMonitoring];
        handler(buttonIndex == [alertView cancelButtonIndex]);
    };
    if (beginMesaMonitoringBeforeShowing) {
        alertView.willPresentBlock = ^(UIAlertView *alertView) {
        [controller startMonitoring];
        };
    } else {
        alertView.didPresentBlock = ^(UIAlertView *alertView) {
        [controller startMonitoring];
        };
    }

    return alertView;
}

-(BOOL)isTouchIDDevice {
    int sysctlbyname(const char *, void *, size_t *, void *, size_t);

    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);

    char *answer = (char *)malloc(size);
    sysctlbyname("hw.machine", answer, &size, NULL, 0);

    NSString *results = [NSString stringWithCString:answer encoding: NSUTF8StringEncoding];

    free(answer);

    NSArray *touchIDModels = @[ @"iPhone6,1", @"iPhone6,2", @"iPhone7,1", @"iPhone7,2", @"iPad5,3", @"iPad5,4", @"iPad4,7", @"iPad4,8", @"iPad4,9" ];

    return [touchIDModels containsObject:results];
}

@end