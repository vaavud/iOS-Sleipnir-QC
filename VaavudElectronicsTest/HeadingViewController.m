//
//  HeadingViewController.m
//  VaavudElectronicsTest
//
//  Created by Andreas Okholm on 07/08/14.
//  Copyright (c) 2014 Vaavud. All rights reserved.
//

#import "HeadingViewController.h"
#import "VaavudElectronic.h"


@interface HeadingViewController ()

@property (weak, nonatomic) IBOutlet UILabel *textLabelHeading;
@property (strong, nonatomic) VaavudElectronic *vaavudElectronics;

@end

@implementation HeadingViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
    self.vaavudElectronics = [VaavudElectronic sharedVaavudElec];
    [self.vaavudElectronics addListener:self];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) newSpeed: (NSNumber*) speed {
    
}
- (void) newAngularVelocities: (NSArray*) angularVelocities {
    
}
- (void) newAngularVelocities: (float*) angularVelocities andLength: (int) length {
    
}
- (void) newWindAngleLocal:(float) angle {
    
}
- (void) newMaxAmplitude: (NSNumber*) amplitude {
    
}


- (void) newHeading: (NSNumber*) heading {
    //    compassHeading = newHeading.trueHeading;
    //    self.windAngleCompassTextField.text = [NSString stringWithFormat: @"%.0fº", newHeading.trueHeading];
    
    //[self.vaavudCoreController newHeading: [NSNumber numberWithDouble: newHeading.trueHeading]];
    
    //    NSLog(@"heading accuracy: %f", newHeading.headingAccuracy);
    
    self.textLabelHeading.text = [NSString stringWithFormat: @"%.0fº", [heading floatValue]];
    
    //    NSLog(@"heading accuracy: %f", newHeading.headingAccuracy);
    
}



@end
