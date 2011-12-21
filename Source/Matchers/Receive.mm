#import "Receive.h"
#import <Foundation/Foundation.h>
#import <objc/runtime.h>

@interface CDRMethodsBag
+ (id)initWithObject:(id)anObject;
+ (id/*OCPartialMockObject*/)existingPartialMockForObject:(id)anObject;
- (BOOL)handleInvocation:(NSInvocation *)anInvocation;
- (id)expect;
@end

// Holds methods for CDRCustomPartialMockObject class that is a subclass of OCPartialMockObject
@interface CDRCustomPartialMockObjectMethodsBag : NSObject
@end

@implementation CDRCustomPartialMockObjectMethodsBag
- (void)forwardInvocationForRealObject:(NSInvocation *)anInvocation {
    id /*OCPartialMockObject*/ mock = [NSClassFromString(@"OCPartialMockObject") existingPartialMockForObject:self];
    if([mock handleInvocation:anInvocation] == NO) {
        // Call out to mock's realObject implementation.
        // This avoids well known 'Ended up in subclass forwarder...' error
        anInvocation.selector = NSSelectorFromString([@"ocmock_replaced_" stringByAppendingString:NSStringFromSelector(anInvocation.selector)]);
        [anInvocation invokeWithTarget:self];
    }
}
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

    if (!mock_) {
        mock_ = [[NSClassFromString(@"OCPartialMockObject") alloc] initWithObject:object_];

        // Make sure we do not blow up if partial mock object gets called with expected method
        // but there are no more recorders left to match against (e.g. method called with non-matching args,
        // method called more than expected number of times)
        Method forwardInvocationMethod = class_getInstanceMethod([CDRCustomPartialMockObjectMethodsBag class], @selector(forwardInvocationForRealObject:));
        IMP forwardInvocationImp = method_getImplementation(forwardInvocationMethod);
        const char *forwardInvocationTypes = method_getTypeEncoding(forwardInvocationMethod);
        class_replaceMethod([object_ class], @selector(forwardInvocation:), forwardInvocationImp, forwardInvocationTypes);
    }

    [[mock_ expect] forwardInvocation:invocation];
    [receiverObjs__ addObject:self];
}

- (void)verify {
    [mock_ verify];
}

+ (void)afterEach {
    CDRSpecFailure *failure = nil;

    for (CDRReceiverObj *receiverObj in receiverObjs__) {
        @try {
            [receiverObj verify];
        } @catch (id x) {
            failure = [CDRSpecFailure specFailureWithRaisedObject:x];
            break;
        }
    }

    [receiverObjs__ release];
    receiverObjs__ = nil;

    [failure raise];
}

@end
