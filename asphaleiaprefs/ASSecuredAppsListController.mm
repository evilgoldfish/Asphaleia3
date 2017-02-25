#include "ASSecuredAppsListController.h"
#import "ASRootListController.h"
#import <Preferences/PSSpecifier.h>
#import <AppList/AppList.h>

static NSMutableArray *iconsToLoad;
static OSSpinLock spinLock;
static UIImage *defaultImage;

@implementation ASSecuredAppsListController

- (NSArray *)specifiers {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(iconLoadedFromNotification:) name:ALIconLoadedNotification object:nil];
    defaultImage = [[[ALApplicationList sharedApplicationList] iconOfSize:ALApplicationIconSizeSmall forDisplayIdentifier:@"com.apple.WebSheet"] retain];
    NSArray *hiddenDisplayIdentifiers = [NSArray arrayWithObjects:
                                    @"com.apple.AdSheet",
                                    @"com.apple.AdSheetPhone",
                                    @"com.apple.AdSheetPad",
                                    @"com.apple.DataActivation",
                                    @"com.apple.DemoApp",
                                    @"com.apple.fieldtest",
                                    @"com.apple.iosdiagnostics",
                                    @"com.apple.iphoneos.iPodOut",
                                    @"com.apple.TrustMe",
                                    @"com.apple.WebSheet",
                                    @"com.apple.springboard",
                                    @"com.apple.purplebuddy",
                                    @"com.apple.datadetectors.DDActionsService",
                                    @"com.apple.FacebookAccountMigrationDialog",
                                    @"com.apple.iad.iAdOptOut",
                                    @"com.apple.ios.StoreKitUIService",
                                    @"com.apple.TextInput.kbd",
                                    @"com.apple.MailCompositionService",
                                    @"com.apple.mobilesms.compose",
                                    @"com.apple.quicklook.quicklookd",
                                    @"com.apple.ShoeboxUIService",
                                    @"com.apple.social.remoteui.SocialUIService",
                                    @"com.apple.WebViewService",
                                    @"com.apple.gamecenter.GameCenterUIService",
                                    @"com.apple.appleaccount.AACredentialRecoveryDialog",
                                    @"com.apple.CompassCalibrationViewService",
                                    @"com.apple.WebContentFilter.remoteUI.WebContentAnalysisUI",
                                    @"com.apple.PassbookUIService",
                                    @"com.apple.uikit.PrintStatus",
                                    @"com.apple.Copilot",
                                    @"com.apple.MusicUIService",
                                    @"com.apple.AccountAuthenticationDialog",
                                    @"com.apple.MobileReplayer",
                                    @"com.apple.SiriViewService",
                                    @"com.apple.TencentWeiboAccountMigrationDialog",
                                    @"com.apple.AskPermissionUI",
                                    @"com.apple.Diagnostics",
                                    @"com.apple.family",
                                    @"com.apple.GameController",
                                    @"com.apple.HealthPrivacyService",
                                    @"com.apple.InCallService",
                                    @"com.apple.mobilesms.notification",
                                    @"com.apple.PhotosViewService",
                                    @"com.apple.PreBoard",
                                    @"com.apple.PrintKit.Print-Center",
                                    @"com.apple.SharedWebCredentialViewService",
                                    @"com.apple.share",
                                    @"com.apple.webapp",
                                    @"com.apple.webapp1",
                                    @"com.apple.CoreAuthUI",
                                    @"com.apple.CloudKit.ShareBear",
                                    @"com.apple.social.SLGoogleAuth",
                                    @"com.apple.StoreDemoViewService",
                                    @"com.apple.social.SLYahooAuth",
                                    @"com.apple.SafariViewService",
                                    @"com.apple.Home.HomeUIService",
                                    @"com.apple.appleseed.FeedbackAssistant",
                                    @"com.apple.Diagnostics.Mitosis",
                                    @"com.apple.managedconfiguration.MDMRemoteAlertService",
                                    nil];

    NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"" ascending:YES selector:@selector(localizedStandardCompare:)];
    asphaleiaSettings = [[NSMutableDictionary alloc] initWithContentsOfFile:kPreferencesPath];
    securedApps = [asphaleiaSettings objectForKey:@"securedApps"] ? [asphaleiaSettings objectForKey:@"securedApps"] : [[NSMutableDictionary alloc] init];
    systemApps = [[[ALApplicationList sharedApplicationList] applicationsFilteredUsingPredicate:[NSPredicate predicateWithFormat:@"(isSystemApplication = TRUE)"]] mutableCopy];
    [systemApps retain];
    for (NSString *key in hiddenDisplayIdentifiers) {
        [systemApps removeObjectForKey:key];
    }
    appStoreApps = [[ALApplicationList sharedApplicationList] applicationsFilteredUsingPredicate:[NSPredicate predicateWithFormat:@"(isSystemApplication = FALSE)"]];
    [appStoreApps retain];
    systemAppsSortedTitles = [[[systemApps allValues] sortedArrayUsingDescriptors:@[descriptor]] retain];
    appStoreAppsSortedTitles = [[[appStoreApps allValues] sortedArrayUsingDescriptors:@[descriptor]] retain];
    systemAppsSortedKeys = [[NSMutableArray alloc] init];
    appStoreAppsSortedKeys = [[NSMutableArray alloc] init];
    for (NSString *title in systemAppsSortedTitles) {
        [systemAppsSortedKeys addObject:[systemApps allKeysForObject:title][0]];
    }
    for (NSString *title in appStoreAppsSortedTitles) {
        [appStoreAppsSortedKeys addObject:[appStoreApps allKeysForObject:title][0]];
    }
    allAppsSortedKeys = [[systemAppsSortedKeys arrayByAddingObjectsFromArray:appStoreAppsSortedKeys] retain];
	return nil;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self updateSelectionButton];
}

+ (void)loadIconsFromBackground {
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  OSSpinLockLock(&spinLock);
  ALApplicationList *appList = [ALApplicationList sharedApplicationList];
  while ([iconsToLoad count]) {
      NSDictionary *userInfo = [[iconsToLoad objectAtIndex:0] retain];
      [iconsToLoad removeObjectAtIndex:0];
      OSSpinLockUnlock(&spinLock);
      CGImageRelease([appList copyIconOfSize:[[userInfo objectForKey:ALIconSizeKey] integerValue] forDisplayIdentifier:[userInfo objectForKey:ALDisplayIdentifierKey]]);
      [userInfo release];
      [pool drain];
      pool = [[NSAutoreleasePool alloc] init];
      OSSpinLockLock(&spinLock);
  }
  [iconsToLoad release];
  iconsToLoad = nil;
  OSSpinLockUnlock(&spinLock);
  [pool drain];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;
    NSString *key;
    if (indexPath.section == 0) {
        UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"ASGlobalAppSecurityCell"];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        UISwitch *switchview = [[UISwitch alloc] initWithFrame:CGRectZero];
        [switchview addTarget:self action:@selector(updateSwitchAtIndexPath:) forControlEvents:UIControlEventValueChanged];
        switchview.tag = indexPath.row;
        cell.textLabel.text = @"Global App Security";
        [switchview setOn:[asphaleiaSettings[@"globalAppSecurity"] boolValue] animated:NO];
        cell.accessoryView = switchview;
        return cell;
    } else if (indexPath.section == 1) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"ASSystemAppCell"];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.indentationWidth = 10.0f;
        cell.indentationLevel = 0;
        UISwitch *switchview = [[UISwitch alloc] initWithFrame:CGRectZero];
        [switchview addTarget:self action:@selector(updateSwitchAtIndexPath:) forControlEvents:UIControlEventValueChanged];
        switchview.tag = indexPath.row;
        cell.textLabel.text = [systemAppsSortedTitles objectAtIndex:indexPath.row];
        [switchview setOn:[securedApps[systemAppsSortedKeys[indexPath.row]] boolValue] animated:NO];
        cell.accessoryView = switchview;
        key = systemAppsSortedKeys[indexPath.row];
    } else {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"ASAppStoreAppCell"];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.indentationWidth = 10.0f;
        cell.indentationLevel = 0;
        UISwitch *switchview = [[UISwitch alloc] initWithFrame:CGRectZero];
        [switchview addTarget:self action:@selector(updateSwitchAtIndexPath:) forControlEvents:UIControlEventValueChanged];
        switchview.tag = indexPath.row;
        cell.textLabel.text = [appStoreAppsSortedTitles objectAtIndex:indexPath.row];
        [switchview setOn:[securedApps[appStoreAppsSortedKeys[indexPath.row]] boolValue] animated:NO];
        cell.accessoryView = switchview;
        key = appStoreAppsSortedKeys[indexPath.row];
    }
    if ([[ALApplicationList sharedApplicationList] hasCachedIconOfSize:29.f forDisplayIdentifier:key]) {
        cell.imageView.image = [[ALApplicationList sharedApplicationList] iconOfSize:29.f forDisplayIdentifier:key];
    } else {
        if (defaultImage.size.width == 29) {
            cell.imageView.image = defaultImage;
            cell.indentationWidth = 10.0f;
            cell.indentationLevel = 0;
        } else {
            cell.indentationWidth = 29 + 7.0f;
            cell.indentationLevel = 1;
            cell.imageView.image = nil;
        }

        NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                          [NSNumber numberWithInteger:29], ALIconSizeKey,
                                          key, ALDisplayIdentifierKey,
                                          nil];
        OSSpinLockLock(&spinLock);
        if (iconsToLoad)
            [iconsToLoad insertObject:userInfo atIndex:0];
        else {
            iconsToLoad = [[NSMutableArray alloc] initWithObjects:userInfo, nil];
            [ASSecuredAppsListController performSelectorInBackground:@selector(loadIconsFromBackground) withObject:nil];
        }
        OSSpinLockUnlock(&spinLock);
    }
    return cell;
}

- (void)updateSwitchAtIndexPath:(UISwitch *)sender {
    UITableViewCell *cell = [sender superview];
    NSIndexPath *indexPath = [[self table] indexPathForCell:cell];
    NSArray *appList;
    if (indexPath.section == 0) {
        [asphaleiaSettings setObject:[NSNumber numberWithBool:sender.on] forKey:@"globalAppSecurity"];
        [asphaleiaSettings writeToFile:kPreferencesPath atomically:YES];
        CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.a3tweaks.asphaleia/ReloadPrefs"), NULL, NULL, YES);
        return;
    } else if (indexPath.section == 1) {
        appList = systemAppsSortedKeys;
    } else {
        appList = appStoreAppsSortedKeys;
    }
    [securedApps setObject:[NSNumber numberWithBool:sender.on] forKey:appList[indexPath.row]];
    [asphaleiaSettings setObject:securedApps forKey:@"securedApps"];
    [asphaleiaSettings writeToFile:kPreferencesPath atomically:YES];
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.a3tweaks.asphaleia/ReloadPrefs"), NULL, NULL, YES);
    [self updateSelectionButton];
}

// AppList code, kindly borrowed from https://github.com/rpetrich/AppList/blob/master/ALApplicationTableDataSource.m
- (void)iconLoadedFromNotification:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    NSString *displayIdentifier = [userInfo objectForKey:ALDisplayIdentifierKey];
    CGFloat iconSize = [[userInfo objectForKey:ALIconSizeKey] floatValue];
    for (NSIndexPath *indexPath in [self table].indexPathsForVisibleRows) {
        [self updateCell:[[self table] cellForRowAtIndexPath:indexPath] forIndexPath:indexPath withLoadedIconOfSize:iconSize forDisplayIdentifier:displayIdentifier];
    }
}

- (void)updateCell:(UITableViewCell *)cell forIndexPath:(NSIndexPath *)indexPath withLoadedIconOfSize:(CGFloat)newIconSize forDisplayIdentifier:(NSString *)displayIdentifier {
    if (indexPath.section == 0)
        return;

    if ([displayIdentifier isEqual:[allAppsSortedKeys objectAtIndex:indexPath.row]] && newIconSize == 29) {
        UIImageView *imageView = cell.imageView;
        UIImage *image = imageView.image;
        if (!image || (image == defaultImage)) {
            cell.indentationLevel = 0;
            cell.indentationWidth = 10.0f;
            imageView.image = [[ALApplicationList sharedApplicationList] iconOfSize:newIconSize forDisplayIdentifier:displayIdentifier];
            [cell setNeedsLayout];
        }
    }
}

// Select/Deselect All Button
- (void)updateSelectionButton {
    int total = 0;
    for (NSInteger j = 1; j <= 2; ++j) {
        for (NSInteger i = 0; i < [self tableView:[self table] numberOfRowsInSection:j]; ++i) {
            if ([(UISwitch *)[self tableView:[self table] cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:j]].accessoryView isOn])
                total++;
        }
    }
    HBLogInfo(@"%i, %i",total,securedApps.count);
    if (total == securedApps.count) {
        UIBarButtonItem *nextBarButton = [[UIBarButtonItem alloc] initWithTitle:@"Deselect All" style:UIBarButtonItemStylePlain target:self action:@selector(disableAllApps)];
        [(UINavigationItem*)self.navigationItem setRightBarButtonItem:nextBarButton animated:NO];
    } else {
        UIBarButtonItem *nextBarButton = [[UIBarButtonItem alloc] initWithTitle:@"Select All" style:UIBarButtonItemStylePlain target:self action:@selector(enableAllApps)];
        [(UINavigationItem*)self.navigationItem setRightBarButtonItem:nextBarButton animated:NO];
    }
}
- (void)enableAllApps {
    for (NSInteger section = 1; section <= 2; ++section) {
        for (NSInteger row = 0; row < [self tableView:[self table] numberOfRowsInSection:section]; ++row) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];
            NSInteger altRow;
            if (section == 2) {
                altRow = [self tableView:[self table] numberOfRowsInSection:1] + row;
            } else {
                altRow = row;
            }
            NSString *displayIdentifier = [allAppsSortedKeys objectAtIndex:altRow];
            UITableViewCell *cell = [[self table] cellForRowAtIndexPath:indexPath];
            [cell.accessoryView setOn:YES animated:YES];
            [cell setNeedsLayout];
            [securedApps setObject:[NSNumber numberWithBool:YES] forKey:displayIdentifier];

        }
    }
    [asphaleiaSettings setObject:securedApps forKey:@"securedApps"];
    [asphaleiaSettings writeToFile:kPreferencesPath atomically:YES];
    CFNotificationCenterPostNotification (CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.a3tweaks.asphaleia/ReloadPrefs"), NULL, NULL,true);
    [[self table] reloadData];
    [self updateSelectionButton];
}

- (void)disableAllApps {
    for (NSInteger section = 1; section <= 2; ++section) {
        for (NSInteger row = 0; row < [self tableView:[self table] numberOfRowsInSection:section]; ++row) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];
            NSInteger altRow;
            if (section == 2) {
                altRow = [self tableView:[self table] numberOfRowsInSection:1] + row;
            } else {
                altRow = row;
            }
            NSString *displayIdentifier = [allAppsSortedKeys objectAtIndex:altRow];
            UITableViewCell *cell = [[self table] cellForRowAtIndexPath:indexPath];
            [cell.accessoryView setOn:NO animated:YES];
            [cell setNeedsLayout];
            [securedApps setObject:[NSNumber numberWithBool:NO] forKey:displayIdentifier];

        }
    }
    [asphaleiaSettings setObject:securedApps forKey:@"securedApps"];
    [asphaleiaSettings writeToFile:kPreferencesPath atomically:YES];
    CFNotificationCenterPostNotification (CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.a3tweaks.asphaleia/ReloadPrefs"), NULL, NULL,true);
    [[self table] reloadData];
    [self updateSelectionButton];
}

// Table view delegate methods
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 1) {
        return @"System Applications";
    } else {
        return @"User Applications";
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 1;
    } else if (section == 1) {
        return [systemApps count];
    } else {
        return [appStoreApps count];
    }
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
