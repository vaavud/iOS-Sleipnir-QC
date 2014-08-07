//
//  LocationManager.h
//  VaavudElectronicsTest
//
//  Created by Andreas Okholm on 07/08/14.
//  Copyright (c) 2014 Vaavud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VaavudElectronicWindDelegate.h"


@interface LocationManager : NSObject

- (id) initWithDelegate:(id<VaavudElectronicWindDelegate>)delegate;

- (void) start;
- (void) stop;

- (BOOL) isHeadingAvailable;

@end
