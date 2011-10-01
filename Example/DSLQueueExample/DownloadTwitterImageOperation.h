//
//  DownloadTwitterImageOperation.h
//  DSLQueueExample
//
//  Created by Pete Callaway on 01/10/2011.
//  Copyright 2011 Dative Studios. All rights reserved.
//


@interface DownloadTwitterImageOperation : DSLOperation

@property (nonatomic, strong, readonly) NSData *imageData;
@property (nonatomic, readonly) NSInteger responseCode;


// Designated initialiser
- (id)initWithURL:(NSURL*)URL;
+ (NSString*)operationIdentifierForImageURL:(NSURL*)imageURL;

@end
