//
//  soundProcessing.m
//  VaavudElectronicsTest
//
//  Created by Andreas Okholm on 09/06/14.
//  Copyright (c) 2014 Vaavud. All rights reserved.
//

#import "SoundProcessingAlgo.h"

@interface SoundProcessingAlgo() {
    int mvgAvg[3];
    int mvgAvgSum;
    int mvgDiff[3];
    int mvgDiffSum;
    unsigned long counter;
}

@end

@implementation SoundProcessingAlgo




#pragma mark - Initialization
-(id)init {
    self = [super init];
    
    counter = 0;
    mvgAvgSum = 0;
    mvgDiffSum = 0;
    
    return self;
}




- (void) newSoundData:(int *)data bufferLength:(UInt32) bufferLength {
    
    
    
    for (int i = 0; i < bufferLength; i++) {
        
        
        // Moving Avg
        if (counter > 3) {
            mvgAvgSum -= mvgAvg[counter%3];
        }
        
        mvgAvg[counter%3] = data[i];
        mvgAvgSum += data[i];
        
        
        
        
        // Moving Diff
        if (counter > 3+1) {
            mvgDiffSum -= mvgDiff[counter%3];
        }
        
        mvgDiff[counter%3] = abs( data[i]- data[i-1]);
        mvgDiffSum += mvgDiff[counter%3];
        
        
        
        
        counter++;
    }
    
    NSLog(@"mvgAvgSum: %d", mvgAvgSum);
    NSLog(@"mvgDiffSum: %d", mvgDiffSum);
    
    
    
}



@end
