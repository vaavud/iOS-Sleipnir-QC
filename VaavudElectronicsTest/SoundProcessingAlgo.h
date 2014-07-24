//
//  soundProcessing.h
//  VaavudElectronicsTest
//
//  Created by Andreas Okholm on 09/06/14.
//  Copyright (c) 2014 Vaavud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VaavudElectronicWindDelegate.h"
#import "DirectionDetectionAlgo.h"

@interface SoundProcessingAlgo : NSObject


@property (strong, nonatomic) DirectionDetectionAlgo *dirDetectionAlgo;

- (void) newSoundData:(int *)data bufferLength:(UInt32) bufferLength;
- (id)initWithDirDelegate:(id<VaavudElectronicWindDelegate>)delegate;

@end
