
#import "CodeInstallUtils.h"
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonCryptor.h>
#import <sys/utsname.h>




@implementation CodeInstallUtils

+ (NSString *)getPBIDWithPrefix:(NSString *)prefix appKey:(NSString *)appkey{
    return  @"";
}


+ (NSString *)sha1:(NSString *)str {
    const char *cstr = [str cStringUsingEncoding:NSUTF8StringEncoding];
    NSData *data = [NSData dataWithBytes:cstr length:str.length];
    //使用对应的CC_SHA1,CC_SHA256,CC_SHA384,CC_SHA512的长度分别是20,32,48,64
    uint8_t digest[CC_SHA1_DIGEST_LENGTH];
    //使用对应的CC_SHA256,CC_SHA384,CC_SHA512
    CC_SHA1(data.bytes, (CC_LONG)data.length, digest);
    
    NSMutableString* output = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
    
    for(int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++)
    [output appendFormat:@"%02x", digest[i]];
    
    return output;
}

+ (NSString *)getInfoPlistValueForKey:(NSString *)key{
    if (!key) {
        return nil;
    }
    return [[NSBundle mainBundle].infoDictionary objectForKey:key];
}

+ (BOOL)isSimuLator{
    if (TARGET_IPHONE_SIMULATOR == 1 && TARGET_OS_IPHONE == 1) {
        //模拟器
        return YES;
    }else{
        //真机
        return NO;
    }
}

+ (long)timeStamp{
    NSTimeInterval timestamp = (long)[[NSDate date] timeIntervalSince1970];
    return  timestamp;
}


+ (NSDictionary *)signParams:(NSMutableDictionary *)paramsMDict appkey:(NSString *)appKey{
    return @{};
}

+ (void)writeStrToPlist:(NSString *)str forKey:(NSString *)key plistFileName:(NSString *) plistFileName{
    NSArray *pathArray = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *path = [pathArray objectAtIndex:0];
    NSString *filePatch = [path stringByAppendingPathComponent:plistFileName];
    NSFileManager *fileMger = [NSFileManager defaultManager];
    
    if ([fileMger fileExistsAtPath:filePatch]) {
        NSError *err;
        [fileMger removeItemAtPath:filePatch error:&err];
    }
    
    NSMutableDictionary *dataDic = [NSMutableDictionary dictionary];
    [dataDic setObject:str forKey:key];
    [dataDic writeToFile:filePatch atomically:YES];
}

+ (NSString *)readStrInPlist: (NSString *)plistFileName forKey:(NSString *)key{
    NSArray *pathArray = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *path = [pathArray objectAtIndex:0];
    NSString *filePatch = [path stringByAppendingPathComponent:plistFileName];
    
    NSDictionary *dic = [[NSDictionary alloc] initWithContentsOfFile:filePatch];
    NSString *customUDID = [dic objectForKey:key];
    return customUDID;
}


+ (NSString *)getBundleIDInMobileProfile{
    NSString *mobileProvisionPath = [[NSBundle mainBundle] pathForResource:@"embedded" ofType:@"mobileprovision"];
    NSData *rawData = [NSData dataWithContentsOfFile:mobileProvisionPath];
    NSString *rawDataString = [[NSString alloc] initWithData:rawData encoding:NSASCIIStringEncoding];
    NSRange plistStartRange = [rawDataString rangeOfString:@"<plist"];
    NSRange plistEndRange = [rawDataString rangeOfString:@"</plist>"];
    if (plistStartRange.location != NSNotFound && plistEndRange.location != NSNotFound) {
        NSString *tempPlistString = [rawDataString substringWithRange:NSMakeRange(plistStartRange.location, NSMaxRange(plistEndRange))];
        NSData *tempPlistData = [tempPlistString dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *plistDic =  [NSPropertyListSerialization propertyListWithData:tempPlistData options:NSPropertyListImmutable format:nil error:nil];
        NSDictionary *entitlementsDic = [plistDic objectForKey:@"Entitlements"];
        NSString *mobileBundleID = [entitlementsDic objectForKey:@"application-identifier"];
        return mobileBundleID;
    }
    
    return  nil;
}

+ (void)addPeriodToUserDefaultsWithKey:(NSString *)key startTime:(long) startTime endTime:(long) endTime{

    NSUserDefaults *udf = [NSUserDefaults standardUserDefaults];
    
    NSArray *nowPeriod = @[[NSNumber numberWithLong:startTime],[NSNumber numberWithLong:endTime]];
    NSArray *allExitTimePeriodArr = (NSArray *)[udf objectForKey:key];
    if (allExitTimePeriodArr == nil || allExitTimePeriodArr.count == 0) {
        [udf setObject:@[nowPeriod] forKey:key];
        [udf synchronize];
    }else{
        NSMutableArray *allArr = [NSMutableArray arrayWithArray:allExitTimePeriodArr];
        [allArr addObject: nowPeriod];
        [udf setObject:allArr forKey:key];
        [udf synchronize];
    }
}

+ (NSArray *)getAllTimeIntervalPeriodInUserDefaultWithKey:(NSString *)key{
    NSUserDefaults *udf = [NSUserDefaults standardUserDefaults];
    NSArray *allExitTimePeriodArr = (NSArray *)[udf objectForKey:key];
    return  allExitTimePeriodArr;
}


+ (void)removeAllTimeIntervalPeriodInUserDefaultWithKey:(NSString *)key{
    NSUserDefaults *udf = [NSUserDefaults standardUserDefaults];
    [udf removeObjectForKey:key];
    [udf synchronize];
}

+ (NSString *)platform{
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *platform = [NSString stringWithCString:systemInfo.machine encoding:NSASCIIStringEncoding];
    if (platform == nil) {
        platform = @"";
    }
    return platform;
}



+ (NSMutableDictionary *)getKeychainQuery:(NSString *)service {
    return [NSMutableDictionary dictionaryWithObjectsAndKeys:
            (__bridge id)kSecClassGenericPassword,(__bridge id)kSecClass,
            service, (__bridge id)kSecAttrService,
            service, (__bridge id)kSecAttrAccount,
            (__bridge id)kSecAttrAccessibleAfterFirstUnlock,(__bridge id)kSecAttrAccessible,
            nil];
}

+ (id)getKeychainDataForKey:(NSString *)key groupItem:(NSString * _Nullable)groupItem{
    id ret = nil;
    NSMutableDictionary *keychainQuery = [self getKeychainQuery:key];
    if (groupItem) {
        [keychainQuery setObject:groupItem forKey:(id)kSecAttrAccessGroup];
    }
    //Configure the search setting
    //Since in our simple case we are expecting only a single attribute to be returned (the password) we can set the attribute kSecReturnData to kCFBooleanTrue
    [keychainQuery setObject:(id)kCFBooleanTrue forKey:(__bridge id)kSecReturnData];
    [keychainQuery setObject:(__bridge id)kSecMatchLimitOne forKey:(__bridge id)kSecMatchLimit];
    CFDataRef keyData = NULL;
    if (SecItemCopyMatching((__bridge CFDictionaryRef)keychainQuery, (CFTypeRef *)&keyData) == noErr) {
        @try {
            ret = [NSKeyedUnarchiver unarchiveObjectWithData:(__bridge NSData *)keyData];
        } @catch (NSException *e) {
            //NSLog(@"Unarchive of %@ failed: %@",key,e);
        } @finally {
        }
    }
    if (keyData)
        CFRelease(keyData);
    return ret;
}

+ (void)addKeychainData:(id)data forKey:(NSString *)key groupItem:(NSString * _Nullable)groupItem{
    //Get search dictionary
    NSMutableDictionary *keychainQuery = [self getKeychainQuery:key];
    if (groupItem) {
        [keychainQuery setObject:groupItem forKey:(id)kSecAttrAccessGroup];
    }

    //Delete old item before add new item
    SecItemDelete((__bridge CFDictionaryRef)keychainQuery);
    //Add new object to search dictionary(Attention:the data format)
    [keychainQuery setObject:[NSKeyedArchiver archivedDataWithRootObject:data] forKey:(__bridge id)kSecValueData];
    //Add item to keychain with the search dictionary
    SecItemAdd((__bridge CFDictionaryRef)keychainQuery, NULL);
}

+ (void)deleteKeychainDataForKey:(NSString *)key groupItem:(NSString * _Nullable)groupItem{
    NSMutableDictionary *keychainQuery = [self getKeychainQuery:key];
    if (groupItem) {
        [keychainQuery setObject:groupItem forKey:(id)kSecAttrAccessGroup];
    }
    SecItemDelete((__bridge CFDictionaryRef)keychainQuery);
}


@end
