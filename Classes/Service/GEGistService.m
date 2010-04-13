//
//  GEGistService.m
//  Driftpad
//
//  Created by Devin Chalmers on 4/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "GEGistService.h"

#import "CJSONDeserializer.h"
#import "CManagedURLConnection.h"
#import "GEGist.h"
#import "GEGistStore.h"
#import "NSManagedObjectContext_Extensions.h"


NSString *kDriftNotificationUpdatedGists = @"kDriftNotificationUpdatedGists";
NSString *kDriftNotificationUpdatedGist = @"kDriftNotificationUpdatedGist";
NSString *kDriftNotificationLoginSucceeded = @"kDriftNotificationLoginSucceeded";
NSString *kDriftNotificationLoginFailed = @"kDriftNotificationLoginFailed";


static NSString *kDriftServiceCallLogin = @"kDriftServiceCallLogin";
static NSString *kDriftServiceCallListGists = @"kDriftServiceCallListGists";
static NSString *kDriftServiceCallFetchGist = @"kDriftServiceCallFetchGist";
static NSString *kDriftServiceCallPushGist = @"kDriftServiceCallPushGist";


@interface GEGistService ()
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

- (void)loginUserWithUsername:(NSString *)username token:(NSString *)token;
{
	NSString *urlString = [NSString stringWithFormat:@"http://github.com/api/v2/json/user/show/%@?login=%@&token=%@", username, username, token];
	NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
	NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
								username, @"username",
								token, @"token", nil];
	CCompletionTicket *ticket = [[[CCompletionTicket alloc] initWithIdentifier:kDriftServiceCallLogin delegate:self userInfo:userInfo subTicket:nil] autorelease];
	CManagedURLConnection *connection = [[[CManagedURLConnection alloc] initWithRequest:req completionTicket:ticket] autorelease];
	[connection start];
}

- (void)listGistsForCurrentUser;
{
	NSString *username = [[NSUserDefaults standardUserDefaults] objectForKey:@"username"];
	NSString *url = [NSString stringWithFormat:@"http://gist.github.com/api/v1/json/gists/%@", username];
	
	NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
	CCompletionTicket *ticket = [[[CCompletionTicket alloc] initWithIdentifier:kDriftServiceCallListGists delegate:self userInfo:nil subTicket:nil] autorelease];
	CManagedURLConnection *connection = [[[CManagedURLConnection alloc] initWithRequest:req completionTicket:ticket] autorelease];
	[connection start];
}

- (void)fetchGist:(GEGist *)gist;
{
	NSString *url = [NSString stringWithFormat:@"http://gist.github.com/%@.txt", gist.gistID];
	
	NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
	NSDictionary *userInfo = [NSDictionary dictionaryWithObject:gist forKey:@"gist"];
	CCompletionTicket *ticket = [[[CCompletionTicket alloc] initWithIdentifier:kDriftServiceCallFetchGist delegate:self userInfo:userInfo subTicket:nil] autorelease];
	CManagedURLConnection *connection = [[[CManagedURLConnection alloc] initWithRequest:req completionTicket:ticket] autorelease];
	[connection start];
}

- (void)pushGist:(GEGist *)gist;
{
	NSString *username = [[NSUserDefaults standardUserDefaults] valueForKey:@"username"];
	NSString *token = [[NSUserDefaults standardUserDefaults] valueForKey:@"token"];
	NSString *post;
	NSString *urlString;
	
	if (gist.gistID) {
		// gist already exists
		NSString *extension = [gist.name componentsSeparatedByString:@"."].lastObject;
		post = [NSString stringWithFormat:@"_method=put&file_contents[%@]=%@&file_ext[%@]=.%@&file_name[%@]=%@&login=%@&token=%@",
												gist.name, gist.body, gist.name, extension, gist.name, gist.name, username, token];
		
		urlString = [NSString stringWithFormat:@"http://gist.github.com/gists/%@", gist.gistID];
	}
	else {
		post = [NSString stringWithFormat:@"files[%@]=%@&login=%@&token=%@",
											gist.name, gist.body, username, token];
		urlString = @"http://gist.github.com/api/v1/json/new";
	}
	NSData *data = [post dataUsingEncoding:NSUTF8StringEncoding];
	
	NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
	
	[req setHTTPMethod:@"POST"];
	[req setValue:[NSString stringWithFormat:@"%d", [data length]] forHTTPHeaderField:@"Content-Length"];
	[req setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
	[req setHTTPBody:data];
	
	NSDictionary *userInfo = [NSDictionary dictionaryWithObject:gist forKey:@"gist"];
	CCompletionTicket *ticket = [[[CCompletionTicket alloc] initWithIdentifier:kDriftServiceCallPushGist delegate:self userInfo:userInfo subTicket:nil] autorelease];
	CManagedURLConnection *connection = [[[CManagedURLConnection alloc] initWithRequest:req completionTicket:ticket] autorelease];
	[connection start];
}

#pragma mark Completion ticket delegate

- (void)completionTicket:(CCompletionTicket *)inCompletionTicket didCompleteForTarget:(id)inTarget result:(id)inResult;
{
	if ([inCompletionTicket identifier] == kDriftServiceCallListGists)
	{
		NSError *err = nil;
		NSDictionary *res = [[CJSONDeserializer deserializer] deserializeAsDictionary:inResult error:&err];
		if (!res) {
			NSLog(@"Error parsing gists: %@", [err localizedDescription]);
		} else {
			for (NSDictionary *gist in [res valueForKey:@"gists"]) {
				[GEGist insertOrUpdateGistWithAttributes:gist];
			}
		}
		[[NSNotificationCenter defaultCenter] postNotificationName:kDriftNotificationUpdatedGists object:self];
	}
	
	else if ([inCompletionTicket identifier] == kDriftServiceCallFetchGist)
	{
		GEGist *gist = [[inCompletionTicket userInfo] valueForKey:@"gist"];
		NSString *bodyString = [[[NSString alloc] initWithData:inResult encoding:NSUTF8StringEncoding] autorelease];
		gist.body = bodyString;
		NSDictionary *userInfo = [NSDictionary dictionaryWithObject:gist forKey:@"gist"];
		[[NSNotificationCenter defaultCenter] postNotificationName:kDriftNotificationUpdatedGist object:self userInfo:userInfo];
	}
	
	else if ([inCompletionTicket identifier] == kDriftServiceCallPushGist)
	{
		GEGist *gist = [[inCompletionTicket userInfo] valueForKey:@"gist"];
		NSArray *gists = [[[CJSONDeserializer deserializer] deserializeAsDictionary:inResult error:nil] objectForKey:@"gists"];
		if (gists && [gists count] > 0) {
			NSDictionary *attributes = [gists objectAtIndex:0];
			[gist updateWithAttributes:attributes];
		}
		gist.dirty = NO;
		NSDictionary *userInfo = [NSDictionary dictionaryWithObject:gist forKey:@"gist"];
		[[NSNotificationCenter defaultCenter] postNotificationName:kDriftNotificationUpdatedGist object:self userInfo:userInfo];
	}
	
	else if ([inCompletionTicket identifier] == kDriftServiceCallLogin)
	{
		id res = [[CJSONDeserializer deserializer] deserialize:inResult error:nil];
		if (!res) {
			[[NSNotificationCenter defaultCenter] postNotificationName:kDriftNotificationLoginFailed object:self];
			return;
		}
		NSDictionary *userInfo = [inCompletionTicket userInfo];
		NSString *username = [userInfo objectForKey:@"username"];
		NSString *token = [userInfo objectForKey:@"token"];
		[[NSUserDefaults standardUserDefaults] setObject:username forKey:@"username"];
		[[NSUserDefaults standardUserDefaults] setObject:token forKey:@"token"];
		[[NSNotificationCenter defaultCenter] postNotificationName:kDriftNotificationLoginSucceeded object:self];
	}
}

- (void)completionTicket:(CCompletionTicket *)inCompletionTicket didBeginForTarget:(id)inTarget;
{
}

- (void)completionTicket:(CCompletionTicket *)inCompletionTicket didFailForTarget:(id)inTarget error:(NSError *)inError;
{
	NSLog(@"Service call %@ failed with error %@", [inCompletionTicket identifier], [inError localizedDescription]);
}

- (void)completionTicket:(CCompletionTicket *)inCompletionTicket didCancelForTarget:(id)inTarget;
{
}

@end
