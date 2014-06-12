//
//  vaavudViewController.h
//  VaavudElectronicsTest
//
//  Created by Andreas Okholm on 04/06/14.
//  Copyright (c) 2014 Vaavud. All rights reserved.
//

#import <UIKit/UIKit.h>
// Import EZAudio header
#import "EZAudio.h"
#import "DirectionDetectionAlgo.h"

// By default this will record a file to the application's documents directory (within the application's sandbox)
#define kAudioFilePath @"EZAudioTest.m4a"
//#define kAudioFilePath @"EZAudioTest.wav"

#define SAMPLE_BUFFER_SIZE 90
#define TICKS_PR_REV 10
#define UPDATE_INTERVAL 0.1 // 10 times a second


@interface vaavudViewController : UIViewController <DirectionRecieverDelegate>

/**
 Use a OpenGL based plot to visualize the data coming in
 */
@property (nonatomic,weak) IBOutlet EZAudioPlotGL *audioPlot;

/**
 The microphone component
 */
@property (nonatomic,strong) EZMicrophone *microphone;

/**
 The recorder component
 */
@property (nonatomic,strong) EZRecorder *recorder;


@end
