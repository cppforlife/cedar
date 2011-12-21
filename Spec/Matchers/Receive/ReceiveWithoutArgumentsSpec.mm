#if TARGET_OS_IPHONE
// Normally you would include this file out of the framework.  However, we're
// testing the framework here, so including the file from the framework will
// conflict with the compiler attempting to include the file from the project.
#import "SpecHelper.h"
#import "OCMock.h"
#else
#import <Cedar/SpecHelper.h>
#import <OCMock/OCMock.h>
#endif

extern "C" {
#import "ReceiveSpecHelper.h"
#import "ExpectFailureWithMessage.h"
}

using namespace Cedar::Matchers;

SPEC_BEGIN(ReceiveWithoutArgumentsSpec)

describe(@"expecting method calls without matching by arguments", ^{
    __block MyObj *obj;

    beforeEach(^{
        obj = [[[MyObj alloc] init] autorelease];
    });

    it(@"should not fail if other failure occurred", ^{
        obj should receive("callWithoutArgs");
        2 should equal(3);
    });

    context(@"when expecting single call without arguments", ^{
        beforeEach(^{
            obj should receive("callWithoutArgs");
        });

        it(@"should fail if method is not called", ^{
            expectReceiveFails(@"expected method was not invoked", ^{});
        });

        it(@"should fail if method is not called and some other method was called", ^{
            expectReceiveFails(@"expected method was not invoked", ^{
                [obj callWithoutArgs2];
            });
        });

        it(@"should pass if method is called once", ^{
            expectReceivePasses(^{
                [obj callWithoutArgs];
            });
        });

        it(@"should fail if method is called more than once", ^{
            expectReceiveFails(@"Unexpected method was invoked", ^{
                [obj callWithoutArgs];
                [obj callWithoutArgs];
            });
        });
    });

    context(@"when expecting single call with arguments", ^{
        beforeEach(^{
            obj should receive("callWithArg:");
        });

        it(@"should fail if method is not called", ^{
            expectReceiveFails(@"expected method was not invoked", ^{});
        });

        it(@"should fail if method is not called and some other method was called", ^{
            expectReceiveFails(@"expected method was not invoked", ^{
                [obj callWithArg2:obj];
            });
        });

        it(@"should pass if method is called once", ^{
            expectReceivePasses(^{
                [obj callWithArg:obj];
            });
        });

        it(@"should fail if method is called more than once", ^{
            expectReceiveFails(@"Unexpected method was invoked", ^{
                [obj callWithArg:obj];
                [obj callWithArg:obj];
            });
        });
    });

    context(@"when expecting multiple calls to the same method", ^{
        beforeEach(^{
            obj should receive("callWithArg:");
            obj should receive("callWithArg:");
        });

        it(@"should fail if method is not called", ^{
            expectReceiveFails(@"expected methods were not invoked", ^{});
        });

        it(@"should fail if method is called less than expected number of times", ^{
            expectReceiveFails(@"expected method was not invoked", ^{
                [obj callWithArg:obj];
            });
        });

        it(@"should pass if method is called exact number of times", ^{
            expectReceivePasses(^{
                [obj callWithArg:obj];
                [obj callWithArg:obj];
            });
        });

        it(@"should fail if method is called more than expected number of times", ^{
            expectReceiveFails(@"Unexpected method was invoked", ^{
                [obj callWithArg:obj];
                [obj callWithArg:obj];
                [obj callWithArg:obj];
            });
        });
    });

    context(@"when expecting multiple calls to different methods", ^{
        beforeEach(^{
            obj should receive("callWithoutArgs");
            obj should receive("callWithArg:");
        });

        it(@"should fail if one of the methods is not called", ^{
            expectReceiveFails(@"expected method was not invoked", ^{
                [obj callWithArg:obj];
            });
        });

        it(@"should pass if both methods are called", ^{
            expectReceivePasses(^{
                [obj callWithoutArgs];
                [obj callWithArg:obj];
            });
        });

        it(@"should pass if both methods are called in different order", ^{
            expectReceivePasses(^{
                [obj callWithArg:obj];
                [obj callWithoutArgs];
            });
        });

        it(@"should fail if one of the methods is called more than expected number of times", ^{
            expectReceiveFails(@"Unexpected method was invoked", ^{
                [obj callWithoutArgs];
                [obj callWithArg:obj];
                [obj callWithArg:obj];
            });
        });
    });
});

SPEC_END
