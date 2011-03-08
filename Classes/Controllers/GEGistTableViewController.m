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
#import "GEGistStore.h"
#import "GEGistService.h"
#import "GEGistViewController.h"
#import "GEGistCell.h"

#import "CHumanDateFormatter.h"

@implementation GEGistTableViewController

@synthesize gistViewController;
@synthesize anonymousHeaderView;

- (void)dealloc;
{
	[gistViewController release], gistViewController = nil;
	[anonymousHeaderView release], anonymousHeaderView = nil;
	
    [super dealloc];
}

#pragma mark -
#pragma mark Interface actions

- (IBAction)loginAction:(id)sender;
{
	[(DriftpadAppDelegate *)[UIApplication sharedApplication].delegate switchUserAction:sender];
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
		fetchRequest = [[GEGist fetchRequestForCurrentUserGists] retain];
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
	cell.textLabel.text = gist.name ? gist.name : [NSString stringWithFormat:@"#%@", gist.gistID];
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

#pragma mark -
#pragma mark View lifecycle

- (void)viewWillAppear:(BOOL)animated;
{
	[super viewWillAppear:animated];
	
	self.navigationItem.title = [GEGistService sharedService].anonymous ? @"(anonymous)" : [GEGistService sharedService].username;
	self.tableView.tableHeaderView = [GEGistService sharedService].anonymous ? self.anonymousHeaderView : nil;
	
	// TODO: better selection logic
	int selectedIndex = [self.fetchedResultsController.fetchedObjects indexOfObject:gistViewController.gist];
	if (selectedIndex == NSNotFound)
		selectedIndex = 0;
	[self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:selectedIndex inSection:0] animated:NO scrollPosition:UITableViewScrollPositionNone];
}

@end

