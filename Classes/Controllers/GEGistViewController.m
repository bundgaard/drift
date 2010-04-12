    //
//  GEGistViewController.m
//  Driftpad
//
//  Created by Devin Chalmers on 4/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "GEGistViewController.h"

#import "GEGist.h"
#import "GEGistStore.h"
#import "GEGistService.h"

#import "DriftpadAppDelegate.h"

@interface GEGistViewController ()
- (void)updateDisplay;
@end


@implementation GEGistViewController

@synthesize textView;
@synthesize userButton;
@synthesize pushButton;
@synthesize actionButton;

@synthesize titleView;
@synthesize titleButton;
@synthesize editTitleTextField;

@synthesize gist;

- (void)dealloc;
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[textView release], textView = nil;
	[userButton release], userButton = nil;
	[pushButton release], pushButton = nil;
	[actionButton release], actionButton = nil;
	
	[titleView release], titleView = nil;
	[titleButton release], titleButton = nil;
	[editTitleTextField release], editTitleTextField = nil;
	
	[gist release], gist = nil;
	
    [super dealloc];
}

- (void)setGist:(GEGist *)newGist;
{
	if (gist == newGist)
		return;
	
	[gist release];
	gist = [newGist retain];
	
	// TODO: better fetch logic
	if (!gist.body && gist.gistID) {
		[[GEGistService sharedService] fetchGist:gist];
	}
	
	[self updateDisplay];
}

#pragma mark -
#pragma mark View controller

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	textView.font = [UIFont fontWithName:@"Courier New" size:17.0];
	
	[self.titleView addSubview:titleButton];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(gistUpdated:) name:kDriftNotificationUpdatedGist object:[GEGistService sharedService]];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewDidUnload;
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark -
#pragma mark Gist display

- (void)updateDisplay;
{
	userButton.title = [[NSUserDefaults standardUserDefaults] valueForKey:@"username"];
	if (self.gist.name) {
		editTitleTextField.text = self.gist.name;
		[titleButton setTitle:self.gist.name forState:UIControlStateNormal];
	} else {
		editTitleTextField.text = @"";
		[titleButton setTitle:self.gist.gistID forState:UIControlStateNormal];
	}
	textView.text = self.gist.body;
	pushButton.enabled = self.gist.dirty;
	actionButton.enabled = (!!self.gist.gistID);
}

#pragma mark -
#pragma mark Service callbacks

- (void)gistUpdated:(NSNotification *)notification;
{
	GEGist *updatedGist = [[notification userInfo] valueForKey:@"gist"];
	if (updatedGist == self.gist) {
		[self updateDisplay];
	}
}

#pragma mark -
#pragma mark Interface actions

- (IBAction)pushAction:(id)sender;
{
	[editTitleTextField resignFirstResponder];
	[textView resignFirstResponder];
	[[GEGistService sharedService] pushGist:self.gist];
}

- (IBAction)actionAction:(id)sender;
{
	// TODO: keep this from being multiply displayed, or displayed at the same time as gist popover
	UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:@"View in Safari", @"Copy URL", nil];
	[sheet showFromBarButtonItem:actionButton animated:YES];
}

- (IBAction)titleAction:(id)sender;
{
	[titleButton removeFromSuperview];
	[titleView addSubview:editTitleTextField];
	editTitleTextField.frame = titleButton.frame;
	[editTitleTextField becomeFirstResponder];
}

- (IBAction)gistListAction:(id)sender;
{
	DriftpadAppDelegate *delegate = (DriftpadAppDelegate *)[[UIApplication sharedApplication] delegate];
	[delegate showGistPopoverFromBarButtonItem:sender];
}

- (IBAction)newGistAction:(id)sender;
{
	NSManagedObjectContext *ctx = [[GEGistStore sharedStore] managedObjectContext];
	GEGist *newGist = [NSEntityDescription insertNewObjectForEntityForName:[GEGist entityName] inManagedObjectContext:ctx];
	newGist.name = @"New gist";
	newGist.createdAt = [NSDate date];
	newGist.dirty = YES;
	[[GEGistStore sharedStore] save];
	self.gist = newGist;
}

#pragma mark -
#pragma mark Action sheet delegate

- (void)actionSheet:(UIActionSheet *)actionSheet willDismissWithButtonIndex:(NSInteger)buttonIndex;
{
	if (buttonIndex < 0)
		return;
	
	NSString *title = [actionSheet buttonTitleAtIndex:buttonIndex];
	
	NSString *urlString = [NSString stringWithFormat:@"http://gist.github.com/%@", self.gist.gistID];
	if ([title isEqual:@"View in Safari"]) {
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString]];
	}
	else if ([title isEqual:@"Copy URL"]) {
		for (NSString *type in UIPasteboardTypeListString)
			[[UIPasteboard generalPasteboard] setValue:urlString forPasteboardType:type];
	}
}

#pragma mark -
#pragma mark Text field delegate

- (void)textFieldDidEndEditing:(UITextField *)textField
{
	NSString *newName = textField.text;
	if (![newName isEqual:self.gist.name]) {
		[titleButton setTitle:newName forState:UIControlStateNormal];
		self.gist.name = newName;
		self.gist.dirty = YES;
	}
	[editTitleTextField removeFromSuperview];
	[titleView addSubview:titleButton];
	[self updateDisplay];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string;
{
	self.gist.name = textField.text;
	self.gist.dirty = YES;
	pushButton.enabled = YES;
	return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField;
{
	[textField resignFirstResponder];
	return NO;
}

#pragma mark -
#pragma mark Text view delegate

- (void)textViewDidChange:(UITextView *)theTextView;
{
	self.gist.body = textView.text;
	self.gist.dirty = YES;
	pushButton.enabled = YES;
}

#pragma mark -
#pragma mark Keyboard

- (void)keyboardWillShow:(NSNotification *)notification;
{
	NSDictionary *userInfo = [notification userInfo];
	CGRect kbFrame = [[userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
	kbFrame = [self.view convertRect:kbFrame fromView:self.view.window];
	
	double duration = [[userInfo valueForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
	UIViewAnimationCurve curve = [[userInfo	valueForKey:UIKeyboardAnimationCurveUserInfoKey] intValue];
	
	[UIView beginAnimations:nil context:nil];
	
	[UIView setAnimationCurve:curve];
	[UIView setAnimationDuration:duration];
	
	CGRect textViewFrame = textView.frame;
	textViewFrame.size.height -= kbFrame.size.height;
	textView.frame = textViewFrame;
	
	[UIView commitAnimations];
}

- (void)keyboardWillHide:(NSNotification *)notification;
{
	NSDictionary *userInfo = [notification userInfo];
	CGRect kbFrame = [[userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
	kbFrame = [self.view convertRect:kbFrame fromView:self.view.window];
	
	double duration = [[userInfo valueForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
	UIViewAnimationCurve curve = [[userInfo	valueForKey:UIKeyboardAnimationCurveUserInfoKey] intValue];
	
	[UIView beginAnimations:nil context:nil];
	
	[UIView setAnimationCurve:curve];
	[UIView setAnimationDuration:duration];
	
	CGRect textViewFrame = textView.frame;
	textViewFrame.size.height += kbFrame.size.height;
	textView.frame = textViewFrame;
	
	[UIView commitAnimations];
}

@end
