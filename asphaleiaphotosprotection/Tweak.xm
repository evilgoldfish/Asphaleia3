#import "../ASCommon.h"
#import "../ASPreferences.h"
#import <UIKit/UIKit.h>
#import <Photos/Photos.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <LocalAuthentication/LocalAuthentication.h>
#import <dlfcn.h>
#import <RocketBootstrap/RocketBootstrap.h>
#import <AppSupport/CPDistributedMessagingCenter.h>
#import "../Asphaleia.h"

BOOL authenticated;
BOOL authenticating;

%group UIImagePickerController
%hook UIImagePickerController
- (void)viewWillAppear:(BOOL)animated {
	if (authenticated || ![[ASPreferences sharedInstance] securePhotos] || authenticating) {
		%orig;
		return;
	}
	if ([ASCommon sharedInstance].displayingAuthAlert) {
		return;
	}
	authenticating = YES;
	[[ASCommon sharedInstance] authenticateFunction:ASAuthenticationAlertPhotos dismissedHandler:^(BOOL wasCancelled){
		authenticating = NO;
		if (!wasCancelled) {
			%orig;
		} else {
			[self dismissViewControllerAnimated:YES completion:nil];
			if ([[ASPreferences sharedInstance] showPhotosProtectMessage]) {
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Asphaleia" message:@"You have allowed this app to access your photos until you close it. If no photos are shown, try opening this section of the app again." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
				[alert show];
				[[ASPreferences sharedInstance] increasePhotosProtectMessageCount];
			}
		}
	}];
}
%end
%end

%group ALAssetsLibrary
ALAssetsLibraryGroupsEnumerationResultsBlock block1;
ALAssetsLibraryAccessFailureBlock block2;
%hook ALAssetsLibrary
+ (int)authorizationStatus {
	if (!authenticated && [[ASPreferences sharedInstance] securePhotos]) {
		return 0;
	}

	return %orig;
}

- (void)enumerateGroupsWithTypes:(unsigned int)arg1 usingBlock:(id)arg2 failureBlock:(id)arg3 {
	if (authenticated || ![[ASPreferences sharedInstance] securePhotos] || authenticating) {
		if (!authenticating)
			%orig;
		return;
	}
	if ([ASCommon sharedInstance].displayingAuthAlert) {
		return;
	}
	authenticating = YES;

	block1 = [arg2 copy];
	block2 = [arg3 copy];
	[[ASCommon sharedInstance] authenticateFunction:ASAuthenticationAlertPhotos dismissedHandler:^(BOOL wasCancelled){
		authenticating = NO;
		if (!wasCancelled) {
			authenticated = YES;
			%orig(arg1,block1,block2);
			if ([[ASPreferences sharedInstance] showPhotosProtectMessage]) {
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Asphaleia" message:@"You have allowed this app to access your photos until you close it. If no photos are shown, try opening this section of the app again." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
				[alert show];
				[[ASPreferences sharedInstance] increasePhotosProtectMessageCount];
			}
		}
	}];
}
%end
%end

%group PHPhotoLibrary
BOOL accessDenied;
typedef void (^PHAuthBlock)(PHAuthorizationStatus status);
PHAuthBlock authBlock;
%hook PHPhotoLibrary
+ (int)authorizationStatus {
	PHAuthorizationStatus status = %orig;
	if (status != PHAuthorizationStatusAuthorized && [[ASPreferences sharedInstance] securePhotos]) {
		accessDenied = YES;
		return status;
	}
	accessDenied = NO;
	if (!authenticated && [[ASPreferences sharedInstance] securePhotos]) {
		return PHAuthorizationStatusNotDetermined;
	}
	return status;
}
+ (void)requestAuthorization:(void (^)(PHAuthorizationStatus status))arg1 {
	if (authenticated || ![[ASPreferences sharedInstance] securePhotos] || accessDenied || authenticating) {
		if (!authenticating) {
			%orig;
		}
		return;
	}
	if ([ASCommon sharedInstance].displayingAuthAlert) {
		return;
	}
	authenticating = YES;

	authBlock = [arg1 copy];
	[[ASCommon sharedInstance] authenticateFunction:ASAuthenticationAlertPhotos dismissedHandler:^(BOOL wasCancelled){
			authenticating = NO;
			if (!wasCancelled) {
				%orig(authBlock);
				authenticated = YES;
				if ([[ASPreferences sharedInstance] showPhotosProtectMessage]) {
					UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Asphaleia" message:@"You have allowed this app to access your photos until you close it. If no photos are shown, try opening this section of the app again." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
					[alert show];
					[[ASPreferences sharedInstance] increasePhotosProtectMessageCount];
				}
			}
		}];
}
%end

%hook PHFetchResult
- (NSUInteger)count {
	if (authenticated || ![[ASPreferences sharedInstance] securePhotos]) {
		return %orig;
	}

	return 0;
}

- (id)objectAtIndexedSubscript:(unsigned int)arg1 {
	if (authenticated || ![[ASPreferences sharedInstance] securePhotos]) {
		return %orig;
	}

	return nil;
}
%end
%end

%group CAMImageWell
%hook CAMImageWell
id origTarget;
SEL origSelector;

- (void)setThumbnailImage:(id)arg1 animated:(BOOL)arg2 {
	if (!authenticated) {
		%orig(nil, arg2);
	}
}
- (void)setThumbnailImage:(id)arg1 uuid:(id)arg2 animated:(BOOL)arg3 {
	if (!authenticated) {
		%orig(nil, arg2, arg3);
	}
}
- (void)willMoveToSuperview:(UIView *)view {
	%orig;
	origTarget = self.allTargets.allObjects[0];
	origSelector = NSSelectorFromString([self actionsForTarget:origTarget forControlEvent:UIControlEventTouchUpInside][0]);
	[self removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
	[self addTarget:self action:@selector(showAuthAlert:) forControlEvents:UIControlEventTouchUpInside];
}
%new
- (void)showAuthAlert:(id)sender {
	CPDistributedMessagingCenter *centre = [%c(CPDistributedMessagingCenter) centerNamed:@"com.a3tweaks.asphaleia.xpc"];
	rocketbootstrap_distributedmessagingcenter_apply(centre);
	NSDictionary *reply = [centre sendMessageAndReceiveReplyName:@"com.a3tweaks.asphaleia.xpc/CheckSlideUpControllerActive" userInfo:nil];

	if (authenticated || ![[ASPreferences sharedInstance] securePhotos] || ([reply[@"active"] boolValue] && [ASPreferences devicePasscodeSet]) || authenticating) {
		[origTarget performSelectorOnMainThread:origSelector withObject:self waitUntilDone:NO];
		return;
	}
	if ([[ASCommon sharedInstance] displayingAuthAlert]) {
		return;
	}
	authenticating = YES;

	[[ASCommon sharedInstance] authenticateFunction:ASAuthenticationAlertPhotos dismissedHandler:^(BOOL wasCancelled){
		authenticating = NO;
		if (!wasCancelled) {
			authenticated = YES;
			[origTarget performSelectorOnMainThread:origSelector withObject:self waitUntilDone:NO];
		}
	}];
}
%end
%end

%ctor {
	if ([[NSBundle mainBundle].bundleIdentifier isEqualToString:@"com.apple.mobileslideshow"]) {
		return;		
	}
	BOOL loaded;
	if (NSClassFromString(@"PHPhotoLibrary") != nil) {
		loaded = YES;
		%init(PHPhotoLibrary);
	}
	if (NSClassFromString(@"ALAssetsLibrary") != nil) {
		loaded = YES;
		%init(ALAssetsLibrary);
	}
	if (NSClassFromString(@"UIImagePickerController") != nil) {
		loaded = YES;
		%init(UIImagePickerController);
	}
	if (NSClassFromString(@"CAMImageWell") != nil) {
		loaded = YES;
		%init(CAMImageWell);
	}
	if (loaded) {
		loadPreferences();
		%init;
	}
}
