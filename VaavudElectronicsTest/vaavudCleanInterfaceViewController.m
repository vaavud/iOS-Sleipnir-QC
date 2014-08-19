//
//  vaavudCleanInterfaceViewController.m
//  VaavudElectronicsTest
//
//  Created by Andreas Okholm on 21/07/14.
//  Copyright (c) 2014 Vaavud. All rights reserved.
//

#import "vaavudCleanInterfaceViewController.h"

@interface vaavudCleanInterfaceViewController () <VaavudElectronicWindDelegate>
@property (strong, nonatomic) VaavudElectronic *vaavudElectronics;

@property (weak, nonatomic) IBOutlet UILabel *rotationSpeedTextField;
@property (weak, nonatomic) IBOutlet UILabel *windAngleTextField;

@end

@implementation vaavudCleanInterfaceViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    self.vaavudElectronics = [VaavudElectronic sharedVaavudElec];
    [self.vaavudElectronics addListener:self];
    
    [self.windAngleTextField setText: @"-"];
    [self.rotationSpeedTextField setText:@"-"];
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


@end
