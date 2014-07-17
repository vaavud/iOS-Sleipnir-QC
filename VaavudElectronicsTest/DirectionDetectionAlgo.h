//
//  DirectionDetectionAlgo.h
//  VaavudElectronicsTest
//
//  Created by Andreas Okholm on 11/06/14.
//  Copyright (c) 2014 Vaavud. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol DirectionRecieverDelegate

- (void) newSpeed: (NSNumber*) speed;
- (void) newAngularVelocities: (float*) angularVelocities andLength: (int) length;
- (void) newWindAngleLocal:(float) angle;

@end


@interface DirectionDetectionAlgo : NSObject

- (void) newTick:(int)samples;
- (id) initWithDirDelegate:(id<DirectionRecieverDelegate>)delegate;

@end
