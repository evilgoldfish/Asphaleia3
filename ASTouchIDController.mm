/* Modified from Sassoty's code
https://github.com/Sassoty/BioTesting */
#import "ASTouchIDController.h"
#import <objc/runtime.h>
#import <UIKit/UIKit.h>
#import "ASActivatorListener.h"
#import "ASControlPanel.h"
#import <libactivator/libactivator.h>
#import <dlfcn.h>
#import <AudioToolbox/AudioServices.h>
#import "ASPreferences.h"
#import <substrate.h>
#import <notify.h>

#define ENABLE_VH "virtualhome.enable"
#define DISABLE_VH "virtualhome.disable"

@interface ASTouchIDController ()
@property (readwrite) BOOL isMonitoring;
@property (readwrite) id lastMatchedFingerprint;
@end

@interface SBScreenFlash
+ (id)mainScreenFlasher;
- (void)flashWhiteWithCompletion:(id)completion;
@end

void startMonitoringNotification(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
	[[ASTouchIDController sharedInstance] startMonitoring];
}

void stopMonitoringNotification(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
	[[ASTouchIDController sharedInstance] stopMonitoring];
}

@implementation ASTouchIDController

+ (instancetype)sharedInstance {
	// Setup instance for current class once
	static id sharedInstance = nil;
	static dispatch_once_t token = 0;
	dispatch_once(&token, ^{
		sharedInstance = [self new];
		addObserver(startMonitoringNotification,"com.a3tweaks.asphaleia.startmonitoring");
		addObserver(stopMonitoringNotification,"com.a3tweaks.asphaleia.stopmonitoring");
	});
	// Provide instance
	return sharedInstance;
}

- (void)biometricKitInterface:(id)interface handleEvent:(unsigned long long)event {
	//[[objc_getClass("SBScreenFlash") mainScreenFlasher] flashWhiteWithCompletion:nil];
	if (!self.isMonitoring || ![ASPreferences isTouchIDDevice]) {
		return;
	}

	switch (event) {
		case TouchIDFingerDown: {
			asphaleiaLogMsg(@"Finger down");
			[[NSNotificationCenter defaultCenter] postNotificationName:@"com.a3tweaks.asphaleia.fingerdown" object:self];
			CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.a3tweaks.asphaleia.fingerdown"), NULL, NULL, YES);
			break;
		}
		case TouchIDFingerUp: {
			asphaleiaLogMsg(@"Finger up");
			[[NSNotificationCenter defaultCenter] postNotificationName:@"com.a3tweaks.asphaleia.fingerup" object:self];
			CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.a3tweaks.asphaleia.fingerup"), NULL, NULL, YES);
			break;
		}
		case TouchIDFingerHeld:
			asphaleiaLogMsg(@"Finger held");
			[[NSNotificationCenter defaultCenter] postNotificationName:@"com.a3tweaks.asphaleia.fingerheld" object:self];
			CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.a3tweaks.asphaleia.fingerheld"), NULL, NULL, YES);
			break;
		case TouchIDMatched:
			asphaleiaLogMsg(@"Finger matched");
			[[NSNotificationCenter defaultCenter] postNotificationName:@"com.a3tweaks.asphaleia.authsuccess" object:self];
			CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.a3tweaks.asphaleia.authsuccess"), NULL, NULL, YES);
			[self stopMonitoring];
			_shouldBlockLockscreenMonitor = NO;
			break;
		case TouchIDNotMatched: {
			asphaleiaLogMsg(@"Authentication failed");
			[[NSNotificationCenter defaultCenter] postNotificationName:@"com.a3tweaks.asphaleia.authfailed" object:self];
			CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.a3tweaks.asphaleia.authfailed"), NULL, NULL, YES);
			if ([[ASPreferences sharedInstance] vibrateOnIncorrectFingerprint]) {
				AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
			}
			break;
		}
		// For the new iPhone
		case 10: {
			asphaleiaLogMsg(@"Authentication failed");
			[[NSNotificationCenter defaultCenter] postNotificationName:@"com.a3tweaks.asphaleia.authfailed" object:self];
			CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.a3tweaks.asphaleia.authfailed"), NULL, NULL, YES);
			if ([[ASPreferences sharedInstance] vibrateOnIncorrectFingerprint]) {
				AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
			}
			break;
		}
	}
}

- (void)matchResult:(id)result withDetails:(id)details {
	if (result) {
		asphaleiaLogMsg(@"Finger matched");
		[[NSNotificationCenter defaultCenter] postNotificationName:@"com.a3tweaks.asphaleia.authsuccess" object:self userInfo:@{ @"fingerprint" : result }];
		self.lastMatchedFingerprint = result;
		CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.a3tweaks.asphaleia.authsuccess"), NULL, NULL, YES);
		_shouldBlockLockscreenMonitor = NO;
	}
}

- (void)startMonitoring {
	// If already monitoring, don't start again
	if (self.isMonitoring || starting || ![ASPreferences isTouchIDDevice]) {
		return;
	}
	starting = YES;

/*
	LAActivator *activator = [objc_getClass("LAActivator") sharedInstance];
	if (activator) {
		LAEvent *event = [objc_getClass("LAEvent") eventWithName:@"libactivator.fingerprint-sensor.press.single" mode:activator.currentEventMode];
		if (event) {
			activatorListenerNames = [activator assignedListenerNamesForEvent:event];
			if (activatorListenerNames) {
				for (NSString *listenerName in activatorListenerNames) {
					[activator removeListenerAssignment:listenerName fromEvent:event];
				}
			}
		}
	}
*/

	_SBUIBiometricKitInterface *interface = [[objc_getClass("BiometricKit") manager] delegate];
	_oldDelegate = interface.delegate;

	dlopen("/usr/lib/libactivator.dylib", RTLD_LAZY);
	Class la = objc_getClass("LASharedActivator");
	if (la) {
		if ([(LAActivator *)objc_getClass("LASharedActivator") hasListenerWithName:@"Dynamic Selection"]) {
			[[ASActivatorListener sharedInstance] unload];
		}

		if ([(LAActivator *)objc_getClass("LASharedActivator") hasListenerWithName:@"Control Panel"]) {
			[[ASControlPanel sharedInstance] unload];
		}
	}

	// Begin listening :D
	[interface setDelegate:self];
	[interface matchWithMode:0 andCredentialSet:nil];

	starting = NO;
	self.isMonitoring = YES;

	asphaleiaLogMsg(@"Touch ID monitoring began");
}

- (void)stopMonitoring {
	if (!self.isMonitoring || stopping || ![ASPreferences isTouchIDDevice]) {
		return;
	}
	stopping = YES;

	_SBUIBiometricKitInterface *interface = [[objc_getClass("BiometricKit") manager] delegate];
	[interface cancel];
	[interface setDelegate:_oldDelegate];
	[interface detectFingerWithOptions:nil];

	_oldDelegate = nil;

/*
	LAActivator *activator = [objc_getClass("LAActivator") sharedInstance];
  if (activator && activatorListenerNames) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^(void){
			LAEvent *event = [objc_getClass("LAEvent") eventWithName:@"libactivator.fingerprint-sensor.press.single" mode:activator.currentEventMode];
			if (event) {
				for (NSString *listenerName in activatorListenerNames) {
					[activator addListenerAssignment:listenerName toEvent:event];
				}
			}
		});
	}
*/

	dlopen("/usr/lib/libactivator.dylib", RTLD_LAZY);
	Class la = objc_getClass("LASharedActivator");
	if (la) {
		if (![(LAActivator *)objc_getClass("LASharedActivator") hasListenerWithName:@"Dynamic Selection"]) {
			[[ASActivatorListener sharedInstance] load];
		}
		if (![(LAActivator *)objc_getClass("LASharedActivator") hasListenerWithName:@"Control Panel"]) {
			[[ASControlPanel sharedInstance] load];
		}
	}

	stopping = NO;
	self.isMonitoring = NO;

	asphaleiaLogMsg(@"Touch ID monitoring ended");
}

@end
