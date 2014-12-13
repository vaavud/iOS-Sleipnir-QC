//
//  Properties+Util.h
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 01/07/2013.
//  Copyright (c) 2013 Andreas Okholm. All rights reserved.
//

#import "Property.h"

static NSString * const KEY_CREATION_TIME = @"creationTime";
static NSString * const KEY_CALIBRATION_WINDSPEED_STANDARD = @"calibrationWindspeedStandard";

@interface Property (Util)

+ (NSString*) getAsString:(NSString*) name;
+ (BOOL) getAsBoolean:(NSString*) name;
+ (BOOL) getAsBoolean:(NSString*)name defaultValue:(BOOL)defaultValue;
+ (NSNumber*) getAsInteger:(NSString*) name;
+ (NSNumber*) getAsInteger:(NSString*) name defaultValue:(int)defaultValue;
+ (NSNumber*) getAsLongLong:(NSString*) name;
+ (NSNumber*) getAsDouble:(NSString*) name;
+ (NSNumber*) getAsDouble:(NSString*) name defaultValue:(double)defaultValue;
+ (NSNumber*) getAsFloat:(NSString*) name;
+ (NSNumber*) getAsFloat:(NSString*) name defaultValue:(float)defaultValue;
+ (NSDate*) getAsDate:(NSString*)name;
+ (NSArray*) getAsFloatArray:(NSString*) name;
+ (void) setAsString:(NSString*) value forKey:(NSString*) name;
+ (void) setAsBoolean:(BOOL) value forKey:(NSString*) name;
+ (void) setAsInteger:(NSNumber*) value forKey:(NSString*) name;
+ (void) setAsLongLong:(NSNumber*) value forKey:(NSString*) name;
+ (void) setAsDouble:(NSNumber*) value forKey:(NSString*) name;
+ (void) setAsFloat:(NSNumber*) value forKey:(NSString*) name;
+ (void) setAsDate:(NSDate*)value forKey:(NSString*)name;
+ (void) setAsFloatArray:(NSArray*) value forKey:(NSString*) name;

@end
