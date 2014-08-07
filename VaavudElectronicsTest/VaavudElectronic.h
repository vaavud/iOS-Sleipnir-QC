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

/* start the audio input/output (and location,heading) and starts sending data */
- (void) start;

/* stop the audio input/output  (and location,heading) and starts sending data */
- (void) stop;

// sets the audioPlot to which buffered raw audio values is send for plotting
- (void) setAudioPlot:(EZAudioPlotGL *) audioPlot;

// Starts the internal soundfile recorder
- (void) startRecording;

// Ends the internal soundfile recorder
- (void) endRecording;

// returns true if recording is active
- (BOOL) isRecording;

// returns the local path of the recording
- (NSURL*) recordingPath;

// returns the local path of the recording
- (NSURL*) summeryPath;

// generate summeryFile
- (void) generateSummeryFile;

// returns the fitcurve used in direction algorithm
- (float *) getFitCurve;

// returns the EdgeAngles for the samples
- (int *) getEdgeAngles;

@end
