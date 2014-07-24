//
//  vaavudRawSignalViewController.m
//  VaavudElectronicsTest
//
//  Created by Andreas Okholm on 22/07/14.
//  Copyright (c) 2014 Vaavud. All rights reserved.
//

#import "vaavudRawSignalViewController.h"

@interface vaavudRawSignalViewController () <VaavudElectronicWindDelegate>
@property (weak, nonatomic) IBOutlet EZAudioPlotGL *audioPlot;
@property (weak, nonatomic) IBOutlet CPTGraphHostingView *graphHostingView;
@property (weak, nonatomic) IBOutlet UILabel *textLabelMaxVelocityDiff;
@property (strong, nonatomic) VaavudElectronic *vaavudElectronics;
@property (nonatomic, strong)   CPTXYGraph    *graph;
@property (nonatomic) NSArray* angularVelocities;

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
    [plotSpace setYRange: [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat( 0.9 ) length:CPTDecimalFromFloat( 0.2 )]];
    [plotSpace setXRange: [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat( 0.0 ) length:CPTDecimalFromFloat( 360 )]];
    
    // Create the plot (we do not define actual x/y values yet, these will be supplied by the datasource...)
    CPTScatterPlot* plot = [[CPTScatterPlot alloc] initWithFrame:CGRectZero];
    
    // Let's keep it simple and let this class act as datasource (therefore we implemtn <CPTPlotDataSource>)
    plot.dataSource = self;
    
    // Finally, add the created plot to the default plot space of the CPTGraph object we created before
    [self.graph addPlot:plot toPlotSpace: self.graph.defaultPlotSpace];
}


// Therefore this class implements the CPTPlotDataSource protocol
-(NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plotnumberOfRecords {
    if (self.angularVelocities) {
        return self.angularVelocities.count;
    }
    else {
        return 0;
    }
    //return 9; // Our sample graph contains 9 'points'
}

// This method is here because this class also functions as datasource for our graph
// Therefore this class implements the CPTPlotDataSource protocol
-(NSNumber *)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index
{
    // We need to provide an X or Y (this method will be called for each) value for every index
    //int x = index - 4;
    
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



- (void) newSpeed: (NSNumber*) speed{
    //[self.rotationSpeedTextField setText:[NSString stringWithFormat:@"%.1f", speed.floatValue]];
    NSLog(@"RAW speed: %.2f", speed.floatValue);
}


- (void) newAngularVelocities: (float*) angularVelocities andLength: (int) length {
    
}

- (void) newAngularVelocities: (NSArray*) angularVelocities {
    self.angularVelocities = angularVelocities;
    
    float min = 1;
    float max = 1;
    
    
    for (int i = 0; i < angularVelocities.count; i++) {
        
        if ([[angularVelocities objectAtIndex:i] floatValue] < min) {
            min = [[angularVelocities objectAtIndex:i] floatValue];
        }
        
        if ([[angularVelocities objectAtIndex:i] floatValue] > max) {
            max = [[angularVelocities objectAtIndex:i] floatValue];
        }
        
    }
    
    
    float maxDiff = MAX(1-min, max-1);
    float lowerBound = 1 - maxDiff;
    float plotLength = maxDiff * 2;
    
    [(CPTXYPlotSpace *) self.graph.defaultPlotSpace setYRange: [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat( lowerBound ) length:CPTDecimalFromFloat( plotLength )]];
    
    self.textLabelMaxVelocityDiff.text = [NSString stringWithFormat:@"%0.2f%%", maxDiff*100];
    
    [self.graph reloadData];
    
}

- (void) newWindAngleLocal:(float) angle {
    //[self.windAngleTextField setText:[NSString stringWithFormat:@"%.0f", angle]];
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
