#define xpcNotifications @[\
	@"com.a3tweaks.asphaleia.xpc/CheckSlideUpControllerActive",\
	@"com.a3tweaks.asphaleia.xpc/SetAsphaleiaState",\
	@"com.a3tweaks.asphaleia.xpc/ReadAsphaleiaState",\
	@"com.a3tweaks.asphaleia.xpc/SetUserAuthorisedApp",\
	@"com.a3tweaks.asphaleia.xpc/AuthenticateApp",\
	@"com.a3tweaks.asphaleia.xpc/AuthenticateFunction",\
	@"com.a3tweaks.asphaleia.xpc/GetCurrentAuthAlert",\
	@"com.a3tweaks.asphaleia.xpc/GetCurrentTempUnlockedApp",\
	@"com.a3tweaks.asphaleia.xpc/IsTouchIDDevice"]
@interface ASXPCHandler : NSObject
@property BOOL slideUpControllerActive;
+ (instancetype)sharedInstance;
- (NSDictionary *)handleMessageNamed:(NSString *)name withUserInfo:(NSDictionary *)userinfo;
@end
