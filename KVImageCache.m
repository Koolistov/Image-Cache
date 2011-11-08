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

@interface KVImageCache ()

@property (retain) NSMutableDictionary *imagesLoading;
@property (retain) NSMutableDictionary *downloadPerImageView;

@end

@implementation KVImageCache

@synthesize imageURLCache = imageURLCache_;
@synthesize imagesLoading = imagesLoading_;
@synthesize downloadPerImageView = downloadPerImageView_;
@synthesize shouldCheckForLocalImages=shouldCheckForLocalImages_;

+ (KVImageCache *)defaultCache  {
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
        
        NSURLCache *cache = [[NSURLCache alloc] initWithMemoryCapacity:1 * 1024 * 1024 diskCapacity:10 * 1024 * 1024 diskPath:diskCachePath];
        self.imageURLCache = cache;
        [cache release];
        
        self.imagesLoading = [NSMutableDictionary dictionary];
        self.downloadPerImageView = [NSMutableDictionary dictionary];
        self.shouldCheckForLocalImages = NO;
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

    // Check if a local image is referenced
    if (self.shouldCheckForLocalImages) {
        UIImage *localImage = [UIImage imageNamed:[imageURL absoluteString]];
        if (localImage) {
            handler(localImage);
            return nil;
        }
    }

    NSURLRequest *cacheRequest = [NSURLRequest requestWithURL:cacheURL];
    NSURLRequest *downloadRequest = [NSURLRequest requestWithURL:imageURL];
    NSCachedURLResponse *earlierCachedResponse = [self.imageURLCache cachedResponseForRequest:cacheRequest];

    if (earlierCachedResponse) {
        UIImage *image = [UIImage imageWithData:[earlierCachedResponse data]];
        handler(image);
        return nil;
    } else {
        NSMutableDictionary *pendingHandlers = [self.imagesLoading objectForKey:cacheURL];
        // UIImageView doesn't comply to NSCopying protocol, its pointer shouldn't change and is unique
        NSString *key = [NSString stringWithFormat:@"%p", imageView];
        if (pendingHandlers) {
            [pendingHandlers setObject:[[handler copy] autorelease] forKey:key];
            return nil;
        } else {
            pendingHandlers = [NSMutableDictionary dictionaryWithObject:[[handler copy] autorelease] forKey:key];
            [self.imagesLoading setObject:pendingHandlers forKey:cacheURL];

            KVDownload *imageDownload = [KVDownload startDownloadWithRequest:downloadRequest completionHandler:^(NSURLResponse * receivedResponse, NSData * data, NSError * error) {
                if (!data || [data length] == 0) {
                    // If no data, return nil image
                    NSMutableDictionary *pendingHandlers = [self.imagesLoading objectForKey:cacheURL];
                    for (void (^handler)(UIImage * image) in [pendingHandlers allValues]) {
                        handler (nil);
                    }
                    [self.imagesLoading removeObjectForKey:cacheURL];
                } else {
                    // Return image
                    UIImage *image = [UIImage imageWithData:data];
                    
                    if (image) {
                        // Store data in cache
                        NSCachedURLResponse *cachedResponse = [[NSCachedURLResponse alloc] initWithResponse:receivedResponse data:data];
                        [self.imageURLCache storeCachedResponse:cachedResponse forRequest:cacheRequest];
                        [cachedResponse release];
                    }
                    
                    NSMutableDictionary *pendingHandlers = [self.imagesLoading objectForKey:cacheURL];
                    for (void (^handler)(UIImage * image) in [pendingHandlers allValues]) {
                        handler (image);
                    }
                    [self.imagesLoading removeObjectForKey:cacheURL];
                }
                
                [self.downloadPerImageView removeObjectForKey:key];
             }];
            
            [self.downloadPerImageView setObject:[NSDictionary dictionaryWithObjectsAndKeys:imageDownload, @"download", cacheURL, @"cacheURL", nil] forKey:key];
            return imageDownload;
        }
    }
}

- (void)cancelDownloadForImageView:(UIImageView *)imageView {
    NSString *key = [NSString stringWithFormat:@"%p", imageView];
    NSDictionary *downloadDict = [self.downloadPerImageView objectForKey:key];
    if (downloadDict) {
        NSURL *cacheURL = [downloadDict objectForKey:@"cacheURL"];
        
        // Check if there are other pendingHandlers for this URL
        NSMutableDictionary *pendingHandlers = [self.imagesLoading objectForKey:cacheURL];
        
        // Remove handler for this imageView
        [pendingHandlers removeObjectForKey:key];
        
        // Cancel download only if no more pending handlers remain
        if ([pendingHandlers count] == 0) {
            KVDownload *download = [downloadDict objectForKey:@"download"];
            [download cancel];
            [self.imagesLoading removeObjectForKey:cacheURL];
        }
        
        [self.downloadPerImageView removeObjectForKey:key];
    }
}

- (UIImage *)cachedImageAtURL:(NSURL *)cacheURL {
    // Check if a local image is referenced
    if (self.shouldCheckForLocalImages) {
        UIImage *localImage = [UIImage imageNamed:[cacheURL absoluteString]];
        
        if (localImage) {
            return localImage;
        }
    }

    NSURLRequest *request = [NSURLRequest requestWithURL:cacheURL];
    NSCachedURLResponse *earlierCachedResponse = [self.imageURLCache cachedResponseForRequest:request];
    return [UIImage imageWithData:[earlierCachedResponse data]];
}

- (void)flush {
    [self.imageURLCache removeAllCachedResponses];
}

@end
