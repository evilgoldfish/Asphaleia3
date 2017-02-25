#import <notify.h>
#import <objc/message.h>

#define addObserver(c, n) CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (c), CFSTR(n), NULL, CFNotificationSuspensionBehaviorCoalesce)
#define loadPreferences() preferencesChangedCallback(NULL, NULL, NULL, NULL, NULL)

void preferencesChangedCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo);

#define kSecuredAppsKey @"securedApps"
#define kSecuredFoldersKey @"securedFolders"
#define kSecuredPanelsKey @"securedPanels"
#define kSecuredSwitchesKey @"securedSwitches"
#define kSecureSwitcherKey @"secureSwitcher"
#define kSecureAppArrangementKey @"preventAppDeletion"
#define kObscureAppContentKey @"obscureAppContent"
#define kObscureBannerKey @"obscureBanners"
#define kUnsecureUnlockToAppKey @"easyUnlockIntoApp"
#define kWifiUnlockKey @"wifiUnlock"
#define kWifiUnlockNetworkKey @"wifiNetwork"
#define kSecureSpotlightKey @"secureSpotlight"
#define kSecurePowerDownKey @"preventPowerOff"
#define kSecureControlCentreKey @"secureCC"
#define kVibrateOnFailKey @"vibrateOnFail"
#define kProtectAllAppsKey @"globalAppSecurity"
#define kDynamicSelectionKey @"dynamicSelection"
#define kAppExitUnlockTimeKey @"timeInterval"
#define kResetAppExitTimerOnLockKey @"ResetTimerOnLock"
#define kDelayAfterLockKey @"delayAfterLock"
#define kDelayAfterLockTimeKey @"timeIntervalLock"
#define kControlPanelInAppsKey @"controlPanelAllowedInApps"
#define kEnableControlPanelKey @"controlPanel"
#define kPasscodeKey @"passcode"
#define kPasscodeEnabledKey @"simplePasscode"
#define kTouchIDEnabledKey @"touchID"
#define kSecurePhotosKey @"securePhotos"
#define kPhotosMessageCount @"photosMsgDisplayCount"
#define kSecuredItemsFingerprintsKey @"securedItemsFingerprints"
#define kSecurityModFingerprintsKey @"securityModifiersFingerprints"
#define kAdvancedSecurityFingerprintsKey @"advancedSecurityFingerprints"
#define kFingerprintSettingsKey @"fingerprintSettings"

@interface ASPreferences : NSObject {
	NSDictionary *_prefs;
}
@property (readonly) BOOL asphaleiaDisabled;
@property (readonly) BOOL itemSecurityDisabled;
+ (instancetype)sharedInstance;
+ (BOOL)isTouchIDDevice;
+ (BOOL)devicePasscodeSet;
- (id)objectForKey:(NSString *)key;
- (void)setObject:(id)object forKey:(NSString *)key;
- (BOOL)requireAuthorisationOnWifi;
- (BOOL)touchIDEnabled;
- (BOOL)passcodeEnabled;
- (NSString *)getPasscode;
- (BOOL)enableControlPanel;
- (BOOL)allowControlPanelInApps;
- (NSInteger)appSecurityDelayTime;
- (BOOL)delayAppSecurity;
- (BOOL)resetAppExitTimerOnLock;
- (NSInteger)appExitUnlockTime;
- (BOOL)enableDynamicSelection;
- (BOOL)protectAllApps;
- (BOOL)vibrateOnIncorrectFingerprint;
- (BOOL)secureControlCentre;
- (BOOL)securePowerDownView;
- (BOOL)secureSpotlight;
- (BOOL)unlockToAppUnsecurely;
- (BOOL)obscureAppContent;
- (BOOL)obscureNotifications;
- (BOOL)secureSwitcher;
- (BOOL)secureAppArrangement;
- (BOOL)securePhotos;
- (BOOL)showPhotosProtectMessage;
- (void)increasePhotosProtectMessageCount;
- (BOOL)securityEnabledForApp:(NSString *)app;
- (BOOL)requiresSecurityForApp:(NSString *)app;
- (BOOL)requiresSecurityForFolder:(NSString *)folder;
- (BOOL)requiresSecurityForPanel:(NSString *)panel;
- (BOOL)requiresSecurityForSwitch:(NSString *)flipswitch;

- (BOOL)fingerprintProtectsSecureItems:(NSString *)fingerprint;
- (BOOL)fingerprintProtectsSecurityMods:(NSString *)fingerprint;
- (BOOL)fingerprintProtectsAdvancedSecurity:(NSString *)fingerprint;
@end
