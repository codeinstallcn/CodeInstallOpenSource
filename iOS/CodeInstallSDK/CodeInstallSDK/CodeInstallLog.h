
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CodeInstallLog : NSObject

+ (CodeInstallLog *) shard;

- (void)MPLog:(NSString *)msg;

@property(nonatomic, strong) NSMutableString *logStrAll;

@end

NS_ASSUME_NONNULL_END




