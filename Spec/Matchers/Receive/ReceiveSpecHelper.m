#import "ReceiveSpecHelper.h"
#import "CDRSpec.h"

@implementation MyObj
- (void)callWithoutArgs {}
- (void)callWithoutArgs2 {}

- (void)callWithArg:(id)arg {}
- (void)callWithArg2:(id)arg {}

- (void)callWithArg:(id)arg arg:(id)arg2 {}
- (void)callWithArg2:(id)arg arg:(id)arg2 {}

- (id)returnId { return self; }
- (MyObj *)returnMyObj {return self; }
- (int)returnInt { return -1; }
- (BOOL)returnBool { return YES; }
- (double)returnDouble { return -2.5f; }
- (float)returnFloat { return -2.5f; }
- (char)returnChar { return 'a'; }
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
    id failure = nil;
    @try {
        block();
    } @catch (id x) {
        failure = x;
    }

    @try {
        [NSClassFromString(@"CDRReceiverObj") afterEach];
    } @catch (id x) {
        if (!failure) failure = x;
    }

    if (!failure) {
        fail(@"Expectation should have raised an exception.");
    } else {
        if (![failure description] || [[failure description] rangeOfString:containedFailureReason].location == NSNotFound) {
            fail([NSString stringWithFormat:
                    @"Expectation should have raised an exception with '%@' but was '%@'",
                    containedFailureReason, [failure description]]);
        }
    }
};
