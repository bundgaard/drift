    //
//  GEGistViewController.m
//  Driftpad
//
//  Created by Devin Chalmers on 4/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "GEGistViewController.h"

#import "GEGist.h"
#import "GEFile.h"
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

@synthesize forkHeaderView;
@synthesize forkHeaderLabel;
@synthesize forkButton;
@synthesize forkSpinner;
@synthesize forkedHeaderView;
@synthesize forkedHeaderLabel;
@synthesize forkOfHeaderView;
@synthesize forkOfHeaderLabel;

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
    
    [forkHeaderView release], forkHeaderView = nil;
    [forkHeaderLabel release], forkHeaderLabel = nil;
    [forkButton release], forkButton = nil;
    [forkSpinner release], forkSpinner = nil;
    [forkedHeaderView release], forkedHeaderView = nil;
    [forkedHeaderLabel release], forkedHeaderLabel = nil;
    [forkOfHeaderLabel release], forkOfHeaderLabel = nil;
	
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
	
	if (self.gist.file.filename) {
		editTitleTextField.text = self.gist.file.filename;
		[titleButton setTitle:self.gist.file.filename forState:UIControlStateNormal];
	} else {
		editTitleTextField.text = @"";
		[titleButton setTitle:self.gist.gistID forState:UIControlStateNormal];
	}
	
	BOOL isEditing = [textView isFirstResponder];
	if (isEditing) [textView resignFirstResponder];
	
	textView.text = self.gist.file.content;
	actionButton.enabled = (!!self.gist.gistID);
	
	if (isEditing) [textView becomeFirstResponder];
	
    BOOL myGist = ([self.gist.user isEqual: [GEGistService sharedService].username]);
    BOOL isLoaded = (self.gist.file.content || !gist.gistID); // de morgan's law? this should exclude undownloaded gists
    
	if (myGist && isLoaded) {
        self.textView.backgroundColor = [UIColor colorWithWhite:0.92 alpha:1.0];
        self.textView.textColor = [UIColor colorWithWhite:0.07 alpha:1.0];
		self.textView.editable = YES;
        self.titleButton.enabled = YES;
        self.editTitleTextField.enabled = YES;
		[self.activitySpinner stopAnimating];
	}
	else {
		[self.textView resignFirstResponder];
        self.textView.backgroundColor = [UIColor colorWithWhite:0.85 alpha:1.0];
        self.textView.textColor = [UIColor colorWithWhite:0.35 alpha:1.0];
		self.textView.editable = NO;
        self.titleButton.enabled = NO;
        self.editTitleTextField.enabled = NO;
	}
    
    // fork headers
    [self.forkHeaderView removeFromSuperview];
    [self.forkedHeaderView removeFromSuperview];
    [self.forkOfHeaderView removeFromSuperview];
    
    UIView *headerView = nil;
    if (!myGist) {
        if (self.gist.forks.count > 0) {
            headerView = self.forkedHeaderView;
            self.forkedHeaderLabel.text = [NSString stringWithFormat:@"This gist belongs to %@. You have", self.gist.user];
        }
        else {
            headerView = self.forkHeaderView;
            self.forkHeaderLabel.text = [NSString stringWithFormat:@"This is %@'s gist. To edit your own copy,", self.gist.user];
        }
    }
    else if (self.gist.forkOf) {
        NSString *anonymousUsername = [[GEGistService sharedService].anonymousUser objectForKey:@"Username"];
        BOOL wasForkedFromAnonymousMode = [self.gist.forkOf.user isEqual:anonymousUsername] && !self.gist.forkOf.public;
        if (!wasForkedFromAnonymousMode) {
            headerView = self.forkOfHeaderView;
            self.forkOfHeaderLabel.text = [NSString stringWithFormat:@"You forked this gist from %@.", self.gist.forkOf.user];
        }
    }
    
    if (headerView) {
        CGRect frame = headerView.frame;
        frame.origin.y = -frame.size.height;
        frame.size.width = self.textView.frame.size.width;
        headerView.frame = frame;
        [self.textView addSubview:headerView];
        
        self.textView.contentInset = UIEdgeInsetsMake(frame.size.height, 0, 0, 0);
        self.textView.contentOffset = CGPointMake(0, -frame.size.height);
    }
    else {
        self.textView.contentInset = UIEdgeInsetsZero;
        self.textView.contentOffset = CGPointZero;
    }
	
	self.interactionDisabled = NO;
}

- (void)scrollToContent;
{
    [self.textView setContentOffset:CGPointMake(0, 0) animated:YES];
}

- (void)fillDefaultTitle;
{
	// use the first non-blank line as the default title, truncated to 37 characters.
	// would be friendly to break on word boundaries.
	
	if (!self.gist || self.gist.file.filename.length > 0)
		return;
	
    GEFile *file = self.gist.file;
    
	NSCharacterSet *set = [[NSCharacterSet whitespaceAndNewlineCharacterSet] invertedSet];
	NSInteger firstCharacterIndex = [file.content rangeOfCharacterFromSet:set].location;
	if (firstCharacterIndex == NSNotFound)
		return;
	
	NSRange searchRange = NSMakeRange(firstCharacterIndex, file.content.length - firstCharacterIndex);
	NSInteger lineEndIndex = [file.content rangeOfString:@"\n" options:0 range:searchRange].location;
	if (lineEndIndex == NSNotFound) lineEndIndex = file.content.length;
	
	BOOL truncated = NO;
	NSRange titleRange = NSMakeRange(firstCharacterIndex, lineEndIndex - firstCharacterIndex);
	if (titleRange.length > 37) {
		titleRange.length = 37;
		truncated = YES;
	}
	
	NSString *defaultTitle = [file.content substringWithRange:titleRange];
	if (truncated) defaultTitle = [defaultTitle stringByAppendingString:@"..."];
	
	file.filename = defaultTitle;
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
	
	NSString *urlString = [NSString stringWithFormat:@"https://raw.github.com/gist/%@", self.gist.gistID];
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
    GEFile *file = self.gist.file;
    
	NSString *newName = [textField.text stringByReplacingCharactersInRange:range withString:string];
	if (![newName isEqual:file.filename]) {
		[titleButton setTitle:newName forState:UIControlStateNormal];
		file.filename = newName;
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
	self.gist.file.content = textView.text;
	self.gist.dirty = YES;
}

- (void)textViewDidEndEditing:(UITextView *)textView;
{
	if (!self.gist.file.filename)
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

- (IBAction)forkAction:(id)sender;
{
    self.forkButton.enabled = NO;
    [self.forkSpinner startAnimating];
    [[GEGistService sharedService] forkGist:self.gist whenDone:^(GEGist *fork) {
        self.forkButton.enabled = YES;
        [self.forkSpinner stopAnimating];
        self.gist = fork;
    } failBlock:^(NSError *err) {
        UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Fork Error" message:@"Couldn't fork that gist!\nTry again later." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease];
        [alert show];
        self.forkButton.enabled = YES;
        [self.forkSpinner stopAnimating];
    }];
}

- (IBAction)forkedAction:(id)sender;
{
    // should already have the child loaded...
    // TODO: this won't work when we load other people's forks as well
    self.gist = [self.gist.forks anyObject];
}

- (IBAction)forkOfAction:(id)sender;
{
    // should already have the parent loaded...
    self.gist = self.gist.forkOf;
}

@end
