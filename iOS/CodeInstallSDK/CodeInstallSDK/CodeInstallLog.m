#import "CodeInstallLog.h"
#import "CodeInstallConfig.h"

@implementation CodeInstallLog

static CodeInstallLog* instance = nil;

+(CodeInstallLog *) shard{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc]init];
        instance.logStrAll = [NSMutableString string];
    });
    
    return instance;
}

- (void)MPLog:(NSString *)msg{
    [self.logStrAll appendString:msg];
    
    NSDictionary *infoDic = [NSBundle mainBundle].infoDictionary;
    bool IsPrint=[(NSNumber*)[infoDic objectForKey:@"print_log"] boolValue];
    if (IsPrint) {
        printf("%s", [msg cStringUsingEncoding:NSUTF8StringEncoding]);
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5* NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:kCodeInstallUpdateLogNotification object:nil];
    });
}


@end
