//
//  ImageCacheTestAppDelegate.h
//  ImageCacheTest
//
//  Created by Johan Kool on 19/8/2011.
//  Copyright 2011 Koolistov. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ImageCacheTestViewController;

@interface ImageCacheTestAppDelegate : NSObject <UIApplicationDelegate>

@property (nonatomic, retain) IBOutlet UIWindow *window;

@property (nonatomic, retain) IBOutlet ImageCacheTestViewController *viewController;

@end
