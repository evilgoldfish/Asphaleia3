#include "ASFingerprintsListController.h"
#import "ASRootListController.h"
#import <Preferences/PSSpecifier.h>
#import <dlfcn.h>
#import <objc/runtime.h>

#define kIconStateFile @"/private/var/mobile/Library/SpringBoard/IconState.plist"

@implementation ASFingerprintsListController

- (NSArray *)specifiers {
	return nil;
	dlopen("/System/Library/PrivateFrameworks/BiometricKit.framework/BiometricKit", RTLD_LAZY);
}

-(void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	asphaleiaSettings = [[NSMutableDictionary alloc] initWithContentsOfFile:kPreferencesPath];
	UIEdgeInsets insets = UIEdgeInsetsMake(0, 0, 20, 0);
	[self table].contentInset = insets;
	fingerprintSecurity = asphaleiaSettings[@"fingerprintSettings"] ? [asphaleiaSettings[@"fingerprintSettings"] mutableCopy] : [[NSMutableDictionary alloc] init];
}

-(NSString *)keyForSection:(NSInteger)section {
	switch (section) {
		case 0:
			return @"securedItemsFingerprints";
			break;
		case 1:
			return @"securityModifiersFingerprints";
			break;
		case 2:
			return @"advancedSecurityFingerprints";
			break;
		default:
			return nil;
			break;
	}
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"ASFingerprintCell"];
	cell.selectionStyle = UITableViewCellSelectionStyleDefault;
	cell.textLabel.text = [[[objc_getClass("BiometricKit") manager] identities:nil][indexPath.row] name];
	cell.accessoryType = [fingerprintSecurity[[self keyForSection:indexPath.section]][cell.textLabel.text] boolValue] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
	NSString *fingerprintAccessKey = [self keyForSection:indexPath.section];
	BOOL cellEnabled = (cell.accessoryType == UITableViewCellAccessoryCheckmark);
	cell.accessoryType = cellEnabled ? UITableViewCellAccessoryNone : UITableViewCellAccessoryCheckmark;
	NSMutableDictionary *fingerprintSettingsDict = [fingerprintSecurity objectForKey:fingerprintAccessKey] ? [fingerprintSecurity objectForKey:fingerprintAccessKey] : [NSMutableDictionary dictionary];
	[fingerprintSettingsDict setObject:[NSNumber numberWithBool:!cellEnabled] forKey:cell.textLabel.text];
	[fingerprintSecurity setObject:fingerprintSettingsDict forKey:fingerprintAccessKey];
	[asphaleiaSettings setObject:fingerprintSecurity forKey:@"fingerprintSettings"];
	[asphaleiaSettings writeToFile:kPreferencesPath atomically:YES];
	CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.a3tweaks.asphaleia/ReloadPrefs"), NULL, NULL, YES);
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [[[objc_getClass("BiometricKit") manager] identities:nil] count];
}

- (id)tableView:(id)arg1 titleForHeaderInSection:(NSInteger)arg2 {
	return nil;
}

- (id)tableView:(id)arg1 titleForFooterInSection:(NSInteger)section {
	return nil;
}

- (id)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
	UIView *headerView = [[UIView alloc] init];
	UILabel *headerLabel = [[UILabel alloc] initWithFrame:CGRectZero];
	headerLabel.backgroundColor = [UIColor clearColor];
	headerLabel.opaque = YES;
	headerLabel.textColor = [UIColor colorWithRed:0.427f green:0.427f blue:0.447f alpha:1.0f];

	headerLabel.font = [UIFont systemFontOfSize:13];
	headerLabel.frame = CGRectMake(15.0, 7.5, [[UIScreen mainScreen] bounds].size.width-30.f,40.0);
	[headerLabel addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"H:[headerLabel(==%f)]",[[UIScreen mainScreen] bounds].size.width-30.f]
                                                               options:0
                                                               metrics:nil
                                                views:NSDictionaryOfVariableBindings(headerLabel)]];

	[headerLabel addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[headerLabel(==40)]"
                                                               options:0
                                                               metrics:nil
                                                views:NSDictionaryOfVariableBindings(headerLabel)]];

	headerLabel.numberOfLines=0;
	switch (section) {
		case 0:
			headerLabel.text = @"Fingerprints that can access secured items.";
			break;
		case 1:
			headerLabel.text = @"Fingerprints that can access control panel and dynamic selection.";
			break;
		case 2:
			headerLabel.text = @"Fingerprints that can access advanced security.";
			break;
		default:
			return @"";
			break;
	}
	[headerLabel sizeToFit];

	[headerView addSubview:headerLabel];

	return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
	if (section == 1)
		return 45.f;
	else
		return 29.f;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 44.f;
}

- (int)tableView:(id)arg1 titleAlignmentForFooterInSection:(int)arg2 {
	return 1;
}

- (id)_tableView:(id)arg1 viewForCustomInSection:(long long)arg2 isHeader:(bool)arg3 {
    return nil;
}

- (CGFloat)_tableView:(id)arg1 heightForCustomInSection:(long long)arg2 isHeader:(bool)arg3 {
    return 0.0f;
}

@end
