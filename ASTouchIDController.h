/* Modified from Sassoty's code
https://github.com/Sassoty/BioTesting */
#import "Asphaleia.h"
@class ASTouchIDController;
@protocol _SBUIBiometricKitInterfaceDelegate
@required
- (void)biometricKitInterface:(id)interface handleEvent:(unsigned long long)event;
@end

typedef void (^BTTouchIDEventBlock) (ASTouchIDController *controller, id monitor, unsigned event);

#define asphaleiaLogMsg(str) NSLog(@"[Asphaleia] %@",str)

@interface _SBUIBiometricKitInterface : NSObject
@property (assign,nonatomic) id<_SBUIBiometricKitInterfaceDelegate> delegate;
- (void)cancel;
- (void)setDelegate:(id<_SBUIBiometricKitInterfaceDelegate>)arg1;
- (int)detectFingerWithOptions:(id)arg1 ;
- (int)matchWithMode:(unsigned long long)arg1 andCredentialSet:(id)arg2;
@end


#define TouchIDFingerDown  1
#define TouchIDFingerUp    0
#define TouchIDFingerHeld  2
#define TouchIDMatched     3
#define TouchIDMaybeMatched 4
#define TouchIDNotMatched  9

@interface ASTouchIDController : NSObject <_SBUIBiometricKitInterfaceDelegate> {
	BOOL starting;
	BOOL stopping;
	NSArray *activatorListenerNames;
}
@property (nonatomic, strong) BTTouchIDEventBlock biometricEventBlock;
@property (readonly) BOOL isMonitoring;
@property (readonly) id oldDelegate;
@property (readonly) id lastMatchedFingerprint;
@property BOOL shouldBlockLockscreenMonitor;
+ (instancetype)sharedInstance;
- (void)startMonitoring;
- (void)stopMonitoring;
@end
