#import "Asphaleia.h"

@class ASAlert;

@protocol ASAlertDelegate <NSObject>
- (void)alertView:(ASAlert *)alertView clickedButtonAtIndex:(NSInteger)index;
@optional
- (void)willPresentAlertView:(ASAlert *)alertView;
@end

@interface ASAlert : SBAlertItem
@property (nonatomic) NSString *title;
@property (nonatomic) NSString *message;
@property (nonatomic, weak) id<ASAlertDelegate> delegate;
@property(nonatomic) NSInteger tag;
- (instancetype)initWithTitle:(NSString *)title message:(NSString *)message delegate:(id<ASAlertDelegate>)delegate;
- (id)alertController;
- (void)addButtonWithTitle:(NSString *)buttonTitle;
- (void)removeButtonWithTitle:(NSString *)buttonTitle;
- (void)setCancelButtonIndex:(NSInteger)cancelButtonIndex;
- (void)setAboveTitleSubview:(UIView *)view;
- (void)show;

@end
