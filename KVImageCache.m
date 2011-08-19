//
//  KVImageCache.m
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

#import "KVImageCache.h"

#import "KVDownload.h"
#import "SDURLCache.h"

@interface KVImageCache ()

@property (retain) NSURLCache *imageURLCache;
@property (retain) NSMutableDictionary *imagesLoading;
@property (retain) NSMutableDictionary *downloadPerImageView;

@end

@implementation KVImageCache

@synthesize imageURLCache = imageURLCache_;
@synthesize imagesLoading = imagesLoading_;
@synthesize downloadPerImageView = downloadPerImageView_;

+ (id)defaultCache  {
    static dispatch_once_t pred;
    static KVImageCache *defaultCache = nil;
    
    dispatch_once(&pred, ^{ defaultCache = [[self alloc] init]; });
    return defaultCache;
}

- (id)init {
    self = [super init];
    if (self) {
        // Create cache with 1 MB memory and 10 MB disk capacity
        // Using SDURLCache subclass which enables caching to disk
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        NSString *diskCachePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"KVImageCache"];
        
        NSURLCache *cache = [[SDURLCache alloc] initWithMemoryCapacity:1 * 1024 * 1024 diskCapacity:10 * 1024 * 1024 diskPath:diskCachePath];
        self.imageURLCache = cache;
        [cache release];
        
        self.imagesLoading = [NSMutableDictionary dictionary];
        self.downloadPerImageView = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)dealloc {
    self.imageURLCache = nil;
    self.imagesLoading = nil;
    [super dealloc];
}

#pragma mark - Main
- (id)loadImageAtURL:(NSURL *)imageURL withHandler:(void (^)(UIImage * image))handler {
    return [self loadImageAtURL:imageURL cacheURL:imageURL withHandler:handler];
}

- (id)loadImageAtURL:(NSURL *)imageURL cacheURL:(NSURL *)cacheURL withHandler:(void (^)(UIImage * image))handler {
    return [self loadImageAtURL:imageURL cacheURL:cacheURL imageView:nil withHandler:handler];
}
            
- (id)loadImageAtURL:(NSURL *)imageURL cacheURL:(NSURL *)cacheURL imageView:(UIImageView *)imageView withHandler:(void (^)(UIImage * image))handler {
    if (!imageURL) {
        handler(nil);
        return nil;
    }

    UIImage *localImage = [UIImage imageNamed:[imageURL absoluteString]];
    if (localImage) {
        handler(localImage);
        return nil;
    }

    NSURLRequest *cacheRequest = [NSURLRequest requestWithURL:cacheURL];
    NSURLRequest *downloadRequest = [NSURLRequest requestWithURL:imageURL];
    NSCachedURLResponse *earlierCachedResponse = [self.imageURLCache cachedResponseForRequest:cacheRequest];

    if (earlierCachedResponse) {
        UIImage *image = [UIImage imageWithData:[earlierCachedResponse data]];
        handler(image);
        return nil;
    } else {
        NSMutableArray *pendingHandlers = [self.imagesLoading objectForKey:cacheURL];
        if (pendingHandlers) {
            [pendingHandlers addObject:[[handler copy] autorelease]];
            return nil;
        } else {
            pendingHandlers = [NSMutableArray arrayWithObject:[[handler copy] autorelease]];
            [self.imagesLoading setObject:pendingHandlers forKey:cacheURL];

            KVDownload *imageDownload = [KVDownload startDownloadWithRequest:downloadRequest completionHandler:^(NSURLResponse * receivedResponse, NSData * data, NSError * error) {
                if (!data || [data length] == 0) {
                    // If no data, return nil image
                    NSMutableArray *pendingHandlers = [self.imagesLoading objectForKey:cacheURL];
                    for (void (^handler)(UIImage * image) in pendingHandlers) {
                        handler (nil);
                    }
                    [self.imagesLoading removeObjectForKey:cacheURL];
                } else {
                    // Store data in cache
                    NSCachedURLResponse *cachedResponse = [[NSCachedURLResponse alloc] initWithResponse:receivedResponse data:data];
                    [self.imageURLCache storeCachedResponse:cachedResponse forRequest:cacheRequest];
                    [cachedResponse release];
                    
                    // Return image
                    UIImage *image = [UIImage imageWithData:data];
                    
                    NSMutableArray *pendingHandlers = [self.imagesLoading objectForKey:cacheURL];
                    for (void (^handler)(UIImage * image) in pendingHandlers) {
                        handler (image);
                    }
                    [self.imagesLoading removeObjectForKey:cacheURL];
                }
                
                // UIImageView doesn't comply to NSCopying protocol, its pointer shouldn't change and is unique
                NSString *key = [NSString stringWithFormat:@"%p", imageView];
                [self.downloadPerImageView removeObjectForKey:key];
             }];
            
            // UIImageView doesn't comply to NSCopying protocol
            NSString *key = [NSString stringWithFormat:@"%p", imageView];
            [self.downloadPerImageView setObject:imageDownload forKey:key];
            return imageDownload;
        }
    }
}

- (void)cancelDownloadForImageView:(UIImageView *)imageView {
    NSString *key = [NSString stringWithFormat:@"%p", imageView];
    KVDownload *download = [self.downloadPerImageView objectForKey:key];
    [download cancel];
    [self.downloadPerImageView removeObjectForKey:key];
}

- (UIImage *)cachedImageAtURL:(NSURL *)cacheURL {
    UIImage *localImage = [UIImage imageNamed:[cacheURL absoluteString]];

    if (localImage) {
        return localImage;
    }

    NSURLRequest *request = [NSURLRequest requestWithURL:cacheURL];
    NSCachedURLResponse *earlierCachedResponse = [self.imageURLCache cachedResponseForRequest:request];
    return [UIImage imageWithData:[earlierCachedResponse data]];
}

- (void)flush {
    [self.imageURLCache removeAllCachedResponses];
}

@end
