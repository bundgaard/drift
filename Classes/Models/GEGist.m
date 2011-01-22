//
//  GEGist.m
//  <#ProjectName#>
//
//  Created by Devin Chalmers on 04/11/10
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "GEGist.h"

#import "GEGistStore.h"

#import "NSManagedObjectContext_Extensions.h"
#import "NSObject_FUNSNull.h"
#import "NSDateFormatter_GithubDateFormatting.h"

#pragma mark begin emogenerator forward declarations
#pragma mark end emogenerator forward declarations


@implementation GEGist

+ (void)clearUserGists;
{
	NSManagedObjectContext *ctx = [GEGistStore sharedStore].managedObjectContext;
	NSArray *gists = [ctx fetchObjectsOfEntityForName:[self entityName] predicate:nil error:nil];
	for (GEGist *gist in gists) {
		[ctx deleteObject:gist];
	}
	[[GEGistStore sharedStore] save];
}

+ (GEGist *)blankGist;
{
	GEGist *newGist = [NSEntityDescription insertNewObjectForEntityForName:[GEGist entityName] inManagedObjectContext:[[GEGistStore sharedStore] managedObjectContext]];
	newGist.name = @"New Gist";
	newGist.createdAt = [NSDate date];
	newGist.dirty = YES;
	[[GEGistStore sharedStore] save];
	return newGist;
}

+ (GEGist *)welcomeGist;
{
	GEGist *newGist = [NSEntityDescription insertNewObjectForEntityForName:[GEGist entityName] inManagedObjectContext:[[GEGistStore sharedStore] managedObjectContext]];
	newGist.name = @"welcome.txt";
	newGist.body = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"welcome" ofType:@"txt"] encoding:NSUTF8StringEncoding error:nil];
	newGist.createdAt = [NSDate date];
	newGist.dirty = YES;
	[[GEGistStore sharedStore] save];
	return newGist;
}

+ (GEGist *)firstGist;
{
	NSManagedObjectContext *ctx = [GEGistStore sharedStore].managedObjectContext;
	NSEntityDescription *entity = [NSEntityDescription entityForName:[self entityName] inManagedObjectContext:ctx];
	NSFetchRequest *fetchRequest = [[[NSFetchRequest alloc] init] autorelease];
	fetchRequest.entity = entity;
	fetchRequest.predicate = nil;
	NSSortDescriptor *desc = [[[NSSortDescriptor alloc] initWithKey:@"createdAt" ascending:NO] autorelease];
	fetchRequest.sortDescriptors = [NSArray arrayWithObject:desc];
	fetchRequest.fetchLimit = 1;
	NSArray *gists = [ctx executeFetchRequest:fetchRequest error:nil];
	
	GEGist *firstGist;
	if (gists.count > 0) {
		firstGist = [gists objectAtIndex:0];
	}
	else {
		firstGist = [self blankGist];
	}
	
	return firstGist;
}

+ (void)insertOrUpdateGistWithAttributes:(NSDictionary *)attributes;
{
	NSNumber *gistID = [attributes valueForKey:@"repo"];
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"gistID = %@", gistID];
	NSManagedObjectContext *ctx = [[GEGistStore sharedStore] managedObjectContext];
	NSError *err = nil;
	GEGist *gist = [ctx fetchObjectOfEntityForName:@"Gist" predicate:predicate error:&err];
	if (!gist) {
		gist = [NSEntityDescription insertNewObjectForEntityForName:@"Gist" inManagedObjectContext:ctx];
		gist.user = [[NSUserDefaults standardUserDefaults] valueForKey:@"username"];
	}
	
	[gist updateWithAttributes:attributes];
	
	[[GEGistStore sharedStore] save];
}

- (void)updateWithAttributes:(NSDictionary *)attributes;
{
	self.gistID = [attributes valueForKey:@"repo"];
	self.desc = [[attributes valueForKey:@"description"] objectOrNil];
	self.createdAt = [[NSDateFormatter githubDateFormatter] dateFromString:[attributes valueForKey:@"created_at"]];
	self.name = [[attributes valueForKey:@"files"] componentsJoinedByString:@", "];
}

#pragma mark begin emogenerator accessors

+ (NSString *)entityName
{
return(@"Gist");
}

@dynamic revision;

@dynamic gistID;

@dynamic body;

@dynamic desc;

@dynamic user;

@dynamic updatedAt;

@dynamic createdAt;

@dynamic dirty;
- (BOOL)dirty
{
return([[self dirtyValue] boolValue]);
}

- (void)setDirty:(BOOL)inDirty
{
[self setDirtyValue:[NSNumber numberWithBool:inDirty]];
}

@dynamic dirtyValue;

- (NSNumber *)dirtyValue
{
[self willAccessValueForKey:@"dirty"];
NSNumber *theResult = [self primitiveValueForKey:@"dirty"];
[self didAccessValueForKey:@"dirty"];
return(theResult);
}

- (void)setDirtyValue:(NSNumber *)inDirty
{
[self willChangeValueForKey:@"dirty"];
[self setPrimitiveValue:inDirty forKey:@"dirty"];
[self didChangeValueForKey:@"dirty"];
}

@dynamic name;

@dynamic url;

#pragma mark end emogenerator accessors

@end
