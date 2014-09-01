//
//  HeadingViewController.m
//  VaavudElectronicsTest
//
//  Created by Andreas Okholm on 07/08/14.
//  Copyright (c) 2014 Vaavud. All rights reserved.
//

#import "HeadingViewController.h"
#import "HeadingPlot.h"


@interface HeadingViewController ()

@property (weak, nonatomic) IBOutlet UILabel *textLabelHeading;
@property (strong, nonatomic) VaavudElectronicSDK *vaavudElectronics;
@property (weak, nonatomic) IBOutlet HeadingPlot *headingPlot;


@end

@implementation HeadingViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
    self.vaavudElectronics = [VaavudElectronicSDK sharedVaavudElectronic];
    [self.vaavudElectronics addAnalysisListener:self];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void) newHeading: (NSNumber*) heading {

    self.textLabelHeading.text = [NSString stringWithFormat: @"%.0fº", [heading floatValue]];
    
}



@end
