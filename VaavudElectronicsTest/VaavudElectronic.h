//
//  VAACore2.h
//  VaavudElectronicsTest
//
//  Created by Andreas Okholm on 21/07/14.
//  Copyright (c) 2014 Vaavud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VaavudElectronicWindDelegate.h"
#import "EZAudio.h"

@interface VaavudElectronic : NSObject <VaavudElectronicWindDelegate>


+ (VaavudElectronic *) sharedVaavudElec;

/* add listener of heading and windspeed information */
- (void) addListener:(id <VaavudElectronicWindDelegate>) delegate;


/* remove listener of heading and windspeed information */
- (void) removeListener:(id <VaavudElectronicWindDelegate>) delegate;

/* start the audio input/output and starts sending data */
- (void) start;

/* start the audio input/output and starts sending data */
- (void) stop;


- (void) setAudioPlot:(EZAudioPlotGL *) audioPlot;

@end
