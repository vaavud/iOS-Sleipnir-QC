//
//  VAACore2.h
//  VaavudElectronicsTest
//
//  Created by Andreas Okholm on 21/07/14.
//  Copyright (c) 2014 Vaavud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VaavudElectronic.h"
#import "EZAudio.h"


@protocol VaavudElectronicWindDelegate <NSObject>

@optional
- (void) newSpeed: (NSNumber*) speed;
- (void) newWindDirection: (NSNumber*) windDirection;

- (void) vaavudPlugedIn;
- (void) vaavudWasUnpluged;
- (void) notVaavudPlugedIn;
- (void) vaavudStartedMeasureing;
- (void) vaavudStopMeasureing;
//- (void) newAngularVelocities: (NSArray*) angularVelocities;
//- (void) newWindAngleLocal:(NSNumber*) angle;
//- (void) newMaxAmplitude: (NSNumber*) amplitude;
//- (void) newHeading: (NSNumber*) heading;

@end


@protocol VaavudElectronicAnalysisDelegate <NSObject>

@optional
//- (void) newSpeed: (NSNumber*) speed;
- (void) newAngularVelocities: (NSArray*) angularVelocities;
- (void) newWindAngleLocal:(NSNumber*) angle;
- (void) newHeading: (NSNumber*) heading;
- (void) newMaxAmplitude: (NSNumber*) amplitude;

@end



@interface VaavudElectronic : NSObject


+ (VaavudElectronic *) sharedVaavudElec;

/* add listener of heading, windspeed and device information */
- (void) addListener:(id <VaavudElectronicWindDelegate>) delegate;

/* remove listener of heading, windspeed and device information */
- (void) removeListener:(id <VaavudElectronicWindDelegate>) delegate;

/* add listener of analysis information */
- (void) addAnalysisListener:(id <VaavudElectronicAnalysisDelegate>) delegate;

/* remove listener of analysis information */
- (void) removeAnalysisListener:(id <VaavudElectronicAnalysisDelegate>) delegate;

/* start the audio input/output (and location,heading) and starts sending data */
- (void) start;

/* stop the audio input/output  (and location,heading) and stop sending data */
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

// returns the local path of the recording
- (NSURL*) summeryAngularVelocitiesPath;

// generate summeryFile
- (void) generateSummeryFile;

// returns the fitcurve used in direction algorithm
- (float *) getFitCurve;

// returns the EdgeAngles for the samples
- (int *) getEdgeAngles;

// return the current heading of device (if avilale)
- (NSNumber*) getHeading;

@end
