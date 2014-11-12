//
//  vaavudModelController.m
//  VaavudElectronicsTest
//
//  Created by Andreas Okholm on 17/07/14.
//  Copyright (c) 2014 Vaavud. All rights reserved.
//

#import "vaavudModelController.h"
#import "vaavudUIViewController.h"


/*
 A controller object that manages a simple model -- a collection of month names.
 
 The controller serves as the data source for the page view controller; it therefore implements pageViewController:viewControllerBeforeViewController: and pageViewController:viewControllerAfterViewController:.
 It also implements a custom method, viewControllerAtIndex: which is useful in the implementation of the data source methods, and in the initial configuration of the application.
 
 There is no need to actually create view controllers for each page in advance -- indeed doing so incurs unnecessary overhead. Given the data model, these methods create, configure, and return a new view controller on demand.
 */

@interface vaavudModelController()


@end

@implementation vaavudModelController

enum Screens : NSUInteger {
    ScreenProductionTest,
    ScreenRawSignal,
    ScreenClean,
    ScreenAudioDescription,
    ScreenNotification,
    ScreenUpload,
    ScreenHeading,
    numScreens
};


- (id)init
{
    self = [super init];
    
    return self;
}

- (UIViewController *)viewControllerAtIndex:(NSUInteger)index storyboard:(UIStoryboard *)storyboard
{
    // Return the data view controller for the given index.
    if ((numScreens == 0) || (index >= numScreens)) {
        return nil;
    }
    
    vaavudUIViewController *viewController;
    
    switch (index)
        case ScreenClean: {
            // Create a new view controller and pass suitable data.
            //viewController = [storyboard instantiateViewControllerWithIdentifier:@"vaavudViewController"];
            viewController = [storyboard instantiateViewControllerWithIdentifier:@"vaavudViewControllerCleanInterface"];
            [viewController setScreenIndex: index];
            break;
            
        case ScreenRawSignal:
            // Create a new view controller and pass suitable data.
            viewController = [storyboard instantiateViewControllerWithIdentifier:@"vaavudRawSignalViewController"];
            [viewController setScreenIndex: index];
            break;
        
        case ScreenHeading:
            // Create a new view controller and pass suitable data.
            viewController = [storyboard instantiateViewControllerWithIdentifier:@"HeadingViewController"];
            [viewController setScreenIndex: index];
            break;
        
        case ScreenUpload:
            // Create a new view controller and pass suitable data.
            //viewController = [storyboard instantiateViewControllerWithIdentifier:@"vaavudViewController"];
            viewController = [storyboard instantiateViewControllerWithIdentifier:@"UploadViewController"];
            [viewController setScreenIndex: index];
            break;
        
        case ScreenNotification:
            // Create a new view controller and pass suitable data.
            //viewController = [storyboard instantiateViewControllerWithIdentifier:@"vaavudViewController"];
            viewController = [storyboard instantiateViewControllerWithIdentifier:@"NotificationViewController"];
            [viewController setScreenIndex: index];
            break;
        
        case ScreenProductionTest:
            viewController = [storyboard instantiateViewControllerWithIdentifier:@"ProductionTestViewController"];
            [viewController setScreenIndex: index];
            break;
            
        case ScreenAudioDescription:
            viewController = [storyboard instantiateViewControllerWithIdentifier:@"AudioDescriptionViewController"];
            [viewController setScreenIndex: index];
            break;
        default:
            break;
    }
    
    
    //dataViewController.dataObject = self.pageData[index];
    return viewController;
}

- (NSUInteger)indexOfViewController:(vaavudUIViewController *)viewController
{
    // Return the index of the given data view controller.
    // For simplicity, this implementation uses a static array of model objects and the view controller stores the model object; you can therefore use the model object to identify the index.
    return [viewController screenIndex];
}

#pragma mark - Page View Controller Data Source

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    NSUInteger index = [(vaavudUIViewController *)viewController screenIndex];
    if ((index == 0) || (index == NSNotFound)) {
        return nil;
    }
    
    index--;
    return [self viewControllerAtIndex:index storyboard:viewController.storyboard];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    NSUInteger index = [(vaavudUIViewController *)viewController screenIndex];
    if (index == NSNotFound) {
        return nil;
    }
    
    index++;
    if (index == numScreens) {
        return nil;
    }
    return [self viewControllerAtIndex:index storyboard:viewController.storyboard];
}

@end
