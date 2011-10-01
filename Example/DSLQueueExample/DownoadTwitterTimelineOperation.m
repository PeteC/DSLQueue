//
//  DownoadTwitterTimelineOperation.m
//  DSLQueueExample
//
//  Created by Pete Callaway on 01/10/2011.
//  Copyright 2011 Dative Studios. All rights reserved.
//

#import "DownoadTwitterTimelineOperation.h"


@interface DownoadTwitterTimelineOperation ()

@property (nonatomic, strong) NSArray *tweets;

@end


@implementation DownoadTwitterTimelineOperation

@synthesize tweets=__tweets;


#pragma mark - Initialisation

// Designated initialiser
- (id)init {
	self = [super init];
	if (self != nil) {
		self.identifier = NSStringFromClass([self class]);
	}
	
	return self;
}


#pragma mark - DSLOperation methods

- (void)performOperation {
    TWRequest *postRequest = [[TWRequest alloc] initWithURL:[NSURL URLWithString:@"http://api.twitter.com/1/statuses/public_timeline.json"] parameters:nil requestMethod:TWRequestMethodGET];
    
    [postRequest performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
        if (urlResponse.statusCode != 200) {
            [self markAsFinished];
            return;
        }
        
        NSError *jsonParsingError = nil;
        id<NSObject> jsonResponse = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:&jsonParsingError];
        if (jsonParsingError != nil || ![jsonResponse isKindOfClass:[NSArray class]]) {
            [self markAsFinished];
            return;
        }
        
        self.tweets = (NSArray*)jsonResponse;
        [self markAsFinished];
    }];
}

@end