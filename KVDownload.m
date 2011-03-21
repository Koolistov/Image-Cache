//
//  KVDownload.m
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

#import "KVDownload.h"

@implementation KVDownload

@synthesize URLRequest, URLResponse, completionHandler;

+ (id)startDownloadWithRequest:(NSURLRequest *)anURLRequest completionHandler:(void (^)(NSURLResponse * response, NSData * data, NSError * error))completionHandler {
    KVDownload *download = [[[self class] alloc] init];

    download.URLRequest = anURLRequest;
    download.completionHandler = completionHandler;

    [download send];
    return [download autorelease];
}

- (void)dealloc {
    [URLRequest release], URLRequest = nil;
    [receivedData release], receivedData = nil;
    [completionHandler release], completionHandler = nil;
    [super dealloc];
}

#pragma mark - Main
- (BOOL)cancel {
    if (!connection) {
        return NO;
    }
    [connection cancel];
    self.completionHandler(nil, nil, nil);

    [connection release];
    connection = nil;

    return YES;
}

- (void)send {
    // Create the connection
    connection = [[NSURLConnection alloc] initWithRequest:self.URLRequest delegate:self];
    if (connection) {
        receivedData = [[NSMutableData alloc] init];
    } else {
        NSError *error = [NSError errorWithDomain:@"KVDownload" code:1 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Could not create connection", NSLocalizedDescriptionKey, nil]];

        // Run completion handler
        self.completionHandler(nil, nil, error);
    }
}

#pragma mark - NSURLConnection delegate methods
// Called when the HTTP socket gets a response.
- (void)connection:(NSURLConnection *)aConnection didReceiveResponse:(NSURLResponse *)response {
    self.URLResponse = response;
    [receivedData setLength:0];
}

// Called when the HTTP socket received data.
- (void)connection:(NSURLConnection *)aConnection didReceiveData:(NSData *)value {
    [receivedData appendData:value];
}

// Called when the HTTP request fails.
- (void)connection:(NSURLConnection *)aConnection didFailWithError:(NSError *)error {
    // Run completion handler
    self.completionHandler(self.URLResponse, nil, error);
    [connection release];
    connection = nil;
    [receivedData release];
    receivedData = nil;
}

// Called when the connection has finished loading.
- (void)connectionDidFinishLoading:(NSURLConnection *)aConnection {
    // Run completion handler
    self.completionHandler(self.URLResponse, receivedData, nil);
    [connection release];
    connection = nil;
    [receivedData release];
    receivedData = nil;
}

@end
