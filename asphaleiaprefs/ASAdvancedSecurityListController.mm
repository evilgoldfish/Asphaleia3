#include "ASAdvancedSecurityListController.h"
#import "ASRootListController.h"
#import <Preferences/PSSpecifier.h>
#import <UIKit/UIKit.h>

@implementation ASAdvancedSecurityListController

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"SecuredItems-AdvancedSecurity" target:self] retain];
	}

	return _specifiers;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    if (indexPath.section == 0) {
        cell.imageView.image = [UIImage imageNamed:@"IconEditMode.png" inBundle:[[NSBundle alloc] initWithPath:kBundlePath] compatibleWithTraitCollection:nil];
    } else if (indexPath.section == 1) {
        cell.imageView.image = [UIImage imageNamed:@"IconPowerOff.png" inBundle:[[NSBundle alloc] initWithPath:kBundlePath] compatibleWithTraitCollection:nil];
    } else if (indexPath.section == 2) {
        cell.imageView.image = [UIImage imageNamed:@"IconMultitasking.png" inBundle:[[NSBundle alloc] initWithPath:kBundlePath] compatibleWithTraitCollection:nil];
    } else if (indexPath.section == 3) {
        cell.imageView.image = [UIImage imageNamed:@"IconControlCenter.png" inBundle:[[NSBundle alloc] initWithPath:kBundlePath] compatibleWithTraitCollection:nil];
    } else if (indexPath.section == 4) {
        cell.imageView.image = [UIImage imageNamed:@"IconSpotlight.png" inBundle:[[NSBundle alloc] initWithPath:kBundlePath] compatibleWithTraitCollection:nil];
    }
    return cell;
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
