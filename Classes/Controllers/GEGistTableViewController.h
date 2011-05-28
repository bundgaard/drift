//
//  GEGistTableViewController.h
//  Driftpad
//
//  Created by Devin Chalmers on 4/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "CFetchedResultsTableViewController.h"

typedef enum _GistTableContext {
    kGistTableContextLocal,
    kGistTableContextRemote
} GistTableContext;

@class GEGistViewController, GEGist;

@interface GEGistTableViewController : CFetchedResultsTableViewController <UISearchBarDelegate> {
	IBOutlet GEGistViewController *gistViewController;
}

@property (nonatomic, retain) IBOutlet GEGistViewController *gistViewController;
@property (nonatomic, retain) IBOutlet UIView *anonymousHeaderView;
@property (nonatomic, retain) IBOutlet UIView *signedInHeaderView;
@property (nonatomic, retain) IBOutlet UIButton *usernameButton;
@property (nonatomic, retain) IBOutlet UISegmentedControl *contextSwitcher;

@property (nonatomic, retain) NSString *otherUsername;

@property (nonatomic, assign) GistTableContext context;

- (void)updateDisplay;

- (IBAction)loginAction:(id)sender;
- (IBAction)contextAction:(id)sender;

@end
