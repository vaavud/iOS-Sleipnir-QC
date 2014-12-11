//
//  vaavudProductionTestResultViewController.m
//  VaavudElectronicsTest
//
//  Created by Andreas Okholm on 11/12/14.
//  Copyright (c) 2014 Vaavud. All rights reserved.
//

#import "vaavudProductionTestResultViewController.h"


@interface vaavudProductionTestResultViewController ()


@property NSString *unChecked;
@property NSString *checked;
@property (weak, nonatomic) IBOutlet UILabel *labelTestResultIcon;
@property VEVaavudElectronicSDK *vaavudElectronics;

@end

@implementation vaavudProductionTestResultViewController

- (void) test: (BOOL) sucessfull {
    self.testSucessful = sucessfull;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.unChecked = @"☑️";
    self.checked = @"✅";
    
    self.labelTestResultIcon.text = self.testSucessful ? self.checked : self.unChecked ;
    
    self.vaavudElectronics = [VEVaavudElectronicSDK sharedVaavudElectronic];
    
    
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) viewDidAppear:(BOOL)animated {
    [self.vaavudElectronics addListener:self];
}

- (void) viewDidDisappear:(BOOL)animated {
    [self.vaavudElectronics removeListener:self];
}

- (void) deviceDisconnectedTypeSleipnir: (BOOL) sleipnir {
    [self.navigationController popViewControllerAnimated:YES];
}

@end
