//
//  vaavudViewController.m
//  VaavudElectronicsTest
//
//  Created by Andreas Okholm on 04/06/14.
//  Copyright (c) 2014 Vaavud. All rights reserved.
//

#import "vaavudViewController.h"
#import <DropboxSDK/DropboxSDK.h>

@interface vaavudViewController () <DBRestClientDelegate, EZMicrophoneDelegate, EZOutputDataSource>
@property (weak, nonatomic) IBOutlet UILabel *recordingTextField;
@property (weak, nonatomic) IBOutlet UILabel *microphoneTextField;
@property (weak, nonatomic) IBOutlet UILabel *outputTextField;
@property (nonatomic, strong) DBRestClient *restClient;
@property (nonatomic, assign) BOOL isRecording;
@end

@implementation vaavudViewController
@synthesize audioPlot;
@synthesize recorder;
@synthesize microphone;
@synthesize isRecording;

double theta;
double theta_increment;
double amplitude;


- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.restClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
    self.restClient.delegate = self;
    
    
    // Create an instance of the microphone and tell it to use this view controller instance as the delegate
    self.microphone = [EZMicrophone microphoneWithDelegate:self];
    
    
    /*
     Customizing the audio plot's look
     */
    // Background color
    self.audioPlot.backgroundColor = [UIColor colorWithRed: 0.984 green: 0.71 blue: 0.365 alpha: 1];
    // Waveform color
    self.audioPlot.color           = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0];
    // Plot type
    self.audioPlot.plotType        = EZPlotTypeBuffer;
    // Fill
    self.audioPlot.shouldFill      = NO;
    // Mirror
    self.audioPlot.shouldMirror    = YES;
    
    /*
     Start the microphone
     */
    [self.microphone startFetchingAudio];
    self.microphoneTextField.text = @"Microphone On";
    self.recordingTextField.text = @"Not Recording";
    self.outputTextField.text = @"Output off";
    
    //  self.playingTextField.text = @"Not Playing";
    
    // Hide the play button
//    self.playButton.hidden = YES;
    
    
    
    /*
     Log out where the file is being written to within the app's documents directory
     */
    NSLog(@"File written to application sandbox's documents directory: %@",[self testFilePathURL]);
    
    // output variables
    
    double frequency = 10000;
    double samplerate = 44100;
    theta_increment = 2.0 * M_PI * frequency / samplerate;
    amplitude = 1;
    
    
    
    // Assign a delegate to the shared instance of the output to provide the output audio data
    [EZOutput sharedOutput].outputDataSource = self;
    
    
}
- (IBAction)toggleMicrophone:(id)sender {
    
    if( ![sender isOn] ){
        [self.microphone stopFetchingAudio];
        self.microphoneTextField.text = @"Microphone Off";
    }
    else {
        [self.microphone startFetchingAudio];
        self.microphoneTextField.text = @"Microphone On";
    }
    
}


#pragma mark - EZMicrophoneDelegate
#warning Thread Safety
// Note that any callback that provides streamed audio data (like streaming microphone input) happens on a separate audio thread that should not be blocked. When we feed audio data into any of the UI components we need to explicity create a GCD block on the main thread to properly get the UI to work.
-(void)microphone:(EZMicrophone *)microphone
 hasAudioReceived:(float **)buffer
   withBufferSize:(UInt32)bufferSize
withNumberOfChannels:(UInt32)numberOfChannels {
    // Getting audio data as an array of float buffer arrays. What does that mean? Because the audio is coming in as a stereo signal the data is split into a left and right channel. So buffer[0] corresponds to the float* data for the left channel while buffer[1] corresponds to the float* data for the right channel.
    
    // See the Thread Safety warning above, but in a nutshell these callbacks happen on a separate audio thread. We wrap any UI updating in a GCD block on the main thread to avoid blocking that audio flow.
    dispatch_async(dispatch_get_main_queue(),^{
        // All the audio plot needs is the buffer data (float*) and the size. Internally the audio plot will handle all the drawing related code, history management, and freeing its own resources. Hence, one badass line of code gets you a pretty plot :)
        [self.audioPlot updateBuffer:buffer[0] withBufferSize:bufferSize];
    });
}



-(void)microphone:(EZMicrophone *)microphone
    hasBufferList:(AudioBufferList *)bufferList
   withBufferSize:(UInt32)bufferSize
withNumberOfChannels:(UInt32)numberOfChannels {
    
    // Getting audio data as a buffer list that can be directly fed into the EZRecorder. This is happening on the audio thread - any UI updating needs a GCD main queue block. This will keep appending data to the tail of the audio file.
    if( self.isRecording ){
        [self.recorder appendDataFromBufferList:bufferList
                                 withBufferSize:bufferSize];
    }
    
}

- (IBAction)toggleRecording:(id)sender {
    
    if (sender == NULL) {
        self.isRecording = self.isRecording ? false : true;
    } else {
        self.isRecording = [sender isOn];
    }
    
    
    if(self.isRecording )
    {
        /*
         Create the recorder
         */
        self.recorder = [EZRecorder recorderWithDestinationURL:[self testFilePathURL]
                                                  sourceFormat:self.microphone.audioStreamBasicDescription
                                           destinationFileType:EZRecorderFileTypeWAV];
    }
    else
    {
        [self.recorder closeAudioFile];
    }
    self.recordingTextField.text = self.isRecording ? @"Recording" : @"Not Recording";

}


- (IBAction)toggleOutput:(id)sender {
    if ([sender isOn]) {
        [[EZOutput sharedOutput] startPlayback];
        
    } else {
        [[EZOutput sharedOutput] stopPlayback];
    }
    
    self.outputTextField.text = [sender isOn] ? @"Output on" : @"Output Off";
    
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/**
 OUTPUT
 */

// Use the AudioBufferList datasource method to read from an EZAudioFile
-(void)             output:(EZOutput *)output
 shouldFillAudioBufferList:(AudioBufferList *)audioBufferList
        withNumberOfFrames:(UInt32)frames
{
//    for (int i = 0; i < audioBufferList->mNumberBuffers; i++) {
//        audioBufferList->mBuffers[i]
//    }
    
    
    // This is a mono tone generator so we only need the first buffer
	const int channelLeft = 0;
	const int channelRight = 1;
    
    Float32 *bufferLeft = (Float32 *)audioBufferList->mBuffers[channelLeft].mData;
    Float32 *bufferRight = (Float32 *)audioBufferList->mBuffers[channelRight].mData;
    
    // Generate the samples
	for (UInt32 frame = 0; frame < frames; frame++)
	{
		bufferLeft[frame] = sin(theta) * amplitude;
        bufferRight[frame] = cos(theta) * amplitude;
        
		theta += theta_increment;
		if (theta > 2.0 * M_PI)
		{
			theta -= 2.0 * M_PI;
		}
	}

}


/**
 DROPBOX
 */
- (IBAction)didPressLink {
    if (![[DBSession sharedSession] isLinked]) {
        [[DBSession sharedSession] linkFromController:self];
    }
}

- (IBAction)uploadFile {
    // Write a file to the local documents directory
    NSString *text = @"Hello world.";
    NSString *filename = @"working-draft.txt";
    NSString *localDir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString *localPath = [localDir stringByAppendingPathComponent:filename];
    [text writeToFile:localPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    
    // Upload file to Dropbox
    NSString *destDir = @"/";
    [self.restClient uploadFile:filename toPath:destDir withParentRev:nil fromPath:localPath];
    NSLog(@"%@", localPath);
}


- (void)restClient:(DBRestClient *)client uploadedFile:(NSString *)destPath
              from:(NSString *)srcPath metadata:(DBMetadata *)metadata {
    NSLog(@"File uploaded successfully to path: %@", metadata.path);
}

- (void)restClient:(DBRestClient *)client uploadFileFailedWithError:(NSError *)error {
    NSLog(@"File upload failed with error: %@", error);
}

- (IBAction)uploadAudioFile {
    // Upload file to Dropbox
    
    if (self.isRecording) {
        [self toggleRecording: NULL];
    }
    
    NSDateFormatter *formatter;
    NSString        *dateString;
    
    formatter = [[NSDateFormatter alloc] init];
//    [formatter setDateFormat:@"dd-MM-yyyy HH:mm:ss"];
    [formatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"];
    
    dateString = [formatter stringFromDate:[NSDate date]];
    
    
    
    NSString *filename = [dateString stringByAppendingString: @"_mic.wav"];
    NSString *destDir = @"/";
    [self.restClient uploadFile:filename toPath:destDir withParentRev:nil fromPath:[[self testFilePathURL] path]];
    
}

/**
 EZaudio File Utility functions
 */

-(NSString*)applicationDocumentsDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return basePath;
}

-(NSURL*)testFilePathURL {
    return [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/%@",
                                   [self applicationDocumentsDirectory],
                                   kAudioFilePath]];
}

@end
