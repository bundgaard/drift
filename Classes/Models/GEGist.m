//
//  GEGist.m
//  <#ProjectName#>
//
//  Created by Devin Chalmers on 04/11/10
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "GEGist.h"

#import "GEFile.h"

#import "GEGistStore.h"
#import "GEGistService.h"

#import "NSManagedObjectContext_Extensions.h"
#import "NSObject_FUNSNull.h"
#import "NSDate_InternetDateExtensions.h"

#pragma mark begin emogenerator forward declarations
#import "GEFile.h"
#pragma mark end emogenerator forward declarations


@implementation GEGist

@dynamic file;

- (GEFile *)file;
{
    NSArray *sortedFiles = [[self.files allObjects] sortedArrayUsingComparator:^NSComparisonResult(GEFile *obj1, GEFile *obj2) {
        return [obj1.filename caseInsensitiveCompare:obj2.filename];
    }];
    
    if (sortedFiles.count < 1) {
        GEFile *file = [NSEntityDescription insertNewObjectForEntityForName:[GEFile entityName] inManagedObjectContext:[GEGistStore sharedStore].managedObjectContext];
        [self.files addObject:file];
        [[GEGistStore sharedStore] save];
        
        return file;
    }
    
    return [sortedFiles objectAtIndex:0];
}

- (NSDictionary *)filesByFilename;
{
    NSArray *sortedFiles = [[self.files allObjects] sortedArrayUsingComparator:^NSComparisonResult(GEFile *obj1, GEFile *obj2) {
        return [obj1.filename caseInsensitiveCompare:obj2.filename];
    }];
    
    NSMutableDictionary *filesByFilename = [NSMutableDictionary dictionary];
    for (GEFile *file in sortedFiles)
        [filesByFilename setObject:file forKey:file.filename];
    
    return filesByFilename;
}

+ (void)clearUserGists;
{
	NSManagedObjectContext *ctx = [GEGistStore sharedStore].managedObjectContext;
	NSArray *gists = [ctx fetchObjectsOfEntityForName:[self entityName] predicate:nil error:nil];
	for (GEGist *gist in gists) {
		[ctx deleteObject:gist];
	}
	[self markCurrentGist:nil];
	[[GEGistStore sharedStore] save];
}

+ (void)markCurrentGist:(GEGist *)gist;
{
	if (gist) {
		NSURL *currentGistURL = [[gist objectID] URIRepresentation];
		[[NSUserDefaults standardUserDefaults] setObject:[currentGistURL absoluteString] forKey:@"currentGistURL"];
	}
	else {
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"currentGistURL"];
	}
	[[NSUserDefaults standardUserDefaults] synchronize];
}

+ (GEGist *)currentGist;
{
	GEGist *currentGist = nil;
	NSString *currentGistURLString = [[NSUserDefaults standardUserDefaults] objectForKey:@"currentGistURL"];
	NSError *err = nil;
	
	// try to fetch last-shown gist
	if (currentGistURLString) {
		NSURL *currentGistURL = [NSURL URLWithString:currentGistURLString];
		NSManagedObjectID *objectID = [[GEGistStore sharedStore].persistentStoreCoordinator managedObjectIDForURIRepresentation:currentGistURL];
		currentGist = (GEGist *)[[GEGistStore sharedStore].managedObjectContext existingObjectWithID:objectID error:&err];
	}
	
	return currentGist;
}

+ (GEGist *)gistWithID:(NSString *)gistID;
{
	NSManagedObjectContext *ctx = [GEGistStore sharedStore].managedObjectContext;
	GEGist *gist = [ctx fetchObjectOfEntityForName:[self entityName] predicate:[NSPredicate predicateWithFormat:@"gistID == %@", gistID] error:nil];
	return gist;
}

+ (GEGist *)blankGist;
{
	GEGist *newGist = [NSEntityDescription insertNewObjectForEntityForName:[GEGist entityName] inManagedObjectContext:[[GEGistStore sharedStore] managedObjectContext]];
	newGist.createdAt = [NSDate date];
	newGist.dirty = YES;
	newGist.user = [GEGistService sharedService].username;
    
    GEFile *newFile = [NSEntityDescription insertNewObjectForEntityForName:[GEFile entityName] inManagedObjectContext:[GEGistStore sharedStore].managedObjectContext];
    newFile.filename = @"";
    newFile.content = @"";
    [newGist.files addObject:newFile];
    
	[[GEGistStore sharedStore] save];
    
	return newGist;
}

+ (GEGist *)welcomeGist;
{
    GEGist *newGist = [self blankGist];
    
    newGist.file.filename = newGist.file.oldFilename = @"welcome.md";
    newGist.file.content = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"welcome" ofType:@"md"] encoding:NSUTF8StringEncoding error:nil];
    
	[[GEGistStore sharedStore] save];
    
	return newGist;
}

+ (GEGist *)firstGist;
{
	NSManagedObjectContext *ctx = [GEGistStore sharedStore].managedObjectContext;
	NSEntityDescription *entity = [NSEntityDescription entityForName:[self entityName] inManagedObjectContext:ctx];
	NSFetchRequest *fetchRequest = [[[NSFetchRequest alloc] init] autorelease];
	fetchRequest.entity = entity;
	fetchRequest.predicate = [NSPredicate predicateWithFormat:@"user == %@", [GEGistService sharedService].username];
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

+ (NSInteger)count;
{
	NSManagedObjectContext *ctx = [GEGistStore sharedStore].managedObjectContext;
	return [ctx countOfObjectsOfEntityForName:[self entityName] predicate:[NSPredicate predicateWithFormat:@"user == %@", [GEGistService sharedService].username] error:nil];
}

+ (void)insertOrUpdateGistWithAttributes:(NSDictionary *)attributes;
{
	NSString *gistID = [attributes valueForKey:@"id"];
	
	NSManagedObjectContext *ctx = [GEGistStore sharedStore].managedObjectContext;
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"gistID = %@", gistID];
	
	GEGist *gist = [ctx fetchObjectOfEntityForName:[self entityName] predicate:predicate createIfNotFound:YES wasCreated:nil error:nil];
	[gist updateWithAttributes:attributes];
	
	[[GEGistStore sharedStore] save];
}

+ (NSFetchRequest *)fetchRequestForCurrentUserGists;
{
    return [self fetchRequestForUserGists:[GEGistService sharedService].username];
}

+ (NSFetchRequest *)fetchRequestForUserGists:(NSString *)username;
{
	NSManagedObjectContext *ctx = [GEGistStore sharedStore].managedObjectContext;
	
	NSFetchRequest *fetchRequest = [[[NSFetchRequest alloc] init] autorelease];
	
	NSEntityDescription *entity = [NSEntityDescription entityForName:[self entityName] inManagedObjectContext:ctx];
	[fetchRequest setEntity:entity];
	[fetchRequest setFetchBatchSize:20];
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"user == %@", username];
	[fetchRequest setPredicate:predicate];
	
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"createdAt" ascending:NO];
	[fetchRequest setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
	
	return fetchRequest;
}

- (void)updateWithAttributes:(NSDictionary *)attributes;
{
	self.gistID = [attributes valueForKey:@"id"];
	self.desc = [[attributes valueForKey:@"description"] objectOrNil];
	self.createdAt = [NSDate dateWithISO8601String:[attributes valueForKey:@"created_at"]];
    
    NSMutableDictionary *files = [NSMutableDictionary dictionaryWithDictionary:self.filesByFilename];
    [self.files removeAllObjects];
    for (NSString *filename in [[attributes valueForKey:@"files"] allKeys]) {
        GEFile *file = [files objectForKey:filename];
        if (!file) file = [GEFile blankFile];
        [file updateWithAttributes:[[attributes valueForKey:@"files"] valueForKey:filename]];
        [self.files addObject:file];
    }
    
    NSString *owner = [attributes valueForKeyPath:@"user.login"];
    if (owner) self.user = owner;
}

#pragma mark begin emogenerator accessors

+ (NSString *)entityName
{
return(@"Gist");
}

@dynamic revision;

@dynamic gistID;

@dynamic files;

- (NSMutableSet *)files
{
return([self mutableSetValueForKey:@"files"]);
}

@dynamic url;

@dynamic updatedAt;

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

@dynamic createdAt;

@dynamic desc;

@dynamic user;

#pragma mark end emogenerator accessors

@end
