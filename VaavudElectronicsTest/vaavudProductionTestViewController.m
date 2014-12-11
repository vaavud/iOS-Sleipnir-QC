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
#define WINDSPEED_STANDARD 3.5
#define WINDSPEED_MAX_DEVIATION 0.4



@interface vaavudProductionTestViewController () <VaavudElectronicAnalysisDelegate, VaavudElectronicWindDelegate>
@property (strong, nonatomic) VEVaavudElectronicSDK *vaavudElectronics;
@property BOOL headset;
@property BOOL amplitudeCheck;
@property BOOL gap;
@property BOOL block;
@property BOOL windDirection;

@property double localWindAngle;
@property UInt32 windAngleCounter;


@property (weak, nonatomic) IBOutlet UILabel *labelHeadsetCheck;
@property (weak, nonatomic) IBOutlet UILabel *labelWindDirection;
@property (weak, nonatomic) IBOutlet UILabel *labelWindSpeed;

@property (weak, nonatomic) IBOutlet UIProgressView *recordingProgressBar;
@property (nonatomic) NSUInteger progressBarStepCount;
@property (strong, nonatomic) NSTimer *progressBarTimer;

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
    self.amplitudeCheck = NO;
    
    self.labelHeadsetCheck.text = self.unChecked;
    self.labelWindDirection.text = self.unChecked;
    
    [self.recordingProgressBar setProgress: 0.0];
    
    self.windAngleCounter = 0;
    
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
            [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(amplitudeCheckReady) userInfo:nil repeats:NO];
//            [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(windDirectionCheck) userInfo:nil repeats:NO];
            
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
        [self windDirectionCheck];
    }

}
             
 - (void) amplitudeCheckReady {
     self.amplitudeCheck = YES;
 }

- (void) windDirectionCheck {
    if (self.windAngleCounter > 20) {
        NSLog(@"awesome");
        
        [self performSegueWithIdentifier:@"testResultScreen" sender:self];
    }
    
}


- (void) newSpeed:(NSNumber *)speed {
    self.labelWindSpeed.text = [NSString stringWithFormat:@"%0.1f", speed.floatValue];
    
}

- (void) newWindAngleLocal:(NSNumber *)angle {
    
    
    if (self.windAngleCounter == 0) {
        double timeInterval = MEASURE_TIME/ (double) PROGRESS_BAR_STEPS;
        
        self.progressBarTimer = [NSTimer scheduledTimerWithTimeInterval:timeInterval target:self selector:@selector(updateProgress) userInfo:nil repeats:YES];
        [self.progressBarTimer setTolerance:0.1];
        [self.progressBarTimer fire];
    }
    
    self.labelWindDirection.text = [NSString stringWithFormat:@"%0.1f", angle.floatValue];
    
    if (abs(angle.floatValue - ANGLE_STARNDARD) > ANGLE_MAX_DEVIATION  ) {
        self.labelWindDirection.textColor = [UIColor redColor];
    } else {
        self.labelWindDirection.textColor = [UIColor blackColor];
    }
    
    self.windAngleCounter++;
    NSLog(@"NewAngle: %d", (unsigned int) self.windAngleCounter);
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


 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
     if ([segue.identifier isEqualToString:@"testResultScreen"]) {
         vaavudProductionTestResultViewController *destViewController = segue.destinationViewController;
         destViewController.testSucessful = YES;
     }
 }



@end
