//
//  GEGistTableViewController.h
//  Driftpad
//
//  Created by Devin Chalmers on 4/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "CFetchedResultsTableViewController.h"

@class GEGistViewController, GEGist;

@interface GEGistTableViewController : CFetchedResultsTableViewController {
	IBOutlet GEGistViewController *gistViewController;
}

@property (nonatomic, retain) IBOutlet GEGistViewController *gistViewController;
@property (nonatomic, retain) IBOutlet UIView *anonymousHeaderView;

- (IBAction)loginAction:(id)sender;

@end
