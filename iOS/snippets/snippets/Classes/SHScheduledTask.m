//
//  SHPeriodicTask.m
//  snippets
//
//  Created by Sumant Hanumante on 05/08/15.
//  Copyright (c) 2015 sumant. All rights reserved.
//

#import "SHScheduledTask.h"

@interface SHScheduledTask ()

@property (nonatomic, strong) dispatch_source_t timer;
@property (nonatomic) NSTimeInterval currentPeriod;
@property (nonatomic, copy) TaskBlock block;
@property (nonatomic) dispatch_queue_t queue;

- (void)startTask;

@end

@implementation SHScheduledTask

- (id)initWithBlock:(TaskBlock)block
  withPeriodSeconds:(NSTimeInterval)period
            onQueue:(dispatch_queue_t)queue
  afterDelaySeconds:(NSTimeInterval)delay {
    self = [super init];
    if (self) {
        _block = block;
        _currentPeriod = period;
        _queue = queue;
        _timer = getDispatchTimer(period, delay, queue, block, self);
    }
    return self;
}

- (void)dealloc {
    [self cancel];
}

//----------------------------------------------------------------------------------------
#pragma mark - public scheduling helpers
//----------------------------------------------------------------------------------------

+ (SHScheduledTask *)scheduleBlock:(TaskBlock)block
                 withPeriodSeconds:(NSTimeInterval)period
                           onQueue:(dispatch_queue_t)queue
                 afterDelaySeconds:(NSTimeInterval)delay {
    SHScheduledTask *task = [[SHScheduledTask alloc]
                             initWithBlock:block
                             withPeriodSeconds:period
                             onQueue:queue
                             afterDelaySeconds:delay];
    [task startTask];
    return task;
}

+ (SHScheduledTask *)scheduleBlock:(void (^)(void))block
                           onQueue:(dispatch_queue_t)queue
                 afterDelaySeconds:(NSTimeInterval)delay {
    TaskBlock oneTimeBlock = ^void(SHScheduledTask *task) {
        block();
        [task cancel];
    };
    SHScheduledTask *task = [[SHScheduledTask alloc]
                             initWithBlock:oneTimeBlock
                             withPeriodSeconds:INT_MAX
                             onQueue:queue
                             afterDelaySeconds:delay];
    [task startTask];
    return task;
}

//----------------------------------------------------------------------------------------
#pragma mark - private methods
//----------------------------------------------------------------------------------------

- (void)startTask {
    dispatch_resume(_timer);
}

- (NSTimeInterval)getPeriod {
    return self.currentPeriod;
}

- (void)updatePeriod:(NSTimeInterval)newPeriod {
    @synchronized(self) {
        if (self.currentPeriod == newPeriod) {
            return;
        }
        dispatch_source_cancel(self.timer);
        self.timer = getDispatchTimer(newPeriod, 0, self.queue, self.block, self);
        dispatch_resume(self.timer);
        self.currentPeriod = newPeriod;
    }
}

- (void)cancel {
    @synchronized(self) {
        if (nil == _timer) {
            return;
        }
        dispatch_source_cancel(_timer);
        _timer = nil;
        _block = nil;
        _queue = nil;
    }
}

- (BOOL)isCancelled {
    @synchronized(self) {
        return nil == self.timer;
    }
}

# pragma mark - timer creator helpers

dispatch_source_t getDispatchTimer(NSTimeInterval interval,
                                   NSTimeInterval delay,
                                   dispatch_queue_t queue,
                                   TaskBlock block,
                                   id self) {
    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER,
                                                     0, 0, queue);
    if (timer) {
        dispatch_source_set_timer(timer,
                                  dispatch_walltime(NULL, delay * NSEC_PER_SEC),
                                  interval * NSEC_PER_SEC,
                                  1 * NSEC_PER_SEC /* leeway */);
        SHScheduledTask __weak *weakSelf = self;
        dispatch_source_set_event_handler(timer, ^{ block(weakSelf); });
    }
    return timer;
}

@end
