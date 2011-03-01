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
- (void)fillDefaultTitle;
@property (nonatomic, retain) UIActionSheet *actionSheet;
@property (nonatomic, assign) BOOL interactionDisabled;
@end


@implementation GEGistViewController

@synthesize textView;

@synthesize gistsButton;
@synthesize actionButton;

@synthesize activitySpinner;

@synthesize titleView;
@synthesize titleButton;
@synthesize editTitleTextField;

@synthesize gist;

@synthesize actionSheet;

@synthesize interactionDisabled;

- (void)dealloc;
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[textView release], textView = nil;
	
	[gistsButton release], gistsButton = nil;
	[actionButton release], actionButton = nil;
	
	[activitySpinner release], activitySpinner = nil;
	
	[titleView release], titleView = nil;
	[titleButton release], titleButton = nil;
	[editTitleTextField release], editTitleTextField = nil;
	
	[gist release], gist = nil;
	
	[actionSheet release], actionSheet = nil;
	
    [super dealloc];
}

- (void)setGist:(GEGist *)newGist;
{
	if (gist == newGist)
		return;
	
	// save current gist
	[self save];
	
	[gist release];
	gist = [newGist retain];
	
	if (gist) [[GEGistService sharedService] fetchGist:gist];
	
	[GEGist markCurrentGist:gist];
	
	[self updateDisplay];
}

#pragma mark -
#pragma mark View controller

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	textView.font = [UIFont fontWithName:@"Inconsolata" size:17.0];
	
	[self.titleView addSubview:titleButton];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(gistUpdated:) name:kDriftNotificationUpdateGistSucceeded object:[GEGistService sharedService]];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(gistUpdateFailed:) name:kDriftNotificationUpdateGistFailed object:[GEGistService sharedService]];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardShow:) name:UIKeyboardDidShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewDidUnload;
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark -
#pragma mark Gist display

- (void)save;
{
	[self fillDefaultTitle];
	[[GEGistStore sharedStore] save];
	if (self.gist) [[GEGistService sharedService] pushGist:self.gist];
}

- (void)updateDisplay;
{
	self.interactionDisabled = YES;
	
	if (self.gist.name) {
		editTitleTextField.text = self.gist.name;
		[titleButton setTitle:self.gist.name forState:UIControlStateNormal];
	} else {
		editTitleTextField.text = @"";
		[titleButton setTitle:self.gist.gistID forState:UIControlStateNormal];
	}
	
	BOOL isEditing = [textView isFirstResponder];
	if (isEditing) [textView resignFirstResponder];
	
	textView.text = self.gist.body;
	actionButton.enabled = (!!self.gist.gistID);
	
	if (isEditing) [textView becomeFirstResponder];
	
	// check for undownloaded gist
	if (!self.gist.body && gist.gistID) {
		[self.textView resignFirstResponder];
		self.textView.editable = NO;
		[self.activitySpinner startAnimating];
	}
	else {
		self.textView.editable = YES;
		[self.activitySpinner stopAnimating];
	}
	
	self.interactionDisabled = NO;
}

- (void)fillDefaultTitle;
{
	// use the first non-blank line as the default title, truncated to 37 characters.
	// would be friendly to break on word boundaries.
	
	if (!self.gist || self.gist.name.length > 0)
		return;
	
	NSCharacterSet *set = [[NSCharacterSet whitespaceAndNewlineCharacterSet] invertedSet];
	NSInteger firstCharacterIndex = [self.gist.body rangeOfCharacterFromSet:set].location;
	if (firstCharacterIndex == NSNotFound)
		return;
	
	NSRange searchRange = NSMakeRange(firstCharacterIndex, self.gist.body.length - firstCharacterIndex);
	NSInteger lineEndIndex = [self.gist.body rangeOfString:@"\n" options:0 range:searchRange].location;
	if (lineEndIndex == NSNotFound) lineEndIndex = self.gist.body.length;
	
	BOOL truncated = NO;
	NSRange titleRange = NSMakeRange(firstCharacterIndex, lineEndIndex - firstCharacterIndex);
	if (titleRange.length > 37) {
		titleRange.length = 37;
		truncated = YES;
	}
	
	NSString *defaultTitle = [self.gist.body substringWithRange:titleRange];
	if (truncated) defaultTitle = [defaultTitle stringByAppendingString:@"..."];
	
	self.gist.name = defaultTitle;
}

#pragma mark -
#pragma mark Service callbacks

- (void)gistUpdated:(NSNotification *)notification;
{
	GEGist *updatedGist = [[notification userInfo] valueForKey:@"gist"];
	if (updatedGist == self.gist && !self.gist.dirty) {
		[self updateDisplay];
	}
}

- (void)gistUpdateFailed:(NSNotification *)notification;
{
	NSLog(@"Couldn't update gist!");
}

#pragma mark -
#pragma mark Interface actions

- (IBAction)actionAction:(id)sender;
{
	// TODO: keep this from being multiply displayed, or displayed at the same time as gist popover
	if (!self.actionSheet) self.actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:@"View in Safari", @"Copy URL", nil];
	[self.actionSheet showFromBarButtonItem:actionButton animated:YES];
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
	self.gist = [GEGist blankGist];
	[self.textView becomeFirstResponder];
}

#pragma mark -
#pragma mark Action sheet delegate

- (void)actionSheet:(UIActionSheet *)theActionSheet willDismissWithButtonIndex:(NSInteger)buttonIndex;
{
	if (buttonIndex < 0)
		return;
	
	NSString *title = [theActionSheet buttonTitleAtIndex:buttonIndex];
	
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
	[editTitleTextField removeFromSuperview];
	[titleView addSubview:titleButton];
	[self updateDisplay];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string;
{
	NSString *newName = [textField.text stringByReplacingCharactersInRange:range withString:string];
	if (![newName isEqual:self.gist.name]) {
		[titleButton setTitle:newName forState:UIControlStateNormal];
		self.gist.name = newName;
		self.gist.dirty = YES;
	}
	self.gist.dirty = YES;
	
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
}

- (void)textViewDidEndEditing:(UITextView *)textView;
{
	if (!self.gist.name)
		[self fillDefaultTitle];
}

#pragma mark -
#pragma mark Keyboard

- (void)keyboardShow:(NSNotification *)notification;
{
	if (self.interactionDisabled)
		return;
	
	NSDictionary *userInfo = [notification userInfo];
	CGRect kbFrame = [[userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
	kbFrame = [self.view convertRect:kbFrame fromView:self.view.window];
	
	double duration = [[userInfo valueForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
	UIViewAnimationCurve curve = [[userInfo	valueForKey:UIKeyboardAnimationCurveUserInfoKey] intValue];
	
	[UIView beginAnimations:nil context:nil];
	
	[UIView setAnimationCurve:curve];
	[UIView setAnimationDuration:duration];
	
    CGRect frame = self.textView.frame;
    frame.size.height = self.view.bounds.size.height - frame.origin.y - kbFrame.size.height;
    self.textView.frame = frame;
	
	[UIView commitAnimations];
}

- (void)keyboardHide:(NSNotification *)notification;
{
	if (self.interactionDisabled)
		return;
	
	NSDictionary *userInfo = [notification userInfo];
	
	double duration = [[userInfo valueForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
	UIViewAnimationCurve curve = [[userInfo	valueForKey:UIKeyboardAnimationCurveUserInfoKey] intValue];
	
	[UIView beginAnimations:nil context:nil];
	
	[UIView setAnimationCurve:curve];
	[UIView setAnimationDuration:duration];
	
    CGRect frame = self.textView.frame;
    frame.size.height = self.view.bounds.size.height - frame.origin.y;
    self.textView.frame = frame;
	
	[UIView commitAnimations];
	
	// save every time we put away the keyboard
	[self save];
}

@end
