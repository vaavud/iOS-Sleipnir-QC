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
    unsigned int lastTickBufferCounter;
    unsigned int startCounter;
    
    unsigned long totalSampleCount[TICKS_PR_REV];
    int mvgSampleCountSum[TICKS_PR_REV];
    int sampleCountBuffer[TICKS_PR_REV][SAMPLE_BUFFER_SIZE];
    float mvgRelativeSpeed[TICKS_PR_REV];
    double nextRefreshTime;
    BOOL startLocated;
    int lastSample;
}

@property (weak, nonatomic) id<DirectionRecieverDelegate> dirDelegate;
- (void) printStatus;
- (void) updateNextRefreshTime;
- (void) resetDirection;

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
    if (samples > 1.4 * lastSample && samples < 1.7 * lastSample) {
        NSLog(@"StartLocated: Ratio: %f, StartCounter: %d", samples / ((float) lastSample), startCounter);
        
        
        if (startCounter == 2* TICKS_PR_REV) {
            startLocated = true;
        }
        
        if (startCounter % TICKS_PR_REV != 0) {
            startCounter = 0;
        }
        
    }
    else {
        lastSample = samples;
    }
    
    startCounter++;
    
}

- (void) newTick:(int)samples {
    
    // recalibrate if pattern is wrong
    if (samples > 882000) {
        [self resetDirection];
        NSLog(@"reset: Samplet over 882000");
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
    
    
    lastTickBufferCounter = tickBufferCounter;
    
    
    if (tickCounter == TICKS_PR_REV-1) {
        tickCounter = 0;
        
        // check if directionReset is needed every rotation
        
        if (samples < 1.2 * lastSample || samples > 2.0 * lastSample) {
            NSLog(@"Out of ratio: %f", samples / ((float) lastSample));
            [self resetDirection];
            return;
        }
        
        // update results
        if (CACurrentMediaTime() > nextRefreshTime) {
            [self updateUI];
            [self updateNextRefreshTime];
        }
        
        
        
        if (tickBufferCounter == SAMPLE_BUFFER_SIZE-1) {
            tickBufferCounter = 0;
            [self updateUI];
        } else {
            tickBufferCounter++;
        }
    } else {
        tickCounter++;
    }
    
    lastSample = samples;
    
}

- (void) updateNextRefreshTime {
    if (nextRefreshTime - UPDATE_INTERVAL < CACurrentMediaTime()) {
        nextRefreshTime = CACurrentMediaTime() + UPDATE_INTERVAL;
    }
    else {
        nextRefreshTime += UPDATE_INTERVAL;
    }
}


- (void) resetDirection {
    
    NSLog(@"reset");
    startLocated = false;
    lastSample = 0;
    
    
    tickCounter = 0;
    tickBufferCounter = 0;
    
    // unsigned long totalSampleCount[TICKS_PR_REV];
    // int mvgSampleCountSum[TICKS_PR_REV];
    // float mvgRelativeSpeed[TICKS_PR_REV]; does not need clearing!
    for (int i = 0; i < TICKS_PR_REV; i++) {
        totalSampleCount[i] = 0;
        mvgSampleCountSum[i] = 0;
    }
    
    //int sampleCountBuffer[TICKS_PR_REV][SAMPLE_BUFFER_SIZE];
    
    for (int outer = 0; outer < TICKS_PR_REV; outer++) {
        for (int inner = 0; inner < SAMPLE_BUFFER_SIZE; inner++) {
            sampleCountBuffer[outer][inner] = 0;
        }
    }
    
    // double nextRefreshTime; does not need reset
    

}



- (void) printStatus {
    NSLog(@"BufferRotation");
    
}

- (void) updateUI {
    
    int totalMvgSampleCount = 0;
    
    for (int i = 0; i < TICKS_PR_REV; i++) {
        totalMvgSampleCount += mvgSampleCountSum[i];
    }
    
    float avgMvgSampleCount = totalMvgSampleCount / ((float) TICKS_PR_REV);
    
    for (int i = 0; i < TICKS_PR_REV; i++) {
        float mvgRelativeTimeUse = mvgSampleCountSum[i] / avgMvgSampleCount;
        
        mvgRelativeSpeed[i] = mvgRelativeTimeUse * compensation[i];
    }
    
    
    int samplesPrLastRotation =0;
    
    for (int i = 0; i < TICKS_PR_REV; i++) {
        samplesPrLastRotation += sampleCountBuffer[i][lastTickBufferCounter];
    }
    
    float windSpeed = 44100 / ((float)samplesPrLastRotation);
    
    
    // See the Thread Safety warning above, but in a nutshell these callbacks happen on a separate audio thread. We wrap any UI updating in a GCD block on the main thread to avoid blocking that audio flow.
    dispatch_async(dispatch_get_main_queue(),^{
        [self.dirDelegate newAngularVelocities: mvgRelativeSpeed andLength:TICKS_PR_REV];
        [self.dirDelegate newSpeed: [NSNumber numberWithFloat:windSpeed]];
    });
    
}


@end
