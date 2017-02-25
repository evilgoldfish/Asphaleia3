#include "ASSecuredSwitchesListController.h"
#import "ASRootListController.h"
#import <Flipswitch/Flipswitch.h>
#import <Preferences/PSSpecifier.h>

@implementation ASSecuredSwitchesListController

- (NSArray *)specifiers {
	return nil;
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    asphaleiaSettings = [[NSMutableDictionary alloc] initWithContentsOfFile:kPreferencesPath];
    securedSwitches = [asphaleiaSettings objectForKey:@"securedSwitches"] ? [asphaleiaSettings objectForKey:@"securedSwitches"] : [[NSMutableDictionary alloc] init];
    switchNames = [[NSMutableDictionary alloc] init];
    for (NSString *identifier in [[FSSwitchPanel sharedPanel] sortedSwitchIdentifiers]) {
        [switchNames setObject:[[FSSwitchPanel sharedPanel] titleForSwitchIdentifier:identifier] forKey:identifier];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"ASFlipswitchCell"];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    UISwitch *switchview = [[UISwitch alloc] initWithFrame:CGRectZero];
    [switchview addTarget:self action:@selector(updateSwitchAtIndexPath:) forControlEvents:UIControlEventValueChanged];
    switchview.tag = indexPath.row;
    cell.textLabel.text = switchNames[[[[FSSwitchPanel sharedPanel] sortedSwitchIdentifiers] objectAtIndex:indexPath.row]];
    [switchview setOn:[securedSwitches[[[[FSSwitchPanel sharedPanel] sortedSwitchIdentifiers] objectAtIndex:indexPath.row]] boolValue] animated:NO];
    cell.accessoryView = switchview;
    return cell;
}

- (void)updateSwitchAtIndexPath:(UISwitch *)sender {
    [securedSwitches setObject:[NSNumber numberWithBool:sender.on] forKey:[[[FSSwitchPanel sharedPanel] sortedSwitchIdentifiers] objectAtIndex:[sender tag]]];
    [asphaleiaSettings setObject:securedSwitches forKey:@"securedSwitches"];
    [asphaleiaSettings writeToFile:kPreferencesPath atomically:YES];
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.a3tweaks.asphaleia/ReloadPrefs"), NULL, NULL, YES);
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[[FSSwitchPanel sharedPanel] sortedSwitchIdentifiers] count];
}

- (id)tableView:(id)arg1 titleForFooterInSection:(NSInteger)arg2 {
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44.f;
}

- (void)tableView:(id)arg1 didSelectRowAtIndexPath:(id)arg2 {
    return;
}

- (id)_tableView:(id)arg1 viewForCustomInSection:(long long)arg2 isHeader:(bool)arg3 {
    return nil;
}

- (CGFloat)_tableView:(id)arg1 heightForCustomInSection:(long long)arg2 isHeader:(bool)arg3 {
    return 0.0f;
}

@end
