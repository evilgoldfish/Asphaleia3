#import <UIKit/UIKit.h>
#import "PKGlyphView.h"
#import "BTTouchIDController.h"
#import "ASCommon.h"
#import "SBIconView.h"
#import "SBIcon.h"
#import "SBIconController.h"
#import "PreferencesHandler.h"
#import "substrate.h"
#import "UIImage+ImageEffects.h"
#import "SBUIController.h"
#import "SBDisplayLayout.h"
#import "SBDisplayItem.h"
#import "SBAppSwitcherIconController.h"
#import "SBAppSwitcherSnapshotView.h"
#import "CAFilter.h"
#import "SBApplication.h"
#import "SBApplicationIcon.h"
#import "SpringBoard.h"
#import "SBSearchViewController.h"

PKGlyphView *fingerglyph;
UIView *containerView;
SBIconView *currentIconView;
SBAppSwitcherIconController *iconController;
BTTouchIDController *iconTouchIDController;

%hook SBIconController

-(void)iconTapped:(SBIconView *)iconView {
	if (fingerglyph && currentIconView && containerView) {
		[currentIconView setHighlighted:NO];
		[iconView setHighlighted:NO];
		[fingerglyph removeFromSuperview];
		[containerView removeFromSuperview];
		fingerglyph = nil;
		currentIconView = nil;
		containerView = nil;
		[iconTouchIDController stopMonitoring];
		if ([iconView isEqual:currentIconView]) {
			// show the passcode view.
		}

		return;
	} else if (![getProtectedApps() containsObject:iconView.icon.applicationBundleID]) {
		%orig;
		return;
	}

	currentIconView = iconView;
	fingerglyph = [[%c(PKGlyphView) alloc] initWithStyle:1];
	fingerglyph.secondaryColor = [UIColor redColor];
	fingerglyph.primaryColor = [UIColor whiteColor];
	CGRect fingerframe = fingerglyph.frame;
	fingerframe.size.height = [iconView _iconImageView].frame.size.height-10;
	fingerframe.size.width = [iconView _iconImageView].frame.size.width-10;
	fingerglyph.frame = fingerframe;
	containerView = [[UIView alloc] initWithFrame:CGRectMake(0,0,fingerframe.size.width,fingerframe.size.height)];
	containerView.center = [iconView _iconImageView].center;
	[containerView addSubview:fingerglyph];
	[iconView addSubview:containerView];
	//[iconView bringSubviewToFront:containerView];

	fingerglyph.transform = CGAffineTransformMakeScale(0.01,0.01);
	[UIView animateWithDuration:0.3f animations:^{
		fingerglyph.transform = CGAffineTransformMakeScale(1,1);
	}];

	iconTouchIDController = [[BTTouchIDController alloc] initWithEventBlock:^void(BTTouchIDController *controller, id monitor, unsigned event) {
		switch (event) {
		case TouchIDMatched:
			if (fingerglyph && currentIconView && containerView) {
				[currentIconView.icon launchFromLocation:currentIconView.location];
				[currentIconView setHighlighted:NO];
				[fingerglyph removeFromSuperview];
				[containerView removeFromSuperview];
				fingerglyph = nil;
				currentIconView = nil;
				containerView = nil;
				[controller stopMonitoring];
			}
			break;
		case TouchIDFingerDown:
			[fingerglyph setState:1 animated:YES completionHandler:nil];
			break;
		case TouchIDFingerUp:
			[fingerglyph setState:0 animated:YES completionHandler:nil];
			break;
		case TouchIDNotMatched:
			[fingerglyph setState:0 animated:YES completionHandler:nil];
			break;
		}
	}];
	[iconTouchIDController startMonitoring];
}

-(void)iconHandleLongPress:(SBIconView *)iconView {
	if (self.isEditing || !shouldSecureAppArrangement()) {
		%orig;
		return;
	}

	[iconView setHighlighted:NO];
	[iconView cancelLongPressTimer];
	[iconView setTouchDownInIcon:NO];
	
	UIAlertView *alertView = [[ASCommon sharedInstance] createAuthenticationAlertOfType:ASAuthenticationAlertAppArranging beginMesaMonitoringBeforeShowing:YES dismissedHandler:^(BOOL wasCancelled) {
		if (!wasCancelled)
			[self setIsEditing:YES];
		}];
	[alertView show];
}

%end

%hook SBAppSwitcherController

-(void)_askDelegateToDismissToDisplayLayout:(SBDisplayLayout *)displayLayout displayIDsToURLs:(id)urls displayIDsToActions:(id)actions {
	SBDisplayItem *item = [displayLayout.displayItems objectAtIndex:0];
	NSMutableDictionary *iconViews = [iconController valueForKey:@"_iconViews"];

	if (![getProtectedApps() containsObject:item.displayIdentifier]) {
		%orig;
		return;
	}

	UIAlertView *alertView = [[ASCommon sharedInstance] createAppAuthenticationAlertWithIconView:[iconViews objectForKey:displayLayout] beginMesaMonitoringBeforeShowing:YES dismissedHandler:^(BOOL wasCancelled) {
	if (!wasCancelled)
		%orig;
	}];
	[alertView show];
}

%end

%hook SBAppSwitcherIconController

-(void)dealloc {
	iconController = nil;
	%orig;
}

-(id)init {
	iconController = %orig;
	return iconController;
}

%end

%hook SBAppSwitcherSnapshotView

-(void)_layoutStatusBar {
	if (![getProtectedApps() containsObject:self.displayItem.displayIdentifier] || !shouldObscureAppContent())
		%orig;
}

-(void)layoutSubviews {
	%orig;
	if (![getProtectedApps() containsObject:self.displayItem.displayIdentifier] || !shouldObscureAppContent()) {
		return;
	}
	/*CAFilter* filter = [CAFilter filterWithName:@"gaussianBlur"];
	[filter setValue:[NSNumber numberWithFloat:15] forKey:@"inputRadius"];
	[filter setValue:[NSNumber numberWithBool:YES] forKey:@"inputHardEdges"];
	UIImageView *snapshotImageView = [self valueForKey:@"_snapshotImageView"];
	snapshotImageView.layer.filters = [NSArray arrayWithObject:filter];
	[self setValue:snapshotImageView forKey:@"_snapshotImageView"];*/

	UIView *obscurityView = [[ASCommon sharedInstance] obscurityViewForSnapshotView:self];
	[self addSubview:obscurityView];
}

%end

%hook SBUIController

-(BOOL)_activateAppSwitcher {
	if (!shouldSecureSwitcher()) {
		return %orig;
	}

	UIAlertView *alertView = [[ASCommon sharedInstance] createAuthenticationAlertOfType:ASAuthenticationAlertSwitcher beginMesaMonitoringBeforeShowing:YES dismissedHandler:^(BOOL wasCancelled) {
		if (!wasCancelled)
			%orig;
		}];
	[alertView show];
	return NO;
}

%end

%hook SBLockScreenManager

-(void)_finishUIUnlockFromSource:(int)source withOptions:(id)options {
	%orig;
	SBApplication *frontmostApp = [(SpringBoard *)[UIApplication sharedApplication] _accessibilityFrontMostApplication];
	if ([getProtectedApps() containsObject:[frontmostApp bundleIdentifier]] && !shouldUnsecurelyUnlockIntoApp()) {
		SBApplicationIcon *appIcon = [[%c(SBApplicationIcon) alloc] initWithApplication:frontmostApp];
		SBIconView *iconView = [[%c(SBIconView) alloc] initWithDefaultSize];
		[iconView _setIcon:appIcon animated:YES];

		__block UIWindow *blurredWindow = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
		UIAlertView *alertView = [[ASCommon sharedInstance] createAppAuthenticationAlertWithIconView:iconView beginMesaMonitoringBeforeShowing:NO dismissedHandler:^(BOOL wasCancelled) {
			blurredWindow.hidden = YES;
			blurredWindow = nil;

			if (wasCancelled) {
				[[%c(SBUIController) sharedInstanceIfExists] clickedMenuButton];
			}
		}];
		blurredWindow.backgroundColor = [UIColor clearColor];

		UIVisualEffect *blurEffect;
		blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
		
		UIVisualEffectView *visualEffectView;
		visualEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
		
		visualEffectView.frame = [[UIScreen mainScreen] bounds];

		blurredWindow.windowLevel = UIWindowLevelAlert-1;
		[blurredWindow addSubview:visualEffectView];
		[blurredWindow makeKeyAndVisible];
		[alertView show];
	}
}

%end

%hook SBSearchViewController
static BOOL hasAuthenticated;
static BOOL authenticating;

-(void)_setShowingKeyboard:(BOOL)keyboard {
	%orig;
	if (keyboard && !hasAuthenticated && !authenticating && shouldSecureSpotlight()) {
		[self cancelButtonPressed];
		UIAlertView *alertView = [[ASCommon sharedInstance] createAuthenticationAlertOfType:ASAuthenticationAlertSpotlight beginMesaMonitoringBeforeShowing:YES dismissedHandler:^(BOOL wasCancelled) {
		if (!wasCancelled)
			hasAuthenticated = YES;
			[(SpringBoard *)[UIApplication sharedApplication] _revealSpotlight];
			[self _setShowingKeyboard:YES];
		}];
		[alertView show];
		authenticating = YES;
	}
}

-(void)dismiss {
	hasAuthenticated = NO;
	authenticating = NO;
	%orig;
}

%end

%hook SBPowerDownController

-(void)activate {
	if (shouldSecurePowerDownView()) {
		UIAlertView *alertView = [[ASCommon sharedInstance] createAuthenticationAlertOfType:ASAuthenticationAlertPowerDown beginMesaMonitoringBeforeShowing:NO dismissedHandler:^(BOOL wasCancelled) {
		if (!wasCancelled)
			%orig;
		}];
		[alertView show];
	}
}

%end

%ctor {
	addObserver(preferencesChangedCallback,kPrefsChangedNotification);
	loadPreferences();
}