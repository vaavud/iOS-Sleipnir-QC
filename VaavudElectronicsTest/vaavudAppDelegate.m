//
//  vaavudAppDelegate.m
//  VaavudElectronicsTest
//
//  Created by Andreas Okholm on 04/06/14.
//  Copyright (c) 2014 Vaavud. All rights reserved.
//

#import "vaavudAppDelegate.h"
#import "TestFairy.h"
#import <DropboxSDK/DropboxSDK.h>


@implementation vaavudAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    
    DBSession *dbSession = [[DBSession alloc]
                            initWithAppKey:@"nl8tv42zs94vgoh"
                            appSecret:@"befkrjtnjgumn3c"
                            root:kDBRootAppFolder]; // either kDBRootAppFolder or kDBRootDropbox
    [DBSession setSharedSession:dbSession];
    
    [TestFairy begin:@"871cd14813a2328db63cf77473e1e5c2820e6b61"];
    
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
    VEVaavudElectronicSDK *vaavudElectronic = [VEVaavudElectronicSDK sharedVaavudElectronic];
    
    [vaavudElectronic endRecording];
    [vaavudElectronic stop];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    VEVaavudElectronicSDK *vaavudElectronic = [VEVaavudElectronicSDK sharedVaavudElectronic];
    [vaavudElectronic start];
    [vaavudElectronic resetCalibration];
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url
  sourceApplication:(NSString *)source annotation:(id)annotation {
    if ([[DBSession sharedSession] handleOpenURL:url]) {
        if ([[DBSession sharedSession] isLinked]) {
            NSLog(@"App linked successfully!");
            // At this point you can start making API calls
        }
        return YES;
    }
    // Add whatever other url handling code your app requires here
    return NO;
}

@end
