//
//  vaavudProductionTestViewController.m
//  VaavudElectronicsTest
//
//  Created by Andreas Okholm on 09/11/14.
//  Copyright (c) 2014 Vaavud. All rights reserved.
//

#import "vaavudProductionTestViewController.h"
#import "vaavudProductionTestResultViewController.h"

const int PROGRESS_BAR_STEPS = 20;
const float MEASURE_TIME = 5.0;
const float ANGLE_MAX_DEVIATION = 25.0;
const float ANGLE_STANDARD = 90;
const float WINDSPEED_MAX_DEVIATION = 0.25;
const float SIGNAL_ERROR_MAX = 15.0;
const int SIGNAL_LOSS_COUNT_MAX = 2;

@interface QCProductionSession : NSObject
@property (nonatomic) float windDirection;
@property (nonatomic) float velocity;
@property (nonatomic) float signalLossCount;
@property (nonatomic) float velocityTarget;
@property (nonatomic) float velocityProfileError;
@property (nonatomic, strong) NSArray *velocityProfile;
@end

@implementation QCProductionSession
- (QCProductionSession *) initWith:(float)velocityTarget {
    self = [super init];
    if (self) {
        self.velocityTarget = velocityTarget;
    }
    return self;
}

- (NSDictionary *)asDic {
    // Convert your data and set your request's HTTPBody property
    NSMutableDictionary *uploadDic = [[NSMutableDictionary alloc] init];
    
    [uploadDic setValue:@(self.velocityProfileError) forKey:@"velocityProfileError"];
    [uploadDic setValue:@(self.velocity) forKey:@"velocity"];
    [uploadDic setValue:@(self.velocityTarget) forKey:@"velocityTarget"];
    [uploadDic setValue:@(self.windDirection) forKey:@"direction"];
    [uploadDic setValue:@(self.signalLossCount) forKey:@"tickDetectionErrorCount"];
    [uploadDic setValue:self.velocityProfile forKey:@"velocityProfile"];
    [uploadDic setValue:@([self qcPassed]) forKey:@"qcPassed"];
    
    return uploadDic;
}

- (BOOL)signalLossCountPassed {
    return self.signalLossCount < SIGNAL_LOSS_COUNT_MAX ? YES : NO;
}

- (BOOL)velocityPassed {
    return fabs(self.velocity - self.velocityTarget) < WINDSPEED_MAX_DEVIATION ? YES : NO;
}

- (BOOL)windDirectinoPassed {
    return fabs(self.windDirection - ANGLE_STANDARD) < ANGLE_MAX_DEVIATION ? YES : NO;
}

- (BOOL)velocityProfileErrorPassed {
    return self.velocityProfileError <= SIGNAL_ERROR_MAX ? true : false;
}

- (NSString *)errorMessage {
    if (![self signalLossCountPassed]) {
        return @"Signal Error";
    }
    if (![self velocityPassed]) {
        return [NSString stringWithFormat:@"Error, Speed: %.2f m/s", self.velocity];
    }
    if (![self windDirectinoPassed]) {
        return [NSString stringWithFormat:@"Error: Direction %.1f deg", self.windDirection];
    }
    if (![self velocityProfileErrorPassed]) {
        return [NSString stringWithFormat:@"Error: S-Quality %.0f", self.velocityProfileError];
    }
    return @"";
}

- (BOOL)qcPassed {
    return [self signalLossCountPassed] && [self velocityPassed] && [self windDirectinoPassed] && [self velocityProfileErrorPassed];
}
@end



@interface vaavudProductionTestViewController () <VaavudElectronicAnalysisDelegate, VaavudElectronicWindDelegate, NSURLConnectionDelegate>

@property (strong, nonatomic) VEVaavudElectronicSDK *vaavudElectronics;
@property (strong, nonatomic) QCProductionSession *qcSession;

@property (nonatomic) BOOL measureWindspeed;
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
}

- (void)reset {
    self.labelHeadsetCheck.text = self.unChecked;
    self.labelWindDirection.text = @"-";
    self.labelWindSpeed.text = @"-";
    self.labelSignalQuality.text = @"-";
    
    [self.recordingProgressBar setProgress: 0.0];
    self.windAngleCounter = 0;
    self.windspeedSum = 0;
    self.windspeedCounter = 0;
    
    self.qcSession = [[QCProductionSession alloc] initWith:[[NSUserDefaults standardUserDefaults] floatForKey:@"MEAN_WIND_SPEED"]];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)updateProgress {
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
    [request setURL:[NSURL URLWithString:@"https://mobile-api.vaavud.com/api/production/qc"]];
    [request setHTTPMethod:@"POST"];
    
    // This is how we set header fields
    [request setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    request.timeoutInterval = 20.0;
    
    
    
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:[self.qcSession asDic]
                                                       options:NSJSONWritingPrettyPrinted // Pass 0 if you don't care about the readability of the generated string
                                                         error:&error];
    request.HTTPBody = jsonData;
    
    if (! jsonData) {
        NSLog(@"Got an error: %@", error);
    } else {
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        NSLog(@"%@", jsonString);
    }
    NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:request delegate:self];
}


- (void)sleipnirAvailabliltyChanged: (BOOL) available {
    self.labelHeadsetCheck.text = available ? self.checked : self.unChecked;
}

- (void) newSpeed:(NSNumber *)speed {
    if (!self.measureWindspeed) {
        return;
    }
    
    self.windspeedSum += speed.doubleValue;
    self.windspeedCounter++;
    self.qcSession.velocity = self.windspeedSum / (float) self.windspeedCounter;
    
    self.labelHeadsetCheck.text = self.checked;
    self.labelWindSpeed.text = [NSString stringWithFormat:@"%0.2f", self.qcSession.velocity];
    self.labelWindSpeed.textColor = [self.qcSession velocityPassed] ? [UIColor blackColor] : [UIColor redColor];
    
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
    
    self.qcSession.windDirection = angle.floatValue;
    self.labelWindDirection.text = [NSString stringWithFormat:@"%0.1f", self.qcSession.windDirection];
    self.labelWindDirection.textColor = [self.qcSession windDirectinoPassed] ? [UIColor blackColor] : [UIColor redColor];
    self.windAngleCounter++;
}

- (void)newVelocityProfileError:(NSNumber *)profileError {
    self.qcSession.velocityProfileError = profileError.floatValue;
    self.labelSignalQuality.text = [NSString stringWithFormat:@"%0.0f", self.qcSession.velocityProfileError];
    self.labelSignalQuality.textColor = [self.qcSession velocityProfileErrorPassed] ? [UIColor blackColor] : [UIColor redColor];
}

- (void)newTickDetectionErrorCount:(NSNumber *)tickDetectionErrorCount {
    self.qcSession.signalLossCount += 1;
}

- (void) measureWindspeedStart {
    self.measureWindspeed = YES;
}

- (void) deviceDisconnectedTypeSleipnir: (BOOL) sleipnir {
    [self reset];
}

- (void)newAngularVelocities:(NSArray *)angularVelocities {
    self.qcSession.velocityProfile = angularVelocities;
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.vaavudElectronics addListener:self];
    [self.vaavudElectronics addAnalysisListener:self];
    [self reset];
    
}

- (void) viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [self.vaavudElectronics removeListener:self];
    [self.vaavudElectronics removeAnalysisListener:self];
    self.progressBarStepCount = 0;
    [self.progressBarTimer invalidate];
}


 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
     if ([segue.identifier isEqualToString:@"testResultScreen"]) {
         vaavudProductionTestResultViewController *destViewController = segue.destinationViewController;
         destViewController.signalQuality = self.qcSession.velocityProfileError;
         destViewController.testSucessful = self.qcSession.qcPassed;
         destViewController.errorMessage = self.qcSession.errorMessage;
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
