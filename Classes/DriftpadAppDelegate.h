//
//  DriftpadAppDelegate.h
//  Driftpad
//
//  Created by Devin Chalmers on 4/11/10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>


@class GEGistTableViewController;
@class GEGistViewController;

@interface DriftpadAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
	
	UIPopoverController *popoverController;
	
	GEGistTableViewController *rootViewController;
	GEGistViewController *detailViewController;
	
	BOOL firstLaunch;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;

@property (nonatomic, retain) IBOutlet GEGistTableViewController *rootViewController;
@property (nonatomic, retain) IBOutlet GEGistViewController *detailViewController;

@property (nonatomic, retain) UIPopoverController *popoverController;

- (void)showGistPopoverFromBarButtonItem:(UIBarButtonItem *)barButtonItem;
- (void)showApplication;

- (IBAction)switchUserAction:(id)sender;

- (void)beginLogin;

@end
