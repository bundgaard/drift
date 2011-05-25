//
//  GELoginViewController.m
//  Driftpad
//
//  Created by Devin Chalmers on 4/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "GELoginViewController.h"

#import <QuartzCore/QuartzCore.h>

#import "GEGistService.h"

@implementation GELoginViewController

@synthesize containerView;
@synthesize splashView;
@synthesize signInView;
@synthesize headerView;

@synthesize loginField;
@synthesize tokenField;
@synthesize overlayView;
@synthesize signInButton;
@synthesize cancelButton;
@synthesize aboutLabel;

- (void)dealloc;
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
    [containerView release], containerView = nil;
    [splashView release], splashView = nil;
    [signInView release], signInView = nil;
    [headerView release], headerView = nil;
    
	[loginField release], loginField = nil;
	[tokenField release], tokenField = nil;
	[overlayView release], overlayView = nil;
	[signInButton release], signInButton = nil;
	[cancelButton release], cancelButton = nil;
	[aboutLabel release], aboutLabel = nil;
	
    [super dealloc];
}

#pragma mark View controller

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (void)viewDidLoad;
{
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginFailed:) name:kDriftNotificationLoginFailed object:nil];
	
	if (!([[GEGistService sharedService] hasCredentials] || [GEGistService sharedService].anonymous))
		[cancelButton removeFromSuperview];
	
	NSString *version = [[[NSBundle mainBundle] infoDictionary] valueForKey:(id)kCFBundleVersionKey];
	aboutLabel.text = [NSString stringWithFormat:@"Drift %@ in Permanent Maintenance since 2010", version];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewDidUnload;
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark Interface actions

- (IBAction)useAnonymouslyAction:(id)sender;
{
	[[GEGistService sharedService] loginAnonymously];
}

- (IBAction)showSignInAction:(id)sender;
{
    CGRect frame = self.containerView.bounds;
    frame.origin.x = frame.size.width;
    self.signInView.frame = frame;
    
    [self.containerView addSubview:self.signInView];
    
    [UIView beginAnimations:nil context:nil];
    
    frame.origin.x = -frame.size.width;
    self.splashView.frame = frame;
    
    frame.origin.x = 0;
    self.signInView.frame = frame;
    
    [UIView commitAnimations];
    
    [self.loginField becomeFirstResponder];
}

- (IBAction)showSplashAction:(id)sender;
{
    [loginField resignFirstResponder];
    [tokenField resignFirstResponder];
    
    CGRect frame = self.containerView.bounds;
    frame.origin.x = -frame.size.width;
    self.signInView.frame = frame;
    
    [self.containerView addSubview:self.splashView];
    
    [UIView beginAnimations:nil context:nil];
    
    frame.origin.x = 0;
    self.splashView.frame = frame;
    
    frame.origin.x = frame.size.width;
    self.signInView.frame = frame;
    
    [UIView commitAnimations];
}

- (IBAction)signInAction:(id)sender;
{
    [loginField resignFirstResponder];
    [tokenField resignFirstResponder];

	self.overlayView.alpha = 0.0;
	self.overlayView.frame = self.view.bounds;
	[self.view addSubview:self.overlayView];

	[UIView beginAnimations:nil context:nil];
	self.overlayView.alpha = 1.0;
	[UIView commitAnimations];
	
	NSString *username = loginField.text;
	NSString *password = tokenField.text;

    [[GEGistService sharedService] loginUserWithUsername:username password:password];
}

- (IBAction)signUpAction:(id)sender;
{
	NSURL *url = [NSURL URLWithString:@"http://github.com/plans"];
	[[UIApplication sharedApplication] openURL:url];
}

- (IBAction)accountPageAction:(id)sender;
{
	NSURL *url = [NSURL URLWithString:@"http://github.com/account"];
	[[UIApplication sharedApplication] openURL:url];
}

- (IBAction)cancelAction:(id)sender;
{
	[self dismissModalViewControllerAnimated:YES];
}

#pragma mark Service callbacks

- (void)loginFailed:(NSNotification *)notification;
{
	[UIView beginAnimations:nil context:nil];
	self.overlayView.alpha = 0.0;
	[UIView commitAnimations];
	
	UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle:@"Sign in failed" message:@"We couldn't sign you in. Double-check your login and password." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease];
	[alertView show];
}

#pragma mark Text field delegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string;
{
	UITextField *otherTextField = (textField ==  loginField) ? tokenField : loginField;
	NSString *newString = [textField.text stringByReplacingCharactersInRange:range withString:string];
	signInButton.enabled = (newString.length > 0 && otherTextField.text.length > 0);
	return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField;
{
	signInButton.enabled = NO;
	return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField;
{
	if (textField == loginField) {
		[tokenField becomeFirstResponder];
	}
	else if (textField == tokenField) {
		[self signInAction:self];
	}
	return NO;
}

#pragma mark - Keyboard

- (void)keyboardShow:(NSNotification *)notification;
{
    NSDictionary *userInfo = [notification userInfo];
    
    CGFloat duration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    int curve = [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue];
    CGRect keyboardRect = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect myRect = [self.containerView convertRect:keyboardRect fromView:self.view.window];
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationCurve:curve];
    [UIView setAnimationDuration:duration];
    
    if (myRect.origin.y <= self.containerView.frame.size.height) {
        CGFloat delta = self.containerView.frame.size.height - myRect.origin.y;
        
        CGRect frame = self.headerView.frame;
        frame.size.height -= delta;
        self.headerView.frame = frame;
        
        frame = self.containerView.frame;
        frame.origin.y -= delta;
        self.containerView.frame = frame;
    }
    
    [UIView commitAnimations];
}

- (void)keyboardHide:(NSNotification *)notification;
{
    NSDictionary *userInfo = [notification userInfo];
    
    CGFloat duration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    int curve = [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue];
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationCurve:curve];
    [UIView setAnimationDuration:duration];
    
    CGRect frame = self.headerView.frame;
    frame.size.height = 299;
    self.headerView.frame = frame;
    
    frame = self.containerView.frame;
    frame.origin.y = 299;
    self.containerView.frame = frame;
    
    [UIView commitAnimations];
}

@end
