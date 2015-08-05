//
//  SHScheduledTask.h
//  snippets
//
//  Created by Sumant Hanumante on 05/08/15.
//  Copyright (c) 2015 sumant. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SHScheduledTask;
typedef void(^TaskBlock)(SHScheduledTask *);

@interface SHScheduledTask : NSObject

/**
 * Use this method to setup a periodic task which runs on the specified queue.
 *
 * @param block     : The block which would be executed periodically. The block should
 *                    ideally not contain strong references within.
 * @param period    : The period in seconds between consecutive task executions.
 * @param queue     : The queue on which to run the task. Can be the main
 *                    queue or a background queue.
 * @param delay     : The initial delay in seconds before first execution of 'block'
 *
 */
+ (SHScheduledTask *)scheduleBlock:(TaskBlock)block
                 withPeriodSeconds:(NSTimeInterval)period
                           onQueue:(dispatch_queue_t)queue
                 afterDelaySeconds:(NSTimeInterval)delay;

/**
 * Use this method to setup a one-time task which runs on the specified queue.
 *
 * @param block     : The block which would be executed. The block should
 *                    ideally not contain strong references within.
 * @param queue     : The queue on which to run the task. Can be the main
 *                    queue or a background queue.
 * @param delay     : The delay after which 'block' is executed.
 *
 */
+ (SHScheduledTask *)scheduleBlock:(void (^)(void))block
                           onQueue:(dispatch_queue_t)queue
                 afterDelaySeconds:(NSTimeInterval)delay;

// Returns the current interval between consecutive executions of the tasks.
- (NSTimeInterval)getPeriod;

// Updates the interval between consecutive tasks. If a task is already executing
// it is allowed to complete and period is updated only for further executions.
- (void)updatePeriod:(NSTimeInterval)newPeriod;

// Asynchronously cancels the periodic task. If a task is currently executing, it is
// allowed to complete. Once cancelled, a task releases its internal references
// and thus cannot be rerun.
- (void)cancel;

// Returns YES if task is cancelled, NO otherwise
- (BOOL)isCancelled;

@end
