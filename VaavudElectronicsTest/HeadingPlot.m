//
//  HeadingPlot.m
//  VaavudElectronicsTest
//
//  Created by Andreas Okholm on 24/08/14.
//  Copyright (c) 2014 Vaavud. All rights reserved.
//

#import "HeadingPlot.h"
#import "CircleView.h"

@interface HeadingPlot()

@property (nonatomic) NSMutableArray * dots;
@property (nonatomic) float centerX;
@property (nonatomic) float centerY;
@property (nonatomic) float speedMax;
@property (nonatomic) float speedMin;
@property (nonatomic) float circleDiameter;
@property (nonatomic) float circleDiameterHalf;
@property (nonatomic) float padding;

@end


@implementation HeadingPlot

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self customInit];
    }
    
    return self;
    
}


-(id)initWithCoder:(NSCoder*)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self customInit];
    }
    
    return self;
}

- (void) customInit {
    
    self.centerX = self.frame.size.width/2;
    self.centerY = self.frame.size.height/2;
    
    self.speedMax = 10;
    self.speedMin = 0;
    
    self.circleDiameter = 20;
    self.circleDiameterHalf = self.circleDiameter/2;
    
    self.padding = self.circleDiameterHalf;
    
    self.dots = [[NSMutableArray alloc] initWithCapacity:20];
    
    
    [self addSubview: [self createDotSpeed:[NSNumber numberWithFloat:4.5]  AndDirection: [NSNumber numberWithFloat:340]]];
    [self addSubview: [self createDotSpeed:[NSNumber numberWithFloat:5]  AndDirection: [NSNumber numberWithFloat:0]]];
    [self addSubview: [self createDotSpeed:[NSNumber numberWithFloat:8]  AndDirection: [NSNumber numberWithFloat:180]]];
    [self addSubview: [self createDotSpeed:[NSNumber numberWithFloat:10]  AndDirection: [NSNumber numberWithFloat:0]]];
}


- (CircleView*) createDotSpeed: (NSNumber*) speed AndDirection: (NSNumber*) direction {
    
    float directionCorrected = direction.floatValue - 90.0;
    
    float x = cos(directionCorrected*M_PI/180) * (speed.floatValue -self.speedMin)/(self.speedMax-self.speedMin) * (self.centerX - self.padding) + self.centerX - self.circleDiameterHalf;
    float y = sin(directionCorrected*M_PI/180) * (speed.floatValue -self.speedMin)/(self.speedMax-self.speedMin) * (self.centerY - self.padding) + self.centerY - self.circleDiameterHalf;
    
    
    return [[CircleView alloc] initWithFrame:CGRectMake(x,y,self.circleDiameter,self.circleDiameter)];
    
}

@end
