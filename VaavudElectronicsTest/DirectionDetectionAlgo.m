//
//  DirectionDetectionAlgo.m
//  VaavudElectronicsTest
//
//  Created by Andreas Okholm on 11/06/14.
//  Copyright (c) 2014 Vaavud. All rights reserved.
//

#import "DirectionDetectionAlgo.h"

#define SAMPLE_BUFFER 90
#define TICKS_PR_REV 10
#define updateInterval 0.1 // 10 times a second

@interface DirectionDetectionAlgo() {
    
    unsigned long totalTickCounter;
    
    unsigned int tickCounter;
    unsigned int tickBufferCounter;
    
    unsigned long totalSampleCount[TICKS_PR_REV];
    int mvgSampleCountSum[TICKS_PR_REV];
    int sampleCountBuffer[TICKS_PR_REV][SAMPLE_BUFFER];
    double nextRefreshTime;
    
}

@property (weak, nonatomic) id<DirectionRecieverDelegate> dirDelegate;
- (void) printStatus;
- (void) updateNextRefreshTime;

@end




@implementation DirectionDetectionAlgo



#pragma mark - Initialization
-(id)init {
    return [self initWithDirDelegate:NULL];
}

- (id) initWithDirDelegate:(id<DirectionRecieverDelegate>)delegate {
    
    self = [super init];
    
    self.dirDelegate = delegate;
    
    nextRefreshTime = CACurrentMediaTime();
    
    return self;
}


- (void) newTick:(int)samples {
    
    totalTickCounter++;
    
    // Moving Avg subtract
    mvgSampleCountSum[tickCounter] -= sampleCountBuffer[tickCounter][tickBufferCounter];
    
    // Moving avg Update buffer value
    sampleCountBuffer[tickCounter][tickBufferCounter] = samples;
    
    // Moving Avg update SUM
    mvgSampleCountSum[tickCounter] += samples;

    // Total SampleCount
    totalSampleCount[tickCounter] += samples;
    
    
    
    if (tickCounter == TICKS_PR_REV-1) {
        tickCounter = 0;
        
        if (tickBufferCounter == SAMPLE_BUFFER-1) {
            tickBufferCounter = 0;
            [self updateUI];
        } else {
            tickBufferCounter++;
        }
    } else {
        tickCounter++;
    }
    
    
    if (CACurrentMediaTime() > nextRefreshTime) {
        [self updateUI];
        [self updateNextRefreshTime];
    }
    
    
}

- (void) updateNextRefreshTime {
    if (nextRefreshTime - updateInterval < CACurrentMediaTime()) {
        nextRefreshTime = CACurrentMediaTime() + updateInterval;
    }
    else {
        nextRefreshTime += updateInterval;
    }
}


- (void) printStatus {
    NSLog(@"BufferRotation");
    
}

- (void) updateUI {
    [self.dirDelegate newSpeed: [[NSNumber alloc] initWithUnsignedLong:totalTickCounter]];
}


@end
