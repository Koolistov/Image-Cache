//
//  ImageCacheTestViewController.h
//  ImageCacheTest
//
//  Created by Johan Kool on 19/8/2011.
//  Copyright 2011 Koolistov. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ImageCacheTestViewController : UIViewController {
    UITextField *imageURL;
    IBOutlet UIImageView *imageView;
}

@property (nonatomic, retain) IBOutlet UITextField *imageURL;
@property (nonatomic, retain) IBOutlet UIImageView *imageView;

- (IBAction)emptyCache:(id)sender;
- (IBAction)loadImage:(id)sender;

@end
