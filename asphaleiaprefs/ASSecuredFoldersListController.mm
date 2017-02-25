#include "ASSecuredFoldersListController.h"
#import "ASRootListController.h"
#import <Preferences/PSSpecifier.h>

#define kIconStateFile @"/private/var/mobile/Library/SpringBoard/IconState.plist"

@implementation ASSecuredFoldersListController

- (NSArray *)specifiers {
	return nil;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSDictionary *iconState = [[NSMutableDictionary alloc] initWithContentsOfFile:kIconStateFile];
    asphaleiaSettings = [[NSMutableDictionary alloc] initWithContentsOfFile:kPreferencesPath];
    securedFolders = [asphaleiaSettings objectForKey:@"securedFolders"] ? [asphaleiaSettings objectForKey:@"securedFolders"] : [[NSMutableDictionary alloc] init];
    [self processDictionaryOrArray:iconState];
}

- (void)processDictionaryOrArray:(id)dictOrArray {
    if (!folderNames)
        folderNames = [[NSMutableArray alloc] init];

    if ([dictOrArray isKindOfClass:[NSDictionary class]]) {
       for(NSString *key in [dictOrArray allKeys]){
        id childDictOrArray = [dictOrArray objectForKey:key];
        if ([key isEqualToString:@"displayName"])
            [folderNames addObject:[dictOrArray objectForKey:key]];
        else
            [self processDictionaryOrArray:childDictOrArray];
       }
    } else if([dictOrArray isKindOfClass:[NSArray class]]) {
       for(id childDictOrArray in dictOrArray){
            [self processDictionaryOrArray:childDictOrArray];
       }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"ASFolderCell"];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    UISwitch *switchview = [[UISwitch alloc] initWithFrame:CGRectZero];
    [switchview addTarget:self action:@selector(updateSwitchAtIndexPath:) forControlEvents:UIControlEventValueChanged];
    switchview.tag = indexPath.row;
    cell.textLabel.text = [folderNames objectAtIndex:indexPath.row];
    [switchview setOn:[securedFolders[folderNames[indexPath.row]] boolValue] animated:NO];
    cell.accessoryView = switchview;
    return cell;
}

- (void)updateSwitchAtIndexPath:(UISwitch *)sender {
    [securedFolders setObject:[NSNumber numberWithBool:sender.on] forKey:[folderNames objectAtIndex:[sender tag]]];
    [asphaleiaSettings setObject:securedFolders forKey:@"securedFolders"];
    [asphaleiaSettings writeToFile:kPreferencesPath atomically:YES];
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.a3tweaks.asphaleia/ReloadPrefs"), NULL, NULL, YES);
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [folderNames count];
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
