//
//  soundManager.h
//  VaavudElectronicsTest
//
//  Created by Andreas Okholm on 21/07/14.
//  Copyright (c) 2014 Vaavud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VaavudElectronicWindDelegate.h"

// Import EZAudio header
#import "EZAudio.h"

// By default this will record a file to the application's documents directory (within the application's sandbox)
#define kAudioFilePath @"EZAudioTest.m4a"
//#define kAudioFilePath @"EZAudioTest.wav"



@interface AudioManager : NSObject

- (void) start;
- (void) stop;
- (id) initWithDirDelegate:(id<VaavudElectronicWindDelegate>)delegate;
- (void) toggleMicrophone:(bool) micOn;

@property (weak, nonatomic) EZAudioPlotGL *audioPlot;

// Starts the internal soundfile recorder
- (void) startRecording;

// Ends the internal soundfile recorder
- (void) endRecording;

// returns true if recording is active
- (BOOL) isRecording;

// returns the local path of the recording
- (NSURL*) recordingPath;


@end
