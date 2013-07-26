#import "NSInvocation+Cedar.h"
#import <objc/runtime.h>

@implementation NSInvocation (Cedar)

- (void)copyBlockArguments {
    static char *blockTypeEncoding = "@?";
    NSMethodSignature *methodSignature = [self methodSignature];
    NSUInteger numberOfArguments = [methodSignature numberOfArguments];
    NSMutableArray *copiedBlocks = [NSMutableArray array];

    for (NSUInteger argumentIndex = 2; argumentIndex < numberOfArguments; ++argumentIndex) {
        const char *encoding = [methodSignature getArgumentTypeAtIndex:argumentIndex];
        if (strncmp(blockTypeEncoding, encoding, 2) == 0) {
            id argument = nil;
            [self getArgument:&argument atIndex:argumentIndex];
            if (argument) {
                // Even under ARC blocks need to be copied
                // when passed down the stack into methods that retain.
                // (i.e. collection methods such as addObject:)
                id copiedArgument = [argument copy];
                [copiedBlocks addObject:copiedArgument];
                [argument release];
                [self setArgument:&copiedArgument atIndex:argumentIndex];
            }
        }
    }

    objc_setAssociatedObject(self, @"copied-blocks", copiedBlocks, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
