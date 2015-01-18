//
//  UploadViewController.m
//  VaavudElectronicsTest
//
//  Created by Andreas Okholm on 22/07/14.
//  Copyright (c) 2014 Vaavud. All rights reserved.
//

#import "UploadViewController.h"
#import <DropboxSDK/DropboxSDK.h>

#define RECORDING_TIME 5.2
#define PROGRESS_BAR_STEPS 20

@interface UploadViewController () <DBRestClientDelegate, UITextFieldDelegate, VaavudElectronicAnalysisDelegate, VaavudElectronicWindDelegate>
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (strong, nonatomic) VEVaavudElectronicSDK *vaavudElectronic;
@property (nonatomic, strong) DBRestClient *restClient;
@property (weak, nonatomic) IBOutlet UISwitch *recordingSwitch;
@property (weak, nonatomic) IBOutlet UIProgressView *recordingProgressBar;
@property (nonatomic) NSUInteger progressBarStepCount;
@property (strong, nonatomic) NSTimer *progressBarTimer;
@property (weak, nonatomic) IBOutlet UITextField *TextFieldTag;
@property (weak, nonatomic) IBOutlet UITextField *TextFieldIncrement;
//@property (nonatomic) NSUInteger increment;
@property (weak, nonatomic) IBOutlet UILabel *labelSpeed;
@property (weak, nonatomic) IBOutlet UILabel *labelDirection;
@property (weak, nonatomic) IBOutlet UIStepper *StepperIncrement;
@property (weak, nonatomic) IBOutlet UITextView *TextViewConsole;


@end

@implementation UploadViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.vaavudElectronic = [VEVaavudElectronicSDK sharedVaavudElectronic];
    
    
    [self.recordingSwitch setOn: [self.vaavudElectronic isRecording]];
    
    // try to link dropbox (if not linked) each time view is loaded
    [self linkDropbox];
    
    self.restClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
    self.restClient.delegate = self;
    
    self.StepperIncrement.maximumValue = 100000;
    
    [self.recordingProgressBar setProgress: 0.0];
    
    [self updateIncrementTextField:NULL];
    
    self.TextFieldTag.delegate = self;
    
    UITapGestureRecognizer *tapper = [[UITapGestureRecognizer alloc]
              initWithTarget:self action:@selector(handleSingleTap:)];
    tapper.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:tapper];
    
    
    self.TextViewConsole.text = @"";
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)updateIncrementTextField:(id)sender {
    self.TextFieldIncrement.text = [NSString stringWithFormat:@"%d", (int) self.StepperIncrement.value];
}

- (IBAction)TextFieldStepperEditingEnded:(id)sender {
    self.StepperIncrement.value = (float) [((UITextField*) sender).text integerValue];
    [self updateIncrementTextField:NULL];
}

- (void)handleSingleTap:(UITapGestureRecognizer *) sender
{
    [self.view endEditing:YES];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return NO;
}


- (IBAction)toggleRecording:(id)sender {
    
    if([self.activityIndicator isAnimating]) {
        if ([sender isOn]) {
            [sender setOn:NO];
        }
    }
    
    if ([sender isOn])
    {
//        [self.vaavudElectronic stop];
        [self.vaavudElectronic startRecording];
//        [self.vaavudElectronic start];
        
        double timeInterval = RECORDING_TIME/ (double) PROGRESS_BAR_STEPS;
        
        self.progressBarTimer = [NSTimer scheduledTimerWithTimeInterval:timeInterval target:self selector:@selector(endRecordingByTimer) userInfo:nil repeats:YES];
        [self.progressBarTimer setTolerance:0.1];
        [self.progressBarTimer fire];
      
    }
    else
    {
        [self.vaavudElectronic endRecording];
    }
    
}

- (void) endRecordingByTimer {
    
    if ( self.progressBarStepCount < PROGRESS_BAR_STEPS) {
        [self.recordingProgressBar setProgress: self.progressBarStepCount / (float) PROGRESS_BAR_STEPS];
        self.progressBarStepCount++;
    }
    else {
        [self.recordingProgressBar setProgress: 1.0];
        self.progressBarStepCount = 0;
        [self.progressBarTimer invalidate];
        [self.vaavudElectronic endRecording];
        [self.recordingSwitch setOn: [self.vaavudElectronic isRecording]];
        [self uploadAudioFile];
        [self uploadSummeryFile];
        self.StepperIncrement.value += self.StepperIncrement.stepValue;
    }
    

}

- (void) uploadSummeryFile {
    // Upload file to Dropbox
    
    if ([self.vaavudElectronic isRecording]) {
        [self.vaavudElectronic endRecording];
    }
    
    NSString *filename = [[self mainFileNameDropbox] stringByAppendingString: @".txt"];
    [self.vaavudElectronic generateSummaryFile];
    
    [self.restClient uploadFile:filename toPath:[self folderDropbox] withParentRev:nil fromPath:[[self.vaavudElectronic summeryPath] path]];
    [self.activityIndicator startAnimating];
    
    NSString *filename_angularVelocites = [[self mainFileNameDropbox] stringByAppendingString: @"_angularVelocities.txt"];
    
    [self.restClient uploadFile:filename_angularVelocites toPath:[self folderDropbox] withParentRev:nil fromPath:[[self.vaavudElectronic summeryAngularVelocitiesPath] path]];
    [self.activityIndicator startAnimating];

    
}


- (void) newRecordingReadyToUpload {
    //[self uploadAudioFile]; don't upload sound when Sleipnir is inserted.
}

- (void) newSpeed: (NSNumber*) speed {
    self.labelSpeed.text = [NSString stringWithFormat:@"%.2f", speed.floatValue];
}

- (void) newWindAngleLocal:(NSNumber*) angle {
    self.labelDirection.text = [NSString stringWithFormat:@"%d", angle.integerValue];
}


- (void) uploadAudioFile {
    // Upload file to Dropbox

    if ([self.vaavudElectronic isRecording]) {
        [self.vaavudElectronic endRecording];
    }
    
    NSString *filename = [[self mainFileNameDropbox] stringByAppendingString: @".wav"];
   
    [self.restClient uploadFile:filename toPath:[self folderDropbox] withParentRev:nil fromPath:[[self.vaavudElectronic recordingPath] path]];
    
    [self.activityIndicator startAnimating];
    
}

- (NSString *) mainFileNameDropbox {
    
    return [NSString stringWithFormat:@"%@_%@", self.TextFieldTag.text, self.TextFieldIncrement.text];
}

- (NSString *) folderDropbox {
    NSDateFormatter *formatter;
    NSString        *dateString;
    
    formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy'-'MM'-'dd"];
    
    dateString = [formatter stringFromDate:[NSDate date]];
    NSString *destDirBase = @"/";
    NSString *destDirFull = [destDirBase stringByAppendingString: dateString];
    
    return destDirFull;
}




/**
 DROPBOX
 */
- (void) linkDropbox {
    if (![[DBSession sharedSession] isLinked]) {
        [[DBSession sharedSession] linkFromController:self];
    }
}


- (void)restClient:(DBRestClient *)client uploadedFile:(NSString *)destPath
              from:(NSString *)srcPath metadata:(DBMetadata *)metadata {
    
    [self.activityIndicator stopAnimating];
    [self.recordingProgressBar setProgress: 0.0];
    
    NSLog(@"File uploaded successfully to path: %@", metadata.path);
    
    [self appendTextToConsole:  [NSString stringWithFormat: @"File uploaded successfully to path: %@", metadata.path ]];
    
    
    [self updateIncrementTextField:NULL];
    
}

- (void)restClient:(DBRestClient *)client uploadFileFailedWithError:(NSError *)error {
    NSLog(@"File upload failed with error: %@", error);
    //self.recordingTextField.text = @"File upload Error!";
}

- (void) appendTextToConsole: (NSString *) message {
    self.TextViewConsole.text = [NSString stringWithFormat: @"%@\n%@", self.TextViewConsole.text, message ];
    [self.TextViewConsole scrollRangeToVisible:NSMakeRange(0,[self.TextViewConsole.text length])];
}

- (void) viewDidAppear:(BOOL)animated {
    [self.vaavudElectronic addAnalysisListener:self];
    [self.vaavudElectronic addListener:self];
}

- (void) viewDidDisappear:(BOOL)animated {
    [self.vaavudElectronic removeAnalysisListener:self];
    [self.vaavudElectronic removeListener:self];
}

@end
