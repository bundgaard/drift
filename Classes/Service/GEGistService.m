//
//  GEGistService.m
//  Driftpad
//
//  Created by Devin Chalmers on 4/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "GEGistService.h"

#import "CJSONDeserializer.h"
#import "CJSONSerializer.h"
#import "GEGist.h"
#import "GEFile.h"
#import "GEGistStore.h"
#import "NSManagedObjectContext_Extensions.h"
#import "NSString_Scraping.h"
#import "UIDevice_Extensions.h"

#import "ASIHTTPRequest.h"
#import "ASIFormDataRequest.h"
#import "CKeychain.h"


NSString *kDriftNotificationUpdateGistsSucceeded = @"kDriftNotificationUpdateGistsSucceeded";
NSString *kDriftNotificationUpdateGistsFailed = @"kDriftNotificationUpdateGistsFailed";

NSString *kDriftNotificationUpdateGistSucceeded = @"kDriftNotificationUpdateGistSucceeded";
NSString *kDriftNotificationUpdateGistFailed = @"kDriftNotificationUpdateGistFailed";

NSString *kDriftNotificationLoginSucceeded = @"kDriftNotificationLoginSucceeded";
NSString *kDriftNotificationLoginFailed = @"kDriftNotificationLoginFailed";

#define kFailureNotificationNameKey @"kFailureNotificationNameKey"

@interface GEGistService ()
- (void)startRequest:(ASIHTTPRequest *)request;
@end



@implementation GEGistService

@dynamic anonymous;
@dynamic anonymousUser;

@dynamic username;
@dynamic password;

+ (GEGistService *)sharedService;
{
	static GEGistService *gService;
	if (!gService) {
		gService = [[GEGistService alloc] init];
	}
	return gService;
}

- (void)setAnonymous:(BOOL)isAnonymous;
{
	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:isAnonymous] forKey:@"anonymous"];
}

- (BOOL)anonymous;
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:@"anonymous"];
}

- (NSDictionary *)anonymousUser;
{
	static NSDictionary *sAnonymousUser = nil;
	@synchronized (self) {
		if (!sAnonymousUser)
			sAnonymousUser = [[NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"AnonymousUser" ofType:@"plist"]] retain];
	}
	return sAnonymousUser;
}

- (NSString *)username;
{
	if (self.anonymous) {
		return [self.anonymousUser objectForKey:@"Username"];
	}
	else {
		return [[NSUserDefaults standardUserDefaults] objectForKey:@"username"];
	}
}

- (NSString *)password;
{
	if (self.anonymous) {
		return [self.anonymousUser objectForKey:@"Password"];
	}
	else {
		return [CKeychain passwordForKey:@"password"];
	}
}

- (void)clearCredentials;
{
	// github session cookies can mess up our API calls
	for (NSHTTPCookie *cookie in [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:[NSURL URLWithString:@"https://github.com"]])
		[[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];
	
	for (NSHTTPCookie *cookie in [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:[NSURL URLWithString:@"https://gist.github.com"]])
		[[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];
	
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"username"];
    [CKeychain savePassword:@"" forKey:@"password"];
}

- (BOOL)hasCredentials;
{
	return (!!self.username);
}

#pragma mark Service actions

- (void)startRequest:(ASIHTTPRequest *)request;
{
	[request setFailedBlock:^{
		NSLog(@"FAILED: %@ %@ failed (%d)", [request requestMethod], [request url], request.responseStatusCode);
        NSLog(@"Error: %@", [request.error localizedDescription]);
		if ([request responseString]) NSLog(@"%@", [request responseString]);
		
		NSString *notificationName = [request.userInfo objectForKey:kFailureNotificationNameKey];
		if (notificationName) [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:self];
	}];
	[request start];
}

- (void)loginUserWithUsername:(NSString *)username password:(NSString *)password;
{
    [self clearCredentials];
    
	NSString *urlString = @"https://github.com/account";
	ASIHTTPRequest *req = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:urlString]];
	
    [req addBasicAuthenticationHeaderWithUsername:username andPassword:password];
    
	req.userInfo = [NSDictionary dictionaryWithObject:kDriftNotificationLoginFailed forKey:kFailureNotificationNameKey];
	
	[req setCompletionBlock:^{
        NSRange range = [[req responseString] rangeOfString:@"logged_out"];
        if (range.location != NSNotFound) {
			[[NSNotificationCenter defaultCenter] postNotificationName:kDriftNotificationLoginFailed object:self];
			return;
        }
		self.anonymous = NO;
		[[NSUserDefaults standardUserDefaults] setObject:username forKey:@"username"];
        [CKeychain savePassword:password forKey:@"password"];
		[[NSNotificationCenter defaultCenter] postNotificationName:kDriftNotificationLoginSucceeded object:self];
	}];
	
	[self startRequest:req];
}

- (void)loginAnonymously;
{
	self.anonymous = YES;
	[self clearCredentials];
	[GEGist markCurrentGist:nil];
	[[NSNotificationCenter defaultCenter] postNotificationName:kDriftNotificationLoginSucceeded object:self];
}

- (void)listGistsForCurrentUser;
{
	if (self.anonymous) {
		// don't perform an API call to list the anonymous user's gists—they're all local
		[[NSNotificationCenter defaultCenter] postNotificationName:kDriftNotificationUpdateGistsSucceeded object:self];
		return;
	}
	
	NSString *urlString = [NSString stringWithFormat:@"https://api.github.com/users/%@/gists", self.username];
	ASIHTTPRequest *req = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:urlString]];
	
	req.userInfo = [NSDictionary dictionaryWithObject:kDriftNotificationUpdateGistsFailed forKey:kFailureNotificationNameKey];
	
	[req setCompletionBlock:^{
		NSError *err = nil;
		NSDictionary *res = [[CJSONDeserializer deserializer] deserializeAsDictionary:[req responseData] error:&err];
		if (!res) {
			NSLog(@"Error parsing gists: %@", [err localizedDescription]);
			[[NSNotificationCenter defaultCenter] postNotificationName:kDriftNotificationUpdateGistsFailed object:self];
		} else {
			for (NSDictionary *gist in [res valueForKey:@"gists"]) {
				[GEGist insertOrUpdateGistWithAttributes:gist];
			}
			[[NSNotificationCenter defaultCenter] postNotificationName:kDriftNotificationUpdateGistsSucceeded object:self];
		}
	}];
	
	[self startRequest:req];
}

- (void)fetchGist:(GEGist *)gist;
{
    NSString *urlString = [NSString stringWithFormat:@"https://gist.github.com/raw/%@/%@", gist.gistID, gist.file.filename];
    urlString = [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	ASIHTTPRequest *req = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:urlString]];
	
	req.userInfo = [NSDictionary dictionaryWithObject:kDriftNotificationUpdateGistFailed forKey:kFailureNotificationNameKey];
	
	[req setCompletionBlock:^{
		if (!gist.dirty) {
			// only update undirtied gists
			gist.file.content = [req responseString];
            [[GEGistStore sharedStore] save];
            
			NSDictionary *userInfo = [NSDictionary dictionaryWithObject:gist forKey:@"gist"];
			[[NSNotificationCenter defaultCenter] postNotificationName:kDriftNotificationUpdateGistSucceeded object:self userInfo:userInfo];
		}
	}];
	
	[self startRequest:req];
}

- (void)pushGist:(GEGist *)gist;
{
	if (!gist.dirty)
		return;
	
	if (![gist.user isEqual:self.username])
		return;
	
	NSLog(@"Pushing gist");
	
    NSMutableDictionary *filesDictionary = [NSMutableDictionary dictionary];
    for (GEFile *file in gist.files) {
        NSArray *nameComponents = [file.filename componentsSeparatedByString:@"."];
        if (nameComponents.count > 1) {
            if ([[nameComponents lastObject] isEqual:@""]) {
                file.filename = [NSString stringWithFormat:@"%@md", file.filename];
            }
        }
        else {
            file.filename = [NSString stringWithFormat:@"%@.md", file.filename];
        }
        
        NSDictionary *fileDictionary = [NSDictionary dictionaryWithObjectsAndKeys:gist.file.content, @"content", gist.file.filename, @"filename", nil];
        [filesDictionary setObject:fileDictionary forKey:(file.oldFilename ? file.oldFilename : file.filename)];
    }
    
    NSMutableDictionary *jsonDictionary = [NSMutableDictionary dictionaryWithObject:filesDictionary forKey:@"files"];
    
	NSString *urlString;
    NSString *verb = @"POST";
	
	if (gist.gistID) {
        verb = @"PATCH";
		urlString = [NSString stringWithFormat:@"https://api.github.com/gists/%@", gist.gistID];
	}
	else {
        verb = @"POST";
		urlString = [NSString stringWithFormat:@"https://api.github.com/gists"];
		if (self.anonymous) {
			[jsonDictionary setValue:[NSNumber numberWithBool:NO] forKey:@"public"];
            
            NSString *desc = [NSString stringWithFormat:@"via Drift for iPad - %@", [[UIDevice currentDevice] obfuscatedUniqueIdentifier]];
            [jsonDictionary setValue:desc forKey:@"description"];
		}
	}
    
    NSData *jsonData = [[CJSONSerializer serializer] serializeDictionary:jsonDictionary error:nil];
    NSMutableData *postData = [[jsonData mutableCopy] autorelease];
    
	ASIHTTPRequest *req = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:urlString]];
    [req setRequestMethod:verb];
    [req addBasicAuthenticationHeaderWithUsername:self.username andPassword:self.password];
    [req setPostBody:postData];
	req.shouldContinueWhenAppEntersBackground = YES;
	
	// avoid losing the managed object while the request goes through: crasher
	NSManagedObjectID *objectID = [gist objectID];
	[req setCompletionBlock:^{
		GEGist *gist = (GEGist *)[[GEGistStore sharedStore].managedObjectContext existingObjectWithID:objectID error:nil];
		if (!gist)
			return;
		
		NSError *err = nil;
        NSDictionary *attributes = [[CJSONDeserializer deserializer] deserializeAsDictionary:[req responseData] error:&err];
        [gist updateWithAttributes:attributes];
		gist.dirty = NO;
		
        NSLog(@"Posted %@, got %@", jsonDictionary, attributes);
        
		NSDictionary *userInfo = [NSDictionary dictionaryWithObject:gist forKey:@"gist"];
		[[NSNotificationCenter defaultCenter] postNotificationName:kDriftNotificationUpdateGistSucceeded object:self userInfo:userInfo];
	}];
	
	[self startRequest:req];
}

@end
