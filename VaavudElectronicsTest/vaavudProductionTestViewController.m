//
//  vaavudProductionTestViewController.m
//  VaavudElectronicsTest
//
//  Created by Andreas Okholm on 09/11/14.
//  Copyright (c) 2014 Vaavud. All rights reserved.
//

#import "vaavudProductionTestViewController.h"
#import "vaavudProductionTestResultViewController.h"

#define MEASURE_TIME 5.0
#define PROGRESS_BAR_STEPS 20
#define ANGLE_MAX_DEVIATION 20
#define ANGLE_STARNDARD 90
#define WINDSPEED_STANDARD 2.00
#define WINDSPEED_MAX_DEVIATION 0.25
#define SIGNAL_ERROR_MAX 7.0



@interface vaavudProductionTestViewController () <VaavudElectronicAnalysisDelegate, VaavudElectronicWindDelegate>
@property (strong, nonatomic) VEVaavudElectronicSDK *vaavudElectronics;
@property BOOL headset;
@property BOOL amplitudeCheck;
@property BOOL gap;
@property BOOL block;
@property BOOL windDirection;
@property BOOL measureWindspeed;
@property double windDirectionValue;

@property BOOL signalQuality;
@property double signalQUalityValue;

@property BOOL windSpeed;
@property double windSpeedValue;
@property (nonatomic) double windspeedSum;
@property (nonatomic) int windspeedCounter;



@property UInt32 windAngleCounter;

@property (weak, nonatomic) IBOutlet UILabel *labelHeadsetCheck;
@property (weak, nonatomic) IBOutlet UILabel *labelWindDirection;
@property (weak, nonatomic) IBOutlet UILabel *labelWindSpeed;
@property (weak, nonatomic) IBOutlet UILabel *labelVersion;
@property (weak, nonatomic) IBOutlet UILabel *labelSignalQuality;

@property (weak, nonatomic) IBOutlet UIProgressView *recordingProgressBar;
@property (nonatomic) NSUInteger progressBarStepCount;
@property (strong, nonatomic) NSTimer *progressBarTimer;

@property (strong, nonatomic) NSString *unChecked;
@property (strong, nonatomic) NSString *checked;

@property double windspeedStandard;

@end

@implementation vaavudProductionTestViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.vaavudElectronics = [VEVaavudElectronicSDK sharedVaavudElectronic];
    
    self.unChecked = @"☑️";
    self.checked = @"✅";
    
    [self reset];
    
    NSString * appBuildString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
    
    NSString * appVersionString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    
    NSString * versionBuildString = [NSString stringWithFormat:@"Version: %@ (%@)", appVersionString, appBuildString];
    
    self.labelVersion.text = versionBuildString;
    
    // Do any additional setup after loading the view.
}

- (void) reset {
    self.headset = NO;
    self.windDirection = NO;
    self.windSpeed = NO;
    self.measureWindspeed = NO;
    self.signalQuality = NO;
    
    
    self.labelHeadsetCheck.text = self.unChecked;
    self.labelWindDirection.text = @"-";
    self.labelWindSpeed.text = @"-";
    self.labelSignalQuality.text = @"-";
    
    
    [self.recordingProgressBar setProgress: 0.0];
    
    self.windAngleCounter = 0;

    self.windspeedSum = 0;
    self.windspeedCounter = 0;
    
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
        }
    }
    else {
        if (self.headset) {
            self.headset = false;
            self.labelHeadsetCheck.text = self.unChecked;
        }
    }
    
}


- (void) updateProgress {
    if ( self.progressBarStepCount < PROGRESS_BAR_STEPS) {
        [self.recordingProgressBar setProgress: self.progressBarStepCount / (float) PROGRESS_BAR_STEPS];
        self.progressBarStepCount++;
    }
    else {
        [self.recordingProgressBar setProgress: 1.0];
        self.progressBarStepCount = 0;
        [self.progressBarTimer invalidate];
        [self performSegueWithIdentifier:@"testResultScreen" sender:self];
    }

}
             

- (void) newSpeed:(NSNumber *)speed {
    
    if (!self.measureWindspeed) {
        return;
    }
    
    self.windspeedSum += speed.doubleValue;
    self.windspeedCounter++;
    
    self.windSpeedValue = self.windspeedSum / (float) self.windspeedCounter;

    
    
    [self sleipnirAvailabliltyChanged: YES];
    self.labelWindSpeed.text = [NSString stringWithFormat:@"%0.2f", self.windSpeedValue];
    
    self.windSpeed = fabs(self.windSpeedValue - self.windspeedStandard) < WINDSPEED_MAX_DEVIATION ? YES : NO;
    self.labelWindSpeed.textColor = self.windSpeed ? [UIColor blackColor] : [UIColor redColor];
    
}

- (void) newWindAngleLocal:(NSNumber *)angle {
    
    
    if (self.windAngleCounter == 0) {
        double timeInterval = MEASURE_TIME/ (double) PROGRESS_BAR_STEPS;
        
        [self.progressBarTimer invalidate];
        self.progressBarTimer = [NSTimer scheduledTimerWithTimeInterval:timeInterval target:self selector:@selector(updateProgress) userInfo:nil repeats:YES];
        [self.progressBarTimer setTolerance:0.1];
        [self.progressBarTimer fire];
        
        [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(measureWindspeedStart) userInfo:nil repeats:NO];
    }
    
    self.labelWindDirection.text = [NSString stringWithFormat:@"%0.1f", angle.floatValue];
    
    self.windDirectionValue = angle.doubleValue;
    
    self.windDirection = fabs(angle.floatValue - ANGLE_STARNDARD) < ANGLE_MAX_DEVIATION ? YES : NO;
    self.labelWindDirection.textColor = self.windDirection ? [UIColor blackColor] : [UIColor redColor];
    
    self.windAngleCounter++;
}

- (void)newVelocityProfileError:(NSNumber *)profileError {
    self.signalQuality = profileError.intValue <= SIGNAL_ERROR_MAX ? true : false;
    
    self.labelSignalQuality.text = [NSString stringWithFormat:@"%i", profileError.intValue];
    self.labelSignalQuality.textColor = self.signalQuality ? [UIColor blackColor] : [UIColor redColor];
    self.signalQUalityValue = profileError.doubleValue;
}

- (void) measureWindspeedStart {
    self.measureWindspeed = YES;
}

- (void) deviceDisconnectedTypeSleipnir: (BOOL) sleipnir {
    [self reset];
}

- (void) viewDidAppear:(BOOL)animated {
    [self.vaavudElectronics addListener:self];
    [self.vaavudElectronics addAnalysisListener:self];
    [self reset];
    
    
    NSNumber *windspeedStandardDatabase = @([[NSUserDefaults standardUserDefaults] floatForKey:@"MEAN_WIND_SPEED"]);
    
    if (windspeedStandardDatabase == nil) {
        self.windspeedStandard = WINDSPEED_STANDARD;
    } else {
        self.windspeedStandard = windspeedStandardDatabase.doubleValue;
    }
    
}

- (void) viewDidDisappear:(BOOL)animated {
    [self.vaavudElectronics removeListener:self];
    [self.vaavudElectronics removeAnalysisListener:self];
    self.progressBarStepCount = 0;
    [self.progressBarTimer invalidate];
}


 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
     if ([segue.identifier isEqualToString:@"testResultScreen"]) {
         vaavudProductionTestResultViewController *destViewController = segue.destinationViewController;
         
         destViewController.testSucessful = NO;
         
         if (self.windAngleCounter < 24) {
             destViewController.errorMessage = @"Signal Error";
             return;
         }
         
         if (!self.windSpeed) {
             destViewController.errorMessage = [NSString stringWithFormat:@"Error, Speed: %.2f m/s", self.windSpeedValue];
             return;
         }
         
         if (!self.windDirection) {
             destViewController.errorMessage = [NSString stringWithFormat:@"Error: Direction %.1f deg", self.windDirectionValue];
             return;
         }
         
         if (!self.signalQuality) {
             destViewController.errorMessage = [NSString stringWithFormat:@"Error: S-Quality %.0f", self.signalQUalityValue];
             return;
         }
     
         destViewController.testSucessful = YES;
         destViewController.errorMessage = @"Sucessful";
     }
 }



@end
