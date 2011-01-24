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


NSString *kDriftNotificationUpdatedGists = @"kDriftNotificationUpdatedGists";
NSString *kDriftNotificationUpdatedGist = @"kDriftNotificationUpdatedGist";
NSString *kDriftNotificationLoginSucceeded = @"kDriftNotificationLoginSucceeded";
NSString *kDriftNotificationLoginFailed = @"kDriftNotificationLoginFailed";


static NSString *kDriftServiceCallLogin = @"kDriftServiceCallLogin";
static NSString *kDriftServiceCallListGists = @"kDriftServiceCallListGists";
static NSString *kDriftServiceCallFetchGist = @"kDriftServiceCallFetchGist";
static NSString *kDriftServiceCallPushGist = @"kDriftServiceCallPushGist";


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

- (BOOL)hasCredentials;
{
	return (!![[NSUserDefaults standardUserDefaults] valueForKey:@"username"]);
}

#pragma mark Service actions

- (void)startRequest:(ASIHTTPRequest *)request;
{
	[request setFailedBlock:^{
		NSLog(@"Request %@ failed: %d", request, request.responseStatusCode);
	}];
	[request start];
}

- (void)loginUserWithUsername:(NSString *)username token:(NSString *)token;
{
	NSString *urlString = [NSString stringWithFormat:@"https://github.com/api/v2/json/user/show/%@?login=%@&token=%@", username, username, token];
	ASIHTTPRequest *req = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:urlString]];
	
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
	
	[req setCompletionBlock:^{
		NSError *err = nil;
		NSDictionary *res = [[CJSONDeserializer deserializer] deserializeAsDictionary:[req responseData] error:&err];
		if (!res) {
			NSLog(@"Error parsing gists: %@", [err localizedDescription]);
		} else {
			for (NSDictionary *gist in [res valueForKey:@"gists"]) {
				[GEGist insertOrUpdateGistWithAttributes:gist];
			}
		}
		[[NSNotificationCenter defaultCenter] postNotificationName:kDriftNotificationUpdatedGists object:self];
	}];
	
	[self startRequest:req];
}

- (void)fetchGist:(GEGist *)gist;
{
	NSString *urlString = [NSString stringWithFormat:@"https://gist.github.com/%@.txt", gist.gistID];
	ASIHTTPRequest *req = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:urlString]];
	
	[req setCompletionBlock:^{
		if (!gist.dirty) {
			// only update undirtied gists
			gist.body = [req responseString];
			NSDictionary *userInfo = [NSDictionary dictionaryWithObject:gist forKey:@"gist"];
			[[NSNotificationCenter defaultCenter] postNotificationName:kDriftNotificationUpdatedGist object:self userInfo:userInfo];
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
							gist.name, [NSString stringWithFormat:@"files[%@]", gist.name],
							username, @"login",
							token, @"token",
							nil];
	}
	
	ASIFormDataRequest *req = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:urlString]];
	for (NSString *key in [postDictionary allKeys]) {
		[req setPostValue:[postDictionary objectForKey:key] forKey:key];
	}
	
	req.shouldContinueWhenAppEntersBackground = YES;
	
	[req setCompletionBlock:^{
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
		[[NSNotificationCenter defaultCenter] postNotificationName:kDriftNotificationUpdatedGist object:self userInfo:userInfo];
	}];
	
	[self startRequest:req];
}

@end
