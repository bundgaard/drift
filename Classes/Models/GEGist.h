//
//  GEGist.h
//  <#ProjectName#>
//
//  Created by Devin Chalmers on 04/11/10
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <CoreData/CoreData.h>

#pragma mark begin emogenerator forward declarations
#pragma mark end emogenerator forward declarations

/** Gist */
@interface GEGist : NSManagedObject {
}

+ (void)clearUserGists;

+ (void)markCurrentGist:(GEGist *)gist;
+ (GEGist *)currentGist;

+ (GEGist *)blankGist;
+ (GEGist *)welcomeGist;
+ (GEGist *)firstGist;

+ (void)insertOrUpdateGistWithAttributes:(NSDictionary *)attributes;

- (void)updateWithAttributes:(NSDictionary *)attributes;

#pragma mark begin emogenerator accessors

+ (NSString *)entityName;

// Attributes
@property (readwrite, retain) NSString *revision;
@property (readwrite, retain) NSString *gistID;
@property (readwrite, retain) NSString *body;
@property (readwrite, retain) NSString *desc;
@property (readwrite, retain) NSString *user;
@property (readwrite, retain) NSDate *updatedAt;
@property (readwrite, retain) NSDate *createdAt;
@property (readwrite, assign) BOOL dirty;
@property (readwrite, retain) NSNumber *dirtyValue;
@property (readwrite, retain) NSString *name;
@property (readwrite, retain) NSString *url;

// Relationships

#pragma mark end emogenerator accessors

@end
