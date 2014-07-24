//
//  DirectionDetectionAlgo.m
//  VaavudElectronicsTest
//
//  Created by Andreas Okholm on 11/06/14.
//  Copyright (c) 2014 Vaavud. All rights reserved.
//

#import "DirectionDetectionAlgo.h"
#import "vaavudViewController.h"
//#define TICKS_PR_REV 10
#define TICKS_PR_REV 15
#define SAMPLE_BUFFER_SIZE 150
#define UPDATE_INTERVAL 0.1 // 10 times a second

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
    int tickAngle[TICKS_PR_REV+2]; // add one point in ether end
}

@property (strong, nonatomic) id<VaavudElectronicWindDelegate> dirDelegate;

@end


@implementation DirectionDetectionAlgo


//float compensation[TICKS_PR_REV] = {1.039799138,1.045523707,1.046944848,1.060272909,1.062841846,1.069164251,1.070833422,1.065796962,1.05726205,0.67142769};
float compensation[TICKS_PR_REV] = {1.02127659574468,1.02127659574468,1.02127659574468,1.02127659574468,1.02127659574468,1.02127659574468,1.02127659574468,1.02127659574468,1.02127659574468,1.02127659574468,1.02127659574468,1.02127659574468,1.02127659574468,1.02127659574468,0.774193548387097};

#pragma mark - Initialization
-(id)init {
    return [self initWithDirDelegate:NULL];
}

- (id) initWithDirDelegate:(id<VaavudElectronicWindDelegate>)delegate {
    
    
    self = [super init];
    self.dirDelegate = delegate;
    nextRefreshTime = CACurrentMediaTime();
    startLocated = false;
    
    
    // standard tick
    
//    int stdTickSize = 34;
//    int bigTickSize = 54;
    
    int stdTickSize = 23.5;
    int bigTickSize = 31;
    
    tickAngle[0] = - bigTickSize/2;
    
    
    for (int i = 1; i < TICKS_PR_REV; i++) {
        tickAngle[i] = stdTickSize/2 + stdTickSize*(i-1); // shift array one to the right
    }
    
    tickAngle[TICKS_PR_REV] = tickAngle[0]+360;
    tickAngle[TICKS_PR_REV+1] = tickAngle[1]+360;
    
    for (int i = 0 ; i < TICKS_PR_REV+2; i++) {
        NSLog(@"angle:%d", tickAngle[i]);
    }
    
//    float xout;
//    float yout;
//    [self parableTopx1:0 andx2:1 andx3:4 andy1:0 andy2:2 andy3:0 andxout:&xout andyout:&yout];
//    NSLog(@"x:%f y:%f", xout, yout);
    
    return self;
    
    
}


- (void) locateStart:(int)samples{
    if (samples > 1.2 * lastSample && samples < 1.4 * lastSample) {
        //NSLog(@"StartLocated: Ratio: %f, StartCounter: %d", samples / ((float) lastSample), startCounter);
        
        
        if (startCounter == 2* TICKS_PR_REV) {
            startLocated = true;
        }
        
        if (startCounter % TICKS_PR_REV != 0 || startCounter > 2 * TICKS_PR_REV) {
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

// http://stackoverflow.com/questions/717762/how-to-calculate-the-vertex-of-a-parabola-given-three-points
- (void) parableTopx1:(int)x1 andx2:(int)x2 andx3:(int)x3 andy1:(float)y1 andy2:(float)y2 andy3:(float)y3 andxout:(float*)xout andyout:(float*)yout {
    
    float denom = (x1 - x2) * (x1 - x3) * (x2 - x3);
	float A     = (x3 * (y2 - y1) + x2 * (y1 - y3) + x1 * (y3 - y2)) / denom;
	float B     = (x3*x3 * (y1 - y2) + x2*x2 * (y3 - y1) + x1*x1 * (y2 - y3)) / denom;
	float C     = (x2 * x3 * (x2 - x3) * y1 + x3 * x1 * (x3 - x1) * y2 + x1 * x2 * (x1 - x2) * y3) / denom;
    
	*xout = -B / (2*A);
	*yout = C - B*B / (4*A);
    
}



- (void) updateUI {
    
    // Calculate relative velocities
    int totalMvgSampleCount = 0;
    for (int i = 0; i < TICKS_PR_REV; i++) {
        totalMvgSampleCount += mvgSampleCountSum[i];
    }
    
    float avgMvgSampleCount = totalMvgSampleCount / ((float) TICKS_PR_REV);
    
    for (int i = 0; i < TICKS_PR_REV; i++) {
        float mvgRelativeTimeUse = mvgSampleCountSum[i] / avgMvgSampleCount;
        
        mvgRelativeSpeed[i] = mvgRelativeTimeUse * compensation[i];
    }
    
    // Calculate velocity for last revolution
    int samplesPrLastRotation =0;
    for (int i = 0; i < TICKS_PR_REV; i++) {
        samplesPrLastRotation += sampleCountBuffer[i][lastTickBufferCounter];
    }
    float windSpeed = 44100 / ((float)samplesPrLastRotation);
    
    // Calculate Angle of slowest movement
    // find slowest rotationspeed (highest mvgSampleCount)
    int index =0;
    float max = 0;
    for (int i = 0; i < TICKS_PR_REV; i++) {
        if (mvgRelativeSpeed[i] > max) {
            max = mvgRelativeSpeed[i];
            index = i;
        }
    }
    
    
    float xout;
    float yout;
    
    
    // notice index (x) is shifted by to the right, and Y is allowed to wrap around
    [self parableTopx1:tickAngle[index] andx2:tickAngle[index+1] andx3:tickAngle[index+2] andy1:mvgRelativeSpeed[(index-1)%TICKS_PR_REV] andy2:mvgRelativeSpeed[index] andy3:mvgRelativeSpeed[(index+1)%TICKS_PR_REV] andxout:&xout andyout:&yout];
    
   
    
    NSLog(@"index: %d x:%f y:%f", index, [self correctAngle:xout], yout);
    
    
    // See the Thread Safety warning above, but in a nutshell these callbacks happen on a separate audio thread. We wrap any UI updating in a GCD block on the main thread to avoid blocking that audio flow.
    dispatch_async(dispatch_get_main_queue(),^{
        [self.dirDelegate newWindAngleLocal:[self correctAngle:xout]];
        
        // wrap mvgRelativeSpeed in Array
        NSMutableArray *angularVelocities = [[NSMutableArray alloc] initWithCapacity:TICKS_PR_REV];
        
        for (int i = 0; i < TICKS_PR_REV; i++) {
            [angularVelocities addObject: [NSNumber numberWithFloat: mvgRelativeSpeed[i]]];
        }
        
        [self.dirDelegate newAngularVelocities: angularVelocities];
        [self.dirDelegate newAngularVelocities: mvgRelativeSpeed andLength:TICKS_PR_REV];
        [self.dirDelegate newSpeed: [NSNumber numberWithFloat:windSpeed]];
    });
    
}

- (float) correctAngle:(float) angle {
    if (angle < 0) {
        angle += 360;
    }
    else if (angle > 360) {
        angle -= 360;
    }
    return angle;
}


@end
