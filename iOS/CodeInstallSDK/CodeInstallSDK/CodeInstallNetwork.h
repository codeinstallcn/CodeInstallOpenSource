
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CodeInstallNetwork : NSObject

+ (void)postParams:(NSDictionary *) paramsDic
 completionHandler:(void (^ __nullable)(NSDictionary * retDic))completionHandler;

+ (void)postParams:(NSDictionary *) paramsDic
 completionHandler:(void (^ __nullable)(NSDictionary * retDic))completionHandler
     failedHandler:(void (^ __nullable)(NSError * error))failedHandler;

@end

NS_ASSUME_NONNULL_END
