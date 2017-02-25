//
//  CRViewController.h
//  pintest
//
//  Created by Callum Ryan on 05/01/2014.
//  Copyright (c) 2014 Callum Ryan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TouchIDInfo.h"

@interface modalPinVC : UIViewController <UITextFieldDelegate,UIScrollViewDelegate> {
    UIScrollView *_scrollView;
    UIView *_altView;
    NSArray *_imageViews;
    int _currentPage;
    NSString *_newPasscode;
    BOOL _isAuth;
    BOOL _isSet;
    BOOL _first;
    id _delegate;
}
- (id)initToAuthWithDelegate:(id)sender;
- (id)initToSetPasscode:(id)sender;
- (id)initWithDelegate:(id)sender;
- (id)initToSetPasscodeFirst:(id)sender;
@end
