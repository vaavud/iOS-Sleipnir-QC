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


- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.TextViewConsole.text = @"";
    
    [[VEVaavudElectronicSDK sharedVaavudElectronic] addListener:self];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void) devicePlugedInChecking {
    [self appendTextToConsole: @"Device pluged in - checking"];
}

- (void) vaavudPlugedIn {
    [self appendTextToConsole: @"Vaavud pluged in"];
}
- (void) notVaavudPlugedIn {
    [self appendTextToConsole: @"Not a vaavud pluged in"];
}


- (void) deviceWasUnpluged {
    [self appendTextToConsole: @"Devuce was unpluged"];
}
- (void) vaavudStartedMeasureing {
    [self appendTextToConsole: @"Vaavud started measureing "];
}
- (void) vaavudStopMeasureing {
    [self appendTextToConsole: @"Vaavud stoped measureing"];
}



- (void) appendTextToConsole: (NSString *) message {
    self.TextViewConsole.text = [NSString stringWithFormat: @"%@\n%@", self.TextViewConsole.text, message ];
    [self.TextViewConsole scrollRangeToVisible:NSMakeRange(0,[self.TextViewConsole.text length])];
}



@end
