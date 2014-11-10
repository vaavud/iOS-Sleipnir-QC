//
//  vaavudProductionTestViewController.m
//  VaavudElectronicsTest
//
//  Created by Andreas Okholm on 09/11/14.
//  Copyright (c) 2014 Vaavud. All rights reserved.
//

#import "vaavudProductionTestViewController.h"

@interface vaavudProductionTestViewController () <VaavudElectronicAnalysisDelegate, VaavudElectronicWindDelegate>
@property (strong, nonatomic) VEVaavudElectronicSDK *vaavudElectronics;
@property BOOL headset;
@property BOOL gap;
@property BOOL block;
@property BOOL windDirection;
@property (weak, nonatomic) IBOutlet UILabel *labelHeadsetCheck;
@property (weak, nonatomic) IBOutlet UILabel *labelGapCheck;
@property (weak, nonatomic) IBOutlet UILabel *labelBlockCheck;
@property (weak, nonatomic) IBOutlet UILabel *labelWindCheck;
@property (strong, nonatomic) NSString *unChecked;
@property (strong, nonatomic) NSString *checked;

@end

@implementation vaavudProductionTestViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.vaavudElectronics = [VEVaavudElectronicSDK sharedVaavudElectronic];
    
    self.unChecked = @"☑️";
    self.checked = @"✅";
    [self reset];

    // Do any additional setup after loading the view.
}

- (void) reset {
    self.headset = NO;
    self.gap = NO;
    self.block = NO;
    self.windDirection = NO;
    
    self.labelHeadsetCheck.text = self.unChecked;
    self.labelGapCheck.text = self.unChecked;
    self.labelBlockCheck.text = self.unChecked;
    self.labelWindCheck.text = self.unChecked;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void) sleipnirAvailabliltyChanged: (BOOL) available {
    if (available) {
        if (!self.headset) {
            self.headset = YES;
            self.labelHeadsetCheck.text = self.checked;
            NSLog(@"headset Detected");
        }
    }
}


- (void) newMaxAmplitude: (NSNumber*) amplitude {
    
    if (!self.gap) {
        if (amplitude.intValue > 3500) {
            self.gap = YES;
            self.labelGapCheck.text = self.checked;
            NSLog(@"GAP detected");
        }
    }
    
    if (!self.block) {
        if (amplitude.intValue < 500) {
            self.block = YES;
            self.labelBlockCheck.text = self.checked;
            NSLog(@"Block Detected");
        }
    }
}


- (void) newWindAngleLocal:(NSNumber *)angle {
    if (!self.windDirection) {
        self.windDirection = YES;
        self.labelWindCheck.text = self.checked;
        NSLog(@"Winddirection Detected");
    }
}


- (void) deviceDisconnectedTypeSleipnir: (BOOL) sleipnir {
    [self reset];
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
