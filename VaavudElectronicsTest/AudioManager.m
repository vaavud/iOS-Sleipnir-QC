//
//  soundManager.m
//  VaavudElectronicsTest
//
//  Created by Andreas Okholm on 21/07/14.
//  Copyright (c) 2014 Vaavud. All rights reserved.
//

#import "AudioManager.h"
#import "SoundProcessingAlgo.h"


@interface AudioManager() <EZMicrophoneDelegate, EZOutputDataSource>

@property (strong, nonatomic) SoundProcessingAlgo *soundProcessor;
@property (nonatomic, assign) BOOL recordingActive;
@property (nonatomic, strong) NSMutableArray *intArray;


/**
 The microphone component
 */
@property (nonatomic,strong) EZMicrophone *microphone;

/**
 The recorder component
 */
@property (nonatomic,strong) EZRecorder *recorder;



@end

@implementation AudioManager

double theta;
double theta_increment;
double amplitude;
int *intArray;
float *arrayLeft;

#pragma mark - Initialization
-(id)init {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:@"-init is not a valid initializer for the class SoundManager"
                                 userInfo:nil];
    return nil;
}

- (id)initWithDirDelegate:(id<VaavudElectronicWindDelegate>)delegate {
    
    self = [super init];
    
    self.soundProcessor = [[SoundProcessingAlgo alloc] initWithDirDelegate:delegate];
    
    // Create an instance of the microphone and tell it to use this view controller instance as the delegate
    self.microphone = [EZMicrophone microphoneWithDelegate:self];

    
    /*
     Log out where the file is being written to within the app's documents directory
     */
    NSLog(@"File written to application sandbox's documents directory: %@",[self recordingFilePathURL]);
    
    // output variables
    
    double frequency = 14700;
    double samplerate = 44100;
    theta_increment = 2.0 * M_PI * frequency / samplerate;
    amplitude = 1;
    
    
    // Assign a delegate to the shared instance of the output to provide the output audio data
    [EZOutput sharedOutput].outputDataSource = self;
    
    size_t bytesPerSample = sizeof (AudioUnitSampleType);
    AudioStreamBasicDescription stereoStreamFormat = {0};
    
    NSLog(@"bytes per sample: %zu", bytesPerSample);
    
    stereoStreamFormat.mFormatID          = kAudioFormatLinearPCM;
    //    stereoStreamFormat.mFormatFlags       = kAudioFormatFlagsAudioUnitCanonical;
    stereoStreamFormat.mFormatFlags       = kAudioFormatFlagsNativeFloatPacked | kAudioFormatFlagIsNonInterleaved;
    stereoStreamFormat.mBytesPerPacket    = bytesPerSample;
    stereoStreamFormat.mBytesPerFrame     = bytesPerSample;
    stereoStreamFormat.mFramesPerPacket   = 1;
    stereoStreamFormat.mBitsPerChannel    = 8 * bytesPerSample;
    stereoStreamFormat.mChannelsPerFrame  = 2;           // 2 indicates stereo
    stereoStreamFormat.mSampleRate        = 44100;
    
    [[EZOutput sharedOutput] setAudioStreamBasicDescription:stereoStreamFormat];
    
    
    return self;
}


- (void) toggleMicrophone:(bool) micOn {
    
    if( micOn){
        [self.microphone startFetchingAudio];
    }
    else {
        [self.microphone stopFetchingAudio];
    }
    
}


// Starts the internal soundfile recorder
- (void) startRecording {
    // Create the recorder
    self.recorder = [EZRecorder recorderWithDestinationURL:[self recordingFilePathURL]
                                              sourceFormat:self.microphone.audioStreamBasicDescription
                                       destinationFileType:EZRecorderFileTypeWAV];
    
    self.recordingActive = YES;
}

// Ends the internal soundfile recorder
- (void) endRecording {
    self.recordingActive = NO;
    [self.recorder closeAudioFile];
    self.recorder = nil;
    
}

// returns true if recording is active
- (BOOL) isRecording {
    return self.recordingActive;
}

// returns the local path of the recording
- (NSURL*) recordingPath {
    return [self recordingFilePathURL];
}




-(void) start {
    [self toggleMicrophone: YES];
    [self toggleOutput: YES];
}

-(void) stop {
    [self toggleMicrophone: NO];
    [self toggleOutput: NO];
}



#pragma mark - EZMicrophoneDelegate
#warning Thread Safety
// Note that any callback that provides streamed audio data (like streaming microphone input) happens on a separate audio thread that should not be blocked. When we feed audio data into any of the UI components we need to explicity create a GCD block on the main thread to properly get the UI to work.
-(void)microphone:(EZMicrophone *)microphone
 hasAudioReceived:(float **)buffer
   withBufferSize:(UInt32)bufferSize
withNumberOfChannels:(UInt32)numberOfChannels {
    // Getting audio data as an array of float buffer arrays. What does that mean? Because the audio is coming in as a stereo signal the data is split into a left and right channel. So buffer[0] corresponds to the float* data for the left channel while buffer[1] corresponds to the float* data for the right channel.
    
    if (intArray == NULL) {
        arrayLeft = buffer[0];
        
        intArray = malloc(sizeof(int) * bufferSize); /* allocate memory for 50 int's */
        if (!intArray) { /* If data == 0 after the call to malloc, allocation failed for some reason */
            perror("Error allocating memory");
            abort();
        }
        /* at this point, we know that data points to a valid block of memory.
         Remember, however, that this memory is not initialized in any way -- it contains garbage.
         Let's start by clearing it. */
        memset(intArray, 0, sizeof(int)*bufferSize);
        /* now our array contains all zeroes. */
    }
    
    
    for(int i = 0; i < bufferSize; ++i) {
        intArray[i] = (int) (arrayLeft[i]*1000);
    }
    
    [self.soundProcessor newSoundData:intArray bufferLength:bufferSize];
    
    
    // See the Thread Safety warning above, but in a nutshell these callbacks happen on a separate audio thread. We wrap any UI updating in a GCD block on the main thread to avoid blocking that audio flow.
    dispatch_async(dispatch_get_main_queue(),^{
        // All the audio plot needs is the buffer data (float*) and the size. Internally the audio plot will handle all the drawing related code, history management, and freeing its own resources. Hence, one badass line of code gets you a pretty plot :)
        if (self.audioPlot) {
            [self.audioPlot updateBuffer:buffer[0] withBufferSize:bufferSize];
        }
    });
    
    
}




-(void)microphone:(EZMicrophone *)microphone
    hasBufferList:(AudioBufferList *)bufferList
   withBufferSize:(UInt32)bufferSize
withNumberOfChannels:(UInt32)numberOfChannels {
    
    // Getting audio data as a buffer list that can be directly fed into the EZRecorder. This is happening on the audio thread - any UI updating needs a GCD main queue block. This will keep appending data to the tail of the audio file.
    if( self.recordingActive ){
        [self.recorder appendDataFromBufferList:bufferList
                                 withBufferSize:bufferSize];
    }
}


- (void) toggleRecording: (BOOL) recording {
    
//    if (recording) {
//        self.isRecording = self.isRecording ? false : true;
//    } else {
//        self.isRecording = [sender isOn];
//    }
    
    
    if(recording )
    {
        /*
         Create the recorder
         */
        self.recorder = [EZRecorder recorderWithDestinationURL:[self recordingFilePathURL]
                                                  sourceFormat:self.microphone.audioStreamBasicDescription
                                           destinationFileType:EZRecorderFileTypeWAV];
    }
    else
    {
        [self.recorder closeAudioFile];
    }
}


- (void)toggleOutput: (bool) output {
    if (output) {
        [[EZOutput sharedOutput] startPlayback];
        
    } else {
        [[EZOutput sharedOutput] stopPlayback];
    }
}


/**
 OUTPUT
 */

// Use the AudioBufferList datasource method to read from an EZAudioFile
-(void)             output:(EZOutput *)output
 shouldFillAudioBufferList:(AudioBufferList *)audioBufferList
        withNumberOfFrames:(UInt32)frames
{
    
    
    // This is a mono tone generator so we only need the first buffer
	const int channelLeft = 0;
	const int channelRight = 1;
    
    Float32 *bufferLeft = (Float32 *)audioBufferList->mBuffers[channelLeft].mData;
    Float32 *bufferRight = (Float32 *)audioBufferList->mBuffers[channelRight].mData;
    
    // Generate the samples
	for (UInt32 frame = 0; frame < frames; frame++)
	{
		bufferLeft[frame] = sin(theta) * amplitude;
        bufferRight[frame] = -sin(theta) * amplitude;
        
		theta += theta_increment;
		if (theta > 2.0 * M_PI)
		{
			theta -= 2.0 * M_PI;
		}
	}
    
    //    NSLog(@"left: %f", bufferLeft[frame]);
    
    
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

-(NSURL*)recordingFilePathURL {
    return [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/%@",
                                   [self applicationDocumentsDirectory],
                                   kAudioFilePath]];
}


@end
