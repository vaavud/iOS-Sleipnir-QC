//
//  windUpdateDelegate.h
//  VaavudElectronicsTest
//
//  Created by Andreas Okholm on 21/07/14.
//  Copyright (c) 2014 Vaavud. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol VaavudElectronicWindDelegate <NSObject>

- (void) newSpeed: (NSNumber*) speed;
- (void) newAngularVelocities: (float*) angularVelocities andLength: (int) length;
- (void) newWindAngleLocal:(float) angle;

@end
