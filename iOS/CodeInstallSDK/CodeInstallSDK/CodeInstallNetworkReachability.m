
#import "CodeInstallNetworkReachability.h"
#if !TARGET_OS_WATCH

#import <netinet/in.h>
#import <netinet6/in6.h>
#import <arpa/inet.h>
#import <ifaddrs.h>
#import <netdb.h>

NSString * const CodeInstallReachabilityDidChangeNotification = @"com.alamofire.CodeInstallnetworking.reachability.change";
NSString * const CodeInstallReachabilityNotificationStatusItem = @"CodeInstallNetworkingReachabilityNotificationStatusItem";

typedef void (^CodeInstallReachabilityStatusBlock)(CodeInstallNetworkReachabilityStatus status);
typedef CodeInstallReachabilityManager * (^CodeInstallReachabilityStatusCallback)(CodeInstallNetworkReachabilityStatus status);

NSString * CodeInstallStringFromNetworkReachabilityStatus(CodeInstallNetworkReachabilityStatus status) {
    switch (status) {
        case NotReachable:
            return NSLocalizedStringFromTable(@"Not Reachable", @"CodeInstallNetworking", nil);
        case ReachableViaWWAN:
            return NSLocalizedStringFromTable(@"Reachable via WWAN", @"CodeInstallNetworking", nil);
        case ReachableViaWiFi:
            return NSLocalizedStringFromTable(@"Reachable via WiFi", @"CodeInstallNetworking", nil);
        case Unknown:
        default:
            return NSLocalizedStringFromTable(@"Unknown", @"CodeInstallNetworking", nil);
    }
}

static CodeInstallNetworkReachabilityStatus CodeInstallReachabilityStatusForFlags(SCNetworkReachabilityFlags flags) {
    BOOL isReachable = ((flags & kSCNetworkReachabilityFlagsReachable) != 0);
    BOOL needsConnection = ((flags & kSCNetworkReachabilityFlagsConnectionRequired) != 0);
    BOOL canConnectionAutomatically = (((flags & kSCNetworkReachabilityFlagsConnectionOnDemand ) != 0) || ((flags & kSCNetworkReachabilityFlagsConnectionOnTraffic) != 0));
    BOOL canConnectWithoutUserInteraction = (canConnectionAutomatically && (flags & kSCNetworkReachabilityFlagsInterventionRequired) == 0);
    BOOL isNetworkReachable = (isReachable && (!needsConnection || canConnectWithoutUserInteraction));

    CodeInstallNetworkReachabilityStatus status = Unknown;
    if (isNetworkReachable == NO) {
        status = NotReachable;
    }
#if	TARGET_OS_IPHONE
    else if ((flags & kSCNetworkReachabilityFlagsIsWWAN) != 0) {
        status = ReachableViaWWAN;
    }
#endif
    else {
        status = ReachableViaWiFi;
    }

    return status;
}

/**
 * Queue a status change notification for the main thread.
 *
 * This is done to ensure that the notifications are received in the same order
 * as they are sent. If notifications are sent directly, it is possible that
 * a queued notification (for an earlier status condition) is processed after
 * the later update, resulting in the listener being left in the wrong state.
 */
static void CodeInstallAFPostReachabilityStatusChange(SCNetworkReachabilityFlags flags, CodeInstallReachabilityStatusCallback block) {
    CodeInstallNetworkReachabilityStatus status = CodeInstallReachabilityStatusForFlags(flags);
    dispatch_async(dispatch_get_main_queue(), ^{
        CodeInstallReachabilityManager *manager = nil;
        if (block) {
            manager = block(status);
        }
        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        NSDictionary *userInfo = @{ CodeInstallReachabilityNotificationStatusItem: @(status) };
        [notificationCenter postNotificationName:CodeInstallReachabilityDidChangeNotification object:manager userInfo:userInfo];
    });
}

static void CodeInstallReachabilityCallback(SCNetworkReachabilityRef __unused target, SCNetworkReachabilityFlags flags, void *info) {
    CodeInstallAFPostReachabilityStatusChange(flags, (__bridge CodeInstallReachabilityStatusCallback)info);
}


static const void * CodeInstallReachabilityRetainCallback(const void *info) {
    return Block_copy(info);
}

static void CodeInstallReachabilityReleaseCallback(const void *info) {
    if (info) {
        Block_release(info);
    }
}

@interface CodeInstallReachabilityManager ()
@property (readonly, nonatomic, assign) SCNetworkReachabilityRef networkReachability;
@property (readwrite, nonatomic, assign) CodeInstallNetworkReachabilityStatus networkReachabilityStatus;
@property (readwrite, nonatomic, copy) CodeInstallReachabilityStatusBlock networkReachabilityStatusBlock;
@end

@implementation CodeInstallReachabilityManager

+ (instancetype)sharedManager {
    static CodeInstallReachabilityManager *_sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedManager = [self manager];
    });

    return _sharedManager;
}

+ (instancetype)managerForDomain:(NSString *)domain {
    SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithName(kCFAllocatorDefault, [domain UTF8String]);

    CodeInstallReachabilityManager *manager = [[self alloc] initWithReachability:reachability];
    
    CFRelease(reachability);

    return manager;
}

+ (instancetype)managerForAddress:(const void *)address {
    SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, (const struct sockaddr *)address);
    CodeInstallReachabilityManager *manager = [[self alloc] initWithReachability:reachability];

    CFRelease(reachability);
    
    return manager;
}

+ (instancetype)manager
{
#if (defined(__IPHONE_OS_VERSION_MIN_REQUIRED) && __IPHONE_OS_VERSION_MIN_REQUIRED >= 90000) || (defined(__MAC_OS_X_VERSION_MIN_REQUIRED) && __MAC_OS_X_VERSION_MIN_REQUIRED >= 101100)
    struct sockaddr_in6 address;
    bzero(&address, sizeof(address));
    address.sin6_len = sizeof(address);
    address.sin6_family = AF_INET6;
#else
    struct sockaddr_in address;
    bzero(&address, sizeof(address));
    address.sin_len = sizeof(address);
    address.sin_family = AF_INET;
#endif
    return [self managerForAddress:&address];
}

- (instancetype)initWithReachability:(SCNetworkReachabilityRef)reachability {
    self = [super init];
    if (!self) {
        return nil;
    }

    _networkReachability = CFRetain(reachability);
    self.networkReachabilityStatus = Unknown;

    return self;
}

- (instancetype)init
{
    @throw [NSException exceptionWithName:NSGenericException
                                   reason:@"`-init` unavailable. Use `-initWithReachability:` instead"
                                 userInfo:nil];
    return nil;
}

- (void)dealloc {
    [self stopMonitoring];
    
    if (_networkReachability != NULL) {
        CFRelease(_networkReachability);
    }
}

#pragma mark -

- (BOOL)isReachable {
    return [self isReachableViaWWAN] || [self isReachableViaWiFi];
}

- (BOOL)isReachableViaWWAN {
    return self.networkReachabilityStatus == ReachableViaWWAN;
}

- (BOOL)isReachableViaWiFi {
    return self.networkReachabilityStatus == ReachableViaWiFi;
}

#pragma mark -

- (void)startMonitoring {
    [self stopMonitoring];

    if (!self.networkReachability) {
        return;
    }

    __weak __typeof(self)weakSelf = self;
    CodeInstallReachabilityStatusCallback callback = ^(CodeInstallNetworkReachabilityStatus status) {
        __strong __typeof(weakSelf)strongSelf = weakSelf;

        strongSelf.networkReachabilityStatus = status;
        if (strongSelf.networkReachabilityStatusBlock) {
            strongSelf.networkReachabilityStatusBlock(status);
        }
        
        return strongSelf;
    };

    SCNetworkReachabilityContext context = {0, (__bridge void *)callback, CodeInstallReachabilityRetainCallback, CodeInstallReachabilityReleaseCallback, NULL};
    SCNetworkReachabilitySetCallback(self.networkReachability, CodeInstallReachabilityCallback, &context);
    SCNetworkReachabilityScheduleWithRunLoop(self.networkReachability, CFRunLoopGetMain(), kCFRunLoopCommonModes);

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),^{
        SCNetworkReachabilityFlags flags;
        if (SCNetworkReachabilityGetFlags(self.networkReachability, &flags)) {
            CodeInstallAFPostReachabilityStatusChange(flags, callback);
        }
    });
}

- (void)stopMonitoring {
    if (!self.networkReachability) {
        return;
    }

    SCNetworkReachabilityUnscheduleFromRunLoop(self.networkReachability, CFRunLoopGetMain(), kCFRunLoopCommonModes);
}

#pragma mark -

- (NSString *)localizedNetworkReachabilityStatusString {
    return CodeInstallStringFromNetworkReachabilityStatus(self.networkReachabilityStatus);
}

#pragma mark -

- (void)setReachabilityStatusChangeBlock:(void (^)(CodeInstallNetworkReachabilityStatus status))block {
    self.networkReachabilityStatusBlock = block;
}

#pragma mark - NSKeyValueObserving

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
    if ([key isEqualToString:@"reachable"] || [key isEqualToString:@"reachableViaWWAN"] || [key isEqualToString:@"reachableViaWiFi"]) {
        return [NSSet setWithObject:@"networkReachabilityStatus"];
    }

    return [super keyPathsForValuesAffectingValueForKey:key];
}

@end
#endif
