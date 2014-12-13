//
//  vaavudProductionTestResultViewController.h
//  VaavudElectronicsTest
//
//  Created by Andreas Okholm on 11/12/14.
//  Copyright (c) 2014 Vaavud. All rights reserved.
//

#import "vaavudUIViewController.h"

@interface vaavudProductionTestResultViewController : vaavudUIViewController <VaavudElectronicWindDelegate>

@property BOOL testSucessful;
@property NSString *errorMessage;

@end
