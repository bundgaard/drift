//
//  GEFile.h
//  <#ProjectName#>
//
//  Created by Devin Chalmers on 05/25/11
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <CoreData/CoreData.h>

#pragma mark begin emogenerator forward declarations
@class GEGist;
#pragma mark end emogenerator forward declarations

/** File */
@interface GEFile : NSManagedObject {
}

+ (id)fileWithAttributes:(NSDictionary *)attributes;
- (void)updateWithAttributes:(NSDictionary *)attributes;

#pragma mark begin emogenerator accessors

+ (NSString *)entityName;

// Attributes
@property (readwrite, retain) NSString *content;
@property (readwrite, retain) NSString *oldFilename;
@property (readwrite, retain) NSString *filename;
@property (readwrite, retain) NSString *rawURL;

// Relationships
@property (readwrite, retain) GEGist *gist;
- (GEGist *)gist;
- (void)setGist:(GEGist *)inGist;

#pragma mark end emogenerator accessors

@end
