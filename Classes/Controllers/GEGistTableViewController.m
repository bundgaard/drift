//
//  GEGistTableViewController.m
//  Driftpad
//
//  Created by Devin Chalmers on 4/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "GEGistTableViewController.h"

#import "DriftpadAppDelegate.h"

#import "GEGist.h"
#import "GEFile.h"
#import "GEGistStore.h"
#import "GEGistService.h"
#import "GEGistViewController.h"
#import "GEGistCell.h"

#import "CHumanDateFormatter.h"

@implementation GEGistTableViewController

@synthesize gistViewController;
@synthesize anonymousHeaderView;
@synthesize signedInHeaderView;
@synthesize usernameButton;
@synthesize contextSwitcher;

@synthesize otherUsername;

@synthesize context;

- (void)dealloc;
{
	[gistViewController release], gistViewController = nil;
	[anonymousHeaderView release], anonymousHeaderView = nil;
    [signedInHeaderView release], signedInHeaderView = nil;
    [usernameButton release], usernameButton = nil;
    [contextSwitcher release], contextSwitcher = nil;
    
    [otherUsername release], otherUsername = nil;
	
    [super dealloc];
}

#pragma mark -
#pragma mark Interface actions

- (IBAction)loginAction:(id)sender;
{
	[(DriftpadAppDelegate *)[UIApplication sharedApplication].delegate switchUserAction:sender];
}

- (IBAction)contextAction:(id)sender;
{
    self.context = [sender selectedSegmentIndex];
}

- (void)setContext:(GistTableContext)newContext;
{
    if (context == newContext)
        return;
    
    context = newContext;
    
    [self updateDisplay];
}

- (void)updateDisplay;
{
    if (self.context == kGistTableContextRemote) {
        UISearchBar *searchBar = [[[UISearchBar alloc] initWithFrame:(CGRect){.size = {.width = 320, .height = 44}}] autorelease];
        searchBar.text = self.otherUsername;
        searchBar.delegate = self;
        self.tableView.tableHeaderView = searchBar;
        if (searchBar.text.length < 1) [searchBar becomeFirstResponder];
        
        [[GEGistService sharedService] listGistsForUser:self.otherUsername];
    }
    else {
        self.tableView.tableHeaderView = [GEGistService sharedService].anonymous ? self.anonymousHeaderView : self.signedInHeaderView;
        
        [[GEGistService sharedService] listGistsForCurrentUser];
    }
    
    self.fetchRequest = nil;
    self.fetchedResultsController = nil;
    [self.fetchedResultsController performFetch:nil];
    [self.tableView reloadData];
    
    // TODO: better selection logic
	int selectedIndex = [self.fetchedResultsController.fetchedObjects indexOfObject:gistViewController.gist];
	if (selectedIndex != NSNotFound)
        [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:selectedIndex inSection:0] animated:NO scrollPosition:UITableViewScrollPositionNone];
}

#pragma mark -
#pragma mark View controller

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation;
{
    return YES;
}

- (void)viewDidLoad;
{
	[super viewDidLoad];
	
	self.tableView.layer.backgroundColor = [UIColor colorWithWhite:0.92 alpha:1.0].CGColor;
	self.tableView.separatorColor = [UIColor colorWithWhite:0.85 alpha:1.0];
    
    self.navigationItem.titleView = self.contextSwitcher;
    self.otherUsername = [[NSUserDefaults standardUserDefaults] objectForKey:@"OtherUsername"];
    
    self.contextSwitcher.selectedSegmentIndex = -1;
}

#pragma mark -
#pragma mark Fetched results table view controller

- (NSManagedObjectContext *)managedObjectContext;
{
	return [[GEGistStore sharedStore] managedObjectContext];
}

- (NSFetchRequest *)fetchRequest;
{
	if (!fetchRequest) {
        switch (self.context) {
            case kGistTableContextLocal:
                fetchRequest = [[GEGist fetchRequestForCurrentUserGists] retain];
                break;
            case kGistTableContextRemote:
                fetchRequest = [[GEGist fetchRequestForUserGists:self.otherUsername] retain];
                break;
        }
		
	}
	return fetchRequest;
}

#pragma mark -
#pragma mark Table View Data Source

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;
{
	GEGistCell *cell = (GEGistCell *)[tableView dequeueReusableCellWithIdentifier:@"GistCell"];
	if (!cell) cell = (GEGistCell *)[[[GEGistCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"GistCell"] autorelease];
	
	GEGist *gist = [self.fetchedResultsController objectAtIndexPath:indexPath];
	cell.textLabel.text = gist.file.filename ? gist.file.filename : [NSString stringWithFormat:@"#%@", gist.gistID];
	cell.detailTextLabel.text = [CHumanDateFormatter formatDate:gist.createdAt singleLine:NO];
	
	if (gist.dirty)
		cell.textLabel.font = [UIFont fontWithName:@"Helvetica-BoldOblique" size:19.0];
	else
		cell.textLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:19.0];
	
	return cell;
}

#pragma mark -
#pragma mark Table View Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath;
{
	GEGist *gist = [self.fetchedResultsController objectAtIndexPath:indexPath];
	gistViewController.gist = gist;
	
	DriftpadAppDelegate *delegate = (DriftpadAppDelegate *)[[UIApplication sharedApplication] delegate];
	[delegate hideGistPopover];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath;
{
	return 60.0;
}

#pragma mark - Search bar delegate

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar;
{
    [searchBar resignFirstResponder];
    
    self.otherUsername = searchBar.text;
    [[NSUserDefaults standardUserDefaults] setObject:self.otherUsername forKey:@"OtherUsername"];
    [[GEGistService sharedService] listGistsForUser:self.otherUsername];

    self.fetchRequest = nil;
    self.fetchedResultsController = nil;
    [self.fetchedResultsController performFetch:nil];
    [self.tableView reloadData];
}

#pragma mark -
#pragma mark View lifecycle

- (void)viewWillAppear:(BOOL)animated;
{
	[super viewWillAppear:animated];
    
    [self.usernameButton setTitle:[GEGistService sharedService].username forState:UIControlStateNormal];
    
    GistTableContext ctx = [gistViewController.gist.user isEqual:[GEGistService sharedService].username] ? kGistTableContextLocal : kGistTableContextRemote;
    self.contextSwitcher.selectedSegmentIndex = ctx;
    [self updateDisplay];
}

@end

