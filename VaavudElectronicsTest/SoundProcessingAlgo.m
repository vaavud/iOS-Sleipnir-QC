//
//  soundProcessing.m
//  VaavudElectronicsTest
//
//  Created by Andreas Okholm on 09/06/14.
//  Copyright (c) 2014 Vaavud. All rights reserved.
//

#import "SoundProcessingAlgo.h"

#include "DirectionDetectionAlgo.h"


@interface SoundProcessingAlgo() {
    int mvgAvg[3];
    int mvgAvgSum;
    int mvgDiff[3];
    int mvgDiffSum;
    int lastValue;
    unsigned long counter;
    unsigned long lastTick;

   
    
    
}

- (BOOL) detectTick;

@property (strong, nonatomic) DirectionDetectionAlgo *dirDetectionAlgo;

@end

@implementation SoundProcessingAlgo



enum detectionState { SeekingHigh, SeekingLow, SeekingTripLow};
enum detectionState dState = SeekingHigh;


int thresholdHigh = 210;
int thresholdLow = 30;
int thresholdPass = -90;


#pragma mark - Initialization
-(id)init {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:@"-init is not a valid initializer for the class SoundProcessingAlgo"
                                 userInfo:nil];
    return nil;
}

- (id)initWithDirDelegate:(id<DirectionRecieverDelegate>)delegate {
    
    self = [super init];
    
    counter = 0;
    mvgAvgSum = 0;
    mvgDiffSum = 0;
    lastValue = 0;
    
    self.dirDetectionAlgo = [[DirectionDetectionAlgo alloc] initWithDirDelegate:delegate];
    
    return self;
}



- (void) newSoundData:(int *)data bufferLength:(UInt32) bufferLength {
   
    for (int i = 0; i < bufferLength; i++) {
        
        int bufferIndex = counter%3;
        
        
        // Moving Avg subtract
        mvgAvgSum -= mvgAvg[bufferIndex];
        // Moving Diff subtrack
        mvgDiffSum -= mvgDiff[bufferIndex];
        
        
        // Moving Diff Update buffer value
        mvgDiff[bufferIndex] = abs( data[i]- mvgAvg[bufferIndex]); // ! need to use old mvgAvgValue so place before mvgAvg update
        // Moving avg Update buffer value
        mvgAvg[bufferIndex] = data[i];
        
        
        // Moving Avg update SUM
        mvgAvgSum += mvgAvg[bufferIndex];
        mvgDiffSum += mvgDiff[bufferIndex];
        
        
        
        if ([self detectTick]) {
            [self.dirDetectionAlgo newTick: (int) (counter - lastTick)];
            
//            NSLog(@"Tick %lu", counter - lastTick);
            lastTick = counter;
        }
        
        counter++;
        
    }
    
//    NSLog(@"counter: %lu", counter);
//    NSLog(@"mvgAvgSum: %d", mvgAvgSum);
//    NSLog(@"mvgDiffSum: %d", mvgDiffSum);
    
}


- (BOOL) detectTick {
    
    switch (dState) {
        case SeekingHigh:
            if (mvgDiffSum > thresholdHigh) {
                dState = SeekingLow;
            }
            break;
        case SeekingLow:
            if (mvgDiffSum < thresholdLow) {
                dState = SeekingTripLow;
            }
            break;
        case SeekingTripLow:
            if (mvgAvgSum < thresholdPass) {
                dState = SeekingHigh;
                return true;
            }
        default:
            break;
    }
    
    return false;
    
}



@end
