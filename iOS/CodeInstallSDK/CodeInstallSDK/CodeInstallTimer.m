

#import "CodeInstallTimer.h"

@interface CodeInstallTimer ()

@property (nonatomic, strong) NSTimer * timer;
@property (nonatomic, copy) void (^timerFireCallback)(void);

@end


@implementation CodeInstallTimer

+ (instancetype)shared{
    static CodeInstallTimer *instance = nil ;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (instance == nil) {
            instance = [[CodeInstallTimer alloc]init];
        }
    });
    return instance;
}

- (instancetype)init{
    self = [super init];
    if (!self){
        if (_timer)
        {
            [_timer invalidate];
            _timer = nil;
        }
    }
    return self;
}

- (void)startTimer: (NSTimeInterval)seconds callback:(void (^)(void))callBackHandler{
    self.timerFireCallback = callBackHandler;
    
    if (_timer)
    {
        [_timer invalidate];
        _timer = nil;
    }
    
    _timer = [NSTimer scheduledTimerWithTimeInterval:seconds
                                              target:self
                                            selector:@selector(onTimer:)
                                            userInfo:nil
                                             repeats:NO];
}

- (void)stopTimer{
    [_timer invalidate];
    _timer = nil;
}

- (void)onTimer: (NSTimer *)timer{
    if (self.timerFireCallback){
        self.timerFireCallback();
    }
}



@end
