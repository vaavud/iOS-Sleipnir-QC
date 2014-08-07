//
//  VAACore2.m
//  VaavudElectronicsTest
//
//  Created by Andreas Okholm on 21/07/14.
//  Copyright (c) 2014 Vaavud. All rights reserved.
//

#import "VaavudElectronic.h"
#import "AudioManager.h"
#import "DirectionDetectionAlgo.h"
#import "SummeryGenerator.h"


@interface VaavudElectronic()

@property (strong, atomic) NSMutableArray *VaaElecWindDelegates;
@property (strong, nonatomic) AudioManager *soundManager;
@property (strong, nonatomic) SummeryGenerator *summeryGenerator;

@end

@implementation VaavudElectronic

// initialize sharedObject as nil (first call only)
static VaavudElectronic *sharedInstance = nil;

+ (VaavudElectronic *) sharedVaavudElec {
    // structure used to test whether the block has completed or not
    static dispatch_once_t p = 0;
    
    // executes a block object once and only once for the lifetime of an application
    dispatch_once(&p, ^{
        sharedInstance = [[super allocWithZone:NULL] init];
        [sharedInstance initSingleton];
    });
    
    // returns the same object each time
    return sharedInstance;
}

- (void) initSingleton {
    self.VaaElecWindDelegates = [[NSMutableArray alloc] initWithCapacity:2];
    self.soundManager = [[AudioManager alloc] initWithDirDelegate:self];
    self.summeryGenerator = [[SummeryGenerator alloc] init];
}

+ (id) allocWithZone:(NSZone *)zone {
    //If coder misunderstands this is a singleton, behave properly with
    // ref count +1 on alloc anyway, and still return singleton!
    return [VaavudElectronic sharedVaavudElec];
}



/* add listener of heading and windspeed information */
- (void) addListener:(id <VaavudElectronicWindDelegate>) delegate {
    
    NSArray *array = [self.VaaElecWindDelegates copy];
    
    if ([array containsObject:delegate]) {
        // do nothing
        NSLog(@"trying to add delegate twice");
    } else {
        [self.VaaElecWindDelegates addObject:delegate];
    }
}


/* remove listener of heading and windspeed information */
- (void) removeListener:(id <VaavudElectronicWindDelegate>) delegate {
    NSArray *array = [self.VaaElecWindDelegates copy];
    if ([array containsObject:delegate]) {
        // do nothing
        [self.VaaElecWindDelegates removeObject:delegate];
    } else {
        NSLog(@"trying to remove, which does not excists");
    }
}


- (void) newSpeed: (NSNumber*) speed {
    for (id<VaavudElectronicWindDelegate> delegate in self.VaaElecWindDelegates) {
        [delegate newSpeed: speed];
    }
}

- (void) newAngularVelocities: (NSArray*) angularVelocities {
    for (id<VaavudElectronicWindDelegate> delegate in self.VaaElecWindDelegates) {
        [delegate newAngularVelocities:angularVelocities];
    }
}

- (void) newAngularVelocities: (float*) angularVelocities andLength: (int) length {
    for (id<VaavudElectronicWindDelegate> delegate in self.VaaElecWindDelegates) {
        [delegate newAngularVelocities: angularVelocities andLength: length];
    }
}

- (void) newWindAngleLocal:(float) angle {
    for (id<VaavudElectronicWindDelegate> delegate in self.VaaElecWindDelegates) {
        [delegate newWindAngleLocal: angle];
    }
}

- (void) newMaxAmplitude: (NSNumber*) amplitude {
    for (id<VaavudElectronicWindDelegate> delegate in self.VaaElecWindDelegates) {
        [delegate newMaxAmplitude: amplitude];
    }
}


/* start the audio input/output and starts sending data */
- (void) start {
    [self.soundManager start];
}

/* start the audio input/output and starts sending data */
- (void) stop {
    [self.soundManager stop];
}

- (void) setAudioPlot:(EZAudioPlotGL *) audioPlot {
    if (self.soundManager) {
        self.soundManager.audioPlot = audioPlot;
    }
}


// Starts the internal soundfile recorder
- (void) startRecording {
    [self.soundManager startRecording];
    [self.summeryGenerator startRecording];
}

// Ends the internal soundfile recorder
- (void) endRecording {
    [self.soundManager endRecording];
    [self.summeryGenerator endRecording];
}

// returns true if recording is active
- (BOOL) isRecording {
    return [self.soundManager isRecording];
}

// returns the local path of the recording
- (NSURL*) recordingPath {
    return [self.soundManager recordingPath];
}

// returns the local path of the summeryfile
- (NSURL*) summeryPath {
    return [self.summeryGenerator recordingPath];
}

// returns the fitcurve used in the directionAlgorithm
- (float *) getFitCurve {
    return [DirectionDetectionAlgo getFitCurve];
}

// returns the EdgeAngles for the samples
- (int *) getEdgeAngles {
    return [self.soundManager.soundProcessor.dirDetectionAlgo getEdgeAngles];
}

- (void) generateSummeryFile {
    [self.summeryGenerator generateFile];
}




@end
