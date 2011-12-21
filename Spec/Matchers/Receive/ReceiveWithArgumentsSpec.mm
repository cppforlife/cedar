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
}

using namespace Cedar::Matchers;

SPEC_BEGIN(ReceiveWithArgumentsSpec)

describe(@"expecting method calls with matching by arguments", ^{
    __block MyObj *obj, *obj2;

    beforeEach(^{
        obj = [[[MyObj alloc] init] autorelease];
        obj2 = [[[MyObj alloc] init] autorelease];
    });

    context(@"when expecting single call", ^{
        beforeEach(^{
            obj should receive("callWithArg:").with(obj);
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

        it(@"should fail if method is called with non-matching arguments", ^{
            expectReceiveFails(@"Unexpected method was invoked", ^{
                [obj callWithArg:obj2];
            });
        });

        it(@"should fail if method is called more than once", ^{
            expectReceiveFails(@"Unexpected method was invoked", ^{
                [obj callWithArg:obj];
                [obj callWithArg:obj];
            });
        });
    });

    context(@"when expecting multiple calls to the same method with same arguments", ^{
        beforeEach(^{
            obj should receive("callWithArg:").with(obj);
            obj should receive("callWithArg:").with(obj);
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

    context(@"when expecting multiple calls to the same method with different arguments", ^{
        beforeEach(^{
            obj should receive("callWithArg:").with(obj);
            obj should receive("callWithArg:").with(obj2);
        });

        it(@"should fail if method is not called", ^{
            expectReceiveFails(@"expected methods were not invoked", ^{});
        });

        it(@"should fail if method is called less than expected number of times", ^{
            expectReceiveFails(@"expected method was not invoked", ^{
                [obj callWithArg:obj];
            });
        });

        it(@"should fail if method is called expected number of times but not satisfying all argument expectations", ^{
            expectReceiveFails(@"Unexpected method was invoked", ^{
                [obj callWithArg:obj];
                [obj callWithArg:obj];
            });
        });

        it(@"should pass if method is called exact number of times", ^{
            expectReceivePasses(^{
                [obj callWithArg:obj];
                [obj callWithArg:obj2];
            });
        });

        it(@"should pass if both methods are called exact number of times in different order", ^{
            expectReceivePasses(^{
                [obj callWithArg:obj2];
                [obj callWithArg:obj];
            });
        });

        it(@"should fail if method is called more than expected number of times", ^{
            expectReceiveFails(@"Unexpected method was invoked", ^{
                [obj callWithArg:obj];
                [obj callWithArg:obj];
                [obj callWithArg:obj2];
            });
        });
    });

    context(@"when expecting multiple calls to different methods", ^{
        beforeEach(^{
            obj should receive("callWithArg:").with(obj);
            obj should receive("callWithArg2:").with(obj2);
        });

        it(@"should fail if one of the methods is not called", ^{
            expectReceiveFails(@"expected method was not invoked", ^{
                [obj callWithArg:obj];
            });
        });

        it(@"should fail if both methods are called but not satisfying all argument expectations", ^{
            expectReceiveFails(@"Unexpected method was invoked", ^{
                [obj callWithArg:obj];
                [obj callWithArg2:obj];
            });
        });

        it(@"should pass if both methods are called", ^{
            expectReceivePasses(^{
                [obj callWithArg:obj];
                [obj callWithArg2:obj2];
            });
        });

        it(@"should pass if both methods are called in different order", ^{
            expectReceivePasses(^{
                [obj callWithArg2:obj2];
                [obj callWithArg:obj];
            });
        });

        it(@"should fail if one of the methods is called more than expected number of times", ^{
            expectReceiveFails(@"Unexpected method was invoked", ^{
                [obj callWithArg2:obj2];
                [obj callWithArg:obj];
                [obj callWithArg:obj];
            });
        });
    });
});

SPEC_END
