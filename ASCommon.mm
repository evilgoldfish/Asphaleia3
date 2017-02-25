#import "ASCommon.h"
#include <sys/sysctl.h>
#import <objc/runtime.h>
#import <AudioToolbox/AudioServices.h>
#import "NSTimer+Blocks.h"
#import "ASPreferences.h"
#import "ASPasscodeHandler.h"
#import "ASAuthenticationController.h"
#import <RocketBootstrap/RocketBootstrap.h>
#import <AppSupport/CPDistributedMessagingCenter.h>

@interface ASCommon ()
- (void)authenticated:(BOOL)wasCancelled;
@end

void authenticationSuccessful(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    [[ASCommon sharedInstance] authenticated:NO];
}

void authenticationCancelled(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    [[ASCommon sharedInstance] authenticated:YES];
}

@implementation ASCommon

static ASCommon *sharedCommonObj;

+ (instancetype)sharedInstance {
    static dispatch_once_t token = 0;
    dispatch_once(&token, ^{
        sharedCommonObj = [[ASCommon alloc] init];
        addObserver(authenticationSuccessful, "com.a3tweaks.asphaleia.xpc/AuthSucceeded");
        addObserver(authenticationCancelled, "com.a3tweaks.asphaleia.xpc/AuthCancelled");
    });

    return sharedCommonObj;
}

- (BOOL)displayingAuthAlert {
    CPDistributedMessagingCenter *centre = [objc_getClass("CPDistributedMessagingCenter") centerNamed:@"com.a3tweaks.asphaleia.xpc"];
    rocketbootstrap_distributedmessagingcenter_apply(centre);
    NSDictionary *reply = [centre sendMessageAndReceiveReplyName:@"com.a3tweaks.asphaleia.xpc/GetCurrentAuthAlert" userInfo:nil];
    return [reply[@"displayingAuthAlert"] boolValue];
}

- (BOOL)authenticateAppWithDisplayIdentifier:(NSString *)appIdentifier customMessage:(NSString *)customMessage dismissedHandler:(ASCommonAuthenticationHandler)handler {
    if (objc_getClass("ASAuthenticationController")) {
      return [[objc_getClass("ASAuthenticationController") sharedInstance] authenticateAppWithDisplayIdentifier:appIdentifier customMessage:customMessage dismissedHandler:handler];
    }

    CPDistributedMessagingCenter *centre = [objc_getClass("CPDistributedMessagingCenter") centerNamed:@"com.a3tweaks.asphaleia.xpc"];
    rocketbootstrap_distributedmessagingcenter_apply(centre);
    NSDictionary *reply = [centre sendMessageAndReceiveReplyName:@"com.a3tweaks.asphaleia.xpc/AuthenticateApp" userInfo:@{ @"appIdentifier" : appIdentifier, @"customMessage" : customMessage }];
    return [reply[@"isProtected"] boolValue];
}

- (BOOL)authenticateFunction:(ASAuthenticationAlertType)alertType dismissedHandler:(ASCommonAuthenticationHandler)handler {
    if (objc_getClass("ASAuthenticationController")) {
      return [[objc_getClass("ASAuthenticationController") sharedInstance] authenticateFunction:alertType dismissedHandler:handler];      
    }

    authHandler = [handler copy];
    CPDistributedMessagingCenter *centre = [objc_getClass("CPDistributedMessagingCenter") centerNamed:@"com.a3tweaks.asphaleia.xpc"];
    rocketbootstrap_distributedmessagingcenter_apply(centre);
    NSDictionary *reply = [centre sendMessageAndReceiveReplyName:@"com.a3tweaks.asphaleia.xpc/AuthenticateFunction" userInfo:@{ @"alertType" : [NSNumber numberWithInt:alertType] }];
    return [reply[@"isProtected"] boolValue];
}

- (void)authenticated:(BOOL)wasCancelled {
    if (authHandler) {
        authHandler(wasCancelled);
        authHandler = nil;
    }
}

@end
