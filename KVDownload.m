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

@interface KVDownload ()

@property (nonatomic, assign, readwrite) float downloadProgress;

@property (retain) NSURLConnection *connection;
@property (retain) NSMutableData *receivedData;

@end

@implementation KVDownload

@synthesize URLRequest = URLRequest_;
@synthesize URLResponse = URLResponse_;
@synthesize completionHandler = completionHandler_;
@synthesize downloadProgress = downloadProgress_;
@synthesize connection = connection_;
@synthesize receivedData = receivedData_;

+ (id)startDownloadWithRequest:(NSURLRequest *)anURLRequest completionHandler:(void (^)(NSURLResponse * response, NSData * data, NSError * error))completionHandler {
    KVDownload *download = [[[self class] alloc] init];
    
    download.URLRequest = anURLRequest;
    download.completionHandler = completionHandler;
    
    [download send];
    return [download autorelease];
}

- (void)dealloc {
    self.URLRequest = nil;
    self.URLResponse = nil;
    self.completionHandler = nil;
    self.connection = nil;
    self.receivedData = nil;
    [super dealloc];
}

#pragma mark - Main
- (BOOL)cancel {
    if (!self.connection) {
        return NO;
    }
    [self.connection cancel];
    self.completionHandler(nil, nil, nil);
    
    self.connection = nil;
    
    return YES;
}

- (void)send {
    // Create the connection
    self.connection = [[[NSURLConnection alloc] initWithRequest:self.URLRequest delegate:self] autorelease];
    if (self.connection) {
        self.receivedData = [NSMutableData data];
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
    [self.receivedData setLength:0];
}

// Called when the HTTP socket received data.
- (void)connection:(NSURLConnection *)aConnection didReceiveData:(NSData *)value {
    [self.receivedData appendData:value];
    
    if ([self.URLResponse isKindOfClass:[NSHTTPURLResponse class]]) {
        NSHTTPURLResponse *response = (NSHTTPURLResponse *)self.URLResponse;
        if ([response statusCode] == 200) {
            self.downloadProgress = ([self.receivedData length] / [response expectedContentLength]);
        } else {
            self.downloadProgress = -1.0f;
        }
    } else {
        self.downloadProgress = -1.0f;   
    }
}

// Called when the HTTP request fails.
- (void)connection:(NSURLConnection *)aConnection didFailWithError:(NSError *)error {
    // Run completion handler
    self.completionHandler(self.URLResponse, self.receivedData, error);
    self.connection = nil;
    self.receivedData = nil;
}

// Called when the connection has finished loading.
- (void)connectionDidFinishLoading:(NSURLConnection *)aConnection {
    // Run completion handler
    self.completionHandler(self.URLResponse, self.receivedData, nil);
    self.connection = nil;
    self.receivedData = nil;
}

// Called if the HTTP request receives an authentication challenge.
- (void)connection:(NSURLConnection *)aConnection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    NSArray *trustedHosts = [[NSUserDefaults standardUserDefaults] arrayForKey:@"trustedHosts"];
    
    if ([challenge previousFailureCount] == 0) {
        if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
            BOOL isTrustedHost = NO;
            for (NSString *trustedHost in trustedHosts) {
                if ([trustedHost isEqualToString:challenge.protectionSpace.host]) {
                    isTrustedHost = YES;
                    break;
                }
            }
            if (isTrustedHost) {
                [[challenge sender] useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];
            }  else {
                [[challenge sender] cancelAuthenticationChallenge:challenge];
            }
        } 
    } else {
        [[challenge sender] cancelAuthenticationChallenge:challenge];
    }
}

- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace {
    return [protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust];
}

@end
