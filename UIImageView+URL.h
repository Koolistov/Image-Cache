//
//  UIImageView+URL.h
//  Koolistov
//
//  Created by Johan Kool on 28-10-10.
//  Copyright 2010-2010 Koolistov. All rights reserved.
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

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface UIImageView (URL) 

// Asynchronously downloads the image at the URL if needed, whilst showing a gray activity indicator.
// No image is shown during the download, and none is shown if no valid image could be loaded.
// Call -cancel on the returned KVDownload instance if you need to cancel the download.
// You then also need to hide the activity indicator using -kv_hideActivityIndicator.
- (void)kv_setImageAtURL:(NSURL *)imageURL;

// Asynchronously downloads the image at the URL if needed.
// Call -cancel on the returned KVDownload instance if you need to cancel the download.
// You may also need to hide the activity indicator using -kv_hideActivityIndicator.
- (void)kv_setImageAtURL:(NSURL *)imageURL showActivityIndicator:(BOOL)showActivityIndicator activityIndicatorStyle:(UIActivityIndicatorViewStyle)indicatorStyle loadingImage:(UIImage *)loadingImage notAvailableImage:(UIImage *)notAvailableImage;

// The image is loaded from imageURL, but will be cached under cacheURL. This allows coallescing
// for example in cases where the imageURL contains changing parameters which don't affect the image to load.
- (void)kv_setImageAtURL:(NSURL *)imageURL cacheURL:(NSURL *)cacheURL showActivityIndicator:(BOOL)showActivityIndicator activityIndicatorStyle:(UIActivityIndicatorViewStyle)indicatorStyle loadingImage:(UIImage *)loadingImage notAvailableImage:(UIImage *)notAvailableImage;

// Cancel any ongoing asynchronous download for the image view. Also hides the activity indicator.
- (void)kv_cancelImageDownload;

- (void)kv_showActivityIndicatorWithStyle:(UIActivityIndicatorViewStyle)indicatorStyle;
- (void)kv_hideActivityIndicator;

@end
