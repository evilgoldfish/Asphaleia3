#import "ASControlPanel.h"
#import "ASAuthenticationController.h"
#import "Asphaleia.h"
#import "ASPreferences.h"
#import <objc/runtime.h>
#import <dlfcn.h>

#define kBundlePath @"/Library/Application Support/Asphaleia/AsphaleiaAssets.bundle"
#define titleWithSpacingForSmallIcon(t) [NSString stringWithFormat:@"\n\n%@",t]

static NSString *img = @"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";

@interface ASControlPanel ()
@property ASAlert *alertView;
@end

@interface ASPreferences ()
@property (readwrite) BOOL asphaleiaDisabled;
@property (readwrite) BOOL itemSecurityDisabled;
@end

@implementation ASControlPanel

+ (instancetype)sharedInstance {
    static id sharedInstance = nil;
    static dispatch_once_t token = 0;
    dispatch_once(&token, ^{
        sharedInstance = [self new];
        dlopen("/usr/lib/libactivator.dylib", RTLD_LAZY);
        [sharedInstance setValue:[[NSData alloc] initWithBase64EncodedString:img options:NSDataBase64DecodingIgnoreUnknownCharacters] forKey:@"smallIconData"];
    });
    return sharedInstance;
}

- (void)activator:(LAActivator *)activator receiveEvent:(LAEvent *)event {
    SBApplication *frontmostApp = [(SpringBoard *)[UIApplication sharedApplication] _accessibilityFrontMostApplication];
    NSString *bundleID = [frontmostApp bundleIdentifier];
    if ((bundleID && ![[ASPreferences sharedInstance] allowControlPanelInApps]) || ![[ASPreferences sharedInstance] enableControlPanel]) {
        [event setHandled:YES];
        return;
    }

    [[ASAuthenticationController sharedInstance] authenticateFunction:ASAuthenticationAlertControlPanel dismissedHandler:^(BOOL wasCancelled) {
        if (!wasCancelled) {
            NSString *mySecuredAppsTitle = [ASPreferences sharedInstance].itemSecurityDisabled ? @"Enable My Secured Items" : @"Disable My Secured Items";
            NSString *enableGlobalAppsTitle = ![[ASPreferences sharedInstance] protectAllApps] ? @"Enable Global App Security" : @"Disable Global App Security"; // Enable/Disable
            NSString *addRemoveFromSecureAppsTitle = nil;
            if (bundleID) {
                addRemoveFromSecureAppsTitle = [[ASPreferences sharedInstance] securityEnabledForApp:bundleID] ? @"Remove from your Secured Apps" : @"Add to your Secured Apps";
            }
            NSMutableArray *buttonTitleArray = [NSMutableArray arrayWithObjects:mySecuredAppsTitle, enableGlobalAppsTitle, nil];
            if (addRemoveFromSecureAppsTitle) {
              [buttonTitleArray addObject:addRemoveFromSecureAppsTitle];
            }

            self.alertView = [[objc_getClass("ASAlert") alloc] initWithTitle:@"Asphaleia Control Panel"
                                message:nil
                                delegate:self];
            for (NSString *buttonTitle in buttonTitleArray) {
              [self.alertView addButtonWithTitle:buttonTitle];
            }
            [self.alertView addButtonWithTitle:@"Close"];
            [self.alertView setCancelButtonIndex:buttonTitleArray.count];
            NSBundle *asphaleiaAssets = [[NSBundle alloc] initWithPath:kBundlePath];
            UIImage *iconImage = [UIImage imageNamed:@"IconDefault.png" inBundle:asphaleiaAssets compatibleWithTraitCollection:nil];
            UIImageView *imgView = [[UIImageView alloc] initWithImage:iconImage];
            imgView.frame = CGRectMake(0,0,iconImage.size.width,iconImage.size.height);
            imgView.center = CGPointMake(270/2,32);
            [self.alertView setAboveTitleSubview:imgView];

            [self.alertView show];
        }
    }];

    [event setHandled:YES];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    SBApplication *frontmostApp = [(SpringBoard *)[UIApplication sharedApplication] _accessibilityFrontMostApplication];
    NSString *bundleID = [frontmostApp bundleIdentifier];
    switch (buttonIndex) {
        case 0: {
          [ASPreferences sharedInstance].itemSecurityDisabled = ![ASPreferences sharedInstance].itemSecurityDisabled;
          if ([ASPreferences sharedInstance].itemSecurityDisabled && [[ASPreferences sharedInstance] protectAllApps]) {
              [[ASPreferences sharedInstance] setObject:[NSNumber numberWithBool:NO] forKey:kProtectAllAppsKey];
          }
          break;
        }
        case 1: {
          [[ASPreferences sharedInstance] setObject:[NSNumber numberWithBool:![[ASPreferences sharedInstance] protectAllApps]] forKey:kProtectAllAppsKey];

          if ([ASPreferences sharedInstance].itemSecurityDisabled && [[ASPreferences sharedInstance] protectAllApps]) {
              [ASPreferences sharedInstance].itemSecurityDisabled = NO;
          }
          break;
        }
        case 2: {
          if (alertView.cancelButtonIndex == 2) {
            break;
          }
          if (![[ASPreferences sharedInstance] objectForKey:kSecuredAppsKey]) {
            [[ASPreferences sharedInstance] setObject:[NSMutableDictionary dictionary] forKey:kSecuredAppsKey];
          }

          NSMutableDictionary *dict = [[ASPreferences sharedInstance] objectForKey:kSecuredAppsKey];
          [dict setObject:[NSNumber numberWithBool:![[ASPreferences sharedInstance] securityEnabledForApp:bundleID]] forKey:frontmostApp.bundleIdentifier];
          [[ASPreferences sharedInstance] setObject:dict forKey:kSecuredAppsKey];
          break;
        }
    }
}

- (void)activator:(LAActivator *)activator abortEvent:(LAEvent *)event {
    if (self.alertView) {
        [self.alertView dismiss];
        self.alertView = nil;
    }
}

- (void)load {
    if (objc_getClass("LAActivator")) {
        if ([[objc_getClass("LAActivator") sharedInstance] isRunningInsideSpringBoard]) {
          [[objc_getClass("LAActivator") sharedInstance] registerListener:self forName:@"Control Panel"];
        }
    }
}

- (void)unload {
    if (objc_getClass("LAActivator")) {
        if ([[objc_getClass("LAActivator") sharedInstance] isRunningInsideSpringBoard]) {
          [[objc_getClass("LAActivator") sharedInstance] unregisterListenerWithName:@"Control Panel"];          
        }
    }
}

- (NSString *)activator:(LAActivator *)activator requiresLocalizedGroupForListenerName:(NSString *)listenerName {
    return @"Asphaleia";
}

- (NSString *)activator:(LAActivator *)activator requiresLocalizedTitleForListenerName:(NSString *)listenerName {
    return @"Control Panel";
}

- (NSString *)activator:(LAActivator *)activator requiresLocalizedDescriptionForListenerName:(NSString *)listenerName {
    return @"Open Asphaleia's control panel";
}

- (NSArray *)activator:(LAActivator *)activator requiresCompatibleEventModesForListenerWithName:(NSString *)listenerName {
    return [NSArray arrayWithObjects:@"springboard", @"application", nil];
}

- (NSData *)activator:(LAActivator *)activator requiresSmallIconDataForListenerName:(NSString *)listenerName scale:(CGFloat *)scale {
    return smallIconData;
}

@end
