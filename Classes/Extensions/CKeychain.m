//
//  CKeychain.m
//  Driftpad
//
//  Created by Devin Chalmers on 3/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "CKeychain.h"

@interface CKeychain ()
+ (NSMutableDictionary *) keychainItemForQuery:(NSDictionary *)keychainQuery;
+ (void) saveKeychainItem:(NSMutableDictionary *)keychainItem matchingQuery:(NSDictionary *)aQuery;
+ (NSMutableDictionary *) fetchItemDataForItemOfClass:(id)itemClass withAttributes:(NSDictionary *)attributes;
@end

@implementation CKeychain

+ (NSString *) passwordForKey:(NSString *)aKey;
{
	NSMutableDictionary *genericAttrQuery = [[NSMutableDictionary alloc] init];
	
	[genericAttrQuery setObject:(id)kSecClassGenericPassword forKey:(id)kSecClass];
	NSData *genericAttrData = [aKey dataUsingEncoding:NSUTF8StringEncoding];
	[genericAttrQuery setObject:genericAttrData forKey:(id)kSecAttrGeneric];
	[genericAttrQuery setObject:(id)kSecMatchLimitOne forKey:(id)kSecMatchLimit];
	[genericAttrQuery setObject:(id)kCFBooleanTrue forKey:(id)kSecReturnAttributes];
    
	NSMutableDictionary *item = [self keychainItemForQuery:genericAttrQuery];
	[genericAttrQuery release];
    
    return [item objectForKey:(id)kSecValueData];
}

+ (void) savePassword:(NSString *)password forKey:(NSString *)aKey;
{
	NSMutableDictionary *genericAttrQuery = [[NSMutableDictionary alloc] init];
	
	[genericAttrQuery setObject:(id)kSecClassGenericPassword forKey:(id)kSecClass];
	NSData *genericAttrData = [aKey dataUsingEncoding:NSUTF8StringEncoding];
	[genericAttrQuery setObject:genericAttrData forKey:(id)kSecAttrGeneric];
	[genericAttrQuery setObject:(id)kSecMatchLimitOne forKey:(id)kSecMatchLimit];
	[genericAttrQuery setObject:(id)kCFBooleanTrue forKey:(id)kSecReturnAttributes];
	
    NSData *data = [password dataUsingEncoding:NSUTF8StringEncoding];
	NSMutableDictionary *keychainItem = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                  data, kSecValueData,
                                  genericAttrData, (id)kSecAttrGeneric,
                                  nil];
    
	[self saveKeychainItem:keychainItem matchingQuery:genericAttrQuery];
    
	[genericAttrQuery release];
}

+ (NSMutableDictionary *) keychainItemForQuery:(NSDictionary *)keychainQuery;
{	
	OSStatus keychainErr = noErr;
	
	id itemClass = [keychainQuery objectForKey:(id)kSecClass];
    
	NSMutableDictionary *outDictionary = nil;
	keychainErr = SecItemCopyMatching((CFDictionaryRef)keychainQuery, (CFTypeRef *)&outDictionary);
    
	if (keychainErr == errSecItemNotFound) 
		return nil;
	if (keychainErr != noErr) {
		NSLog(@"Error fetching Keychain Item (%d).", (int)keychainErr);
		return nil;
	}
	
	NSMutableDictionary *keychainDictionary = [self fetchItemDataForItemOfClass:itemClass withAttributes:outDictionary];
	[outDictionary release];
	return keychainDictionary;
}

+ (void) saveKeychainItem:(NSMutableDictionary *)keychainItem matchingQuery:(NSDictionary *)aQuery;
{
	OSStatus keychainErr = noErr;
	NSDictionary *attributes = nil;
	if (SecItemCopyMatching((CFDictionaryRef)aQuery, (CFTypeRef *)&attributes) == noErr){
        NSMutableDictionary *foundItem = [NSMutableDictionary dictionaryWithDictionary:attributes];
		[foundItem setObject:[aQuery objectForKey:(id)kSecClass] forKey:(id)kSecClass];		
		
		keychainErr = SecItemUpdate((CFDictionaryRef)foundItem,(CFDictionaryRef)keychainItem);
        NSAssert1(keychainErr == noErr, @"Couldn't update the Keychain Item (%d).", keychainErr);
    } else {
		[keychainItem setObject:[aQuery objectForKey:(id)kSecClass] forKey:(id)kSecClass];		
		keychainErr = SecItemAdd((CFDictionaryRef)keychainItem,NULL);
        NSAssert1(keychainErr == noErr, @"Couldn't add the Keychain Item (%d).", keychainErr);
    }
}

+ (NSMutableDictionary *) fetchItemDataForItemOfClass:(id)itemClass withAttributes:(NSDictionary *)attributes;
{
    NSMutableDictionary *keychainItem = [NSMutableDictionary
                                         dictionaryWithDictionary:attributes];
	
    [keychainItem setObject:(id)kCFBooleanTrue forKey:(id)kSecReturnData];
    [keychainItem setObject:(id)itemClass forKey:(id)kSecClass];
	
    NSData *itemData = nil;
    OSStatus keychainError = noErr; 
    keychainError = SecItemCopyMatching((CFDictionaryRef)keychainItem, (CFTypeRef *)&itemData);
    if(keychainError == noErr) {
        [keychainItem removeObjectForKey:(id)kSecReturnData];
		if([itemClass isEqual:(id)kSecClassGenericPassword] || [itemClass isEqual:(id)kSecClassInternetPassword]) {
			NSString *password = [[NSString alloc] initWithBytes:[itemData bytes]
                                                          length:[itemData length] encoding:NSUTF8StringEncoding];
			[keychainItem setObject:password forKey:(id)kSecValueData];
			[password release];
		}
    } else {
		if (keychainError == errSecItemNotFound)
            NSAssert(NO, @"Nothing was found in the keychain.\n");
		else {
			NSAssert(NO, @"Serious error");
		}
	}
	
    [itemData release];
	[keychainItem removeObjectForKey:(id)kSecReturnData];
    return keychainItem;
}

@end
