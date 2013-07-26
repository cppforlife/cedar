#import <Cedar/SpecHelper.h>
#import "SimpleIncrementer.h"

#if !__has_feature(objc_arc)
#error This spec must be compiled with ARC to work properly
#endif

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SHARED_EXAMPLE_GROUPS_BEGIN(CedarDoubleARCSharedExamples)

sharedExamplesFor(@"a Cedar double when used with ARC", ^(NSDictionary *sharedContext) {
    __block __unsafe_unretained id<CedarDouble, SimpleIncrementer> myDouble;

    beforeEach(^{
        myDouble = [sharedContext objectForKey:@"double"];
    });

    context(@"when recording an invocation", ^{
        context(@"with a block on stack", ^{
            it(@"should complete happily", ^{
                myDouble stub_method("methodWithBlock:").and_do(^(NSInvocation *invocation) {
                    void (^runBlock)();
                    [invocation getArgument:&runBlock atIndex:2];
                });

                int var = 0;
                [myDouble methodWithBlock:^{ if (var) {} }];
            });
        });
    });
});

SHARED_EXAMPLE_GROUPS_END
