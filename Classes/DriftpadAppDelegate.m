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

@interface DriftpadAppDelegate (CoreDataPrivate)
@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;
- (NSString *)applicationDocumentsDirectory;
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
	// restore last-shown gist
	NSString *currentGistURLString = [[NSUserDefaults standardUserDefaults] objectForKey:@"currentGistURL"];
	if (!detailViewController.gist && currentGistURLString) {
		NSURL *currentGistURL = [NSURL URLWithString:currentGistURLString];
		NSManagedObjectID *objectID = [[GEGistStore sharedStore].persistentStoreCoordinator managedObjectIDForURIRepresentation:currentGistURL];
		NSError *err = nil;
		GEGist *currentGist = (GEGist *)[[GEGistStore sharedStore].managedObjectContext existingObjectWithID:objectID error:&err];
		if (!currentGist) {
			NSLog(@"Error restoring current gist: %@", [err localizedDescription]);
		} else {
			detailViewController.gist = currentGist;
		}
	}
	
	// show drift UI
	[UIView beginAnimations:nil context:nil];
	detailViewController.view.alpha = 1.0;
	[UIView commitAnimations];
	
	// fetch current gists
	[[GEGistService sharedService] listGistsForCurrentUser];
}

- (void)applicationWillTerminate:(UIApplication *)application;
{
	// save current gist
	[[GEGistStore sharedStore] save];
	GEGist *currentGist = detailViewController.gist;
	NSURL *currentGistURL = [[currentGist objectID] URIRepresentation];
	[[NSUserDefaults standardUserDefaults] setObject:[currentGistURL absoluteString] forKey:@"currentGistURL"];
}

- (void)applicationDidEnterBackground:(UIApplication *)application;
{
	// save state
	[[GEGistStore sharedStore] save];
	GEGist *currentGist = detailViewController.gist;
	NSURL *currentGistURL = [[currentGist objectID] URIRepresentation];
	[[NSUserDefaults standardUserDefaults] setObject:[currentGistURL absoluteString] forKey:@"currentGistURL"];
	
	// push current gist
	[[GEGistService sharedService] pushGist:currentGist];
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
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fetchedFirstGists:) name:kDriftNotificationUpdatedGists object:nil];
	[GEGist clearUserGists];
	[[GEGistService sharedService] listGistsForCurrentUser];
}

- (void)fetchedFirstGists:(NSNotification *)notification;
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:kDriftNotificationUpdatedGists object:nil];
	[detailViewController dismissModalViewControllerAnimated:YES];
	
	if (firstLaunch) {
		detailViewController.gist = [GEGist welcomeGist];
	}
	else {
		detailViewController.gist = [GEGist firstGist];
	}
	[self showApplication];
}

@end

