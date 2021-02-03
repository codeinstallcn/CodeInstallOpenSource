
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CodeInstallUtils : NSObject

+ (NSString *)getPBIDWithPrefix:(NSString *)prefix appKey:(NSString *)appkey;

+ (NSString *)sha1:(NSString *)str;

+ (NSString *)getInfoPlistValueForKey:(NSString *)key;

+ (BOOL)isSimuLator;

+ (long)timeStamp;

+ (NSDictionary *)signParams:(NSMutableDictionary *)paramsMDict appkey:(NSString *)appKey;

+ (void)writeStrToPlist:(NSString *)str forKey:(NSString *)key plistFileName:(NSString *) plistFileName;
+ (NSString *)readStrInPlist: (NSString *)plistFileName forKey:(NSString *)key;

+ (NSString *)getBundleIDInMobileProfile;

+ (void)addPeriodToUserDefaultsWithKey:(NSString *)key startTime:(long) startTime endTime:(long) endTime;
+ (NSArray *)getAllTimeIntervalPeriodInUserDefaultWithKey:(NSString *)key;
+ (void)removeAllTimeIntervalPeriodInUserDefaultWithKey:(NSString *)key;

+ (NSString *)platform;


+ (id)getKeychainDataForKey:(NSString *)key groupItem:(NSString * _Nullable)groupItem;
+ (void)addKeychainData:(id)data forKey:(NSString *)key groupItem:(NSString * _Nullable)groupItem;
+ (void)deleteKeychainDataForKey:(NSString *)key groupItem:(NSString * _Nullable)groupItem;

@end

NS_ASSUME_NONNULL_END
