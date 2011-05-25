//
//  GEGist.h
//  <#ProjectName#>
//
//  Created by Devin Chalmers on 04/11/10
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <CoreData/CoreData.h>

#pragma mark begin emogenerator forward declarations
@class GEFile;
#pragma mark end emogenerator forward declarations

/** Gist */
@interface GEGist : NSManagedObject {
}

+ (void)clearUserGists;

+ (void)markCurrentGist:(GEGist *)gist;
+ (GEGist *)currentGist;

+ (GEGist *)gistWithID:(NSString *)gistID;

+ (GEGist *)blankGist;
+ (GEGist *)welcomeGist;
+ (GEGist *)firstGist;

+ (NSInteger)count;

+ (void)insertOrUpdateGistWithAttributes:(NSDictionary *)attributes;

+ (NSFetchRequest *)fetchRequestForCurrentUserGists;

- (void)updateWithAttributes:(NSDictionary *)attributes;

@property (nonatomic, readonly) GEFile *file;
@property (nonatomic, readonly) NSDictionary *filesByFilename;

#pragma mark begin emogenerator accessors

+ (NSString *)entityName;

// Attributes
@property (readwrite, retain) NSString *revision;
@property (readwrite, retain) NSString *gistID;
@property (readwrite, retain) NSString *url;
@property (readwrite, retain) NSDate *updatedAt;
@property (readwrite, assign) BOOL dirty;
@property (readwrite, retain) NSNumber *dirtyValue;
@property (readwrite, retain) NSDate *createdAt;
@property (readwrite, retain) NSString *desc;
@property (readwrite, retain) NSString *user;

// Relationships
@property (readonly, retain) NSMutableSet *files;
- (NSMutableSet *)files;

#pragma mark end emogenerator accessors

@end
