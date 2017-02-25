#import <Preferences/PSSpecifier.h>
#import <Preferences/PSListController.h>
#import <Preferences/PSTableCell.h>
#import "../ASCommon.h"
#import <UIKit/UIKit.h>
#import "../ASPreferences.h"
#import "../NSTimer+Blocks.h"
@interface PSSpecifier ()
@property (assign,nonatomic) Class detailControllerClass;
@end
@interface PSUIPrefsListController : PSListController
- (void)lazyLoadBundle:(PSSpecifier *)specifier;
- (id)table;
@end

%hook PSUIPrefsListController
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (![[ASPreferences sharedInstance] requiresSecurityForPanel:[[(PSTableCell *)[tableView cellForRowAtIndexPath:indexPath] specifier] identifier]]) {
		%orig;
		return;
	}
	[[ASCommon sharedInstance] authenticateFunction:ASAuthenticationAlertSettingsPanel dismissedHandler:^(BOOL wasCancelled){
		if (!wasCancelled) {
			%orig;
		} else {
			[[self table] deselectRowAtIndexPath:[[self table] indexPathForSelectedRow] animated:YES];
		}
	}];
}
%end

%ctor {
	loadPreferences();
}
