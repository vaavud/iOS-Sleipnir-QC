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

    
    NSDateFormatter *formatter;
    NSString        *dateString;
    NSString        *timeString;
    
    formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy'-'MM'-'dd"];
    dateString = [formatter stringFromDate:[NSDate date]];
    [formatter setDateFormat:@"HH'-'mm'-'ss"];
    timeString = [formatter stringFromDate:[NSDate date]];
    
    
    
    
    NSMutableArray *headerrow = [[NSMutableArray alloc] initWithCapacity:30];
    
    [headerrow addObject: @"date"];
    [headerrow addObject: @"time"];
    [headerrow addObject: @"windspeed"];
    [headerrow addObject: @"localHeading"];
    
    for (int i = 0; i < self.anglularVelocties.count; i++) {
        [headerrow addObject: [NSString stringWithFormat: @"angVel_%d", i]];
    }
    
    NSMutableArray *valuerow = [[NSMutableArray alloc] initWithCapacity:30];
    
    [valuerow addObject: dateString];
    [valuerow addObject: timeString];
    [valuerow addObject: self.speed.stringValue];
    [valuerow addObject: [NSString stringWithFormat:@"%f", self.angle]];
    
    for (int i = 0; i < self.anglularVelocties.count; i++) {
        [valuerow addObject: [(NSNumber *)[self.anglularVelocties objectAtIndex:i] stringValue]];
    }
    
    
    //NSArray *myStrings = [[NSArray alloc] initWithObjects:first, second, third, fourth, fifth, nil];
    NSString *headerRowString = [headerrow componentsJoinedByString:@","];
    NSString *valueRowString = [valuerow componentsJoinedByString:@","];
    
    
    //create content - four lines of text
    NSString *content = [NSString stringWithFormat: @"%@\n%@", headerRowString, valueRowString ];
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
