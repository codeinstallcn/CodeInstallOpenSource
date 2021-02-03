
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CodeInstallTimer : NSObject

+ (instancetype)shared;

- (void)startTimer: (NSTimeInterval)seconds callback:(void (^)(void))callBackHandler;
- (void)stopTimer;

@end

NS_ASSUME_NONNULL_END
