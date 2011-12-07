/*
 DSLOperation.m
 
 Copyright (c) 2011 Dative Studios. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 * Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided with the distribution.
 
 * Neither the name of the author nor the names of its contributors may be used
 to endorse or promote products derived from this software without specific
 prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */


#import "DSLOperation.h"
#import "DSLQueue.h"


@interface DSLOperation ()

@property (assign) BOOL cancelRequested;
@property (nonatomic, retain) NSMutableArray *mutableCompletionBlocks;

@end


@implementation DSLOperation

@synthesize cancelRequested=__cancelRequested;
@synthesize identifier=__identifier;
@synthesize mutableCompletionBlocks=__mutableCompletionBlocks;


#pragma mark - Memory management

- (void)dealloc {
    [__identifier release], __identifier = nil;
    [__mutableCompletionBlocks release], __mutableCompletionBlocks = nil;
    
    [super dealloc];
}

#pragma mark - Property accessors

- (NSArray*)completionBlocks {
    return self.mutableCompletionBlocks;
}


#pragma mark - Initialisation

// Designated initialiser
- (id)init {
	self = [super init];
	if (self != nil) {
        __cancelRequested = NO;
		__mutableCompletionBlocks = [[NSMutableArray alloc] init];
	}
	
	return self;
}

- (void)addCompletionBlock:(DSLOperationCompletionBlock)block {
	
	DSLOperationCompletionBlock givenBlock = [[block copy] autorelease];
	dispatch_queue_t callingQueue = dispatch_get_current_queue();
	
	DSLOperationCompletionBlock wrappedBlock = ^(DSLOperation *operation) {
		dispatch_async(callingQueue, ^{
			givenBlock(operation);
		});
	};
	
    [self.mutableCompletionBlocks addObject:[[wrappedBlock copy] autorelease]];
}

- (void)copyCompletionBlocksFromOperation:(DSLOperation*)source {
    [self.mutableCompletionBlocks addObjectsFromArray:source.completionBlocks]; // Completion blocks in the source have already been copied
}

- (void)performOperation {
}

- (void)markAsFinished {
    // Perform any custom completion blocks on the main thread
    __block DSLOperation *blockSelf = self;
    for (DSLOperationCompletionBlock completionBlock in self.mutableCompletionBlocks) {
        completionBlock(blockSelf);
    }
}

- (void)requestCancel {
    self.cancelRequested = YES;
}


@end