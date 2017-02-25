#include "ASControlPanelListController.h"
#import "ASRootListController.h"
#import "modalPinVC.h"
#import "TouchIDInfo.h"
#import <Preferences/PSSpecifier.h>
#import <dlfcn.h>
#import <objc/runtime.h>
#import <libactivator/libactivator.h>

@implementation ASControlPanelListController

- (NSArray *)specifiers {
	if (!_specifiers) {
      _specifiers = [[self loadSpecifiersFromPlistName:@"PasscodeOptions-AsphaleiaControlPanel" target:self] retain];
  }
  return _specifiers;
}

- (void)openActivatorControlPanel {
    dlopen("/usr/lib/libactivator.dylib", RTLD_LAZY);
    Class la = objc_getClass("LAListenerSettingsViewController");
    if (la) {
        LAListenerSettingsViewController *vc = [[la alloc] init];
        [vc setListenerName:@"Control Panel"];
        vc.title = @"Control Panel";
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
