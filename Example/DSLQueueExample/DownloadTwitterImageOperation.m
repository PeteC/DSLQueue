//
//  DownloadTwitterImageOperation.m
//  DSLQueueExample
//
//  Created by Pete Callaway on 01/10/2011.
//  Copyright 2011 Dative Studios. All rights reserved.
//

#import "DownloadTwitterImageOperation.h"

NSUInteger const kDownloadTwitterImageOperationMaximumImageSize = 250 * 128; // 250kb


@interface DownloadTwitterImageOperation ()

@property (nonatomic, strong) NSURL *imageURL;
@property (nonatomic, strong) NSMutableData *mutableImageData;
@property (nonatomic) NSInteger responseCode;
@property (nonatomic, strong) NSURLConnection *URLConnection;

@end


@implementation DownloadTwitterImageOperation

@synthesize imageURL=__imageURL;
@synthesize mutableImageData=__mutableImageData;
@synthesize responseCode=__responseCode;
@synthesize URLConnection=__URLConnection;


#pragma mark - Property accessors

- (NSData*)imageData {
    return self.mutableImageData;
}

+ (NSString*)operationIdentifierForImageURL:(NSURL*)imageURL {
    return [NSString stringWithFormat:@"%@:%@", NSStringFromClass([self class]), imageURL.absoluteString];
}


#pragma mark - Initialisation

// Designated initialiser
- (id)initWithURL:(NSURL *)URL {
	self = [super init];
	if (self != nil) {
        self.identifier = [DownloadTwitterImageOperation operationIdentifierForImageURL:URL];
		self.imageURL = URL;
        self.responseCode = 0;
	}
	
	return self;
}


#pragma mark - DSLOperation methods

- (void)performOperation {
    self.URLConnection = [[NSURLConnection alloc] initWithRequest:[[NSURLRequest alloc] initWithURL:self.imageURL] delegate:self];
    [self.URLConnection start];
    CFRunLoopRun();
}


#pragma mark - NSURLConnectionDelegate methods

- (void)connection:(NSURLConnection*)connection didReceiveResponse:(NSHTTPURLResponse*)response {
    self.mutableImageData = [NSMutableData data];
    self.responseCode = [response statusCode];
}

- (void)connection:(NSURLConnection*)connection didReceiveData:(NSData*)newData {
    if (self.mutableImageData.length + newData.length > kDownloadTwitterImageOperationMaximumImageSize) {
        self.mutableImageData = nil;
        [connection cancel];
        [self markAsFinished];
        CFRunLoopStop(CFRunLoopGetCurrent());
    }
    else {
        [self.mutableImageData appendData:newData];
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection*)connection {
    [self markAsFinished];
    CFRunLoopStop(CFRunLoopGetCurrent());
}

- (void)connection:(NSURLConnection*)connection didFailWithError:(NSError*)error {
    self.mutableImageData = nil;
    [self markAsFinished];
    CFRunLoopStop(CFRunLoopGetCurrent());
}

@end