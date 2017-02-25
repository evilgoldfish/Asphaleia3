#include "ASSecuredSettingsListController.h"
#import "ASRootListController.h"
#import <Preferences/PSSpecifier.h>
#import <Preferences/PSRootController.h>
#import <Preferences/PSTableCell.h>

#define kIconStateFile @"/private/var/mobile/Library/SpringBoard/IconState.plist"

@interface PrefsListController : PSListController
-(id)table;
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section;
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView;
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;
@end
@interface PrefsRootController : PSRootController
-(PrefsListController *)rootListController;
@end
@interface PSListController ()
-(PrefsRootController *)navigationController;
@end

@implementation ASSecuredSettingsListController

- (NSArray *)specifiers {
	return nil;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    settingsPanelNames = [[NSMutableArray alloc] init];
    asphaleiaSettings = [[NSMutableDictionary alloc] initWithContentsOfFile:kPreferencesPath];
    securedSettings = [asphaleiaSettings objectForKey:@"securedPanels"] ? [asphaleiaSettings objectForKey:@"securedPanels"] : [[NSMutableDictionary alloc] init];
}

- (int)getRowIndexFromAllRows:(NSIndexPath *)indexPath {
    int total = 0;
    for (int i = 0; i < indexPath.section; i++) {
        total += [self tableView:[self table] numberOfRowsInSection:i];
    }
    total += indexPath.row;
    return total;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[[self navigationController] rootListController] tableView:[[[self navigationController] rootListController] table] cellForRowAtIndexPath:indexPath];
    if (!cell) { // Invalid indexPath.
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"ASSettingsCell"];
        return cell;
    }
    if ([cell.accessoryView isKindOfClass:[UISwitch class]]) {
        cell.userInteractionEnabled = NO;
        cell.textLabel.enabled = NO;
        cell.detailTextLabel.enabled = NO;
        [(UISwitch *)cell.accessoryView setEnabled:NO];
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    UISwitch *switchview = [[UISwitch alloc] initWithFrame:CGRectZero];

    if ([[(PSTableCell *)cell specifier] identifier] && ![settingsPanelNames containsObject:[[(PSTableCell *)cell specifier] identifier]])
        [settingsPanelNames insertObject:[[(PSTableCell *)cell specifier] identifier] atIndex:[self getRowIndexFromAllRows:indexPath]];

    [switchview addTarget:self action:@selector(updateSwitchAtIndexPath:) forControlEvents:UIControlEventValueChanged];
    switchview.tag = [self getRowIndexFromAllRows:indexPath];
    [switchview setOn:[securedSettings[settingsPanelNames[[self getRowIndexFromAllRows:indexPath]]] boolValue] animated:NO];

    cell.detailTextLabel.text = nil;
    cell.accessoryView = switchview;
    return cell;
}

- (void)updateSwitchAtIndexPath:(UISwitch *)sender {
    [securedSettings setObject:[NSNumber numberWithBool:sender.on] forKey:[settingsPanelNames objectAtIndex:[sender tag]]];
    [asphaleiaSettings setObject:securedSettings forKey:@"securedPanels"];
    [asphaleiaSettings writeToFile:kPreferencesPath atomically:YES];
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.a3tweaks.asphaleia/ReloadPrefs"), NULL, NULL, YES);
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [[[self navigationController] rootListController] numberOfSectionsInTableView:[[[self navigationController] rootListController] table]];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[[self navigationController] rootListController] tableView:[[[self navigationController] rootListController] table] numberOfRowsInSection:section];
}

- (id)tableView:(id)arg1 titleForHeaderInSection:(NSInteger)arg2 {
    return nil;
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
