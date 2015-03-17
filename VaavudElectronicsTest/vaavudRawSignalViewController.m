//
//  vaavudRawSignalViewController.m
//  VaavudElectronicsTest
//
//  Created by Andreas Okholm on 22/07/14.
//  Copyright (c) 2014 Vaavud. All rights reserved.
//

#import "vaavudRawSignalViewController.h"

#define NUMBER_OF_POINTS_FIT_PLOT 36

@interface vaavudRawSignalViewController () <VaavudElectronicAnalysisDelegate, VaavudElectronicWindDelegate>
@property (weak, nonatomic) IBOutlet EZAudioPlotGL *audioPlot;
@property (weak, nonatomic) IBOutlet CPTGraphHostingView *graphHostingView;
@property (weak, nonatomic) IBOutlet UILabel *textLabelMaxVelocityDiff;
@property (weak, nonatomic) IBOutlet UILabel *textLabelMaxAmplitudeDiff;
@property (weak, nonatomic) IBOutlet UILabel *textLabelTickErrorCount;
@property (weak, nonatomic) IBOutlet UILabel *textLabelVelocityProfileError;
@property (weak, nonatomic) IBOutlet UIProgressView *calibrationProgressBar;
@property (strong, nonatomic) VEVaavudElectronicSDK *vaavudElectronics;
@property (nonatomic, strong)   CPTXYGraph    *graph;
@property (nonatomic) NSArray *angularVelocities;
@property (nonatomic) NSArray *fitPlotAngles;
@property (nonatomic) float localWindAngle;
@property (nonatomic) float maxDiffRawPlot;

enum plotName : NSInteger {
    DataPlotFit = 0,
    DataPlotRaw = 1
};

@end

@implementation vaavudRawSignalViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    
    self.vaavudElectronics = [VEVaavudElectronicSDK sharedVaavudElectronic];
    
    /*
     Customizing the audio plot's look
     */
    // Background color
    //self.audioPlot.backgroundColor = [UIColor colorWithRed: 0.984 green: 0.71 blue: 0.365 alpha: 1];
    self.audioPlot.backgroundColor           = [UIColor colorWithRed:0.0 green:0.6298 blue:0.8789 alpha:1.0];
    // Waveform color
    self.audioPlot.color           = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0];
    // Plot type
    self.audioPlot.plotType        = EZPlotTypeBuffer;
    // Fill
    self.audioPlot.shouldFill      = NO;
    // Mirror
    self.audioPlot.shouldMirror    = NO;

    
    // generate fitplot angles
    
    NSMutableArray *fitPlotAnglesMutable = [[NSMutableArray alloc] initWithCapacity:NUMBER_OF_POINTS_FIT_PLOT];
    
    for (int i = 0; i < NUMBER_OF_POINTS_FIT_PLOT; i++) {
        [fitPlotAnglesMutable addObject: [NSNumber numberWithFloat: i * 360/ (float) NUMBER_OF_POINTS_FIT_PLOT]];
    }
    self.fitPlotAngles = [fitPlotAnglesMutable copy];
    
    
    //* GRAPH
    // We need a hostview, you can create one in IB (and create an outlet) or just do this:
    //CPTGraphHostingView* hostView = [[CPTGraphHostingView alloc] initWithFrame:self.view.frame];
    [self.view addSubview: self.graphHostingView];
    
    // Create a CPTGraph object and add to hostView
    //CPTGraph* graph = [[CPTXYGraph alloc] initWithFrame:self.graphHostingView.bounds];
    self.graph = [[CPTXYGraph alloc] initWithFrame:self.graphHostingView.bounds];
    
    self.graphHostingView.hostedGraph = self.graph;
    
    
    CPTXYAxisSet *axisSet = (CPTXYAxisSet *) self.graphHostingView.hostedGraph.axisSet;
//    axisSet.hidden = NO;
    
    CPTAxis *y = axisSet.yAxis;
//    y.labelingPolicy = CPTAxisLabelingPolicyNone;
    
    CPTXYAxis *x = axisSet.xAxis;
    x.labelingPolicy = CPTAxisLabelingPolicyNone;
    
    // Grid line styles
    CPTMutableLineStyle *majorGridLineStyle = [CPTMutableLineStyle lineStyle];
    majorGridLineStyle.lineWidth = 0.75;
    majorGridLineStyle.lineColor = [[CPTColor blackColor] colorWithAlphaComponent:0.75];
    
    CPTMutableLineStyle *minorGridLineStyle = [CPTMutableLineStyle lineStyle];
    minorGridLineStyle.lineWidth = 0.25;
    minorGridLineStyle.lineColor = [[CPTColor blackColor] colorWithAlphaComponent:0.5];
    
    y.minorGridLineStyle = minorGridLineStyle;
    y.majorGridLineStyle = majorGridLineStyle;
    y.majorIntervalLength = [[NSNumber numberWithInteger:10] decimalValue];
    y.minorTicksPerInterval = 10;
    
//    x.hidden = YES;
    
    // Get the (default) plotspace from the graph so we can set its x/y ranges
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *) self.graph.defaultPlotSpace;
    
    // Note that these CPTPlotRange are defined by START and LENGTH (not START and END) !!
    [plotSpace setYRange: [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat( -5 ) length:CPTDecimalFromFloat( 5 )]];
    [plotSpace setXRange: [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat( 0.0 ) length:CPTDecimalFromFloat( 360 )]];
    
    // Create the plot (we do not define actual x/y values yet, these will be supplied by the datasource...)
    CPTScatterPlot* plot = [[CPTScatterPlot alloc] initWithFrame:CGRectZero];
    
    // Let's keep it simple and let this class act as datasource (therefore we implemtn <CPTPlotDataSource>)
    plot.dataSource = self;
    
    // adde identifyer
    plot.identifier = [NSNumber numberWithInteger:DataPlotRaw];
    
    
    // Finally, add the created plot to the default plot space of the CPTGraph object we created before
    [self.graph addPlot:plot toPlotSpace: self.graph.defaultPlotSpace];
    
    
    
    // Create the plot (we do not define actual x/y values yet, these will be supplied by the datasource...)
    CPTScatterPlot* plotFit = [[CPTScatterPlot alloc] initWithFrame:CGRectZero];
    
    // Let's keep it simple and let this class act as datasource (therefore we implemtn <CPTPlotDataSource>)
    plotFit.dataSource = self;
    
    CPTMutableLineStyle *lineStyle      = [CPTMutableLineStyle lineStyle];
    lineStyle.miterLimit                = 1.0f;
    lineStyle.lineWidth                 = 4.0f;
    
    CPTColor *vaavudBlue                = [[CPTColor alloc] initWithComponentRed: 0 green: (float) 174/255 blue: (float) 239/255 alpha: 1 ];
    lineStyle.lineColor                 = vaavudBlue;
    plotFit.dataLineStyle     = lineStyle;
    
    // adde identifyer
    plotFit.identifier = [NSNumber numberWithInteger:DataPlotFit];
    
    
    // Finally, add the created plot to the default plot space of the CPTGraph object we created before
    [self.graph addPlot:plotFit toPlotSpace: self.graph.defaultPlotSpace];
    
    
    self.textLabelMaxVelocityDiff.text = @"-";
    
    self.calibrationProgressBar.progress = 0;
    self.calibrationProgressBar.hidden = true;
    
    
    
    [self.vaavudElectronics addAnalysisListener:self];
    [self.vaavudElectronics addListener:self];
    [self.vaavudElectronics setMicrophoneFloatRawListener:self];
}


// Therefore this class implements the CPTPlotDataSource protocol
-(NSUInteger)numberOfRecordsForPlot:(CPTPlot *) plot {
    
    if ([(NSNumber *) plot.identifier integerValue] == DataPlotRaw) {
        if (self.angularVelocities) {
            return self.angularVelocities.count;
        }
        else {
            return 0;
        }
    }
    
    if ([(NSNumber *) plot.identifier integerValue] == DataPlotFit) {
        return 36; // HARDCODED NUMBER OF PLOT POINTS
    }
    
    return 0;
    //return 9; // Our sample graph contains 9 'points'
}

// This method is here because this class also functions as datasource for our graph
// Therefore this class implements the CPTPlotDataSource protocol
-(NSNumber *)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index
{
    
    if ([(NSNumber *) plot.identifier integerValue] == DataPlotRaw) {
        
        // This method is actually called twice per point in the plot, one for the X and one for the Y value
        if(fieldEnum == CPTScatterPlotFieldX)
        {
            // Return x value, which will, depending on index, be between -4 to 4
            //return [NSNumber numberWithInt: x];
            
            return [NSNumber numberWithInt: [self.vaavudElectronics getEdgeAngles][index]];
            
        } else {
            // Return y value, for this example we'll be plotting y = x * x
            return [self.angularVelocities objectAtIndex:index];
        }
    }
    
    if ([(NSNumber *) plot.identifier integerValue] == DataPlotFit) {
        if(fieldEnum == CPTScatterPlotFieldX) {
            return [self.fitPlotAngles objectAtIndex:index];
        } else {
            
            int fitAngleIndex = [[self.fitPlotAngles objectAtIndex:index] integerValue] - (int) self.localWindAngle;
            if (fitAngleIndex < 0)
                fitAngleIndex += 360;
            
//            return [NSNumber numberWithFloat:[self.vaavudElectronics getFitCurve][fitAngleIndex] * self.maxDiffRawPlot / 1.8438 ];
            return [NSNumber numberWithFloat:[self.vaavudElectronics getFitCurve][fitAngleIndex]];
            
        }
        
        return [NSNumber numberWithInt:0]; // HARDCODED NUMBER OF PLOT POINTS
    }
    
    return [NSNumber numberWithInt:0];
    
}

-(void)updateBuffer:(float *)buffer withBufferSize:(UInt32)bufferSize {
//    NSLog(@"vaavudRawSignal, buffer called, value 0: %f", buffer[0]);
    dispatch_async(dispatch_get_main_queue(),^{
        // All the audio plot needs is the buffer data (float*) and the size. Internally the audio plot will handle all the drawing related code, history management, and freeing its own resources. Hence, one badass line of code gets you a pretty plot :)
        [self.audioPlot updateBuffer:buffer withBufferSize:bufferSize];
    });
}



- (void) newSpeed: (NSNumber*) speed{
    //[self.rotationSpeedTextField setText:[NSString stringWithFormat:@"%.1f", speed.floatValue]];
//    NSLog(@"RAW speed: %.2f", speed.floatValue);
}



- (void) newAngularVelocities: (NSArray*) angularVelocities {
    self.angularVelocities = angularVelocities;
    
    float min = 0;
    float max = 0;
    
    
    for (int i = 0; i < angularVelocities.count; i++) {
        
        if ([[angularVelocities objectAtIndex:i] floatValue] < min) {
            min = [[angularVelocities objectAtIndex:i] floatValue];
        }
        
        if ([[angularVelocities objectAtIndex:i] floatValue] > max) {
            max = [[angularVelocities objectAtIndex:i] floatValue];
        }
        
    }
    
    
    self.maxDiffRawPlot = (max + min > 0) ? max*1.0 : min * (-1.0);
    float lowerBound = 0 - self.maxDiffRawPlot;
    float plotLength = self.maxDiffRawPlot * 2;
    
    [(CPTXYPlotSpace *) self.graph.defaultPlotSpace setYRange: [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat( lowerBound ) length:CPTDecimalFromFloat( plotLength )]];
    
    self.textLabelMaxVelocityDiff.text = [NSString stringWithFormat:@"%0.2f%%", self.maxDiffRawPlot];
    
    [self.graph reloadData];
    
}

- (void) newWindAngleLocal:(NSNumber*) angle {
    //[self.windAngleTextField setText:[NSString stringWithFormat:@"%.0f", angle]];
    self.localWindAngle = angle.floatValue;
}


- (void) newMaxAmplitude: (NSNumber*) amplitude {
    self.textLabelMaxAmplitudeDiff.text = amplitude.stringValue;
}

- (void) newTickDetectionErrorCount: (NSNumber *) tickDetectionErrorCount {
    self.textLabelTickErrorCount.text = tickDetectionErrorCount.stringValue;
}

- (void) newVelocityProfileError:(NSNumber *)profileError {
    self.textLabelVelocityProfileError.text = [NSString stringWithFormat:@"%.1f", profileError.floatValue];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)startCalibration:(id)sender {
    [self.vaavudElectronics startCalibration];
    self.calibrationProgressBar.hidden = NO;
}

- (void) calibrationPercentageComplete:(NSNumber *)percentage {
    self.calibrationProgressBar.progress = percentage.floatValue;
    if (percentage.floatValue >= 1) {
        self.calibrationProgressBar.hidden = YES;
        self.calibrationProgressBar.progress = 0.0;
    } 
}

- (IBAction)resetCalibration:(id)sender {
    [self.vaavudElectronics resetCalibration];
}

- (void)dealloc{
    [self.vaavudElectronics removeAnalysisListener:self];
    [self.vaavudElectronics removeListener:self];
}

@end
