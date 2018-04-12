#import "MSCrashesInternal.h"
#import "MSCrashesUtil.h"
#import "MSCrashesUtilPrivate.h"
#import "MSLogger.h"
#import "MSUtility.h"
#import "MSUtility+File.h"

@implementation MSCrashesUtil

static dispatch_once_t crashesDirectoryOnceToken;
static dispatch_once_t logBufferDirectoryOnceToken;
static dispatch_once_t wrapperExceptionsDirectoryOnceToken;

#pragma mark - Public

+ (NSString *)crashesDir {
  dispatch_once(&crashesDirectoryOnceToken, ^{
    [MSUtility createSubDirectoryForPathComponent:kMSCrashesDirectory];
  });

  return kMSCrashesDirectory;
}

+ (NSString *)logBufferDir {
  dispatch_once(&logBufferDirectoryOnceToken, ^{
    [MSUtility createSubDirectoryForPathComponent:kMSLogBufferDirectory];
  });

  return kMSLogBufferDirectory;
}

+ (NSString *)wrapperExceptionsDir {
  dispatch_once(&wrapperExceptionsDirectoryOnceToken, ^{
    [MSUtility createSubDirectoryForPathComponent:kMSWrapperExceptionsDirectory];
  });

  return kMSWrapperExceptionsDirectory;
}

#pragma mark - Private

+ (void)resetDirectory {
  crashesDirectoryOnceToken = 0;
  logBufferDirectoryOnceToken = 0;
  wrapperExceptionsDirectoryOnceToken = 0;
}

@end
