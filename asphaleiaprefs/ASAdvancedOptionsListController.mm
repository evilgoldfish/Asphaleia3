#include "ASAdvancedOptionsListController.h"
#import "ASRootListController.h"
#import "modalPinVC.h"
#import "TouchIDInfo.h"
#import <Preferences/PSSpecifier.h>
#import <SystemConfiguration/CaptiveNetwork.h>

static UITextField *wifiTextField;

@implementation ASAdvancedOptionsListController

- (NSArray *)specifiers {
	if (!_specifiers) {
      _specifiers = [[self loadSpecifiersFromPlistName:@"PasscodeOptions-AdvancedOptions" target:self] retain];
  }
	
	if (!isTouchIDDevice()) {
			NSMutableArray *mutableSpecifiers = [_specifiers mutableCopy];
      for (PSSpecifier *specifier in [_specifiers copy]) {
          if ([[specifier identifier] isEqualToString:@"fingerprintCell"] || [[specifier identifier] isEqualToString:@"fingerprintGroupCell"])
              [mutableSpecifiers removeObject:specifier];
      }
			_specifiers = [mutableSpecifiers copy];
  }

  return _specifiers;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    for (id subview in [cell.contentView subviews]) {
        if ([subview isKindOfClass:[UITextField class]]) {
            wifiTextField = subview;
            wifiTextField.delegate = self;
            [wifiTextField setReturnKeyType:UIReturnKeyDone];
        }
    }
    return cell;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textfield {
    [textfield resignFirstResponder];
    return YES;
}

- (void)addCurrentNetwork {
    NSMutableDictionary *settings = [NSMutableDictionary dictionaryWithContentsOfFile:kPreferencesPath];
    NSMutableString *currentWifiString = [NSMutableString stringWithString:[wifiTextField text]];
    NSString *currentSSID = [self currentWifiSSID];
    NSArray *networks = [currentWifiString componentsSeparatedByString:@", "];
    if (![networks containsObject:currentSSID]) {
        if(currentWifiString.length != 0) {
            [currentWifiString appendString:@", "];
        }
        [currentWifiString appendString:currentSSID];
        [wifiTextField setText:currentWifiString];
        [settings setObject:currentWifiString forKey:@"wifiNetwork"];
        [settings writeToFile:kPreferencesPath atomically:YES];
        CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.a3tweaks.asphaleia/ReloadPrefs"), NULL, NULL, YES);
    }
}

- (NSString *)currentWifiSSID {
    NSString *ssid = nil;
    NSArray *ifs = (id)CNCopySupportedInterfaces();
    for (NSString *ifnam in ifs) {
        NSDictionary *info = (id)CNCopyCurrentNetworkInfo((__bridge CFStringRef)ifnam);
        if (info[@"SSID"]) {
            ssid = info[@"SSID"];
        }
    }
    return ssid;
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
