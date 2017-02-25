#import "Asphaleia.h"

@class ASAuthenticationAlert;

@protocol ASAuthenticationAlertDelegate <NSObject>
- (void)authAlertView:(ASAuthenticationAlert *)alertView dismissed:(BOOL)dismissed authorised:(BOOL)authorised fingerprint:(BiometricKitIdentity *)fingerprint;
@optional
- (void)willPresentAlertView:(ASAuthenticationAlert *)alertView;
@end

@interface ASAuthenticationAlert : SBAlertItem
@property (nonatomic) NSString *title;
@property (nonatomic) NSString *message;
@property (nonatomic, weak) id<ASAuthenticationAlertDelegate> delegate;
@property(nonatomic) NSInteger tag;
@property (nonatomic) UIView *icon;
@property (nonatomic) NSTimer *resetFingerprintTimer;
@property BOOL useSmallIcon;
- (instancetype)initWithTitle:(NSString *)title message:(NSString *)message icon:(UIView *)icon smallIcon:(BOOL)useSmallIcon delegate:(id<ASAuthenticationAlertDelegate>)delegate;
- (instancetype)initWithApplication:(NSString *)identifier message:(NSString *)message delegate:(id<ASAuthenticationAlertDelegate>)delegate;
- (_SBAlertController*)alertController;
- (void)show;

@end
