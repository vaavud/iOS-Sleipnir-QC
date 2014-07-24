//
//  DirectionDetectionAlgo.m
//  VaavudElectronicsTest
//
//  Created by Andreas Okholm on 11/06/14.
//  Copyright (c) 2014 Vaavud. All rights reserved.
//

#import "DirectionDetectionAlgo.h"
#import "vaavudViewController.h"
//#define TICKS_PR_REV 10
#define TICKS_PR_REV 15
#define SAMPLE_BUFFER_SIZE 150
#define UPDATE_INTERVAL 0.1 // 10 times a second
#define ANGLE_CORRRECTION_COEFFICIENT 200 // originally 400 (but since actual velocity difference is about double...
#define ANGLE_DIFF 1

@interface DirectionDetectionAlgo() {
    
    unsigned long totalTickCounter;
    unsigned int tickCounter;
    unsigned int tickBufferCounter;
    unsigned int lastTickBufferCounter;
    unsigned int startCounter;
    
    unsigned long totalSampleCount[TICKS_PR_REV];
    int mvgSampleCountSum[TICKS_PR_REV];
    int sampleCountBuffer[TICKS_PR_REV][SAMPLE_BUFFER_SIZE];
    float mvgRelativeSpeed[TICKS_PR_REV];
    double nextRefreshTime;
    BOOL startLocated;
    int lastSample;
    int tickEdgeAngle[TICKS_PR_REV+2]; // add one point in ether end
    int angleEstimator;
}

@property (strong, nonatomic) id<VaavudElectronicWindDelegate> dirDelegate;

@end


@implementation DirectionDetectionAlgo


//float compensation[TICKS_PR_REV] = {1.039799138,1.045523707,1.046944848,1.060272909,1.062841846,1.069164251,1.070833422,1.065796962,1.05726205,0.67142769};
float compensation[TICKS_PR_REV] = {1.02127659574468,1.02127659574468,1.02127659574468,1.02127659574468,1.02127659574468,1.02127659574468,1.02127659574468,1.02127659574468,1.02127659574468,1.02127659574468,1.02127659574468,1.02127659574468,1.02127659574468,1.02127659574468,0.774193548387097};

float fitcurve[360] = {0.492458649,0.475097354,0.457163957,0.43815945,0.417886639,0.396242588,0.373193991,0.348732732,0.322879916,0.295672578,0.267183381,0.237489337,0.206641721,0.174677409,0.141600479,0.107406628,0.07209709,0.035688557,-0.001736149,-0.040075612,-0.07923396,-0.119129452,-0.159740474,-0.201061524,-0.243077494,-0.285760295,-0.329033628,-0.372803527,-0.416960496,-0.461402046,-0.506079352,-0.550959589,-0.596012058,-0.641196554,-0.686428389,-0.7316121,-0.776658427,-0.821486639,-0.86604414,-0.910288407,-0.954188159,-0.997700711,-1.04073065,-1.083175145,-1.12494851,-1.16598175,-1.206248783,-1.245730511,-1.284401833,-1.322222309,-1.35911024,-1.394980303,-1.429757641,-1.463384106,-1.495839109,-1.527106984,-1.557169943,-1.585997072,-1.613529906,-1.639696711,-1.664406959,-1.687601625,-1.709282576,-1.729457027,-1.74813003,-1.765282558,-1.780859427,-1.794803517,-1.807059467,-1.817581803,-1.826338197,-1.833321748,-1.838553517,-1.84204704,-1.843804633,-1.843792211,-1.841944468,-1.838249925,-1.832745295,-1.825473679,-1.816480633,-1.80579389,-1.793427007,-1.779377851,-1.763635502,-1.746202119,-1.727092459,-1.706365053,-1.68409811,-1.660337682,-1.635109964,-1.608412061,-1.580235053,-1.550616518,-1.519614761,-1.487298201,-1.453736585,-1.418986229,-1.383093725,-1.346079822,-1.307958645,-1.268751389,-1.228494188,-1.187278554,-1.145207708,-1.102372253,-1.058842387,-1.014624021,-0.969715571,-0.924141562,-0.877944757,-0.831209266,-0.78402377,-0.736464629,-0.688598276,-0.640468694,-0.592115358,-0.543576794,-0.494899106,-0.44614985,-0.397404684,-0.348751134,-0.300263472,-0.251976054,-0.203912713,-0.156086855,-0.10852055,-0.061262099,-0.014363334,0.032125377,0.078156936,0.123691932,0.168700214,0.213172016,0.257094806,0.300440905,0.343184169,0.385308604,0.426806622,0.467688543,0.507964995,0.547639562,0.58670484,0.625126162,0.662869708,0.699917607,0.73625826,0.771890291,0.806812245,0.841016494,0.874493663,0.907232597,0.939221704,0.970449152,1.000900762,1.030553985,1.059385444,1.087375959,1.114505087,1.140742981,1.166060005,1.190438161,1.213862209,1.236314756,1.257776959,1.278225832,1.297633722,1.315954517,1.333135258,1.349119955,1.363855799,1.377318038,1.389494105,1.400378159,1.409951801,1.418076094,1.424530067,1.428874321,1.430639695,1.430122786,1.428011813,1.424680913,1.420303899,1.414930331,1.408532526,1.401097839,1.392624121,1.383096477,1.37249209,1.360817791,1.348104446,1.334379409,1.319665819,1.303975728,1.287311211,1.269681735,1.251104507,1.231593603,1.211159378,1.189813449,1.167569322,1.144447977,1.120479517,1.095694423,1.07012312,1.043804911,1.016791552,0.989133975,0.960880318,0.932066647,0.902710394,0.872830775,0.842452803,0.811610204,0.780351071,0.748729377,0.716807246,0.684646888,0.652308948,0.619847393,0.587303161,0.554717634,0.522136376,0.489608502,0.457189654,0.42493216,0.392879086,0.361074674,0.329568768,0.298422805,0.267723596,0.237553106,0.207972891,0.179032244,0.150757817,0.123176972,0.096327221,0.07024757,0.044976913,0.020561135,-0.002936205,-0.025457777,-0.046969061,-0.067447519,-0.086892,-0.105291043,-0.122598499,-0.138774737,-0.15381041,-0.167694295,-0.180398536,-0.191902979,-0.202213255,-0.211335348,-0.219266207,-0.225994202,-0.231489991,-0.235734227,-0.238738505,-0.240530984,-0.241168554,-0.240696271,-0.239120849,-0.236449199,-0.232701902,-0.227904392,-0.222088868,-0.215295326,-0.207579507,-0.198992345,-0.189568766,-0.179341391,-0.168342673,-0.156609304,-0.144187581,-0.131137561,-0.117546956,-0.103496067,-0.089040512,-0.074222947,-0.059064807,-0.043593933,-0.027858432,-0.011911511,0.004188358,0.020386066,0.036635476,0.05290363,0.069183898,0.085468723,0.101740721,0.117966516,0.134080232,0.15002522,0.165775284,0.18132632,0.196714689,0.211966194,0.227069861,0.241999243,0.25670392,0.271133347,0.285244656,0.299017463,0.312482338,0.325666375,0.338570125,0.351176947,0.363437404,0.375304993,0.386753264,0.397767313,0.40835403,0.418526516,0.428305101,0.437708505,0.446747839,0.455425806,0.463725206,0.471637854,0.479191402,0.486426988,0.493406718,0.500187139,0.506796072,0.513247318,0.519527751,0.525622405,0.531527514,0.537247267,0.542804947,0.548221221,0.553493734,0.558608105,0.563524665,0.568203411,0.572624306,0.576775653,0.580660011,0.584271312,0.587555089,0.590442236,0.592853185,0.594707773,0.595934991,0.596475777,0.596313552,0.595435733,0.593792844,0.591320567,0.587934721,0.58354927,0.578099024,0.571531296,0.563824527,0.554976375,0.545033796,0.53411216,0.522618315,0.51106101};

#pragma mark - Initialization
-(id)init {
    return [self initWithDirDelegate:NULL];
}

- (id) initWithDirDelegate:(id<VaavudElectronicWindDelegate>)delegate {
    
    
    self = [super init];
    self.dirDelegate = delegate;
    nextRefreshTime = CACurrentMediaTime();
    startLocated = false;
    
    
    // standard tick
    
//    int stdTickSize = 34;
//    int bigTickSize = 54;
    
    float stdTickSize = 23.5;
    //int bigTickSize = 31;
    
    tickEdgeAngle[0] = 0;
    for (int i = 1; i < TICKS_PR_REV; i++) {
        tickEdgeAngle[i] = (int) (stdTickSize*i); // shift array one to the right
    }
    
    for (int i = 0 ; i < TICKS_PR_REV; i++) {
        NSLog(@"angle:%d", tickEdgeAngle[i]);
    }
    
    return self;
    
    
}


- (void) locateStart:(int)samples{
    if (samples > 1.2 * lastSample && samples < 1.4 * lastSample) {
        //NSLog(@"StartLocated: Ratio: %f, StartCounter: %d", samples / ((float) lastSample), startCounter);
        
        
        if (startCounter == 2* TICKS_PR_REV) {
            startLocated = true;
        }
        
        if (startCounter % TICKS_PR_REV != 0 || startCounter > 2 * TICKS_PR_REV) {
            startCounter = 0;
        }
        
    }
    else {
        lastSample = samples;
    }
    
    startCounter++;
    
}

- (void) newTick:(int)samples {
    
    // recalibrate if pattern is wrong
    if (samples > 882000) {
        [self resetDirection];
        NSLog(@"reset: Samplet over 882000");
    }
    if (!startLocated) {
        [self locateStart:samples];
        return;
    }
    totalTickCounter++;
    
    // Moving Avg subtract
    mvgSampleCountSum[tickCounter] -= sampleCountBuffer[tickCounter][tickBufferCounter];
    
    // Moving avg Update buffer value
    sampleCountBuffer[tickCounter][tickBufferCounter] = samples;
    
    // Moving Avg update SUM
    mvgSampleCountSum[tickCounter] += samples;

    // Total SampleCount
    totalSampleCount[tickCounter] += samples;
    
    
    lastTickBufferCounter = tickBufferCounter;
    
    
    if (tickCounter == TICKS_PR_REV-1) {
        tickCounter = 0;
        
        // check if directionReset is needed every rotation
        
        if (samples < 1.0 * lastSample || samples > 2.0 * lastSample) {
            NSLog(@"Out of ratio: %f", samples / ((float) lastSample));
            [self resetDirection];
            return;
        }
        
        // update results
        if (CACurrentMediaTime() > nextRefreshTime) {
            [self updateUI];
            [self updateNextRefreshTime];
        }
        
        
        
        if (tickBufferCounter == SAMPLE_BUFFER_SIZE-1) {
            tickBufferCounter = 0;
            [self updateUI];
        } else {
            tickBufferCounter++;
        }
    } else {
        tickCounter++;
    }
    
    lastSample = samples;
    
}

- (void) updateNextRefreshTime {
    if (nextRefreshTime - UPDATE_INTERVAL < CACurrentMediaTime()) {
        nextRefreshTime = CACurrentMediaTime() + UPDATE_INTERVAL;
    }
    else {
        nextRefreshTime += UPDATE_INTERVAL;
    }
}


- (void) resetDirection {
    
    NSLog(@"reset");
    startLocated = false;
    lastSample = 0;
    
    
    tickCounter = 0;
    tickBufferCounter = 0;
    
    // unsigned long totalSampleCount[TICKS_PR_REV];
    // int mvgSampleCountSum[TICKS_PR_REV];
    // float mvgRelativeSpeed[TICKS_PR_REV]; does not need clearing!
    for (int i = 0; i < TICKS_PR_REV; i++) {
        totalSampleCount[i] = 0;
        mvgSampleCountSum[i] = 0;
    }
    
    //int sampleCountBuffer[TICKS_PR_REV][SAMPLE_BUFFER_SIZE];
    
    for (int outer = 0; outer < TICKS_PR_REV; outer++) {
        for (int inner = 0; inner < SAMPLE_BUFFER_SIZE; inner++) {
            sampleCountBuffer[outer][inner] = 0;
        }
    }
    
    // double nextRefreshTime; does not need reset
    

}



//- (void) printStatus {
//    NSLog(@"BufferRotation");
//    
//}
//
//// http://stackoverflow.com/questions/717762/how-to-calculate-the-vertex-of-a-parabola-given-three-points
//- (void) parableTopx1:(int)x1 andx2:(int)x2 andx3:(int)x3 andy1:(float)y1 andy2:(float)y2 andy3:(float)y3 andxout:(float*)xout andyout:(float*)yout {
//    
//    float denom = (x1 - x2) * (x1 - x3) * (x2 - x3);
//	float A     = (x3 * (y2 - y1) + x2 * (y1 - y3) + x1 * (y3 - y2)) / denom;
//	float B     = (x3*x3 * (y1 - y2) + x2*x2 * (y3 - y1) + x1*x1 * (y2 - y3)) / denom;
//	float C     = (x2 * x3 * (x2 - x3) * y1 + x3 * x1 * (x3 - x1) * y2 + x1 * x2 * (x1 - x2) * y3) / denom;
//    
//	*xout = -B / (2*A);
//	*yout = C - B*B / (4*A);
//    
//}



- (void) updateUI {
    
    // Calculate relative velocities
    int totalMvgSampleCount = 0;
    for (int i = 0; i < TICKS_PR_REV; i++) {
        totalMvgSampleCount += mvgSampleCountSum[i];
    }
    
    float avgMvgSampleCount = totalMvgSampleCount / ((float) TICKS_PR_REV);
    
    for (int i = 0; i < TICKS_PR_REV; i++) {
        float mvgRelativeTimeUse = mvgSampleCountSum[i] / avgMvgSampleCount;
        
        mvgRelativeSpeed[i] = (mvgRelativeTimeUse * compensation[i] -1) * 100;
    }
    
    // Calculate velocity for last revolution
    int samplesPrLastRotation =0;
    for (int i = 0; i < TICKS_PR_REV; i++) {
        samplesPrLastRotation += sampleCountBuffer[i][lastTickBufferCounter];
    }
    float windSpeed = 44100 / ((float)samplesPrLastRotation);
    
    /*OLD ANGLE ALGORITHM
    // Calculate Angle of slowest movement
    // find slowest rotationspeed (highest mvgSampleCount)
    int index =0;
    float max = 0;
    for (int i = 0; i < TICKS_PR_REV; i++) {
        if (mvgRelativeSpeed[i] > max) {
            max = mvgRelativeSpeed[i];
            index = i;
        }
    }
    float xout;
    float yout;
    
    // notice index (x) is shifted by to the right, and Y is allowed to wrap around
    [self parableTopx1:tickEdgeAngle[index] andx2:tickEdgeAngle[index+1] andx3:tickEdgeAngle[index+2] andy1:mvgRelativeSpeed[(index-1)%TICKS_PR_REV] andy2:mvgRelativeSpeed[index] andy3:mvgRelativeSpeed[(index+1)%TICKS_PR_REV] andxout:&xout andyout:&yout];
    
    NSLog(@"index: %d x:%f y:%f", index, [self correctAngle:xout], yout);
     */
    
//    float mvgRelativeSpeedPercent[TICKS_PR_REV];
//    
//    for (int i = 0; i < TICKS_PR_REV; i++) {
//        mvgRelativeSpeedPercent[i] = (mvgRelativeSpeed[i] - 1) * 100.0;
//    }
    
    [self iterateAngle: (float *) mvgRelativeSpeed];
    
    
    
    
    // See the Thread Safety warning above, but in a nutshell these callbacks happen on a separate audio thread. We wrap any UI updating in a GCD block on the main thread to avoid blocking that audio flow.
    dispatch_async(dispatch_get_main_queue(),^{
        [self.dirDelegate newWindAngleLocal:[self correctAngle: angleEstimator]];
        
        // wrap mvgRelativeSpeed in Array
        NSMutableArray *angularVelocities = [[NSMutableArray alloc] initWithCapacity:TICKS_PR_REV];
        
        for (int i = 0; i < TICKS_PR_REV; i++) {
            [angularVelocities addObject: [NSNumber numberWithFloat: mvgRelativeSpeed[i]]];
        }
        
        [self.dirDelegate newAngularVelocities: angularVelocities];
        [self.dirDelegate newAngularVelocities: mvgRelativeSpeed andLength:TICKS_PR_REV];
        [self.dirDelegate newSpeed: [NSNumber numberWithFloat:windSpeed]];
    });
    
}


- (void) iterateAngle: (float *) mvgRelativeSpeedPercent {
    
    // SMALL NOTICE (ANGLES IN USE ARE EDGE ANGLES, MIGHT BE BETTER TO CALCULATE EXCATE ANGLES!)
    
    int angleLow = (angleEstimator - ANGLE_DIFF);
    int angleHigh = (angleEstimator + ANGLE_DIFF);
    
    if (angleLow < 0)
        angleLow += 360;
    
    if (angleHigh > 360)
        angleHigh -= 360;
    
    float angleLowSum = 0.0;
    float angleHighSum = 0.0;
    
    for (int i = 0; i < TICKS_PR_REV; i++) {
        
        int signalExpectedIndexLow = tickEdgeAngle[i] - angleLow;
        if (signalExpectedIndexLow < 0)
            signalExpectedIndexLow += 360;
        
        int signalExpectedIndexHigh = tickEdgeAngle[i] - angleHigh;
        if (signalExpectedIndexHigh < 0)
            signalExpectedIndexHigh += 360;
        
        angleLowSum += powf(fitcurve[signalExpectedIndexLow]-mvgRelativeSpeedPercent[i], 2.0);
        angleHighSum += powf(fitcurve[signalExpectedIndexHigh]-mvgRelativeSpeedPercent[i], 2.0);
    }
    
    float angleHLDiff = (angleLowSum - angleHighSum)/ (float) TICKS_PR_REV;
    angleEstimator += angleHLDiff * (ANGLE_CORRRECTION_COEFFICIENT);
    
    if (angleEstimator < 0)
        angleEstimator += 360;
    
    if (angleEstimator > 360)
        angleEstimator -= 360;
    
}


- (float) correctAngle:(float) angle {
    if (angle < 0) {
        angle += 360;
    }
    else if (angle > 360) {
        angle -= 360;
    }
    return angle;
}

+ (float *) getFitCurve {
    return fitcurve;
}

- (int *) getEdgeAngles {
    return tickEdgeAngle;
}

@end
