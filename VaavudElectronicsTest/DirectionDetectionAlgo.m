//
//  DirectionDetectionAlgo.m
//  VaavudElectronicsTest
//
//  Created by Andreas Okholm on 11/06/14.
//  Copyright (c) 2014 Vaavud. All rights reserved.
//

#import "DirectionDetectionAlgo.h"
#import "vaavudViewController.h"


@interface DirectionDetectionAlgo() {
    
    unsigned long totalTickCounter;
    
    unsigned int tickCounter;
    unsigned int tickBufferCounter;
    
    unsigned long totalSampleCount[TICKS_PR_REV];
    int mvgSampleCountSum[TICKS_PR_REV];
    int sampleCountBuffer[TICKS_PR_REV][SAMPLE_BUFFER_SIZE];
    
    float mvgRelativeSpeed[TICKS_PR_REV];
    double nextRefreshTime;
    
    BOOL startLocated;
    int lastSample;
    
    // compensation[TICKS_PR_REV];
    
}

@property (weak, nonatomic) id<DirectionRecieverDelegate> dirDelegate;
- (void) printStatus;
- (void) updateNextRefreshTime;

@end




@implementation DirectionDetectionAlgo


float compensation[TICKS_PR_REV] = {1.036139713,1.050774403,1.055187509,1.062085179,1.062860154,1.066879081,1.068977472,1.067596821,1.059609302,0.666717504};



#pragma mark - Initialization
-(id)init {
    return [self initWithDirDelegate:NULL];
}

- (id) initWithDirDelegate:(id<DirectionRecieverDelegate>)delegate {
    
    self = [super init];
    
    self.dirDelegate = delegate;
    
    nextRefreshTime = CACurrentMediaTime();
    
    startLocated = false;
    
    return self;
}


- (void) locateStart:(int)samples{
    if (samples > 1.48 * lastSample && samples < 1.6 * lastSample) {
        startLocated = true;
    }
    else {
        lastSample = samples;
    }
    
    
}

- (void) newTick:(int)samples {
    
    
    if ( samples > 13200 ) { // less than 1/3 Hz
        startLocated = false;
    }
    
    if (!startLocated) {
        [self locateStart:samples];
        return;
    }
    
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
        
        if (tickBufferCounter == SAMPLE_BUFFER_SIZE-1) {
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
    if (nextRefreshTime - UPDATE_INTERVAL < CACurrentMediaTime()) {
        nextRefreshTime = CACurrentMediaTime() + UPDATE_INTERVAL;
    }
    else {
        nextRefreshTime += UPDATE_INTERVAL;
    }
}


- (void) printStatus {
    NSLog(@"BufferRotation");
    
}

- (void) updateUI {
    [self.dirDelegate newSpeed: [[NSNumber alloc] initWithUnsignedLong:totalTickCounter]];
    
    int totalMvgSampleCount = 0;
    
    for (int i = 0; i < TICKS_PR_REV; i++) {
        totalMvgSampleCount += mvgSampleCountSum[i];
    }
    
    float avgMvgSampleCount = totalMvgSampleCount / ((float) TICKS_PR_REV);
    
    for (int i = 0; i < TICKS_PR_REV; i++) {
        float mvgRelativeTimeUse = mvgSampleCountSum[i] / avgMvgSampleCount;
        
        mvgRelativeSpeed[i] = mvgRelativeTimeUse * compensation[i];
    }
    
    // See the Thread Safety warning above, but in a nutshell these callbacks happen on a separate audio thread. We wrap any UI updating in a GCD block on the main thread to avoid blocking that audio flow.
    dispatch_async(dispatch_get_main_queue(),^{
        [self.dirDelegate newAngularVelocities: mvgRelativeSpeed andLength:TICKS_PR_REV];
    });
    
    
}


@end
