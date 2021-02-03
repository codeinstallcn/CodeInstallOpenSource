
#import "CodeInstallSDK.h"
#import "CodeInstallConfig.h"
#import "CodeInstallUtils.h"
#import "CodeInstallNetworkReachability.h"
#import "CodeInstallLog.h"
#import "CodeInstallUtils.h"
#import "CodeInstallTimer.h"
#import "CodeInstallNetwork.h"

@implementation CodeInstallData
@end

@interface CodeInstallSDK ()

@property(nonatomic, weak) id <CodeInstallDelegate> codeInstallDelegate;
@property (nonatomic, unsafe_unretained) UIBackgroundTaskIdentifier taskId;

@end


@implementation CodeInstallSDK

+ (instancetype)shared{
    static CodeInstallSDK *instance = nil ;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (instance == nil) {
            instance = [[CodeInstallSDK alloc]init];
        }
    });
    return instance;
}

+ (void)initWithDelegate:(id<CodeInstallDelegate> _Nonnull)delegate{
    NSString *appKey = [CodeInstallUtils getInfoPlistValueForKey: kCodeInstallAppKeyInInfoPlist];
    if (appKey == nil) {
        NSLog(kCodeInstallAppKeyLostWarning);
        return;
    }
    
    [CodeInstallSDK shared].codeInstallDelegate = delegate;
    [CodeInstallSDK handleApplicationLifeCycle];
    
    BOOL sdkInit = [[NSUserDefaults standardUserDefaults] boolForKey:kCodeInstallSDKInit];
    if (sdkInit) {
        [[CodeInstallLog shard] MPLog:@"**已经打开过软件\n"];
    }else{
        [[CodeInstallLog shard] MPLog:@"**第一次安装\n"];
        
        [[CodeInstallReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(CodeInstallNetworkReachabilityStatus status) {
            if (status == ReachableViaWiFi || status == ReachableViaWWAN) {
                [[CodeInstallLog shard] MPLog:@"***有网络了....开始请求\n"];
                [[CodeInstallReachabilityManager sharedManager] stopMonitoring];
                [CodeInstallSDK statisticAppInstallInfo];
            }
        }];
        [[CodeInstallReachabilityManager sharedManager] startMonitoring];
    }
}

+ (void)statisticAppInstallInfo{
    NSString *appKey = [CodeInstallUtils getInfoPlistValueForKey: kCodeInstallAppKeyInInfoPlist];
    if (appKey == nil) {
        NSLog(kCodeInstallAppKeyLostWarning);
        return;
    }
    
    NSString *installID = [CodeInstallSDK getInstallIDFromKeyChainThenPlist];
    installID = installID ? installID : @"";
    NSString *pbID = [CodeInstallUtils getPBIDWithPrefix:kCodeInstallPrifixForPBIDInPastboard appKey:appKey];
    pbID = pbID ? pbID : @"";
    
    NSString *bundleIDFromMoblieProfile = [CodeInstallUtils getBundleIDInMobileProfile];
    bundleIDFromMoblieProfile = bundleIDFromMoblieProfile ? bundleIDFromMoblieProfile : @"";
    
    NSDictionary *params = @{
        @"pbid":pbID,
        @"app_key":appKey,
        @"installId":installID,
        @"bundleId_inMoblieProfile": bundleIDFromMoblieProfile,
        @"action": @"statistic_app_install_info"
    };
    
    [CodeInstallNetwork postParams:params completionHandler:^(NSDictionary *retDic) {
        NSString *installID = retDic[@"installId"];
        if (installID) {
            NSString * keychainKeyInstallID = [NSString stringWithFormat:@"__KeyChainInstall%@",[[NSBundle mainBundle] bundleIdentifier]];
            [CodeInstallUtils addKeychainData:installID forKey:keychainKeyInstallID groupItem:nil];
            [CodeInstallUtils writeStrToPlist:installID forKey:kCodeInstallInstallIDInPlistKey plistFileName:kCodeInstallInstallIDPlistFileName];
            [[NSUserDefaults standardUserDefaults] setBool:true forKey:kCodeInstallSDKInit];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [UIPasteboard generalPasteboard].string = @" ";
        }
    }];
}

+ (NSString *)getInstallIDFromKeyChainThenPlist{
    NSString * keychainKeyInstallID = [NSString stringWithFormat:@"__KeyChainInstall%@",[[NSBundle mainBundle] bundleIdentifier]];
    NSString *installID = [CodeInstallUtils getKeychainDataForKey:keychainKeyInstallID groupItem:nil];
    if (installID == nil || installID.length < 5) {
        installID = [CodeInstallUtils readStrInPlist:kCodeInstallInstallIDPlistFileName forKey:kCodeInstallInstallIDInPlistKey];
        return installID;
    }
    
    return installID;
}

+ (BOOL)handLinkURL:(NSURL *)url{
    CodeInstallData *appData = [CodeInstallSDK parseUrlToCodeInstallData:url];
    if ([[CodeInstallSDK shared].codeInstallDelegate respondsToSelector:@selector(getWakeUpParams:)]) {
        [[CodeInstallSDK shared].codeInstallDelegate getWakeUpParams:appData];
    }
    return YES;
}

+ (BOOL)continueUserActivity:(NSUserActivity *)userActivity{
    NSURL *url = userActivity.webpageURL;
    CodeInstallData *appData = [CodeInstallSDK parseUrlToCodeInstallData:url];
    if ([[CodeInstallSDK shared].codeInstallDelegate respondsToSelector:@selector(getWakeUpParams:)]) {
        [[CodeInstallSDK shared].codeInstallDelegate getWakeUpParams:appData];
    }
    return YES;
}


+ (void)getInstallParams:(void (^)(CodeInstallData * _Nullable appData))completionHandler{
    NSString *appKey = [CodeInstallUtils getInfoPlistValueForKey: kCodeInstallAppKeyInInfoPlist];
    if (appKey == nil) {
        NSLog(kCodeInstallAppKeyLostWarning);
        return;
    }
    
    NSString *installID = [CodeInstallSDK getInstallIDFromKeyChainThenPlist];
    installID = installID ? installID : @"";
    NSString *pbID = [CodeInstallUtils getPBIDWithPrefix:kCodeInstallPrifixForPBIDInPastboard appKey:appKey];
    pbID = pbID ? pbID : @"";
    
    NSDictionary *params = @{
        @"app_key":appKey,
        @"pbid":pbID,
        @"installId":installID,
        @"action": @"app_install_config"
    };
    
    [CodeInstallNetwork postParams:params completionHandler:^(NSDictionary *retDic) {
        NSString *channelNo = retDic[@"channelNo"];
        NSString *pbDataStr = retDic[@"pbData"];
        NSData *strData = [pbDataStr dataUsingEncoding:NSUTF8StringEncoding];
        
        NSError *jsonSError = nil;
        NSDictionary *pbData = [NSJSONSerialization JSONObjectWithData:strData options:NSJSONReadingAllowFragments error:&jsonSError];
        if (pbData!= nil && pbData.allKeys.count == 0) {
            pbData = nil;
        }
        
        CodeInstallData *appData = [[CodeInstallData alloc] init];
        appData.channelNo = channelNo;
        appData.data = pbData;
        completionHandler(appData);
        
    } failedHandler:^(NSError *error) {
        CodeInstallData *appData = [[CodeInstallData alloc] init];
        appData.channelNo = nil;
        appData.data = nil;
        completionHandler(appData);
    }];
}

+ (void)reportRegister{
    NSString *installID = [CodeInstallSDK getInstallIDFromKeyChainThenPlist];
    installID = installID ? installID : @"";
    NSDictionary *params = @{
        @"installId":installID,
        @"action":@"statistic_app_register_info"
    };
    
    [CodeInstallNetwork postParams:params completionHandler:nil];
}

+ (void)reportRegisterCompleted:(void (^)(void))completionHandler failed:(void (^)(void))failedHandler{
    NSString *installID = [CodeInstallSDK getInstallIDFromKeyChainThenPlist];
    installID = installID ? installID : @"";
    NSDictionary *params = @{
        @"installId":installID,
        @"action":@"statistic_app_register_info"
    };
    
    [CodeInstallNetwork postParams:params completionHandler:^(NSDictionary *retDic) {
        completionHandler();
    } failedHandler:^(NSError *error) {
        failedHandler();
    }];
    
}

+ (NSString *)sdkVersion{
    // 以下两句打印不能删掉
    [[CodeInstallLog shard] MPLog:kCodeInstallSDKVersion_MACHO];
    [[CodeInstallLog shard] MPLog:@"\n\n"];
    return kCodeInstallSDKVersion_API;
}

+ (CodeInstallData *)parseUrlToCodeInstallData:(NSURL *)url{
    CodeInstallData *defaultXSData = [[CodeInstallData alloc] init];
    defaultXSData.data = nil;
    defaultXSData.channelNo = nil;
    
    NSString *appKey = [CodeInstallUtils getInfoPlistValueForKey: kCodeInstallAppKeyInInfoPlist];
    if (appKey == nil) {
        NSLog(kCodeInstallAppKeyLostWarning);
        return defaultXSData;
    }
    
    if (!url) {
        return defaultXSData;
    }
    
    NSString *queryString = url.query;
    if (!queryString) {
        return defaultXSData;
    }
    
    if (![url.absoluteString containsString: appKey]) {
        return defaultXSData;
    }
    
    NSMutableDictionary *retDic = [NSMutableDictionary dictionaryWithCapacity:3];
    NSArray *subArr = [queryString componentsSeparatedByString:@"&"];
    for (NSString *subStr in subArr) {
        NSArray *arr = [subStr componentsSeparatedByString:@"="];
        if (arr.count == 2) {
            NSString *key = arr[0];
            key = [key stringByRemovingPercentEncoding];
            
            NSString *value = arr[1];
            value = [value stringByRemovingPercentEncoding];
            
            [retDic setObject:value forKey:key];
        }
    }
    
    NSDictionary *queryDic = [NSDictionary dictionaryWithDictionary:retDic];
    NSString *dataBase64Str = [queryDic objectForKey:kCodeInstallPrefixForHandleURL];
    if (dataBase64Str == nil) {
        return defaultXSData;
    }
    
    NSData *base64DecodeData = [[NSData alloc] initWithBase64EncodedString:dataBase64Str options:0];
    
    NSString *base64DecodeString = [[NSString alloc] initWithData:base64DecodeData encoding:NSUTF8StringEncoding];
    [[CodeInstallLog shard] MPLog:base64DecodeString];
    
    NSError *jsonSError = nil;
    NSDictionary *xDic = [NSJSONSerialization JSONObjectWithData:base64DecodeData options:NSJSONReadingAllowFragments error:&jsonSError];
    
    if (jsonSError) {
        return defaultXSData;
    }
    
    if (!xDic) {
        return defaultXSData;
    }
    
    NSDictionary *pbData = [xDic objectForKey:@"data"];
    NSString *channelNo = [xDic objectForKey:@"channelNo"];
    
    CodeInstallData *appData = [[CodeInstallData alloc] init];
    appData.channelNo = channelNo;
    appData.data = pbData;
    
    return appData;
}

/// 上报打开时间段
/// @param periodArr 时间段数组
+ (void)appEventWithPeriodArr:(NSArray *)periodArr{
    
    NSError *error = nil;
    NSData *jsonData = nil;
    jsonData = [NSJSONSerialization dataWithJSONObject:periodArr options:NSJSONWritingFragmentsAllowed error:&error];
    if ([jsonData length] == 0 || error != nil) {
    }
    NSString *onlineTimeStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    NSString *logStr = [NSString stringWithFormat:@"\n发送时间段:\n%@\n",onlineTimeStr];
    [[CodeInstallLog shard] MPLog:logStr];
    
    NSString *installID = [CodeInstallSDK getInstallIDFromKeyChainThenPlist];
    installID = installID ? installID : @"";
    
    //活跃接口：online_times，二维数组json结构字符串[[start_time(时间戳10位，精确到秒),end_time],......]
    NSDictionary *params = @{
        @"installId": installID,
        @"action": @"statistic_app_event_info",
        @"online_times":onlineTimeStr
    };
    
    [CodeInstallNetwork postParams:params completionHandler:^(NSDictionary *retDic) {
        if (codeInstallAppEndTime == 0) {
            // 30秒倒计时发送
            [CodeInstallUtils removeAllTimeIntervalPeriodInUserDefaultWithKey:kCodeInstallAllTimeIntervalPeriod];
        }
        
        if (codeInstallAppEndTime > 0) {
            // > 35秒 主动发送
        }
        
        
    } failedHandler:^(NSError *error) {
        if (codeInstallAppEndTime == 0) {
            // 30秒倒计时发送
        }
        
        if (codeInstallAppEndTime > 0) {
            // > 35秒 主动发送
            [CodeInstallUtils addPeriodToUserDefaultsWithKey:kCodeInstallAllTimeIntervalPeriod startTime:codeInstallAppStartTime endTime:codeInstallAppEndTime];
        }
    }];
    
}

#pragma mark: -  处理程序失活和启动

+(void)handleApplicationLifeCycle{
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        [CodeInstallSDK applicationBecomeActive];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillResignActiveNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        [CodeInstallSDK applicationResignActive];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidEnterBackgroundNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        [CodeInstallSDK applicationDidEnterBackgroundNotification];
    }];
}

static long codeInstallAppStartTime = 0;
static long codeInstallAppEndTime = 0;

/// 程序激活
+ (void)applicationBecomeActive{
    [[CodeInstallLog shard] MPLog:@"\n*** 程序激活\n"];
    codeInstallAppStartTime = [CodeInstallUtils timeStamp];
    codeInstallAppEndTime = 0;
    
    [[CodeInstallTimer shared] startTimer:30 callback:^{
        [[CodeInstallLog shard] MPLog:@"\n*** 30秒倒计时结束\n"];
        
        //检查本地是否有之前产生的未发送的时间段
        NSArray *allExitTimePeriodArr = [CodeInstallUtils getAllTimeIntervalPeriodInUserDefaultWithKey:kCodeInstallAllTimeIntervalPeriod];
        if (allExitTimePeriodArr != nil && allExitTimePeriodArr.count > 0) {
            [[CodeInstallLog shard] MPLog:@"\n*** 30秒检查,之前有时间段未发送,开始发送\n"];
            [CodeInstallSDK appEventWithPeriodArr:allExitTimePeriodArr];
        }
    }];
}

/// 程序失活
+ (void)applicationResignActive{
    [[CodeInstallLog shard] MPLog:@"\n*** 程序失活\n"];
    
    codeInstallAppEndTime = [CodeInstallUtils timeStamp];
    
    [[CodeInstallTimer shared] stopTimer];
    
    long timeInterval = codeInstallAppEndTime - codeInstallAppStartTime;
    if (timeInterval <= 0.5) {return;}
    
    if (timeInterval < 35) {
        [[CodeInstallLog shard] MPLog:@"\n*** 本次打开时间小于35秒,把本次时间保存到本地\n"];
        [CodeInstallUtils addPeriodToUserDefaultsWithKey:kCodeInstallAllTimeIntervalPeriod startTime:codeInstallAppStartTime endTime:codeInstallAppEndTime];
    }else{
        [[CodeInstallLog shard] MPLog:@"\n*** 本次打开时间大于35秒,向后台发送本次打开时间\n"];
        
        NSArray *nowPeriod = @[[NSNumber numberWithLong:codeInstallAppStartTime],[NSNumber numberWithLong:codeInstallAppEndTime]];
        [CodeInstallSDK appEventWithPeriodArr:@[nowPeriod]];
    }
}

+ (void)applicationDidEnterBackgroundNotification{
    
    if([CodeInstallSDK shared].taskId != UIBackgroundTaskInvalid){
        return;
    }
    [CodeInstallSDK shared].taskId =[[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^(void) {
        //当申请的后台时间用完的时候调用这个block
        //此时我们需要结束后台任务，
        //结束后台任务
        [[UIApplication sharedApplication] endBackgroundTask:[CodeInstallSDK shared].taskId];
        [CodeInstallSDK shared].taskId = UIBackgroundTaskInvalid;
    }];
}


@end
