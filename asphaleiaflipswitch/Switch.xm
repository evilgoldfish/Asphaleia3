#import "FSSwitchDataSource.h"
#import "FSSwitchPanel.h"
#import "../ASPreferences.h"

@interface NSUserDefaults (Tweak_Category)
- (id)objectForKey:(NSString *)key inDomain:(NSString *)domain;
- (void)setObject:(id)value forKey:(NSString *)key inDomain:(NSString *)domain;
@end

//static NSString *nsNotificationString = @"com.a3tweaks.asphaleia/ReloadPrefs";

@interface ASPreferences ()
@property (readwrite) BOOL asphaleiaDisabled;
@property (readwrite) BOOL itemSecurityDisabled;
@end

@interface AsphaleiaFlipswitchSwitch : NSObject <FSSwitchDataSource> {
	BOOL state;
}
@end

@implementation AsphaleiaFlipswitchSwitch

- (instancetype)init {
	AsphaleiaFlipswitchSwitch *flipswitch = [super init];
	if (flipswitch) {
		loadPreferences();
	}
	return flipswitch;
}

- (NSString *)titleForSwitchIdentifier:(NSString *)switchIdentifier {
	return @"Asphaleia";
}

- (FSSwitchState)stateForSwitchIdentifier:(NSString *)switchIdentifier {
	return (![ASPreferences sharedInstance].asphaleiaDisabled) ? FSSwitchStateOn : FSSwitchStateOff;
}

- (void)applyState:(FSSwitchState)newState forSwitchIdentifier:(NSString *)switchIdentifier {
	switch (newState) {
	case FSSwitchStateIndeterminate:
		break;
	case FSSwitchStateOn:
		[ASPreferences sharedInstance].asphaleiaDisabled = NO;
		break;
	case FSSwitchStateOff:
		[ASPreferences sharedInstance].asphaleiaDisabled = YES;
		break;
	}
	return;
}

@end
