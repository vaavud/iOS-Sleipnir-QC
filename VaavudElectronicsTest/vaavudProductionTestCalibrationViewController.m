//
//  vaavudProductionTestCalibrationViewController.m
//  VaavudElectronicsTest
//
//  Created by Andreas Okholm on 13/12/14.
//  Copyright (c) 2014 Vaavud. All rights reserved.
//

#import "vaavudProductionTestCalibrationViewController.h"

#define PROGRESS_BAR_STEPS 20
#define MEASURE_TIME 15

@interface vaavudProductionTestCalibrationViewController ()
@property (weak, nonatomic) IBOutlet UILabel *labelWindspeed;
@property (strong, nonatomic) VEVaavudElectronicSDK *vaavudElectronic;


@property (weak, nonatomic) IBOutlet UILabel *windSpeedAverage;

@property (strong, nonatomic) NSTimer *progressBarTimer;

@property (weak, nonatomic) IBOutlet UIProgressView *progressbar;
@property (weak, nonatomic) IBOutlet UIButton *buttonStart;

@property (nonatomic) int progressBarStepCount;
@property (nonatomic) double windspeedSum;
@property (nonatomic) int windspeedCounter;

@end

@implementation vaavudProductionTestCalibrationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.vaavudElectronic = [VEVaavudElectronicSDK sharedVaavudElectronic];
    
    self.progressbar.progress = 0.0;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)buttonStartTest:(id)sender {
    
    // setup windspeed array
    self.windspeedSum = 0;
    self.windspeedCounter = 0;
    
    
    double timeInterval = MEASURE_TIME/ (double) PROGRESS_BAR_STEPS;
    [self.progressBarTimer invalidate];
    self.progressBarTimer = [NSTimer scheduledTimerWithTimeInterval:timeInterval target:self selector:@selector(updateProgress) userInfo:nil repeats:YES];
    
    self.buttonStart.hidden = YES;
    
}

- (void) updateProgress {
    if ( self.progressBarStepCount < PROGRESS_BAR_STEPS) {
        [self.progressbar setProgress: self.progressBarStepCount / (float) PROGRESS_BAR_STEPS];
        self.progressBarStepCount++;
    }
    else {
        [self.progressbar setProgress: 1.0];
        self.progressBarStepCount = 0;
        [self.progressBarTimer invalidate];
        
        [[NSUserDefaults standardUserDefaults] setFloat:self.windspeedSum / (double) self.windspeedCounter forKey:@"MEAN_WIND_SPEED"];
        
        [self.navigationController popViewControllerAnimated:YES];
    }
    
}

- (void) newSpeed:(NSNumber *)speed {
    self.labelWindspeed.text = [NSString stringWithFormat: @"%0.2f", speed.doubleValue];
    
    self.windspeedSum += speed.doubleValue;
    self.windspeedCounter++;
    
    float averageWindspeed = self.windspeedSum / (float) self.windspeedCounter;
    
    self.windSpeedAverage.text = [NSString stringWithFormat: @"%0.2f", averageWindspeed];
}



/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void) viewDidAppear:(BOOL)animated {
    [self.vaavudElectronic addListener:self];
    [super viewDidAppear:animated];
}

- (void) viewDidDisappear:(BOOL)animated {
    [self.vaavudElectronic removeListener:self];
    [super viewDidDisappear:animated];
}



@end
