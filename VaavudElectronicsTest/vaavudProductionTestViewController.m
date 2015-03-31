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



@interface vaavudProductionTestViewController () <VaavudElectronicAnalysisDelegate, VaavudElectronicWindDelegate, NSURLConnectionDelegate>
//{
//    NSMutableData *_responseData;
//}
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
@property NSMutableData *responseData;



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
        [self upload];
        [self performSegueWithIdentifier:@"testResultScreen" sender:self];
        
    }

}

- (void)upload {
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request addValue:@"gvasidyfgaisudyfgoauysgdf" forHTTPHeaderField:@"authToken"];
    [request setURL:[NSURL URLWithString:@"http://54.75.224.219/api/production/qc"]];
    [request setHTTPMethod:@"POST"];
    
    // This is how we set header fields
    [request setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    request.timeoutInterval = 20.0;
    
    // Convert your data and set your request's HTTPBody property
    NSMutableDictionary *uploadDic = [[NSMutableDictionary alloc] init];
    
    [uploadDic setValue:@(self.signalQUalityValue) forKey:@"velocityProfileError"];
    [uploadDic setValue:@(self.windSpeedValue) forKey:@"velocity"];
    [uploadDic setValue:@(self.windDirectionValue) forKey:@"direction"];
    [uploadDic setValue:@(self.windAngleCounter) forKey:@"measurementPoints"];
    
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:uploadDic
                                                       options:NSJSONWritingPrettyPrinted // Pass 0 if you don't care about the readability of the generated string
                                                         error:&error];
    request.HTTPBody = jsonData;
    
    
    if (! jsonData) {
        NSLog(@"Got an error: %@", error);
    } else {
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        NSLog(@"%@", jsonString);
    }
    
    
    
    
//    // Create the request.
//    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://google.com"]];
    
    // Create url connection and fire request
    NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    
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
    
    [super viewDidAppear:animated];
    
}

- (void) viewDidDisappear:(BOOL)animated {
    [self.vaavudElectronics removeListener:self];
    [self.vaavudElectronics removeAnalysisListener:self];
    self.progressBarStepCount = 0;
    [self.progressBarTimer invalidate];
    
    [super viewDidDisappear:animated];
}


 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
     if ([segue.identifier isEqualToString:@"testResultScreen"]) {
         vaavudProductionTestResultViewController *destViewController = segue.destinationViewController;
         
         
         destViewController.testSucessful = NO;
         destViewController.signalQuality = self.signalQUalityValue;
         
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


#pragma mark NSURLConnection Delegate Methods



 - (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)response {
     // A response has been received, this is where we initialize the instance var you created
     // so that we can append data to it in the didReceiveData method
     // Furthermore, this method is called each time there is a redirect so reinitializing it
     // also serves to clear it
     
     NSLog(@"Response Status code: %i", (int)response.statusCode);
     self.responseData = [[NSMutableData alloc] init];
 }
 
 - (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
     // Append the new data to the instance variable you declared
     [self.responseData appendData:data];
 }
 
 - (NSCachedURLResponse *)connection:(NSURLConnection *)connection
 willCacheResponse:(NSCachedURLResponse*)cachedResponse {
     // Return nil to indicate not necessary to store a cached response for this connection
     return nil;
 }
 
 - (void)connectionDidFinishLoading:(NSURLConnection *)connection {
     // The request is complete and data has been received
     // You can parse the stuff in your instance variable now
//     NSLog(@"connectionDidFinishLoading");
 }
 
 - (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
     // The request has failed for some reason!
     // Check the error var
 }
     
     
@end
