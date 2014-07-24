//
//  SummeryGenerator.h
//  VaavudElectronicsTest
//
//  Created by Andreas Okholm on 24/07/14.
//  Copyright (c) 2014 Vaavud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VaavudElectronicWindDelegate.h"

@interface SummeryGenerator : NSObject <VaavudElectronicWindDelegate>


// Starts the recieving updates
- (void) startRecording;

// Ends the recieving updates
- (void) endRecording;

// generated the file
- (void) generateFile;

// returns the local path of the summeryfile
- (NSURL*) recordingPath;

@end
