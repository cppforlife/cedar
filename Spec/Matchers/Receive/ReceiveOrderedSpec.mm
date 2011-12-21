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

SPEC_BEGIN(ReceiveOrderedSpec)

describe(@"expecting method calls in specific order", ^{
    __block MyObj *obj, *obj2;

    beforeEach(^{
        obj = [[[MyObj alloc] init] autorelease];
        obj2 = [[[MyObj alloc] init] autorelease];
    });

    context(@"when expecting multiple calls to different methods", ^{
        beforeEach(^{
            obj should receive("callWithoutArgs").ordered();
            obj should receive("callWithArg:").ordered();
        });

        it(@"should pass if methods are called in correct order", ^{
            expectReceivePasses(^{
                [obj callWithoutArgs];
                [obj callWithArg:obj];
            });
        });

        it(@"should fail correctly", PENDING);
    });
});

SPEC_END
