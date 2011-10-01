/*
 DSLQueue.m
 
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

#import "DSLQueue.h"
#import "DSLOperation.h"


@interface DSLQueue ()

@property (retain) DSLOperation *operationInProgress;
@property (retain) NSMutableArray *operations;

- (void)addOperationWithoutStarting:(DSLOperation*)operation prioritised:(BOOL)prioritised;
- (DSLOperation*)queuedOperationWithIdentifier:(NSString*)identifier;
- (void)startNextOperation;

@end


@implementation DSLQueue

@synthesize operationInProgress=__operationInProgress;
@synthesize operations=__operations;


#pragma mark - Memory management

- (void)dealloc {
	// Release properties
    [__operationInProgress release], __operationInProgress = nil;
    [__operations release], __operations = nil;
    
    [super dealloc];
}


#pragma mark - Initialisation

// Designated initialiser
- (id)init {
	self = [super init];
	if (self != nil) {
		__operations = [[NSMutableArray alloc] init];
	}
	
	return self;
}


#pragma mark -

- (void)addOperation:(DSLOperation*)operation {
    [self addOperations:[NSArray arrayWithObject:operation] prioritised:YES];
}

- (void)addOperations:(NSArray *)operations {
    [self addOperations:operations prioritised:YES];
}

- (void)addOperation:(DSLOperation*)operation prioritised:(BOOL)prioritised {
    [self addOperations:[NSArray arrayWithObject:operation] prioritised:prioritised];
}

- (void)addOperations:(NSArray *)operations prioritised:(BOOL)prioritised {
    NSEnumerator *enumerator = prioritised ? operations.reverseObjectEnumerator : operations.objectEnumerator;
    for (DSLOperation *operation in enumerator) {
        [self addOperationWithoutStarting:operation prioritised:prioritised];
    }
    
    if (self.operationInProgress == nil) {
        [self startNextOperation];
    }
}

- (BOOL)containsOperationWithIdentifier:(NSString*)identifier {
    return ([self queuedOperationWithIdentifier:identifier] != nil);
}

- (void)cancelOperationWithIdentifier:(NSString*)identifier {
    if ([[self.operationInProgress identifier] isEqualToString:identifier]) {
        [self.operationInProgress requestCancel];
    }
    else {
        DSLOperation *operation = [self queuedOperationWithIdentifier:identifier];
        if (operation != nil) {
            @synchronized(self) {
                [self.operations removeObject:operation];
            }
        }
    }
}


#pragma mark - Private methods

- (void)addOperationWithoutStarting:(DSLOperation *)operation prioritised:(BOOL)prioritised {
    NSString *operationIdentifer = [operation identifier];
    NSAssert1((operationIdentifer.length > 0), @"Override identifer in %@", NSStringFromClass([operation class]));
    
    @synchronized(self) {
        if ([[self.operationInProgress identifier] isEqualToString:operationIdentifer]) {
            [self.operationInProgress copyCompletionBlocksFromOperation:operation];
        }
        else {
            // Check an operation already exists with the same id
            DSLOperation *queuedOperation = [self queuedOperationWithIdentifier:operationIdentifer];
            if (queuedOperation != nil) {
                [queuedOperation copyCompletionBlocksFromOperation:operation];
                
                if (prioritised) {
                    [queuedOperation retain];
                    [self.operations removeObject:queuedOperation];
                    [self.operations insertObject:queuedOperation atIndex:0];
                    [queuedOperation release];
                }
            }
            else {
                if (prioritised) {
                    [self.operations insertObject:operation atIndex:0];
                }
                else {
                    [self.operations addObject:operation];
                }
            }
        }
    }
}

- (DSLOperation*)queuedOperationWithIdentifier:(NSString*)identifier {
    // TODO change this to anything better than iterating through the array
    __block DSLOperation *foundOperation = nil;
    
    [self.operations enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        DSLOperation *queuedOperation = obj;
        if ([[queuedOperation identifier] isEqualToString:identifier]) {
            foundOperation = queuedOperation;
            *stop = YES;
        }
    }];
     
    return foundOperation;
}

- (void)startNextOperation {
    if (self.operationInProgress != nil || self.operations.count == 0) {
        return;
    }
    
    // Setup the next operation
    @synchronized(self) {
        self.operationInProgress = [self.operations objectAtIndex:0];
        [self.operations removeObjectAtIndex:0];

        [self.operationInProgress addCompletionBlock:^(DSLOperation *operation) {
            // Start the next operation in the queue
            self.operationInProgress = nil;
            [self startNextOperation];
        }];
    }

    // Start the opeation on a background thread
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^(void) {
        [self.operationInProgress performOperation];
    });
}


@end