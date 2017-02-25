#import "ASAuthenticationAlert.h"
#import "ASAuthenticationController.h"
#import "ASPreferences.h"
#import <SpringBoard/SBAlertItemsController.h>
#import "NSTimer+Blocks.h"
#import "ASPasscodeHandler.h"

#define titleWithSpacingForIcon(t) [NSString stringWithFormat:@"\n\n\n%@",t]
#define titleWithSpacingForSmallIcon(t) [NSString stringWithFormat:@"\n\n%@",t]

@interface ASAuthenticationAlert ()
- (NSArray *)allSubviewsOfView:(UIView *)view;
- (void)addSubviewToAlert:(UIView *)view;
+ (PKGlyphView *)sharedGlyph;
- (UIImage *)colouriseImage:(UIImage *)origImage withColour:(UIColor *)tintColour;
@end

%subclass ASAuthenticationAlert : SBAlertItem

%new
- (instancetype)initWithTitle:(NSString *)title message:(NSString *)message icon:(UIView *)icon smallIcon:(BOOL)useSmallIcon delegate:(id<ASAuthenticationAlertDelegate>)delegate {
	if ((self = [self init])) {
		self.title = title;
		self.message = message;
		self.delegate = delegate;
		self.icon = icon;
		self.useSmallIcon = useSmallIcon;
	}
	return self;
}

%new
- (instancetype)initWithApplication:(NSString *)identifier message:(NSString *)message delegate:(id<ASAuthenticationAlertDelegate>)delegate {
	if (!identifier) {
		return nil;
	}

	if ((self = [self init])) {
		SBApplication *application = [[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:identifier];
		self.title = application.displayName;
		self.message = message;
		self.delegate = delegate;

		SBApplicationIcon *appIcon = [[%c(SBApplicationIcon) alloc] initWithApplication:application];
		SBIconView *iconView = [[%c(SBIconView) alloc] initWithContentType:0];
		[iconView _setIcon:appIcon animated:YES];

		UIImageView *imgView;
		UIImage *iconImage = [iconView.icon getIconImage:2];
		imgView = [[UIImageView alloc] initWithImage:iconImage];
		imgView.frame = CGRectMake(0,0,iconImage.size.width,iconImage.size.height);

		if ([[ASPreferences sharedInstance] touchIDEnabled]) {
			dispatch_async(dispatch_get_main_queue(), ^{
				[[ASAuthenticationController sharedInstance] initialiseGlyphIfRequired];
				imgView.image = [self colouriseImage:iconImage withColour:[UIColor colorWithWhite:0.f alpha:0.5f]];
				CGRect fingerframe = [[ASAuthenticationController sharedInstance] fingerglyph].frame;
				fingerframe.size.height = [iconView _iconImageView].frame.size.height-10;
				fingerframe.size.width = [iconView _iconImageView].frame.size.width-10;
				[[ASAuthenticationController sharedInstance] fingerglyph].frame = fingerframe;
				[[ASAuthenticationController sharedInstance] fingerglyph].center = CGPointMake(CGRectGetMidX(imgView.bounds),CGRectGetMidY(imgView.bounds));
				[imgView addSubview:[[ASAuthenticationController sharedInstance] fingerglyph]];
			});
		}
		self.icon = imgView;

		self.useSmallIcon = NO;
	}
	return self;
}

- (void)configure:(BOOL)configure requirePasscodeForActions:(BOOL)requirePasscode {
	%orig;
	if (self.useSmallIcon) {
		[self alertController].title = titleWithSpacingForSmallIcon(self.title);
		self.icon.center = CGPointMake(270/2,34);
	} else {
		[self alertController].title = titleWithSpacingForIcon(self.title);
		self.icon.center = CGPointMake(270/2,41);
	}
	[self alertController].message = self.message;

	UIAlertAction *cancelButton = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
		CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.a3tweaks.asphaleia.stopmonitoring"), NULL, NULL, YES);
		[[ASAuthenticationController sharedInstance] setCurrentAuthAlert:nil];
		if (self.delegate) {
			[self.delegate authAlertView:self dismissed:YES authorised:NO fingerprint:nil];
		}

		[self dismiss];
	}];

	UIAlertAction *passcodeButton = [UIAlertAction actionWithTitle:@"Passcode" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
		CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.a3tweaks.asphaleia.stopmonitoring"), NULL, NULL, YES);
		[[ASAuthenticationController sharedInstance] setCurrentAuthAlert:nil];
		if (self.delegate) {
			SBIconView *icon = [self.icon isKindOfClass:%c(SBIconView)] ? (SBIconView *)self.icon : nil;

			id delegateReference = self.delegate;
			[[ASPasscodeHandler sharedInstance] showInKeyWindowWithPasscode:[[ASPreferences sharedInstance] getPasscode] iconView:icon eventBlock:^void(BOOL authenticated){
				if (authenticated) {
					[delegateReference authAlertView:self dismissed:YES authorised:YES fingerprint:nil];
				}
			}];
		}

		[self dismiss];
	}];

	[[self alertController] addAction:cancelButton];
	[[self alertController] addAction:passcodeButton];
	dispatch_async(dispatch_get_main_queue(), ^{
		[self addSubviewToAlert:self.icon];
	});
}

- (BOOL)shouldShowInLockScreen {
	return NO;
}

%new
-(void)addSubviewToAlert:(UIView *)view {
	UIView *labelSuperview;
	for (id subview in [self allSubviewsOfView:[[self alertController] view]]) {
		if ([subview isKindOfClass:[UILabel class]]) {
			labelSuperview = [subview superview];
		}
	}
	if ([labelSuperview respondsToSelector:@selector(addSubview:)]) {
		[labelSuperview addSubview:view];
	}
}

%new
- (NSArray *)allSubviewsOfView:(UIView *)view {
	NSMutableArray *viewArray = [[NSMutableArray alloc] init];
	[viewArray addObject:view];
	for (UIView *subview in view.subviews) {
		[viewArray addObjectsFromArray:(NSArray *)[self allSubviewsOfView:subview]];
	}
	return [NSArray arrayWithArray:viewArray];
}

%new
- (void)show {
	if ([[ASAuthenticationController sharedInstance] currentAuthAlert]) {
		[[[ASAuthenticationController sharedInstance] currentAuthAlert] dismiss];
	}

	[[ASAuthenticationController sharedInstance] setCurrentAuthAlert:self];

	if ([[ASPreferences sharedInstance] touchIDEnabled]) {
		CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.a3tweaks.asphaleia.startmonitoring"), NULL, NULL, YES);
	}

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivedNotification:) name:@"com.a3tweaks.asphaleia.fingerdown" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivedNotification:) name:@"com.a3tweaks.asphaleia.fingerup" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivedNotification:) name:@"com.a3tweaks.asphaleia.authsuccess" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivedNotification:) name:@"com.a3tweaks.asphaleia.authfailed" object:nil];

	if (%c(SBAlertItemsController)) {
		[[%c(SBAlertItemsController) sharedInstance] activateAlertItem:self];
	}
}

%new
- (void)receivedNotification:(NSNotification *)notification {
	NSString *name = [notification name];
	if ([name isEqualToString:@"com.a3tweaks.asphaleia.fingerdown"]) {
		if (self.useSmallIcon) {
			[self alertController].title = titleWithSpacingForSmallIcon(@"Scanning finger...");
		} else {
			[self alertController].title = titleWithSpacingForIcon(@"Scanning finger...");
		}
		self.resetFingerprintTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 block:^{
			if (self.useSmallIcon) {
				[self alertController].title = titleWithSpacingForSmallIcon(self.title);
			} else {
				[self alertController].title = titleWithSpacingForIcon(self.title);
			}
		} repeats:NO];
		if ([[ASAuthenticationController sharedInstance] fingerglyph]) {
			[[[ASAuthenticationController sharedInstance] fingerglyph] setState:1 animated:YES completionHandler:nil];
		}
	} else if ([name isEqualToString:@"com.a3tweaks.asphaleia.fingerup"]) {
		if ([[ASAuthenticationController sharedInstance] fingerglyph]) {
			[[[ASAuthenticationController sharedInstance] fingerglyph] setState:0 animated:YES completionHandler:nil];
		}
	} else if ([name isEqualToString:@"com.a3tweaks.asphaleia.authsuccess"]) {
		if ([[ASAuthenticationController sharedInstance] fingerglyph]) {
			[[[ASAuthenticationController sharedInstance] fingerglyph] setState:0 animated:YES completionHandler:nil];
		}

		if (self.delegate) {
			[self.delegate authAlertView:self dismissed:NO authorised:YES fingerprint:[notification userInfo][@"fingerprint"]];
		}
	} else if ([name isEqualToString:@"com.a3tweaks.asphaleia.authfailed"]) {
		if (self.useSmallIcon) {
			[self alertController].title = titleWithSpacingForSmallIcon(self.title);
		} else {
			[self alertController].title = titleWithSpacingForIcon(self.title);
		}
		if ([[ASAuthenticationController sharedInstance] fingerglyph]) {
			[[[ASAuthenticationController sharedInstance] fingerglyph] setState:0 animated:YES completionHandler:nil];
		}
	}
}

- (void)dismiss {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	if (self.resetFingerprintTimer) {
		[self.resetFingerprintTimer invalidate];
		self.resetFingerprintTimer = nil;
	}
	%orig;
}

// Properties
%new
- (void)setTitle:(NSString *)title {
	objc_setAssociatedObject(self, @selector(title), title, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	[self alertController].title = title;
}
%new
- (NSString *)title {
	return objc_getAssociatedObject(self, @selector(title));
}

%new
- (void)setMessage:(NSString *)message {
	objc_setAssociatedObject(self, @selector(message), message, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	[self alertController].message = message;
}
%new
- (NSString *)message {
	return objc_getAssociatedObject(self, @selector(message));
}

%new
- (void)setDelegate:(id<ASAuthenticationAlertDelegate>)delegate {
	objc_setAssociatedObject(self, @selector(delegate), delegate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
%new
- (id<ASAuthenticationAlertDelegate>)delegate {
	return objc_getAssociatedObject(self, @selector(delegate));
}

%new
- (void)setTag:(NSInteger)tag {
	objc_setAssociatedObject(self, @selector(tag), [NSNumber numberWithInt:tag], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
%new
- (NSInteger)tag {
	return [objc_getAssociatedObject(self, @selector(tag)) intValue];
}

%new
- (void)setIcon:(UIView *)icon {
	objc_setAssociatedObject(self, @selector(icon), icon, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
%new
- (UIView *)icon {
	return objc_getAssociatedObject(self, @selector(icon));
}

%new
- (void)setUseSmallIcon:(BOOL)useSmallIcon {
	objc_setAssociatedObject(self, @selector(useSmallIcon), [NSNumber numberWithBool:useSmallIcon], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
%new
- (BOOL)useSmallIcon {
	return [objc_getAssociatedObject(self, @selector(useSmallIcon)) boolValue];
}

%new
- (void)setResetFingerprintTimer:(NSTimer *)resetFingerprintTimer {
	objc_setAssociatedObject(self, @selector(resetFingerprintTimer), resetFingerprintTimer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
%new
- (UIView *)resetFingerprintTimer {
	return objc_getAssociatedObject(self, @selector(resetFingerprintTimer));
}

// Other
%new
- (UIImage *)colouriseImage:(UIImage *)origImage withColour:(UIColor *)tintColour {
	UIGraphicsBeginImageContextWithOptions(origImage.size, NO, origImage.scale);
	CGContextRef imgContext = UIGraphicsGetCurrentContext();
	CGRect imageRect = CGRectMake(0, 0, origImage.size.width, origImage.size.height);
	CGContextScaleCTM(imgContext, 1, -1);
	CGContextTranslateCTM(imgContext, 0, -imageRect.size.height);
	CGContextSaveGState(imgContext);
	CGContextClipToMask(imgContext, imageRect, origImage.CGImage);
	[tintColour set];
	CGContextFillRect(imgContext, imageRect);
	CGContextRestoreGState(imgContext);
	CGContextSetBlendMode(imgContext, kCGBlendModeMultiply);
	CGContextDrawImage(imgContext, imageRect, origImage.CGImage);
	UIImage *finalImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return finalImage;
}

%end
