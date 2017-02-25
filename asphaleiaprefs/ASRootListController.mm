#import <Preferences/PSTableCell.h>
#import <Preferences/PSListController.h>
#import <Social/Social.h>
#import <MessageUI/MessageUI.h>
#import <MobileGestalt/MobileGestalt.h>
#import <sys/sysctl.h>
#import "modalPinVC.h"
#import "TouchIDInfo.h"
#import "ASRootListController.h"
#import "ASCreatorsListController.h"
#import "ASPasscodeOptionsListController.h"
#import "ASSecuredItemsListController.h"

@implementation ASRootListController

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"Root" target:self] retain];
	}
	UIBarButtonItem *nextBarButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/AsphaleiaPrefs.bundle/NavHeart@2x.png"] style:UIBarButtonItemStylePlain target:self action:@selector(loveMeh)];
	UIImageView *A3ImageView = [[UIImageView alloc] initWithImage:[UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/AsphaleiaPrefs.bundle/NavA3tweaks@2x.png"]];
	[(UINavigationItem*)self.navigationItem setTitleView:A3ImageView];
	[(UINavigationItem*)self.navigationItem titleView].alpha = 0.0f;
	[(UINavigationItem*)self.navigationItem setRightBarButtonItem:nextBarButton animated:NO];
	[(UINavigationItem*)self.navigationItem setLeftBarButtonItem:nil];
	[(UINavigationItem*)self.navigationItem setBackBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:@"Asphaleia"
			   style:UIBarButtonItemStylePlain
			   target:nil
			   action:nil]];

	return _specifiers;
}

- (void)loveMeh {
	if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter]) {
		SLComposeViewController *controller = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
		[controller setInitialText:@"Securing my apps with #AsphaleiaX from @ShadeZepheri!"];

		[(UIViewController *)[[[[[UIApplication sharedApplication] keyWindow] subviews] objectAtIndex:0] nextResponder] presentViewController:controller animated:YES completion:NULL];
	} else {
		UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Asphaleia" message:@"You don't seem to be able to tweet right now." preferredStyle:UIAlertControllerStyleAlert];
		[alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
		[self presentViewController:alert animated:YES completion:nil];
	}
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	if (!_enteredCorrectly && !self.passcodeViewIsTransitioning) {
		[self presentAuthView];
		_enteredCorrectly = NO;
	} else {
		if (!self.alreadyAnimatedOnce) {
			self.alreadyAnimatedOnce = YES;
			[(UINavigationItem*)self.navigationItem titleView].alpha = 0.0f;
			[UIView animateWithDuration:0.3f animations:^{
				[(UINavigationItem*)self.navigationItem titleView].alpha = 1.0f;
			}];
		}
	}
}

- (void)presentAuthView {
	// NSLog(@"================presentAuthView");
	if([[NSFileManager defaultManager]fileExistsAtPath:kPreferencesPath] && [(NSString *)[[NSDictionary dictionaryWithContentsOfFile:kPreferencesPath] objectForKey:@"passcode"] length] == 6) {
		// NSLog(@"================presentAuthView def");
		pinVC = [[modalPinVC alloc] initToAuthWithDelegate:self];
		[(UIViewController *)self presentViewController:pinVC animated:YES completion:NULL];
	} else {
		// NSLog(@"================presentAuthView set");
		pinVC = [[modalPinVC alloc] initToSetPasscodeFirst:self];
		[(UIViewController *)self presentViewController:pinVC animated:YES completion:NULL];
	}
}

- (void)goBack {
	_enteredCorrectly = NO;
	self.alreadyAnimatedOnce = NO;
	self.passcodeViewIsTransitioning = NO;
	[[[self rootController] navigationController] popToRootViewControllerAnimated:YES];
}

- (void)authenticated {
	_enteredCorrectly = YES;
}

- (void)showSecurity {
	[self pushController:[[ASSecuredItemsListController alloc] init]];
}

- (void)showCreators {
	[self pushController:[[ASCreatorsListController alloc] init]];
}

- (void)showPasscodeOptions {
	[self pushController:[[ASPasscodeOptionsListController alloc] init]];
}

- (void)showMailDialog {
	// NSLog(@"showMailDialog");
	if ([MFMailComposeViewController canSendMail]) {
		MFMailComposeViewController *mailViewController = [[MFMailComposeViewController alloc] init];
		mailViewController.mailComposeDelegate = (id<MFMailComposeViewControllerDelegate>)self;
		[mailViewController setSubject:@"Asphaleia X Support"];
		[mailViewController setToRecipients:[NSArray arrayWithObject:@"ziroalpha@gmail.com"]];
		size_t size;
		sysctlbyname("hw.machine", NULL, &size, NULL, 0);
		char *machine = (char *)malloc(size);
		sysctlbyname("hw.machine", machine, &size, NULL, 0);
		CFStringRef udid = (const struct __CFString *)MGCopyAnswer(kMGUniqueDeviceID);

		[mailViewController setMessageBody:[NSString stringWithFormat:@"\n\n UUID: %@\nDevice: %@\nFirmware: %@",udid, [NSString stringWithCString:machine encoding:NSUTF8StringEncoding], [[UIDevice currentDevice] systemVersion] ] isHTML:NO];
		[(UINavigationController *)self presentViewController:mailViewController animated:YES completion:NULL];
		free(machine);
	} else {
		UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Asphaleia" message:@"Something went wrong while trying to compose the support email." preferredStyle:UIAlertControllerStyleAlert];
		[alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
		[self presentViewController:alert animated:YES completion:nil];
	}
}
- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
	[controller dismissViewControllerAnimated:YES completion:NULL];
}

- (BOOL)canBeShownFromSuspendedState {
	return NO;
}
@end
