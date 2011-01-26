//
//  GEGistService.m
//  Driftpad
//
//  Created by Devin Chalmers on 4/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "GEGistService.h"

#import "CJSONDeserializer.h"
#import "GEGist.h"
#import "GEGistStore.h"
#import "NSManagedObjectContext_Extensions.h"

#import "ASIHTTPRequest.h"
#import "ASIFormDataRequest.h"


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

+ (GEGistService *)sharedService;
{
	static GEGistService *gService;
	if (!gService) {
		gService = [[GEGistService alloc] init];
	}
	return gService;
}

- (void)clearCredentials;
{
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"username"];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"token"];
}

- (BOOL)hasCredentials;
{
	return (!![[NSUserDefaults standardUserDefaults] valueForKey:@"username"]);
}

#pragma mark Service actions

- (void)startRequest:(ASIHTTPRequest *)request;
{
	[request setFailedBlock:^{
		NSLog(@"FAILED: %@ %@ failed", [request requestMethod], [request url]);
		if ([request responseString]) NSLog(@"%d: %@", request.responseStatusCode, [request responseString]);
		
		NSString *notificationName = [request.userInfo objectForKey:kFailureNotificationNameKey];
		if (notificationName) [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:self];
	}];
	[request start];
}

- (void)loginUserWithUsername:(NSString *)username token:(NSString *)token;
{
	NSString *urlString = [NSString stringWithFormat:@"https://github.com/api/v2/json/user/show/%@?login=%@&token=%@", username, username, token];
	ASIHTTPRequest *req = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:urlString]];
	
	req.userInfo = [NSDictionary dictionaryWithObject:kDriftNotificationLoginFailed forKey:kFailureNotificationNameKey];
	
	[req setCompletionBlock:^{
		id res = [[CJSONDeserializer deserializer] deserialize:[req responseData] error:nil];
		if (!res) {
			[[NSNotificationCenter defaultCenter] postNotificationName:kDriftNotificationLoginFailed object:self];
			return;
		}
		[[NSUserDefaults standardUserDefaults] setObject:username forKey:@"username"];
		[[NSUserDefaults standardUserDefaults] setObject:token forKey:@"token"];
		[[NSNotificationCenter defaultCenter] postNotificationName:kDriftNotificationLoginSucceeded object:self];
	}];
	
	[self startRequest:req];
}

- (void)listGistsForCurrentUser;
{
	NSString *username = [[NSUserDefaults standardUserDefaults] objectForKey:@"username"];
	NSString *urlString = [NSString stringWithFormat:@"https://gist.github.com/api/v1/json/gists/%@", username];
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
	NSString *urlString = [NSString stringWithFormat:@"https://gist.github.com/%@.txt", gist.gistID];
	ASIHTTPRequest *req = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:urlString]];
	
	req.userInfo = [NSDictionary dictionaryWithObject:kDriftNotificationUpdateGistFailed forKey:kFailureNotificationNameKey];
	
	[req setCompletionBlock:^{
		if (!gist.dirty) {
			// only update undirtied gists
			gist.body = [req responseString];
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
	
	NSLog(@"Pushing gist");
	
	NSString *username = [[NSUserDefaults standardUserDefaults] valueForKey:@"username"];
	NSString *token = [[NSUserDefaults standardUserDefaults] valueForKey:@"token"];
	NSString *urlString;
	NSDictionary *postDictionary;
	
	if (gist.gistID) {
		// gist already exists: update with a faked form post
		urlString = [NSString stringWithFormat:@"https://gist.github.com/gists/%@", gist.gistID];
		
		NSString *extension = @"";
		NSArray *nameComponents = [gist.name componentsSeparatedByString:@"."];
		if (nameComponents.count > 1) extension = [nameComponents lastObject];
		
		postDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
							@"put", @"_method",
							gist.body, [NSString stringWithFormat:@"file_contents[%@]", gist.name],
							extension, [NSString stringWithFormat:@"file_ext[%@]", gist.name],
							gist.name, [NSString stringWithFormat:@"file_name[%@]", gist.name],
							username, @"login",
							token, @"token",
							nil];
	}
	else {
		// new gist: use the API
		urlString = @"https://gist.github.com/api/v1/json/new";
		postDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
							gist.body, [NSString stringWithFormat:@"files[%@]", gist.name],
							username, @"login",
							token, @"token",
							nil];
	}
	
	ASIFormDataRequest *req = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:urlString]];
	for (NSString *key in [postDictionary allKeys]) {
		[req setPostValue:[postDictionary objectForKey:key] forKey:key];
	}
	
	req.shouldContinueWhenAppEntersBackground = YES;
	
	// avoid losing the managed object while the request goes through: crasher
	NSManagedObjectID *objectID = [gist objectID];
	[req setCompletionBlock:^{
		GEGist *gist = (GEGist *)[[GEGistStore sharedStore].managedObjectContext existingObjectWithID:objectID error:nil];
		if (!gist)
			return;
		
		NSError *err = nil;
		NSArray *gists = [[[CJSONDeserializer deserializer] deserializeAsDictionary:[req responseData] error:&err] objectForKey:@"gists"];
		if (gists && [gists count] > 0) {
			NSDictionary *attributes = [gists objectAtIndex:0];
			[gist updateWithAttributes:attributes];
		}
		else {
			// JSON parse failure is okay: for updates we get a web page back, because there is no API yet.
		}
		gist.dirty = NO;
		
		NSDictionary *userInfo = [NSDictionary dictionaryWithObject:gist forKey:@"gist"];
		[[NSNotificationCenter defaultCenter] postNotificationName:kDriftNotificationUpdateGistSucceeded object:self userInfo:userInfo];
	}];
	
	[self startRequest:req];
}

@end
