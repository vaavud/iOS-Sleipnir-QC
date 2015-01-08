//
//  vaavudCleanInterfaceViewController.m
//  VaavudElectronicsTest
//
//  Created by Andreas Okholm on 21/07/14.
//  Copyright (c) 2014 Vaavud. All rights reserved.
//

#import "vaavudCleanInterfaceViewController.h"

@interface vaavudCleanInterfaceViewController () <VaavudElectronicAnalysisDelegate, VaavudElectronicWindDelegate>
@property (strong, nonatomic) VEVaavudElectronicSDK *vaavudElectronics;

@property (weak, nonatomic) IBOutlet UILabel *rotationSpeedTextField;
@property (weak, nonatomic) IBOutlet UILabel *windAngleTextField;
@property (weak, nonatomic) IBOutlet UILabel *windAngleLocalTextField;
@property (weak, nonatomic) IBOutlet UILabel *headingTextField;
@property (weak, nonatomic) IBOutlet UILabel *signalErrorTextField;

@end

@implementation vaavudCleanInterfaceViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.vaavudElectronics = [VEVaavudElectronicSDK sharedVaavudElectronic];
    
    [self.windAngleTextField setText: @"-"];
    [self.rotationSpeedTextField setText:@"-"];
    [self.windAngleLocalTextField setText:@"-"];
    [self.headingTextField setText:@"-"];
    [self.signalErrorTextField setText:@"-"];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void) newSpeed: (NSNumber*) speed{
    [self.rotationSpeedTextField setText:[NSString stringWithFormat:@"%.1f", speed.floatValue]];
//    NSLog(@"awesome speed: %.2f", speed.floatValue);
}


- (void) newWindDirection:(NSNumber *) windDirection {
    [self.windAngleTextField setText:[NSString stringWithFormat:@"%.0f", windDirection.floatValue]];
}

- (void) newWindAngleLocal:(NSNumber *)angle {
    [self.windAngleLocalTextField setText:[NSString stringWithFormat:@"%.0f", angle.floatValue]];
}

- (void) newHeading:(NSNumber *)heading {
    [self.headingTextField setText:[NSString stringWithFormat:@"%.0f", heading.floatValue]];
}

- (void) newVelocityProfileError:(NSNumber *)profileError {
    self.signalErrorTextField.text = [NSString stringWithFormat:@"%.1f", profileError.floatValue];
}

- (void) viewDidAppear:(BOOL)animated {
    [self.vaavudElectronics addListener:self];
    [self.vaavudElectronics addAnalysisListener:self];
}

- (void) viewDidDisappear:(BOOL)animated {
    [self.vaavudElectronics removeListener:self];
    [self.vaavudElectronics removeAnalysisListener:self];
}

@end
