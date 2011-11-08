//
//  KVImageCache.h
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

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

// The check for local image allows the URL to be either "localimage.png" or "http://www.example.com/remoteimage.png".
// This way it is possible to point to a file already included in the app's bundle.

@interface KVImageCache : NSObject 

+ (KVImageCache *)defaultCache;

// Allows referring to images included in the app's bundle (passing the absolute URL to the -[UIImage imageNamed:] method). Note however that enabling this takes a performance hit. Defaults to NO.
@property (assign) BOOL shouldCheckForLocalImages;

// The cache that holds the actual data.
@property (retain) NSURLCache *imageURLCache;

// Checks if the URL points to a local image, otherwise asynchronously downloads the image if needed
// Call -cancel on the returned KVDownload instance if you need to cancel the download
- (id)loadImageAtURL:(NSURL *)imageURL withHandler:(void(^)(UIImage *image))handler;

// The image is loaded from imageURL, but will be cached under cacheURL. This allows coallescing
// for example in cases where the imageURL contains changing parameters which don't affect the image to load.
- (id)loadImageAtURL:(NSURL *)imageURL cacheURL:(NSURL *)cacheURL withHandler:(void(^)(UIImage *image))handler;

- (id)loadImageAtURL:(NSURL *)imageURL cacheURL:(NSURL *)cacheURL imageView:(UIImageView *)imageView withHandler:(void (^)(UIImage * image))handler;
- (void)cancelDownloadForImageView:(UIImageView *)imageView;

// Checks if the URL points to a local image, otherwise returns the image only if already available from cache
- (UIImage *)cachedImageAtURL:(NSURL *)anURL;

// Flush the cache
- (void)flush;

@end
