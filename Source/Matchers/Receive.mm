#import "Receive.h"
#import <Foundation/Foundation.h>

@interface NSInvocation (CDRPrivate)
+ (NSInvocation *)invocationWithMethodSignature:(NSMethodSignature *)signature arguments:(void *)arguments;
@end

@interface CDRFakeOCMockObject
+ (id)partialMockForObject:(id)obj;
- (id)expect;
@end


static NSMutableArray *receiverObjs__ = nil;

@implementation CDRReceiverObj

- (void)dealloc {
    [object_ release];
    [mock_ release];
    if (hasArguments_) va_end(arguments_); // balances va_copy in setArguments:
    [super dealloc];
}

- (void)setObject:(id)object {
    [object_ release];
    object_ = [object retain];
}

- (void)setSelector:(SEL)selector {
    selector_ = selector;
}

- (void)setArguments:(va_list)arguments {
    if (hasArguments_)
        va_end(arguments_);
    
    hasArguments_ = YES;
    va_copy(arguments_, arguments);
}

- (void)setAs:(NSArray *)as {
    hasArguments_ = YES;
    as_ = [as retain];
}

- (void)construct {
    NSAssert(!mock_,    @"Cannot be constructed more than once.");
    NSAssert(object_,   @"Target object should be set.");
    NSAssert(selector_, @"Selector should be set.");

    NSInvocation *invocation = nil;
    if (hasArguments_) {
        NSMethodSignature *signature = [object_ methodSignatureForSelector:selector_];
        invocation = [NSInvocation invocationWithMethodSignature:signature];
        invocation.selector = selector_;
        
        for (int i=2; i<signature.numberOfArguments; i++) {
            void *arg;
            [[as_ objectAtIndex:i-2] getValue:&arg];
            [invocation setArgument:&arg atIndex:i];
        }

//        http://blog.jayway.com/2010/03/30/performing-any-selector-on-the-main-thread/
//        char *args = (char *)arguments_;
//        for (int i=2; i<signature.numberOfArguments; i++) {
//            const char *type = [signature getArgumentTypeAtIndex:i];
//            
//            NSUInteger size, align;
//            NSGetSizeAndAlignment(type, &size, &align);
//            
//            NSUInteger mod = (NSUInteger)args % align;
//            if (mod != 0) args += align - mod;
//            
//            [invocation setArgument:args atIndex:i];
//            args += size;
//        }
    } else {
        NSMethodSignature *signature = [NSMethodSignature signatureWithObjCTypes:"v@:"]; // (void)id,SEL
        invocation = [NSInvocation invocationWithMethodSignature:signature];
        invocation.selector = selector_;
    }

    mock_ = [[NSClassFromString(@"OCMockObject") partialMockForObject:object_] retain];
    [[mock_ expect] forwardInvocation:invocation];

    if (!receiverObjs__) 
        receiverObjs__ = [[NSMutableArray alloc] init];
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
