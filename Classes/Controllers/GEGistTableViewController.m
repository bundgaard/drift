//
//  GEGistTableViewController.m
//  Driftpad
//
//  Created by Devin Chalmers on 4/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "GEGistTableViewController.h"

#import "GEGist.h"
#import "GEGistStore.h"
#import "GEGistViewController.h"

#import "CHumanDateFormatter.h"

@implementation GEGistTableViewController

@synthesize gistViewController;

- (void)dealloc;
{
	[gistViewController release], gistViewController = nil;
	
    [super dealloc];
}

#pragma mark -
#pragma mark View controller

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation;
{
    return YES;
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
		fetchRequest = [[NSFetchRequest alloc] init];
		
		NSEntityDescription *entity = [NSEntityDescription entityForName:@"Gist" inManagedObjectContext:[self managedObjectContext]];
		[fetchRequest setEntity:entity];
		[fetchRequest setFetchBatchSize:20];
		
		NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"createdAt" ascending:NO];
		[fetchRequest setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
	}
	return fetchRequest;
}

#pragma mark -
#pragma mark Table View Data Source

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;
{
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"GistCell"];
	if (!cell) cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"GistCell"] autorelease];
	
	GEGist *gist = [self.fetchedResultsController objectAtIndexPath:indexPath];
	cell.textLabel.text = gist.name ? gist.name : [NSString stringWithFormat:@"#%@", gist.gistID];
	cell.detailTextLabel.text = [CHumanDateFormatter formatDate:gist.createdAt singleLine:NO];
	NSLog(@"%@", [CHumanDateFormatter formatDate:gist.createdAt singleLine:NO]);
	
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
}

#pragma mark -
#pragma mark View lifecycle

- (void)viewWillAppear:(BOOL)animated;
{
	[super viewWillAppear:animated];
	
	// TODO: better selection logic
	int selectedIndex = [self.fetchedResultsController.fetchedObjects indexOfObject:gistViewController.gist];
	if (selectedIndex == NSNotFound)
		selectedIndex = 0;
	[self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:selectedIndex inSection:0] animated:NO scrollPosition:UITableViewScrollPositionNone];
}

@end

