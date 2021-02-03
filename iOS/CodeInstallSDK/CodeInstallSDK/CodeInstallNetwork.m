
#import "CodeInstallNetwork.h"
#import "CodeInstallUtils.h"
#import "CodeInstallConfig.h"
#import "CodeInstallLog.h"


@implementation CodeInstallNetwork

static int CodeInstallNetworkRequestCount = 0;

+ (void)postParams:(NSDictionary *) paramsDic
 completionHandler:(void (^ __nullable)(NSDictionary * retDic))completionHandler{
    [CodeInstallNetwork postParams:paramsDic completionHandler:completionHandler failedHandler:nil];
}

+ (void)postParams:(NSDictionary *) paramsDic
 completionHandler:(void (^ __nullable)(NSDictionary * retDic))completionHandler
     failedHandler:(void (^ __nullable)(NSError * error))failedHandler{
    
    NSString *appKey = [CodeInstallUtils getInfoPlistValueForKey: kCodeInstallAppKeyInInfoPlist];
    if (appKey == nil) {
        NSLog(kCodeInstallAppKeyLostWarning);
        return;
    }
    
    NSString *baseUrl = kCodeInstallBaseUrl_pro;
    NSDictionary *infoDic = [NSBundle mainBundle].infoDictionary;
    NSString *environment = [infoDic objectForKey:@"now_environment"];
    if ([environment isEqualToString:@"dev"]) {
        baseUrl = kCodeInstallBaseUrl_dev;
    }
    
    if ([environment isEqualToString:@"pre"]) {
        baseUrl = kCodeInstallBaseUrl_pre;
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:baseUrl]];
    request.HTTPMethod = @"POST";
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
        
    NSMutableDictionary *mDic = [NSMutableDictionary dictionaryWithDictionary:paramsDic];
    NSString *isS = [CodeInstallUtils isSimuLator] ? @"1" : @"0";
    
    [mDic setObject:isS forKey:@"is_simulator"];
    [mDic setObject:[infoDic objectForKey:@"CFBundleShortVersionString"] forKey:@"app_ver"];
    [mDic setObject:UIDevice.currentDevice.systemVersion forKey:@"os_ver"];
    [mDic setObject:kCodeInstall_API_Version forKey:@"api_version_no"];
    [mDic setObject:[CodeInstallUtils platform] forKey:@"device_model"];
    [mDic setObject:@"iOS" forKey:@"os_type"];
    [mDic setObject:kCodeInstallSDKVersion_API forKey:@"sdk_version_no"];
    [mDic setObject:[[NSBundle mainBundle] bundleIdentifier] forKey:@"application_id"];
    

    NSDictionary *params = [CodeInstallUtils signParams:mDic appkey:appKey];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = [NSString stringWithFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString * dateStr = [dateFormatter stringFromDate:[NSDate date]];
    
    NSString *logStr = [NSString stringWithFormat:@"\n\n\n*** 开始请求 (%d) %@ ***\n%@\n%@\n***\n",CodeInstallNetworkRequestCount,dateStr,baseUrl,params];
    
    [[CodeInstallLog shard] MPLog:logStr];
    
    NSArray *allKeysArr = [params allKeys];
    NSMutableString *paramString = [NSMutableString string];
    for (NSInteger idx = 0; idx < allKeysArr.count; idx++) {
        if ([paramString length] > 0)
        {
            [paramString appendString: @"&"];
        }
        NSString *key = allKeysArr[idx];
        id value = params[key];
        [paramString appendFormat:@"%@=%@", key, value];
    }
    request.HTTPBody = [paramString dataUsingEncoding:NSUTF8StringEncoding];
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = [NSString stringWithFormat:@"yyyy-MM-dd HH:mm:ss"];
        NSString * dateStr = [dateFormatter stringFromDate:[NSDate date]];
        [[CodeInstallLog shard] MPLog:[NSString stringWithFormat:@"*** 请求结束 (%d) %@***\n",CodeInstallNetworkRequestCount,dateStr]];
        
        if (error != nil) {
            
            
            [[CodeInstallLog shard] MPLog:[NSString stringWithFormat:@"*** (%d):请求出错\n%@\nerror:%@",CodeInstallNetworkRequestCount,[NSDate date],[error description]]];
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1* NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if (failedHandler) {
                    failedHandler(error);
                }
            });
            return;
        }
        
        if (data == nil) {
            [[CodeInstallLog shard] MPLog:[NSString stringWithFormat:@"请求出错,data nil"]];
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1* NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if (failedHandler) {
                    NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:121 userInfo:@{NSLocalizedDescriptionKey:@"data nil"}];
                    failedHandler(error);
                }
            });
            return;
        }
        
        NSError *jsonSError = nil;
        NSDictionary *retDic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&jsonSError];
        if (jsonSError) {
            NSString *retStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            
            [[CodeInstallLog shard] MPLog:[NSString stringWithFormat:@"解析出错: %@,retStr:%@",[jsonSError description], retStr]];
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1* NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if (failedHandler) {
                    failedHandler(jsonSError);
                }
            });
            return;
        }
        
        if (retDic == nil) {
            [[CodeInstallLog shard] MPLog:[NSString stringWithFormat:@"解析出错,retDict nil"]];
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1* NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if (failedHandler) {
                    NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:121 userInfo:@{NSLocalizedDescriptionKey:@"retDic nil"}];
                    failedHandler(error);
                }
            });
            return;
        }
        
        NSData *printData = [NSJSONSerialization dataWithJSONObject:retDic options:NSJSONWritingPrettyPrinted error:nil];
        NSString *printStr = [[NSString alloc] initWithData:printData encoding:NSUTF8StringEncoding];
        [[CodeInstallLog shard] MPLog:printStr];
        
        NSNumber *codeNum = [retDic objectForKey:@"code"];
        if (codeNum == nil) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1* NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if (failedHandler) {
                    NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:121 userInfo:@{NSLocalizedDescriptionKey:@"retDic nil"}];
                    failedHandler(error);
                }
            });
            return;
        }
        
        NSInteger code = [codeNum integerValue];
        if (code != 0){
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1* NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if (failedHandler) {
                    NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:121 userInfo:@{NSLocalizedDescriptionKey:@"retDic nil"}];
                    failedHandler(error);
                }
            });
            return;
        }
        
        NSDictionary *dataDic = [retDic objectForKey:@"data"];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1* NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (completionHandler) {
                completionHandler(dataDic);
            }
        });
        
        CodeInstallNetworkRequestCount +=1;
        
    }];
    [task resume];
}


@end
