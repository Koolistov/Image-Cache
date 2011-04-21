//
//  UIImageView+URL.m
//  Koolistov
//
//  Created by Johan Kool on 28-10-10.
//  Copyright 2010-2011 Koolistov. All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without modification, are 
//  permitted provided that the following conditions are met:
//
//  * Redistributions of source code must retain the above copyright notice, this list of 
//    conditions and the following disclaimer.
//  * Redistributions in binary form must reproduce the above copyright notice, this list 
//    of conditions and the following disclaimer in the documentation and/or other materials 
//    provided with the distribution.
//  * Neither the name of KOOLISTOV nor the names of its contributors may be used to 
//    endorse or promote products derived from this software without specific prior written 
//    permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY 
//  EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF 
//  MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL 
//  THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, 
//  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT 
//  OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) 
//  HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, 
//  OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS 
//  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

#import "UIImageView+URL.h"

#import "KVImageCache.h"
#import "KVDownload.h"

#define kActivityIndicatorTag 18942347

@implementation UIImageView (URL)

- (void)kv_showActivityIndicatorWithStyle:(UIActivityIndicatorViewStyle)indicatorStyle {
    UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:indicatorStyle];

    activityIndicator.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    CGRect currentFrame = activityIndicator.frame;
    CGRect newFrame = CGRectMake(CGRectGetMidX(self.bounds) - 0.5f * currentFrame.size.width,
                                 CGRectGetMidY(self.bounds) - 0.5f * currentFrame.size.height,
                                 currentFrame.size.width,
                                 currentFrame.size.height);
    activityIndicator.frame = newFrame;
    activityIndicator.tag = kActivityIndicatorTag;
    [activityIndicator startAnimating];
    [self addSubview:activityIndicator];
    [activityIndicator release];
}

- (void)kv_hideActivityIndicator {
    UIView *activityIndicator = [self viewWithTag:kActivityIndicatorTag];

    [activityIndicator removeFromSuperview];
}

- (id)kv_setImageAtURL:(NSURL *)imageURL {
    return [self kv_setImageAtURL:imageURL showActivityIndicator:YES activityIndicatorStyle:UIActivityIndicatorViewStyleGray loadingImage:nil notAvailableImage:nil];
}

- (id)kv_setImageAtURL:(NSURL *)imageURL showActivityIndicator:(BOOL)showActivityIndicator activityIndicatorStyle:(UIActivityIndicatorViewStyle)indicatorStyle loadingImage:(UIImage *)loadingImage notAvailableImage:(UIImage *)notAvailableImage {
    return [self kv_setImageAtURL:imageURL cacheURL:imageURL showActivityIndicator:showActivityIndicator activityIndicatorStyle:indicatorStyle loadingImage:loadingImage notAvailableImage:notAvailableImage];
}

- (id)kv_setImageAtURL:(NSURL *)imageURL cacheURL:(NSURL *)cacheURL showActivityIndicator:(BOOL)showActivityIndicator activityIndicatorStyle:(UIActivityIndicatorViewStyle)indicatorStyle loadingImage:(UIImage *)loadingImage notAvailableImage:(UIImage *)notAvailableImage {

    self.image = loadingImage;

    if (!imageURL) {
        self.image = notAvailableImage;
        return nil;
    }
    
    if (showActivityIndicator)
        [self kv_showActivityIndicatorWithStyle:indicatorStyle];

        KVDownload *imageDownload = [[KVImageCache defaultCache] loadImageAtURL:imageURL cacheURL:cacheURL withHandler:^(UIImage * image) {
            if (!image) {
                self.image = notAvailableImage;
            } else {
                self.image = image;
            }
            if (showActivityIndicator) {
                [self performSelectorOnMainThread:@selector(kv_hideActivityIndicator) withObject:nil waitUntilDone:NO];
            }
     }];
    
    return imageDownload;
}

@end
