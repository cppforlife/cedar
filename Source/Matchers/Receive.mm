#import "Receive.h"
#import <Foundation/Foundation.h>

@interface CDRFakeOCMockObject
+ (id)partialMockForObject:(id)obj;
- (id)expect;
@end


static NSMutableArray *receiverObjs__ = nil;

@implementation CDRReceiverObj

- (void)dealloc {
    [mock_ release];
    [object_ release];
    [arguments_ release];
    [super dealloc];
}

- (void)setObject:(id)object {
    [object_ release];
    object_ = [object retain];
}

- (void)setSelector:(SEL)selector {
    selector_ = selector;
}

- (void)setArguments:(NSArray *)arguments {
    [arguments_ release];
    arguments_ = [arguments retain];
}

- (void)construct {
    NSAssert(!mock_,    @"Cannot be constructed more than once.");
    NSAssert(object_,   @"Target object should be set.");
    NSAssert(selector_, @"Selector should be set.");

    NSInvocation *invocation = nil;
    if (arguments_) {
        NSMethodSignature *signature = [object_ methodSignatureForSelector:selector_];
        invocation = [NSInvocation invocationWithMethodSignature:signature];
        invocation.selector = selector_;

        for (int i=2; i<signature.numberOfArguments; i++) {
            void *arg;
            [[arguments_ objectAtIndex:i-2] getValue:&arg];
            [invocation setArgument:&arg atIndex:i];
        }
    } else {
        // Tricks OCMock to compare based on selector ignoring all arguments
        NSMethodSignature *signature = [NSMethodSignature signatureWithObjCTypes:"v@:"]; // (void)id,SEL
        invocation = [NSInvocation invocationWithMethodSignature:signature];
        invocation.selector = selector_;
    }

    if (!receiverObjs__)
        receiverObjs__ = [[NSMutableArray alloc] init];

    // Reuse previously created mock object for this target object
    for (CDRReceiverObj *receiverObj in receiverObjs__) {
        if (receiverObj->object_ == object_) {
            mock_ = [receiverObj->mock_ retain];
            break;
        }
    }

    if (!mock_)
        mock_ = [[NSClassFromString(@"OCMockObject") partialMockForObject:object_] retain];

    [[mock_ expect] forwardInvocation:invocation];
    [receiverObjs__ addObject:self];
}

- (void)verify {
    [mock_ verify];
}

+ (void)afterEach {
    for (CDRReceiverObj *receiverObj in receiverObjs__) {
        [receiverObj verify];
    }

    [receiverObjs__ release];
    receiverObjs__ = nil;
}

@end
