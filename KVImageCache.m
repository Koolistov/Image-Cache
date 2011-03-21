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

@end

static KVImageCache * defaultCache = nil;

@implementation KVImageCache

@synthesize imageURLCache;

+ (id)defaultCache {
    @synchronized(self) {
        if (defaultCache == nil) {
            defaultCache = [[self alloc] init];
            // Create cache with 1 MB memory and 10 MB disk capacity
            // Using SDURLCache subclass which enables caching to disk
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
            NSString *diskCachePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"KVImageCache"];

            NSURLCache *cache = [[SDURLCache alloc] initWithMemoryCapacity:1 * 1024 * 1024 diskCapacity:10 * 1024 * 1024 diskPath:diskCachePath];
            defaultCache.imageURLCache = cache;
            [cache release];
        }
    }

    return defaultCache;
}

- (void)dealloc {
    [super dealloc];
}

#pragma mark - Main
- (id)loadImageAtURL:(NSURL *)anURL withHandler:(void (^)(UIImage * image))handler {
    if (!anURL) {
        handler(nil);
        return nil;
    }
    
    UIImage *localImage = [UIImage imageNamed:[anURL absoluteString]];
    if (localImage) {
        handler(localImage);
        return nil;
    }
    
    NSURLRequest *request = [NSURLRequest requestWithURL:anURL];
    NSCachedURLResponse *earlierCachedResponse = [self.imageURLCache cachedResponseForRequest:request];

    if (earlierCachedResponse) {
        UIImage *image = [UIImage imageWithData:[earlierCachedResponse data]];
        handler(image);
        return nil;
    } else {
        KVDownload *imageDownload = [KVDownload startDownloadWithRequest:request completionHandler:^(NSURLResponse * receivedResponse, NSData * data, NSError * error) {
             // If no data, return nil image
             if (!data || [data length] == 0) {
                 handler (nil);
                 return;
             } else {
                 // Store data in cache
                 NSCachedURLResponse *cachedResponse = [[NSCachedURLResponse alloc] initWithResponse:receivedResponse data:data];
                 [self.imageURLCache storeCachedResponse:cachedResponse forRequest:request];
                 [cachedResponse release];
             }

             // Return image
             UIImage *image = [UIImage imageWithData:data];
             handler (image);
         }];
        return imageDownload;
    }
}

- (UIImage *)cachedImageAtURL:(NSURL *)anURL {
    UIImage *localImage = [UIImage imageNamed:[anURL absoluteString]];
    if (localImage) {
        return localImage;
    }
    
    NSURLRequest *request = [NSURLRequest requestWithURL:anURL];
    NSCachedURLResponse *earlierCachedResponse = [self.imageURLCache cachedResponseForRequest:request];
    return [UIImage imageWithData:[earlierCachedResponse data]];
}

- (void)flush {
    [self.imageURLCache removeAllCachedResponses];
}

#pragma mark - Singleton Pattern
+ (id)allocWithZone:(NSZone *)zone {
    @synchronized(self) {
        if (defaultCache == nil) {
            defaultCache = [super allocWithZone:zone];
            return defaultCache;
        }
    }

    return nil;
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (id)init {
    if ([super init] == nil) {
        return nil;
    }

    return self;
}

- (id)retain {
    return self;
}

- (unsigned)retainCount {
    return UINT_MAX;
}

- (void)release {
    // Do nothing.
}

- (id)autorelease {
    return self;
}

@end
