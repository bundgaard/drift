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
#import "NSString_Scraping.h"

#import "ASIHTTPRequest.h"
#import "ASIFormDataRequest.h"


NSString *kDriftNotificationUpdateGistsSucceeded = @"kDriftNotificationUpdateGistsSucceeded";
NSString *kDriftNotificationUpdateGistsFailed = @"kDriftNotificationUpdateGistsFailed";

NSString *kDriftNotificationUpdateGistSucceeded = @"kDriftNotificationUpdateGistSucceeded";
NSString *kDriftNotificationUpdateGistFailed = @"kDriftNotificationUpdateGistFailed";

NSString *kDriftNotificationGetAPIKeySucceeded = @"kDriftNotificationGetAPIKeySucceeded";
NSString *kDriftNotificationGetAPIKeyFailed = @"kDriftNotificationGetAPIKeyFailed";

NSString *kDriftNotificationLoginSucceeded = @"kDriftNotificationLoginSucceeded";
NSString *kDriftNotificationLoginFailed = @"kDriftNotificationLoginFailed";

#define kFailureNotificationNameKey @"kFailureNotificationNameKey"

@interface GEGistService ()
- (void)startRequest:(ASIHTTPRequest *)request;
@property (readonly) NSDictionary *anonymousUser;
@end



@implementation GEGistService

@dynamic anonymous;
@dynamic anonymousUser;

@dynamic username;
@dynamic apiKey;

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

- (NSString *)apiKey;
{
	if (self.anonymous) {
		return [self.anonymousUser objectForKey:@"APIKey"];
	}
	else {
		return [[NSUserDefaults standardUserDefaults] objectForKey:@"token"];
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
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"token"];
}

- (BOOL)hasCredentials;
{
	return (!!self.username);
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
		self.anonymous = NO;
		[[NSUserDefaults standardUserDefaults] setObject:username forKey:@"username"];
		[[NSUserDefaults standardUserDefaults] setObject:token forKey:@"token"];
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

- (void)obtainAPIKeyFromUsername:(NSString *)username password:(NSString *)password;
{
	// TODO: this will leak (retain cycle)
	// actually, all the service requests will leak.
	
	ASIHTTPRequest		*fetchLoginPageRequest;
	ASIFormDataRequest	*loginRequest;
	ASIHTTPRequest		*fetchAPIKeyRequest;
	
	void (^failBlock)(void) = ^{
		[[NSNotificationCenter defaultCenter] postNotificationName:kDriftNotificationGetAPIKeyFailed object:nil];
	};
	
	fetchLoginPageRequest = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"https://github.com/login"]];
	loginRequest = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:@"https://github.com/session"]];
	fetchAPIKeyRequest = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"https://github.com/account"]];
	
	[fetchLoginPageRequest setFailedBlock:failBlock];
	[loginRequest setFailedBlock:failBlock];
	[fetchAPIKeyRequest setFailedBlock:failBlock];
	
	[fetchLoginPageRequest setCompletionBlock:^{
		NSString *authToken = [[fetchLoginPageRequest responseString] scrapeStringAnchoredBy:@"window._auth_token = " offset:1 length:40];
		NSLog(@"Form authenticity token: %@", authToken);
		[loginRequest addPostValue:authToken forKey:@"authenticity_token"];
		[loginRequest start];
	}];
	
	[loginRequest addPostValue:username forKey:@"login"];
	[loginRequest addPostValue:password forKey:@"password"];
	[loginRequest setCompletionBlock:^{
		[fetchAPIKeyRequest start];
	}];
	
	[fetchAPIKeyRequest setCompletionBlock:^{
		NSString *apiToken = [[fetchAPIKeyRequest responseString] scrapeStringAnchoredBy:@"Your API token is <code>" offset:0 length:32];
		if (!apiToken) {
			[self clearCredentials];
			[[NSNotificationCenter defaultCenter] postNotificationName:kDriftNotificationGetAPIKeyFailed object:nil];
			return;
		}
		NSLog(@"API token: %@", apiToken);
		NSDictionary *userInfo = [NSDictionary dictionaryWithObject:apiToken forKey:@"APIToken"];
		[[NSNotificationCenter defaultCenter] postNotificationName:kDriftNotificationGetAPIKeySucceeded object:nil userInfo:userInfo];
	}];
	
	[fetchLoginPageRequest start];
}

- (void)listGistsForCurrentUser;
{
	if (self.anonymous) {
		// don't perform an API call to list the anonymous user's gists—they're all local
		[[NSNotificationCenter defaultCenter] postNotificationName:kDriftNotificationUpdateGistsSucceeded object:self];
		return;
	}
	
	NSString *urlString = [NSString stringWithFormat:@"https://gist.github.com/api/v1/json/gists/%@", self.username];
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
	
	if (![gist.user isEqual:self.username])
		return;
	
	NSLog(@"Pushing gist");
	
	NSString *urlString;
	NSMutableDictionary *postDictionary;
	
	if (gist.gistID) {
		// gist already exists: update with a faked form post
		urlString = [NSString stringWithFormat:@"https://gist.github.com/gists/%@", gist.gistID];
		
		NSString *extension = @"";
		NSArray *nameComponents = [gist.name componentsSeparatedByString:@"."];
		if (nameComponents.count > 1) {
			extension = [nameComponents lastObject];
		}
		else {
			gist.name = [NSString stringWithFormat:@"%@.md", gist.name];
			extension = @".md";
		}
		
		postDictionary = [NSMutableDictionary dictionaryWithObjectsAndKeys:
							@"put", @"_method",
							gist.body, [NSString stringWithFormat:@"file_contents[%@]", gist.name],
							extension, [NSString stringWithFormat:@"file_ext[%@]", gist.name],
							gist.name, [NSString stringWithFormat:@"file_name[%@]", gist.name],
							self.username, @"login",
							self.apiKey, @"token",
							nil];
	}
	else {
		// new gist: use the API
		urlString = @"https://gist.github.com/api/v1/json/new";
		postDictionary = [NSMutableDictionary dictionaryWithObjectsAndKeys:
							gist.body, [NSString stringWithFormat:@"files[%@]", gist.name],
							self.username, @"login",
							self.apiKey, @"token",
							nil];
		
		if (self.anonymous) {
			[postDictionary setValue:[NSNumber numberWithBool:YES] forKey:@"private"];
		}
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
