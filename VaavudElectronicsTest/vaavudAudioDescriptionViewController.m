//
//  vaavudAudioDescriptionViewController.m
//  VaavudElectronicsTest
//
//  Created by Andreas Okholm on 11/11/14.
//  Copyright (c) 2014 Vaavud. All rights reserved.
//

#import "vaavudAudioDescriptionViewController.h"

@interface vaavudAudioDescriptionViewController ()
@property (strong, nonatomic) VEVaavudElectronicSDK *vaavudElectronics;
@property (weak, nonatomic) IBOutlet UITextView *textViewSoundOutput;
@property (weak, nonatomic) IBOutlet UITextView *textViewSoundInput;



@end

@implementation vaavudAudioDescriptionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.vaavudElectronics = [VEVaavudElectronicSDK sharedVaavudElectronic];
    // Do any additional setup after loading the view.
    self.textViewSoundOutput.text = [self.vaavudElectronics soundOutputDescription];
    self.textViewSoundInput.text = [self.vaavudElectronics soundInputDescription];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
