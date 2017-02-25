#import "ASAlert.h"
#import <SpringBoard/SBAlertItemsController.h>

#define titleWithSpacingForIcon(t) [NSString stringWithFormat:@"\n\n\n%@",t]
#define titleWithSpacingForSmallIcon(t) [NSString stringWithFormat:@"\n\n%@",t]

@interface ASAlert ()
@property (nonatomic) NSMutableArray *buttons;
@property (nonatomic) UIView *aboveTitleSubview;
@property NSInteger cancelButtonIndex;
- (NSArray *)allSubviewsOfView:(UIView *)view;
- (void)addSubviewToAlert:(UIView *)view;
@end

%subclass ASAlert : SBAlertItem

%new
- (instancetype)initWithTitle:(NSString *)title message:(NSString *)message delegate:(id<ASAlertDelegate>)delegate {
	if ((self = [self init])) {
		self.title = title;
		self.message = message;
		self.delegate = delegate;
		self.buttons = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void)configure:(BOOL)configure requirePasscodeForActions:(BOOL)requirePasscode {
	%orig;
	self.alertSheet.title = self.title;
	self.alertSheet.message = self.message;

	for (NSString *button in self.buttons) {
		[self.alertSheet addButtonWithTitle:button];
	}

	self.alertSheet.cancelButtonIndex = self.cancelButtonIndex;

	if (self.aboveTitleSubview) {
		self.alertSheet.title = titleWithSpacingForSmallIcon(self.title);
		self.aboveTitleSubview.center = CGPointMake(270/2,32);
		dispatch_async(dispatch_get_main_queue(), ^{
			[self addSubviewToAlert:self.aboveTitleSubview];
		});
	}
}

- (void)alertView:(id)arg1 clickedButtonAtIndex:(NSInteger)arg2 {
	if (self.delegate && [self.delegate respondsToSelector:@selector(alertView:clickedButtonAtIndex:)]) {
		[self.delegate alertView:arg1 clickedButtonAtIndex:arg2];
	}

	[self dismiss];
}

- (BOOL)shouldShowInLockScreen {
	return NO;
}

%new
- (void)addSubviewToAlert:(UIView *)view {
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
	if (self.delegate && [self.delegate respondsToSelector:@selector(willPresentAlertView:)]) {
		[self.delegate willPresentAlertView:self];
	}
	if (%c(SBAlertItemsController)) {
		[[%c(SBAlertItemsController) sharedInstance] activateAlertItem:self];
	}
}

%new
- (void)addButtonWithTitle:(NSString *)buttonTitle {
	if ([buttonTitle isKindOfClass:[NSString class]]) {
		[self.buttons addObject:buttonTitle];
	}
}

%new
- (void)removeButtonWithTitle:(NSString *)buttonTitle {
	if ([buttonTitle isKindOfClass:[NSString class]]) {
		[self.buttons removeObject:buttonTitle];
	}
}

// Properties
%new
- (void)setTitle:(NSString *)title {
	objc_setAssociatedObject(self, @selector(title), title, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
%new
- (NSString *)title {
	return objc_getAssociatedObject(self, @selector(title));
}

%new
- (void)setMessage:(NSString *)message {
	objc_setAssociatedObject(self, @selector(message), message, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
%new
- (NSString *)message {
	return objc_getAssociatedObject(self, @selector(message));
}

%new
- (void)setDelegate:(id<ASAlertDelegate>)delegate {
	objc_setAssociatedObject(self, @selector(delegate), delegate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
%new
- (id<ASAlertDelegate>)delegate {
	return objc_getAssociatedObject(self, @selector(delegate));
}

%new
- (void)setButtons:(NSMutableArray *)buttons {
	objc_setAssociatedObject(self, @selector(buttons), buttons, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
%new
- (NSMutableArray *)buttons {
	return objc_getAssociatedObject(self, @selector(buttons));
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
- (void)setAboveTitleSubview:(UIView *)aboveTitleSubview {
	objc_setAssociatedObject(self, @selector(aboveTitleSubview), aboveTitleSubview, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
%new
- (UIView *)aboveTitleSubview {
	return objc_getAssociatedObject(self, @selector(aboveTitleSubview));
}

%new
- (void)setCancelButtonIndex:(NSInteger)cancelButtonIndex {
	objc_setAssociatedObject(self, @selector(cancelButtonIndex), [NSNumber numberWithInt:cancelButtonIndex], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
%new
- (NSInteger)cancelButtonIndex {
	return [objc_getAssociatedObject(self, @selector(cancelButtonIndex)) intValue];
}

%end
