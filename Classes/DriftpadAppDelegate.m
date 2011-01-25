//
//  DriftpadAppDelegate.m
//  Driftpad
//
//  Created by Devin Chalmers on 4/11/10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import "DriftpadAppDelegate.h"

#import "GEGist.h"
#import "GEGistStore.h"
#import "GELoginViewController.h"
#import "GEGistTableViewController.h"
#import "GEGistViewController.h"

#import "GEGistService.h"


#define CONTEXT_THRESHOLD_MINUTES 30


@interface DriftpadAppDelegate (CoreDataPrivate)
@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;
- (NSString *)applicationDocumentsDirectory;

- (void)recordLastUseDate;
- (BOOL)isContextStale;
@end


@implementation DriftpadAppDelegate

@synthesize window;
@synthesize rootViewController;
@synthesize detailViewController;
@synthesize popoverController;


- (void)dealloc {
	[rootViewController release], detailViewController = nil;
	[detailViewController release], detailViewController = nil;
	[popoverController release], popoverController = nil;

	[window release], window = nil;
	
	[super dealloc];
}

#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [window makeKeyAndVisible];
	detailViewController.view.alpha = 0.0;
	[window addSubview:detailViewController.view];
	
	if ([[GEGistService sharedService] hasCredentials]) {
		[self showApplication];
	}
	else {
		firstLaunch = YES;
		[self beginLogin];
	}
	return YES;
}

- (void)showApplication;
{
	BOOL shouldShowGistList = NO;
	
	// restore last-shown gist
	if (!detailViewController.gist) {
		GEGist *currentGist = [GEGist currentGist];
		
		// if there's no current gist, just show a blank gist
		if (!currentGist) {
			currentGist = [GEGist firstGist]; // should always return a gist
			shouldShowGistList = YES; // this is probably not what the user was expecting, so show the list and let them get reacquainted
		}
		
		detailViewController.gist = currentGist;
	}
	
	shouldShowGistList = shouldShowGistList || [self isContextStale];
	
	// show drift UI
	[UIView beginAnimations:nil context:nil];
	detailViewController.view.alpha = 1.0;
	[UIView commitAnimations];
	
	// fetch current gists
	[[GEGistService sharedService] listGistsForCurrentUser];
	
	if (shouldShowGistList) [self showGistPopoverFromBarButtonItem:self.detailViewController.gistsButton];
}

- (void)applicationWillEnterForeground:(UIApplication *)application;
{
	if ([self isContextStale]) [self showGistPopoverFromBarButtonItem:self.detailViewController.gistsButton];
}

- (void)applicationWillTerminate:(UIApplication *)application;
{
	[self.detailViewController save];
}

- (void)applicationDidEnterBackground:(UIApplication *)application;
{
	[self recordLastUseDate];
	[self.detailViewController save];
}

- (void)applicationWillResignActive:(UIApplication *)application;
{
	[self recordLastUseDate];
	[self.detailViewController save];
}

#pragma mark -
#pragma mark State

- (void)recordLastUseDate;
{
	NSInteger now = [[NSDate date] timeIntervalSinceReferenceDate];
	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:now] forKey:@"lastUseDate"];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)isContextStale;
{
	NSNumber *lastUsage = [[NSUserDefaults standardUserDefaults] objectForKey:@"lastUseDate"];
	if (!lastUsage) return YES;
	
	NSInteger now = [[NSDate date] timeIntervalSinceReferenceDate];
	NSInteger then = [lastUsage integerValue];
	
	return ((now - then) / 60.0 > CONTEXT_THRESHOLD_MINUTES);
}

#pragma mark -
#pragma mark Interface actions

- (void)showGistPopoverFromBarButtonItem:(UIBarButtonItem *)barButtonItem;
{
	if (!popoverController) {
		UINavigationController *nav = [[[UINavigationController alloc] initWithRootViewController:rootViewController] autorelease];
		popoverController = [[UIPopoverController alloc] initWithContentViewController:nav];
	}
	[popoverController presentPopoverFromBarButtonItem:barButtonItem permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
}

- (void)hideGistPopover;
{
	[popoverController dismissPopoverAnimated:YES];
}

- (IBAction)switchUserAction:(id)sender;
{
	[popoverController dismissPopoverAnimated:YES];
	[self beginLogin];
}

#pragma mark -
#pragma mark Login flow

- (void)beginLogin;
{
	GELoginViewController *viewController = [[GELoginViewController alloc] initWithNibName:nil bundle:nil];
	viewController.modalPresentationStyle = UIModalPresentationFormSheet;
	[detailViewController presentModalViewController:viewController animated:YES];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginSucceeded:) name:kDriftNotificationLoginSucceeded object:nil];
}

- (void)loginSucceeded:(NSNotification *)notification;
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:kDriftNotificationLoginSucceeded object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fetchedFirstGists:) name:kDriftNotificationUpdateGistsSucceeded object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fetchFirstGistsFailed:) name:kDriftNotificationUpdateGistsFailed object:nil];
	
	detailViewController.gist = nil;
	[GEGist clearUserGists];
	[[GEGistService sharedService] listGistsForCurrentUser];
}

- (void)fetchedFirstGists:(NSNotification *)notification;
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:kDriftNotificationUpdateGistsSucceeded object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:kDriftNotificationUpdateGistsFailed object:nil];
	
	[detailViewController dismissModalViewControllerAnimated:YES];
	
	if (firstLaunch) {
		detailViewController.gist = [GEGist welcomeGist];
	}
	else {
		detailViewController.gist = [GEGist firstGist];
	}
	[self showApplication];
}

- (void)fetchFirstGistsFailed:(NSNotification *)notification;
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:kDriftNotificationUpdateGistsSucceeded object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:kDriftNotificationUpdateGistsFailed object:nil];
	
	[[GEGistService sharedService] clearCredentials];
}

@end

