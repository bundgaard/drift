//
//  GEGistViewController.h
//  Driftpad
//
//  Created by Devin Chalmers on 4/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GEGist;

@interface GEGistViewController : UIViewController <UITextViewDelegate, UITextFieldDelegate, UIActionSheetDelegate> {
}

@property (nonatomic, retain) IBOutlet UITextView *textView;

@property (nonatomic, retain) IBOutlet UIBarButtonItem *gistsButton;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *actionButton;

@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *activitySpinner;

@property (nonatomic, retain) IBOutlet UIView *titleView;
@property (nonatomic, retain) IBOutlet UIButton *titleButton;
@property (nonatomic, retain) IBOutlet UITextField *editTitleTextField;

@property (nonatomic, retain) GEGist *gist;

- (void)save;

- (IBAction)actionAction:(id)sender;
- (IBAction)titleAction:(id)sender;

- (IBAction)gistListAction:(id)sender;
- (IBAction)newGistAction:(id)sender;

@end
