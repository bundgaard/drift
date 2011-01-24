//
//  GELoginViewController.h
//  Driftpad
//
//  Created by Devin Chalmers on 4/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface GELoginViewController : UIViewController <UITextFieldDelegate> {
	IBOutlet UITextField *loginField;
	IBOutlet UITextField *tokenField;
	IBOutlet UIView *overlayView;
	IBOutlet UIButton *signInButton;
	IBOutlet UIButton *cancelButton;
}

@property (nonatomic, retain) IBOutlet UITextField *loginField;
@property (nonatomic, retain) IBOutlet UITextField *tokenField;
@property (nonatomic, retain) IBOutlet UIView *overlayView;
@property (nonatomic, retain) IBOutlet UIButton *signInButton;
@property (nonatomic, retain) IBOutlet UIButton *cancelButton;
@property (nonatomic, retain) IBOutlet UILabel *aboutLabel;

- (IBAction)signInAction:(id)sender;
- (IBAction)signUpAction:(id)sender;
- (IBAction)accountPageAction:(id)sender;
- (IBAction)cancelAction:(id)sender;

@end
