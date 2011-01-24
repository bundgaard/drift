    //
//  GELoginViewController.m
//  Driftpad
//
//  Created by Devin Chalmers on 4/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "GELoginViewController.h"

#import "GEGistService.h"

@implementation GELoginViewController

@synthesize loginField;
@synthesize tokenField;
@synthesize overlayView;
@synthesize signInButton;
@synthesize cancelButton;
@synthesize aboutLabel;

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
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
	if ([[GEGistService sharedService] hasCredentials]) {
		loginField.text = [[NSUserDefaults standardUserDefaults] valueForKey:@"username"];
		tokenField.text = [[NSUserDefaults standardUserDefaults] valueForKey:@"token"];
	}
	else {
		[cancelButton removeFromSuperview];
	}
	
	NSString *version = [[[NSBundle mainBundle] infoDictionary] valueForKey:(id)kCFBundleVersionKey];
	aboutLabel.text = [NSString stringWithFormat:@"Drift %@ in Permanent Maintenance since 2010", version];
}

- (void)viewDidUnload;
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillAppear:(BOOL)animated;
{
	[loginField becomeFirstResponder];
}

#pragma mark Interface actions

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
	NSString *token = tokenField.text;
	
	[[GEGistService sharedService] loginUserWithUsername:username token:token];
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
	
	UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle:@"Sign in failed" message:@"We couldn't sign you in. Double-check your login and API token." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease];
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

@end
