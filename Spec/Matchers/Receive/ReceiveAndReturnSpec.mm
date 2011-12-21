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

SPEC_BEGIN(ReceiveAndReturnSpec)

describe(@"expecting method calls and specifying return values", ^{
    __block MyObj *obj, *obj2;

    beforeEach(^{
        obj = [[[MyObj alloc] init] autorelease];
        obj2 = [[[MyObj alloc] init] autorelease];
    });

    it(@"should return return value", ^{
        [obj returnId] should equal(obj);
        obj should receive("returnId").and_return(@"LOL");
        [obj returnId] should equal(@"LOL");
    });

    it(@"should return return values for respective method calls", ^{
        [obj returnId] should equal(obj);

        obj should receive("returnId").and_return(@"call-1");
        obj should receive("returnId").and_return(@"call-2");

        [obj returnId] should equal(@"call-1");
        [obj returnId] should equal(@"call-2");
    });

    describe(@"return types", ^{
        it(@"should return nil (looks like nil is actually defined as long)", ^{
            [obj returnId] should equal(obj);
            obj should receive("returnId").and_return(nil);
            [obj returnId] should be_nil;
        });

        it(@"should return id-ed object", ^{
            [obj returnId] should equal(obj);
            obj should receive("returnId").and_return(@"LOL");
            [obj returnId] should equal(@"LOL");
        });

        it(@"should return pointer-ed object", ^{
            [obj returnMyObj] should equal(obj);
            obj should receive("returnMyObj").and_return(obj2);
            [obj returnMyObj] should equal(obj2);
        });

        it(@"should return an int", ^{
            [obj returnInt] should equal(-1);
            obj should receive("returnInt").and_return(1);
            [obj returnInt] should equal(1);
        });

        it(@"should return a bool", ^{
            [obj returnBool] should equal(YES);
            obj should receive("returnBool").and_return(NO);
            [obj returnBool] should equal(NO);
        });

        it(@"should return a double", ^{
            [obj returnDouble] should equal(-2.5);
            obj should receive("returnDouble").and_return(10.5);
            [obj returnDouble] should equal(10.5);
        });

        it(@"should return a float", ^{
            [obj returnFloat] should equal(-2.5f);
            obj should receive("returnFloat").and_return(10.5f);
            [obj returnFloat] should equal(10.5f);
        });

        it(@"should return a char", ^{
            [obj returnChar] should equal('a');
            obj should receive("returnChar").and_return('z');
            [obj returnChar] should equal('z');
        });

        it(@"should return Class", PENDING);
        it(@"should return selector", PENDING);
        it(@"should return ...", PENDING);
        it(@"should blow up when trying to set return value on methods that return void", PENDING);
    });
});

SPEC_END
