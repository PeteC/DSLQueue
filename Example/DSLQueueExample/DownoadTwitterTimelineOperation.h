//
//  DownoadTwitterTimelineOperation.h
//  DSLQueueExample
//
//  Created by Pete Callaway on 01/10/2011.
//  Copyright 2011 Dative Studios. All rights reserved.
//


@interface DownoadTwitterTimelineOperation : DSLOperation

@property (nonatomic, strong, readonly) NSArray *tweets;

- (id)init;

@end
