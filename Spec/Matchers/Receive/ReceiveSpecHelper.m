#import "ReceiveSpecHelper.h"
#import "CDRSpec.h"

@implementation MyObj
- (void)callWithoutArgs {}
- (void)callWithArg:(id)arg {}
- (void)callWithArg2:(id)arg {}
- (void)callWithArg:(id)arg arg:(id)arg2 {}
- (void)callWithArg2:(id)arg arg:(id)arg2 {}
@end

@interface Dude
+ (void)afterEach;
@end

void expectReceivePasses(CDRSpecBlock block) {
    block();

    @try {
        [NSClassFromString(@"CDRReceiverObj") afterEach];
    } @catch (id x) {
        fail(@"Expectation should not have raised an exception.");
    }
};

void expectReceiveFails(NSString *containedFailureReason, CDRSpecBlock block) {
    block();

    BOOL failed = NO;
    @try {
        [NSClassFromString(@"CDRReceiverObj") afterEach];
    } @catch (id x) {
        failed = YES;
        if (![x description] || [[x description] rangeOfString:containedFailureReason].location == NSNotFound) {
            NSString *failure = [NSString stringWithFormat:@"Expectation should have raised an exception with '%@' but was '%@'", containedFailureReason, [x description]];
            fail(failure);
        }
    }

    if (!failed) fail(@"Expectation should have raised an exception.");
};
