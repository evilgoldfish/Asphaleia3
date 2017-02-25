#include "ASSecuredItemsListController.h"
#import "ASRootListController.h"
#import <Preferences/PSSpecifier.h>
#import <dlfcn.h>
#import <objc/runtime.h>
#import <libactivator/libactivator.h>

@implementation ASSecuredItemsListController

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"SecuredItems" target:self] retain];
	}
	dlopen("/usr/lib/libactivator.dylib", RTLD_LAZY);
  Class la = objc_getClass("LAActivator");
  if (!la) {
		NSMutableArray *mutableSpecifiers = [_specifiers mutableCopy];
		[(PSSpecifier *)_specifiers[0] setProperty:@"Activator is required to use this feature." forKey:@"footerText"];
		[(PSSpecifier *)_specifiers[1] setProperty:[NSNumber numberWithBool:NO] forKey:@"enabled"];
		[mutableSpecifiers removeObjectAtIndex:2];
		_specifiers = [mutableSpecifiers copy];
	}
	return _specifiers;
}

-(void)openDynamicSelActivatorControlPanel {
	dlopen("/usr/lib/libactivator.dylib", RTLD_LAZY);
    Class la = objc_getClass("LAListenerSettingsViewController");
    if (la) {
        LAListenerSettingsViewController *vc = [[la alloc] init];
        [vc setListenerName:@"Dynamic Selection"];
        vc.title = @"Dynamic Selection";
        [self.navigationController pushViewController:vc animated:YES];
    }
}

- (id)readPreferenceValue:(PSSpecifier*)specifier {
    NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:PreferencesPath];
    if (!settings[specifier.properties[@"key"]]) {
        return specifier.properties[@"default"];
    }
    return settings[specifier.properties[@"key"]];
}

- (void)setPreferenceValue:(id)value specifier:(PSSpecifier*)specifier {
    NSMutableDictionary *defaults = [NSMutableDictionary dictionary];
    [defaults addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:PreferencesPath]];
    [defaults setObject:value forKey:specifier.properties[@"key"]];
    [defaults writeToFile:PreferencesPath atomically:YES];
    CFStringRef toPost = (CFStringRef)specifier.properties[@"PostNotification"];
    if (toPost) CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), toPost, NULL, NULL, YES);
}

@end
