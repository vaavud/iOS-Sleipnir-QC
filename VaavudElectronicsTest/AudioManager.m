//
//  soundManager.m
//  VaavudElectronicsTest
//
//  Created by Andreas Okholm on 21/07/14.
//  Copyright (c) 2014 Vaavud. All rights reserved.
//

#define kAudioFilePath @"tempRawAudioFile.wav"

#define sampleFrequency 44100
#define signalFrequency 14700

#import "AudioManager.h"

@interface AudioManager() <EZMicrophoneDelegate, EZOutputDataSource>

@property (nonatomic) BOOL measurementActive;
@property (nonatomic) BOOL recordingActive;
@property (nonatomic) BOOL deviceAvailable;

@property (nonatomic) float originalAudioVolume;

/** The microphone component */
@property (nonatomic,strong) EZMicrophone *microphone;

/** The recorder component */
@property (nonatomic,strong) EZRecorder *recorder;

@property (nonatomic, weak) id<AudioManagerDelegate> delegate;


@end


@implementation AudioManager {
    double theta;
    double theta_increment;
    double amplitude;
    int *intArray;
    float *arrayLeft;
}


#pragma mark - Initialization
-(id)init {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:@"-init is not a valid initializer for the class SoundManager"
                                 userInfo:nil];
    return nil;
}


- (id)initWithDirDelegate:(id<AudioManagerDelegate, SoundProcessingDelegate, DirectionDetectionDelegate>)delegate {
    
    self = [super init];
    
    self.delegate = delegate;
    
    // create sound processor (locates ticks)
    self.soundProcessor = [[SoundProcessingAlgo alloc] initWithDirDelegate:delegate];
    
    // Create an instance of the microphone and tell it to use this object as the delegate
    self.microphone = [EZMicrophone microphoneWithDelegate:self];

    [self setupSoundOutput];
    
    // Assign a delegate to the shared instance of the output to provide the output audio data
    [EZOutput sharedOutput].outputDataSource = self;
    
    // set the output format from the audioOutput stream.
    [[EZOutput sharedOutput] setAudioStreamBasicDescription: [self getBasicAudioOutStreamingFormat]];
    
    // register for notification for chances in audio routing (inserting/removing jack plut)
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioRouteChangeListenerCallback:)
                                                 name:AVAudioSessionRouteChangeNotification
                                               object:nil];
    
    // set device available property
    self.deviceAvailable = ([self isVaavudDeviceAvailable]) ? YES : NO;
    
    return self;
}



-(void) start {
    
    self.measurementActive = YES;
    
    if (self.deviceAvailable) {
        [self startMicAndOutput];
    }
}

-(void) stop {
    [self toggleMicrophone: NO];
    [self toggleOutput: NO];
    MPMusicPlayerController* musicPlayer = [MPMusicPlayerController iPodMusicPlayer];
    if (musicPlayer.volume != self.originalAudioVolume) {
        musicPlayer.volume = self.originalAudioVolume;
    }
    
    [self.delegate vaavudStopMeasureing];
}


- (void) startMicAndOutput {
    [self toggleMicrophone: YES];
    [self toggleOutput: YES];
    
    MPMusicPlayerController* musicPlayer = [MPMusicPlayerController iPodMusicPlayer];
    
    self.originalAudioVolume = musicPlayer.volume;
    
    if (musicPlayer.volume != 1) {
         musicPlayer.volume = 1; // device volume will be changed to maximum value
    }
    
    [self.delegate vaavudStartedMeasureing];
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









- (BOOL) isVaavudDeviceAvailable {
    
    // might perform more check buf first check if headphoneOut and headphone Mic is available
    
    return ([self isHeadphoneMicAvailable] && [self isHeadphoneOutAvailable]) ? YES : NO;
}


- (BOOL) isHeadphoneOutAvailable {
    
    AVAudioSessionRouteDescription *audioRoute = [[AVAudioSession sharedInstance] currentRoute];
    for (AVAudioSessionPortDescription* desc in [audioRoute outputs]) {
        if ([[desc portType] isEqualToString:AVAudioSessionPortHeadphones])
            return YES;
    }
    return NO;
}


- (BOOL) isHeadphoneMicAvailable {
    
    AVAudioSessionRouteDescription *audioRoute = [[AVAudioSession sharedInstance] currentRoute];
    for (AVAudioSessionPortDescription* desc in [audioRoute inputs]) {
        if ([[desc portType] isEqualToString:AVAudioSessionPortHeadsetMic])
            return YES;
    }
    return NO;
}


- (void) setupSoundOutput {
    
    double frequency = signalFrequency;
    double samplerate = sampleFrequency;
    theta_increment = 2.0 * M_PI * frequency / samplerate;
    amplitude = 1;
    
}




// If the user pulls out he headphone jack, stop playing.
- (void)audioRouteChangeListenerCallback:(NSNotification*)notification
{
    NSDictionary *interuptionDict = notification.userInfo;
    
    NSInteger routeChangeReason = [[interuptionDict valueForKey:AVAudioSessionRouteChangeReasonKey] integerValue];
    
    switch (routeChangeReason) {
            
        case AVAudioSessionRouteChangeReasonOldDeviceUnavailable:
//            NSLog(@"AVAudioSessionRouteChangeReasonOldDeviceUnavailable");
//            NSLog(@"Headphone/Line was pulled. Stopping player....");
            
            self.deviceAvailable = NO;
            [self.delegate vaavudWasUnpluged];
            [self stop];
            
            break;
        case AVAudioSessionRouteChangeReasonNewDeviceAvailable:
//            NSLog(@"AVAudioSessionRouteChangeReasonNewDeviceAvailable");
//            NSLog(@"Headphone/Line plugged in");
            
            [self toggleMicrophone: YES];
            // For some reason Microphone needs to be active to determine audio route properly.
            // It works fine the first time the app is started without....
            
            if (!self.deviceAvailable && [self isVaavudDeviceAvailable]) {
                self.deviceAvailable = true;
                [self.delegate vaavudPlugedIn];
                if (self.measurementActive) {
                    [self startMicAndOutput];
                }
            }
            
            break;
            
//        case AVAudioSessionRouteChangeReasonCategoryChange:
//            // called at start - also when other audio wants to play
//            NSLog(@"AVAudioSessionRouteChangeReasonCategoryChange");
//            break;
            
        default:
            NSLog(@"default audio stuff");

    }
}



/* delegate method - Feed microphone data to sound-processor and plot */
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



// delegate method - feed microphone data to recorder (audio file).
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




- (void)toggleOutput: (bool) output {
    if (output) {
        [[EZOutput sharedOutput] startPlayback];
        
    } else {
        [[EZOutput sharedOutput] stopPlayback];
    }
}

- (void) toggleMicrophone:(bool) micOn {
    
    if( micOn){
        [self.microphone startFetchingAudio];
    }
    else {
        [self.microphone stopFetchingAudio];
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




- (AudioStreamBasicDescription) getBasicAudioOutStreamingFormat {
    
    size_t bytesPerSample = sizeof (AudioUnitSampleType);
    AudioStreamBasicDescription stereoStreamFormat = {0};
    
    
    stereoStreamFormat.mFormatID          = kAudioFormatLinearPCM;
    //    stereoStreamFormat.mFormatFlags       = kAudioFormatFlagsAudioUnitCanonical;
    stereoStreamFormat.mFormatFlags       = kAudioFormatFlagsNativeFloatPacked | kAudioFormatFlagIsNonInterleaved;
    stereoStreamFormat.mBytesPerPacket    = bytesPerSample;
    stereoStreamFormat.mBytesPerFrame     = bytesPerSample;
    stereoStreamFormat.mFramesPerPacket   = 1;
    stereoStreamFormat.mBitsPerChannel    = 8 * bytesPerSample;
    stereoStreamFormat.mChannelsPerFrame  = 2;           // 2 indicates stereo
    stereoStreamFormat.mSampleRate        = 44100;
    
    return stereoStreamFormat;
    
}


@end
