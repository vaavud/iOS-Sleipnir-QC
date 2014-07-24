//
//  SummeryGenerator.m
//  VaavudElectronicsTest
//
//  Created by Andreas Okholm on 24/07/14.
//  Copyright (c) 2014 Vaavud. All rights reserved.
//

#import "SummeryGenerator.h"
#import "VaavudElectronic.h"

@interface SummeryGenerator()
@property (nonatomic, strong) NSNumber *speed;
@property (nonatomic) float angle;
@property (nonatomic, strong) NSArray *anglularVelocties;
@property (nonatomic, weak) VaavudElectronic *vaavudElectronic;


@end

@implementation SummeryGenerator


- (id) init {
    self = [super init];
    if (self) {
        //self.vaavudElectronic = [VaavudElectronic sharedVaavudElec];
    }
    
    return self;
}

- (void) newSpeed: (NSNumber*) speed {
    self.speed = speed;
}
- (void) newAngularVelocities: (NSArray*) angularVelocities {
    self.anglularVelocties = angularVelocities;
}
- (void) newAngularVelocities: (float*) angularVelocities andLength: (int) length {
    
}
- (void) newWindAngleLocal:(float) angle {
    self.angle = angle;
}

- (NSURL*) recordingPath {
    return [self recordingFilePathURL];
}


// Starts the recieving updates
- (void) startRecording {
    if (!self.vaavudElectronic) {
        self.vaavudElectronic = [VaavudElectronic sharedVaavudElec];
    }
    
    [self.vaavudElectronic addListener:self];
}

// Ends the recieving updates
- (void) endRecording {
    
    if (!self.vaavudElectronic) {
        self.vaavudElectronic = [VaavudElectronic sharedVaavudElec];
    }
    
    [self.vaavudElectronic removeListener:self];
}

// generated the file
- (void) generateFile {

    
    
    
    //create content - four lines of text
    NSString *content = @"One\nTwo\nThree\nFour\nFive";
    //save content to the documents directory
    [content writeToFile:[[self recordingFilePathURL] relativePath]
              atomically:NO
                encoding:NSStringEncodingConversionAllowLossy
                   error:nil];
}

-(NSString*)applicationDocumentsDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return basePath;
}

-(NSURL*)recordingFilePathURL {
    return [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/%@",
                                   [self applicationDocumentsDirectory],
                                   @"summeryTextFile.txt"]];
}



@end
