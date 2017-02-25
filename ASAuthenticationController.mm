#import "ASAuthenticationController.h"
#include <sys/sysctl.h>
#import <objc/runtime.h>
#import <AudioToolbox/AudioServices.h>
#import "NSTimer+Blocks.h"
#import "ASPreferences.h"
#import "ASPasscodeHandler.h"

#define kBundlePath @"/Library/Application Support/Asphaleia/AsphaleiaAssets.bundle"
#define titleWithSpacingForIcon(t) [NSString stringWithFormat:@"\n\n\n%@",t]
#define titleWithSpacingForSmallIcon(t) [NSString stringWithFormat:@"\n\n%@",t]

#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

@interface ASAuthenticationController ()
- (void)receivedNotificationOfName:(NSString *)name fingerprint:(id)fingerprint;
@end

void touchIDNotificationReceived(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    id fingerprint = nil;
    if ([(__bridge NSString *)name isEqualToString:@"com.a3tweaks.asphaleia.authsuccess"]) {
      fingerprint = [[ASTouchIDController sharedInstance] lastMatchedFingerprint];
    }
    [[ASAuthenticationController sharedInstance] receivedNotificationOfName:(__bridge NSString *)name fingerprint:fingerprint];
}

@implementation ASAuthenticationController

static ASAuthenticationController *sharedCommonObj;

+ (instancetype)sharedInstance {
    static dispatch_once_t token = 0;
    dispatch_once(&token, ^{
        sharedCommonObj = [[ASAuthenticationController alloc] init];
        [sharedCommonObj registerForTouchIDNotifications];
    });

    return sharedCommonObj;
}

- (void)dealloc {
    [self deregisterForTouchIDNotifications];
}

- (ASAuthenticationAlert *)returnAppAuthenticationAlertWithApplication:(NSString *)appIdentifier customMessage:(NSString *)customMessage delegate:(id<ASAuthenticationAlertDelegate>)delegate {
    NSString *message;
    if (customMessage) {
      message = customMessage;
    } else {
      message = @"Scan fingerprint to open.";
    }

    ASAuthenticationAlert *alertView = [[objc_getClass("ASAuthenticationAlert") alloc] initWithApplication:appIdentifier
                   message:message
                   delegate:delegate];
    alertView.tag = ASAuthenticationItem;

    currentAuthAppBundleID = appIdentifier;

    return alertView;
}

- (ASAuthenticationAlert *)returnAuthenticationAlertOfType:(ASAuthenticationAlertType)alertType delegate:(id<ASAuthenticationAlertDelegate>)delegate {
    NSBundle *asphaleiaAssets = [[NSBundle alloc] initWithPath:kBundlePath];

    NSString *title;
    UIImage *iconImage;
    int tag;
    switch (alertType) {
        case ASAuthenticationAlertAppArranging: {
          title = @"Arrange Apps";
          iconImage = [UIImage imageNamed:@"IconEditMode.png" inBundle:asphaleiaAssets compatibleWithTraitCollection:nil];
          tag = ASAuthenticationFunction;
          break;
        }
        case ASAuthenticationAlertSwitcher: {
          title = @"Multitasking";
          iconImage = [UIImage imageNamed:@"IconMultitasking.png" inBundle:asphaleiaAssets compatibleWithTraitCollection:nil];
          tag = ASAuthenticationFunction;
          break;
        }
        case ASAuthenticationAlertSpotlight: {
          title = @"Spotlight";
          iconImage = [UIImage imageNamed:@"IconSpotlight.png" inBundle:asphaleiaAssets compatibleWithTraitCollection:nil];
          tag = ASAuthenticationFunction;
          break;
        }
        case ASAuthenticationAlertPowerDown: {
          title = @"Slide to Power Off";
          iconImage = [UIImage imageNamed:@"IconPowerOff.png" inBundle:asphaleiaAssets compatibleWithTraitCollection:nil];
          tag = ASAuthenticationFunction;
          break;
        }
        case ASAuthenticationAlertControlCentre: {
          title = @"Control Center";
          iconImage = [UIImage imageNamed:@"IconControlCenter.png" inBundle:asphaleiaAssets compatibleWithTraitCollection:nil];
          tag = ASAuthenticationFunction;
          break;
        }
        case ASAuthenticationAlertControlPanel: {
          title = @"Asphaleia Control Panel";
          iconImage = [UIImage imageNamed:@"IconDefault.png" inBundle:asphaleiaAssets compatibleWithTraitCollection:nil];
          tag = ASAuthenticationSecurityMod;
          break;
        }
        case ASAuthenticationAlertDynamicSelection: {
          title = @"Dynamic Selection";
          iconImage = [UIImage imageNamed:@"IconDefault.png" inBundle:asphaleiaAssets compatibleWithTraitCollection:nil];
          tag = ASAuthenticationSecurityMod;
          break;
        }
        case ASAuthenticationAlertPhotos: {
          title = @"Photo Library";
          iconImage = [UIImage imageNamed:@"IconDefault.png" inBundle:asphaleiaAssets compatibleWithTraitCollection:nil];
          tag = ASAuthenticationFunction;
          break;
        }
        case ASAuthenticationAlertSettingsPanel: {
          title = @"Settings Panel";
          iconImage = [UIImage imageNamed:@"IconDefault.png" inBundle:asphaleiaAssets compatibleWithTraitCollection:nil];
          tag = ASAuthenticationItem;
          break;
        }
        case ASAuthenticationAlertFlipswitch: {
          title = @"Flipswitch";
          iconImage = [UIImage imageNamed:@"IconDefault.png" inBundle:asphaleiaAssets compatibleWithTraitCollection:nil];
          tag = ASAuthenticationItem;
          break;
        }
        default: {
          title = @"Asphaleia";
          iconImage = [UIImage imageNamed:@"IconDefault.png" inBundle:asphaleiaAssets compatibleWithTraitCollection:nil];
          tag = ASAuthenticationFunction;
          break;
        }
    }

    UIImageView *imgView = [[UIImageView alloc] initWithImage:iconImage];
    imgView.frame = CGRectMake(0,0,iconImage.size.width,iconImage.size.height);

    ASAuthenticationAlert *alertView = [[objc_getClass("ASAuthenticationAlert") alloc] initWithTitle:title
                   message:@"Scan fingerprint to access."
                   icon:imgView
                   smallIcon:YES
                   delegate:delegate];
    alertView.tag = tag;

    return alertView;
}

- (BOOL)authenticateAppWithDisplayIdentifier:(NSString *)appIdentifier customMessage:(NSString *)customMessage dismissedHandler:(ASCommonAuthenticationHandler)handler {
    [[objc_getClass("SBIconController") sharedInstance] asphaleia_resetAsphaleiaIconView];

    if (![[ASPreferences sharedInstance] requiresSecurityForApp:appIdentifier]) {
        return NO;
    }

    authHandler = [handler copy];

    ASAuthenticationAlert *alertView = [self returnAppAuthenticationAlertWithApplication:appIdentifier customMessage:customMessage delegate:self];

    if (![[ASPreferences sharedInstance] touchIDEnabled] && ![[ASPreferences sharedInstance] passcodeEnabled]) {
        return NO;
    }

    if (![[ASPreferences sharedInstance] touchIDEnabled]) {
        [[ASPasscodeHandler sharedInstance] showInKeyWindowWithPasscode:[[ASPreferences sharedInstance] getPasscode] iconView:nil eventBlock:^void(BOOL authenticated){
                if (authenticated)
                    _appUserAuthorisedID = appIdentifier;
                authHandler(!authenticated);
            }];
        return YES;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        [alertView show];
    });
    return YES;
}

- (BOOL)authenticateFunction:(ASAuthenticationAlertType)alertType dismissedHandler:(ASCommonAuthenticationHandler)handler {
    if ([ASPreferences sharedInstance].asphaleiaDisabled) {
        return NO;
    }

    [[objc_getClass("SBIconController") sharedInstance] asphaleia_resetAsphaleiaIconView];
    authHandler = [handler copy];

    ASAuthenticationAlert *alertView = [self returnAuthenticationAlertOfType:alertType delegate:self];

    if (![[ASPreferences sharedInstance] touchIDEnabled] && ![[ASPreferences sharedInstance] passcodeEnabled]) {
        return NO;
    }

    if (![[ASPreferences sharedInstance] touchIDEnabled]) {
        [[ASPasscodeHandler sharedInstance] showInKeyWindowWithPasscode:[[ASPreferences sharedInstance] getPasscode] iconView:nil eventBlock:^void(BOOL authenticated){
            authHandler(!authenticated);
        }];
        return YES;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        [alertView show];
    });
    return YES;
}

- (BOOL)authenticateAppWithIconView:(SBIconView *)iconView authenticatedHandler:(ASCommonAuthenticationHandler)handler {
    if (![[NSBundle mainBundle].bundleIdentifier isEqualToString:@"com.apple.springboard"]) {
      return NO;
    }

    if ([ASPreferences sharedInstance].asphaleiaDisabled || [ASPreferences sharedInstance].itemSecurityDisabled || [[iconView icon] isDownloadingIcon]) {
        [[objc_getClass("SBIconController") sharedInstance] asphaleia_resetAsphaleiaIconView];
        [iconView setHighlighted:NO];
        return NO;
    }

    NSString *displayName;
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.4")) {
        displayName = [iconView.icon displayNameForLocation:iconView.location];
    } else {
        displayName = [iconView.icon displayName];
    }
    currentAuthAppBundleID = iconView.icon.applicationBundleID;

    if (_fingerglyph && _currentHSIconView) {
        [iconView setHighlighted:NO];
        if ([iconView isEqual:_currentHSIconView]) {
            [[ASPasscodeHandler sharedInstance] showInKeyWindowWithPasscode:[[ASPreferences sharedInstance] getPasscode] iconView:iconView eventBlock:^void(BOOL authenticated){
                if (authenticated) {
                    [ASAuthenticationController sharedInstance].appUserAuthorisedID = iconView.icon.applicationBundleID;
                }
                handler(!authenticated);
            }];
        }
        [[objc_getClass("SBIconController") sharedInstance] asphaleia_resetAsphaleiaIconView];

        return YES;
    } else if (([iconView.icon isApplicationIcon] && ![[ASPreferences sharedInstance] requiresSecurityForApp:iconView.icon.applicationBundleID]) || ([iconView.icon isFolderIcon] && ![[ASPreferences sharedInstance] requiresSecurityForFolder:displayName])) {
        [iconView setHighlighted:NO];
        return NO;
    } else if (![[ASPreferences sharedInstance] touchIDEnabled] && [[ASPreferences sharedInstance] passcodeEnabled]) {
        [iconView setHighlighted:NO];
        [[ASPasscodeHandler sharedInstance] showInKeyWindowWithPasscode:[[ASPreferences sharedInstance] getPasscode] iconView:iconView eventBlock:^void(BOOL authenticated){

            if (authenticated){
                [ASAuthenticationController sharedInstance].appUserAuthorisedID = iconView.icon.applicationBundleID;
            }
            handler(!authenticated);
        }];
        return YES;
    }

    if (!_anywhereTouchWindow) {
        _anywhereTouchWindow = [[ASTouchWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    }

    _currentHSIconView = iconView;

    [self initialiseGlyphIfRequired];

    CGRect fingerframe = _fingerglyph.frame;
    fingerframe.size.height = [iconView _iconImageView].frame.size.height-10;
    fingerframe.size.width = [iconView _iconImageView].frame.size.width-10;
    _fingerglyph.frame = fingerframe;
    _fingerglyph.center = CGPointMake(CGRectGetMidX([iconView _iconImageView].bounds),CGRectGetMidY([iconView _iconImageView].bounds));
    [[iconView _iconImageView] addSubview:_fingerglyph];

    _fingerglyph.transform = CGAffineTransformMakeScale(0.01,0.01);
    [UIView animateWithDuration:0.3f animations:^{
        _fingerglyph.transform = CGAffineTransformMakeScale(1,1);
    }];

    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.a3tweaks.asphaleia.startmonitoring"), NULL, NULL, YES);

    [_currentHSIconView asphaleia_updateLabelWithText:@"Scan finger..."];

    [_anywhereTouchWindow blockTouchesAllowingTouchInView:_currentHSIconView touchBlockedHandler:^void(ASTouchWindow *touchWindow, BOOL blockedTouch){
        if (blockedTouch) {
            [[objc_getClass("SBIconController") sharedInstance] asphaleia_resetAsphaleiaIconView];
            handler(YES);
        }
    }];
    return YES;
}

- (void)receivedNotificationOfName:(NSString *)name fingerprint:(id)fingerprint {
    if (self.currentHSIconView) {
        if ([fingerprint isKindOfClass:objc_getClass("BiometricKitIdentity")]) {
            if (![[ASPreferences sharedInstance] fingerprintProtectsSecureItems:[fingerprint name]]) {
              name = @"com.a3tweaks.asphaleia.authfailed";
            }
        }
        if (![[NSBundle mainBundle].bundleIdentifier isEqualToString:@"com.apple.springboard"]) {
          return;
        }
        if ([name isEqualToString:@"com.a3tweaks.asphaleia.fingerdown"]) {
            if (_fingerglyph && _currentHSIconView) {
                [_fingerglyph setState:1 animated:YES completionHandler:nil];
                [_currentHSIconView asphaleia_updateLabelWithText:@"Scanning..."];
            }
        } else if ([name isEqualToString:@"com.a3tweaks.asphaleia.fingerup"]) {
            if (_fingerglyph) {
              [_fingerglyph setState:0 animated:YES completionHandler:nil];
            }
        } else if ([name isEqualToString:@"com.a3tweaks.asphaleia.authsuccess"]) {
            if (_fingerglyph && _currentHSIconView) {
                [ASAuthenticationController sharedInstance].appUserAuthorisedID = currentAuthAppBundleID;
                if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.3")) {
                    [_currentHSIconView.icon launchFromLocation:_currentHSIconView.location context:nil];
                } else {
                    [_currentHSIconView.icon launchFromLocation:_currentHSIconView.location];
                }
                [[objc_getClass("SBIconController") sharedInstance] asphaleia_resetAsphaleiaIconView];
                currentAuthAppBundleID = nil;
            }
        } else if ([name isEqualToString:@"com.a3tweaks.asphaleia.authfailed"]) {
            if (_fingerglyph && _currentHSIconView) {
                [_fingerglyph setState:0 animated:YES completionHandler:nil];
                [_currentHSIconView asphaleia_updateLabelWithText:@"Scan finger..."];
            }
        }
    }
}

- (void)registerForTouchIDNotifications {
    addObserver(touchIDNotificationReceived, "com.a3tweaks.asphaleia.fingerdown");
    addObserver(touchIDNotificationReceived, "com.a3tweaks.asphaleia.fingerup");
    addObserver(touchIDNotificationReceived, "com.a3tweaks.asphaleia.authsuccess");
    addObserver(touchIDNotificationReceived, "com.a3tweaks.asphaleia.authfailed");
}

- (void)deregisterForTouchIDNotifications {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)dismissAnyAuthenticationAlerts {
    if (self.currentAuthAlert)
        [self.currentAuthAlert dismiss];
}

- (NSArray *)allSubviewsOfView:(UIView *)view {
    NSMutableArray *viewArray = [[NSMutableArray alloc] init];
    [viewArray addObject:view];
    for (UIView *subview in view.subviews) {
        [viewArray addObjectsFromArray:(NSArray *)[self allSubviewsOfView:subview]];
    }
    return [NSArray arrayWithArray:viewArray];
}

- (void)initialiseGlyphIfRequired {
    if (!_fingerglyph) {
        _fingerglyph = [(PKGlyphView*)[objc_getClass("PKGlyphView") alloc] initWithStyle:1];
        _fingerglyph.secondaryColor = [UIColor grayColor];
        _fingerglyph.primaryColor = [UIColor redColor];
    }
}

// ASAuthenticationAlert delegate methods
- (void)authAlertView:(ASAuthenticationAlert *)alertView dismissed:(BOOL)dismissed authorised:(BOOL)authorised fingerprint:(BiometricKitIdentity *)fingerprint {
    BOOL correctFingerUsed = YES;
    if ([fingerprint isKindOfClass:objc_getClass("BiometricKitIdentity")]) {
        correctFingerUsed = NO;
        switch (self.currentAuthAlert.tag) {
            case ASAuthenticationItem:
                correctFingerUsed = [[ASPreferences sharedInstance] fingerprintProtectsSecureItems:[fingerprint name]];
                break;
            case ASAuthenticationFunction:
                correctFingerUsed = [[ASPreferences sharedInstance] fingerprintProtectsAdvancedSecurity:[fingerprint name]];
                break;
            case ASAuthenticationSecurityMod:
                correctFingerUsed = [[ASPreferences sharedInstance] fingerprintProtectsSecurityMods:[fingerprint name]];
                break;
            default:
                correctFingerUsed = YES;
                break;
        }
    }

    if (!correctFingerUsed) {
      return;
    } else if (correctFingerUsed && !dismissed) {
      [self.currentAuthAlert dismiss];
    }
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.a3tweaks.asphaleia.stopmonitoring"), NULL, NULL, YES);
    if (authorised) {
      _appUserAuthorisedID = currentAuthAppBundleID;
    }

    authHandler(!(authorised && correctFingerUsed));
    self.currentAuthAlert = nil;
    currentAuthAppBundleID = nil;
}

@end
