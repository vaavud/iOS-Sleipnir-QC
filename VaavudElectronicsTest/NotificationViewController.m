//
//  NotificationViewerController.m
//  VaavudElectronicsTest
//
//  Created by Andreas Okholm on 22/08/14.
//  Copyright (c) 2014 Vaavud. All rights reserved.
//

#import "NotificationViewController.h"

@interface NotificationViewController ()<VaavudElectronicWindDelegate>
@property (weak, nonatomic) IBOutlet UITextView *TextViewConsole;

@end

@implementation NotificationViewController


- (void) viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.TextViewConsole.text = @"";
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}




- (void) sleipnirAvailabliltyChanged: (BOOL) available {
    if (available) {
        NSLog(@"[NotificationViewController] Sleipnir availablilty changed - available");
        [self appendTextToConsole: @"Sleipnir availablilty changed - available"];
    }
    
    else {
        NSLog(@"[NotificationViewController] Sleipnir availablilty changed - Not available");
        [self appendTextToConsole: @"Sleipnir availablilty changed - Not available"];
    }
    
}


- (void) deviceConnectedTypeSleipnir: (BOOL) sleipnir {
    if (sleipnir) {
        NSLog(@"[NotificationViewController] Device connected - Sleipnir");
        [self appendTextToConsole: @"Device connected - Sleipnir "];
    }
    else {
        NSLog(@"[NotificationViewController] Device connected - Unknown");
        [self appendTextToConsole: @"Device connected - Unknown "];
    }
    
    
}


- (void) deviceDisconnectedTypeSleipnir: (BOOL) sleipnir {
    if (sleipnir) {
        NSLog(@"[NotificationViewController] Device disconnected - Sleipnir");
        [self appendTextToConsole: @"Device disconnected - Sleipnir "];
    }
    else {
        NSLog(@"[NotificationViewController] Device disconnected - Unknown");
        [self appendTextToConsole: @"Device disconnected - Unknown"];
    }
    
    
}

- (void) deviceConnectedChecking {
    NSLog(@"[NotificationViewController] Device Connected Checking");
    [self appendTextToConsole: @"Device Connected Checking"];
}




- (void) sleipnirStartedMeasureing {
    [self appendTextToConsole: @"Vaavud started measureing "];
    NSLog(@"[NotificationViewController] Vaavud started measureing");
}
- (void) sleipnirStopedMeasureing {
    [self appendTextToConsole: @"Vaavud stoped measureing"];
    NSLog(@"[NotificationViewController] Vaavud Stoped measureing");
}



- (void) appendTextToConsole: (NSString *) message {
    self.TextViewConsole.text = [NSString stringWithFormat: @"%@\n%@", self.TextViewConsole.text, message ];
    [self.TextViewConsole scrollRangeToVisible:NSMakeRange(0,[self.TextViewConsole.text length])];
}

- (void) viewDidAppear:(BOOL)animated {
    [[VEVaavudElectronicSDK sharedVaavudElectronic] addListener:self];
    [super viewDidAppear:animated];
}

- (void) viewDidDisappear:(BOOL)animated {
    [[VEVaavudElectronicSDK sharedVaavudElectronic] removeListener:self];
    [super viewDidDisappear:animated];
}

- (void) dealloc {
    NSLog(@"dealloc");
}



@end
