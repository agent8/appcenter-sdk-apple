// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSAppCenterUserDefaults.h"
#import "MSAppCenterInternal.h"
#import "MSLogger.h"

static NSString *const kMSAppCenterUserDefaultsMigratedKeyFormat = @"310%@UserDefaultsMigratedKey";

static MSAppCenterUserDefaults *sharedInstance = nil;
static dispatch_once_t onceToken;

@implementation MSAppCenterUserDefaults

+ (instancetype)shared {
  dispatch_once(&onceToken, ^{
    sharedInstance = [[MSAppCenterUserDefaults alloc] init];
  });
  return sharedInstance;
}

+ (void)resetSharedInstance {

  // Reset the once_token so dispatch_once will run again.
  onceToken = 0;
  sharedInstance = nil;
}

- (void)migrateKeys:(NSDictionary *)migratedKeys forService:(NSString *)service {
  NSNumber *serviceMigrated = [self objectForKey:[NSString stringWithFormat:kMSAppCenterUserDefaultsMigratedKeyFormat, service]];
  if (serviceMigrated) {
    return;
  }

  MSLogVerbose([MSAppCenter logTag], @"Migrating the old NSDefaults keys to new ones.");
  for (NSObject *newKey in migratedKeys) {
    if (![newKey isKindOfClass:[NSString class]]) {
      MSLogError([MSAppCenter logTag], @"Unsupported type %@ for key %@", [newKey class], newKey);
      continue;
    }
    id<NSObject> oldKey = migratedKeys[newKey];
    NSString *newKeyString = (NSString *)newKey;
    if ([oldKey isKindOfClass:[NSString class]]) {
      id value = [[NSUserDefaults standardUserDefaults] objectForKey:(NSString *)oldKey];
      [self swapKeys:(NSString *)oldKey newKey:newKeyString value:value];
    } else if ([oldKey isKindOfClass:[MSUserDefaultsPrefixKey class]]) {

      // List all the keys starting with oldKey.
      NSString *oldKeyPrefix = ((MSUserDefaultsPrefixKey *)oldKey).keyPrefix;
      NSArray *userDefaultKeys = [[[NSUserDefaults standardUserDefaults] dictionaryRepresentation] allKeys];
      for (NSString *userDefaultsKey in userDefaultKeys) {
        if ([userDefaultsKey hasPrefix:oldKeyPrefix]) {
          NSString *suffix = [userDefaultsKey stringByReplacingOccurrencesOfString:oldKeyPrefix withString:@""];
          NSString *newKeyWithSuffix = [newKeyString stringByAppendingString:suffix];
          id value = [[NSUserDefaults standardUserDefaults] objectForKey:userDefaultsKey];
          [self swapKeys:userDefaultsKey newKey:newKeyWithSuffix value:value];
        }
      }
    } else {
      MSLogError([MSAppCenter logTag], @"Unsupported type %@ for key %@", [oldKey class], oldKey);
      continue;
    }
  }
  [self setObject:@YES forKey:[NSString stringWithFormat:kMSAppCenterUserDefaultsMigratedKeyFormat, service]];
}

- (void)swapKeys:(NSString *)oldKey newKey:(NSString *)newKey value:(id)value {
  if (value == nil) {
    return;
  }
  [[NSUserDefaults standardUserDefaults] setObject:value forKey:newKey];
  [[NSUserDefaults standardUserDefaults] removeObjectForKey:oldKey];
  MSLogVerbose([MSAppCenter logTag], @"Migrating key %@ -> %@", oldKey, newKey);
}

- (NSString *)getAppCenterKeyFrom:(NSObject *)key {
  if (![key isKindOfClass:[NSString class]]) {
    MSLogError([MSAppCenter logTag], @"Unsupported type %@ for key %@", [key class], key);
    return nil;
  }
  NSString *keyString = (NSString *)key;
  NSAssert(![keyString hasPrefix:kMSUserDefaultsPrefix], @"Please do not prepend the key with 'MSAppCenter'. It's done automatically.");
  return [kMSUserDefaultsPrefix stringByAppendingString:keyString];
}

- (id)objectForKey:(NSObject *)key {
  NSString *keyPrefixed = [self getAppCenterKeyFrom:key];
  return [[NSUserDefaults standardUserDefaults] objectForKey:keyPrefixed];
}

- (void)setObject:(id)value forKey:(NSObject *)key {
  NSString *keyPrefixed = [self getAppCenterKeyFrom:key];
  [[NSUserDefaults standardUserDefaults] setObject:value forKey:keyPrefixed];
}

- (void)removeObjectForKey:(NSObject *)key {
  NSString *keyPrefixed = [self getAppCenterKeyFrom:key];
  [[NSUserDefaults standardUserDefaults] removeObjectForKey:keyPrefixed];
}

@end

@implementation MSUserDefaultsPrefixKey

- (instancetype)initWithPrefix:(NSString *)prefix {
  if ((self = [super init])) {
    _keyPrefix = prefix;
  }
  return self;
}

- (id)copyWithZone:(nullable __unused NSZone *)zone {
  return [[MSUserDefaultsPrefixKey alloc] initWithPrefix:self.keyPrefix];
}

@end
