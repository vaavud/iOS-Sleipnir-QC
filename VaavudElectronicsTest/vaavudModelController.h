//
//  vaavudModelController.h
//  VaavudElectronicsTest
//
//  Created by Andreas Okholm on 17/07/14.
//  Copyright (c) 2014 Vaavud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class vaavudViewController;

@interface vaavudModelController : NSObject <UIPageViewControllerDataSource>


- (vaavudViewController *)viewControllerAtIndex:(NSUInteger)index storyboard:(UIStoryboard *)storyboard;
- (NSUInteger)indexOfViewController:(vaavudViewController *)viewController;


@end
