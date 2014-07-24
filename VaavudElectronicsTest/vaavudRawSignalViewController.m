//
//  vaavudRawSignalViewController.m
//  VaavudElectronicsTest
//
//  Created by Andreas Okholm on 22/07/14.
//  Copyright (c) 2014 Vaavud. All rights reserved.
//

#import "vaavudRawSignalViewController.h"

#define NUMBER_OF_POINTS_FIT_PLOT 36

@interface vaavudRawSignalViewController () <VaavudElectronicWindDelegate>
@property (weak, nonatomic) IBOutlet EZAudioPlotGL *audioPlot;
@property (weak, nonatomic) IBOutlet CPTGraphHostingView *graphHostingView;
@property (weak, nonatomic) IBOutlet UILabel *textLabelMaxVelocityDiff;
@property (strong, nonatomic) VaavudElectronic *vaavudElectronics;
@property (nonatomic, strong)   CPTXYGraph    *graph;
@property (nonatomic) NSArray* angularVelocities;
@property (nonatomic) NSArray* fitPlotAngles;
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
    
    
    self.vaavudElectronics = [VaavudElectronic sharedVaavudElec];
    [self.vaavudElectronics addListener:self];
    
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
    self.audioPlot.shouldMirror    = NO;

    [self.vaavudElectronics setAudioPlot: self.audioPlot];
    
    
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
    axisSet.hidden = YES;
    
    CPTAxis *y = axisSet.yAxis;
    y.labelingPolicy = CPTAxisLabelingPolicyNone;
    
    CPTXYAxis *x = axisSet.xAxis;
    x.labelingPolicy = CPTAxisLabelingPolicyNone;
    
    
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
            
            return [NSNumber numberWithFloat:[self.vaavudElectronics getFitCurve][fitAngleIndex] * self.maxDiffRawPlot / 1.8438 ];
            
        }
        
        return [NSNumber numberWithInt:0]; // HARDCODED NUMBER OF PLOT POINTS
    }
    
    return [NSNumber numberWithInt:0];
    
}



- (void) newSpeed: (NSNumber*) speed{
    //[self.rotationSpeedTextField setText:[NSString stringWithFormat:@"%.1f", speed.floatValue]];
    NSLog(@"RAW speed: %.2f", speed.floatValue);
}


- (void) newAngularVelocities: (float*) angularVelocities andLength: (int) length {
    
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
    
    
    self.maxDiffRawPlot = MAX(1-min, max-1);
    float lowerBound = 0 - self.maxDiffRawPlot;
    float plotLength = self.maxDiffRawPlot * 2;
    
    [(CPTXYPlotSpace *) self.graph.defaultPlotSpace setYRange: [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat( lowerBound ) length:CPTDecimalFromFloat( plotLength )]];
    
    self.textLabelMaxVelocityDiff.text = [NSString stringWithFormat:@"%0.2f%%", self.maxDiffRawPlot];
    
    [self.graph reloadData];
    
}

- (void) newWindAngleLocal:(float) angle {
    //[self.windAngleTextField setText:[NSString stringWithFormat:@"%.0f", angle]];
    self.localWindAngle = angle;
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
