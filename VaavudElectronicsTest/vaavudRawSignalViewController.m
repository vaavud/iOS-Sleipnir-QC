//
//  vaavudRawSignalViewController.m
//  VaavudElectronicsTest
//
//  Created by Andreas Okholm on 22/07/14.
//  Copyright (c) 2014 Vaavud. All rights reserved.
//

#import "vaavudRawSignalViewController.h"

@interface vaavudRawSignalViewController ()
@property (weak, nonatomic) IBOutlet EZAudioPlotGL *audioPlot;
@property (strong, nonatomic) VaavudElectronic *vaavudElectronics;
@end

@implementation vaavudRawSignalViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    
    self.vaavudElectronics = [VaavudElectronic sharedVaavudElec];
    
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
    
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
