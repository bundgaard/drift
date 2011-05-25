//
//  GEFile.m
//  <#ProjectName#>
//
//  Created by Devin Chalmers on 05/25/11
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "GEFile.h"

#import "GEGistStore.h"

#pragma mark begin emogenerator forward declarations
#import "GEGist.h"
#pragma mark end emogenerator forward declarations

@implementation GEFile

+ (id)blankFile;
{
    GEFile *file = [NSEntityDescription insertNewObjectForEntityForName:[self entityName] inManagedObjectContext:[GEGistStore sharedStore].managedObjectContext];
    file.oldFilename = file.filename = file.rawURL = file.content = @"";
    return file;
}

+ (id)fileWithAttributes:(NSDictionary *)attributes;
{
    GEFile *file = [GEFile blankFile];
    [file updateWithAttributes:attributes];
    return file;
}

- (void)updateWithAttributes:(NSDictionary *)attributes;
{
    if ([attributes objectForKey:@"filename"]) self.filename = [attributes objectForKey:@"filename"];
    if ([attributes objectForKey:@"filename"]) self.oldFilename = [attributes objectForKey:@"filename"];
    if ([attributes objectForKey:@"raw_url"]) self.rawURL = [attributes objectForKey:@"raw_url"];
    if ([attributes objectForKey:@"content"]) self.content = [attributes objectForKey:@"content"];
}

#pragma mark begin emogenerator accessors

+ (NSString *)entityName
{
return(@"File");
}

@dynamic content;

@dynamic oldFilename;

@dynamic filename;

@dynamic rawURL;

@dynamic gist;

- (GEGist *)gist
{
[self willAccessValueForKey:@"gist"];
GEGist *theResult = [self primitiveValueForKey:@"gist"];
[self didAccessValueForKey:@"gist"];
return(theResult);
}

- (void)setGist:(GEGist *)inGist
{
[self willChangeValueForKey:@"gist"];
[self setPrimitiveValue:inGist forKey:@"gist"];
[self didChangeValueForKey:@"gist"];
}

#pragma mark end emogenerator accessors

@end
