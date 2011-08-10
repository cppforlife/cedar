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

#import "CDRExample.h"
#import "CDRExampleGroup.h"
#import "CDRSpecFailure.h"

using namespace Cedar::Matchers;

SPEC_BEGIN(CDRExampleSpec)

typedef void (^CDRSharedExampleBlock)(NSDictionary *context);

CDRSharedExampleBlock sharedExampleMethod = [^(NSDictionary *context) {
    __block CDRExample *example;
    __block NSString *exampleText;

    beforeEach(^{
        example = [context valueForKey:@"example"];
        exampleText = [context valueForKey:@"exampleText"];
    });

    describe(@"with no parent", ^{
        beforeEach(^{
            id parent = example.parent;
            expect(parent).to(be_nil());
        });

        it(@"should return just its own text", ^{
            NSString *fullText = example.fullText;
            expect(fullText).to(equal(exampleText));
        });
    });

    describe(@"with a parent", ^{
        __block CDRExampleGroup *group;
        NSString *groupText = @"Parent!";

        beforeEach(^{
            group = [[CDRExampleGroup alloc] initWithText:groupText];
            [group add:example];
            expect(example.parent).to_not(be_nil());
        });

        afterEach(^{
            [group release];
        });

        it(@"should return its parent's text prepended with its own text", ^{
            NSString *fullText = example.fullText;
            expect(fullText).to(equal([NSString stringWithFormat:@"%@ %@", groupText, exampleText]));
        });

        describe(@"when the parent also has a parent", ^{
            __block CDRExampleGroup *rootGroup;
            NSString *rootGroupText = @"Root!";

            beforeEach(^{
                rootGroup = [[CDRExampleGroup alloc] initWithText:rootGroupText];
                [rootGroup add:group];
            });

            afterEach(^{
                [rootGroup release];
            });

            it(@"should include the text from all parents, pre-pended in the appropriate order", ^{
                NSString *fullText = example.fullText;
                expect(fullText).to(equal([NSString stringWithFormat:@"%@ %@ %@", rootGroupText, groupText, exampleText]));
            });
        });
    });

    describe(@"with a root group as a parent", ^{
        __block CDRExampleGroup *rootGroup;

        beforeEach(^{
            rootGroup = [[CDRExampleGroup alloc] initWithText:@"wibble wobble" isRoot:YES];
            [rootGroup add:example];

            expect(example.parent).to_not(be_nil());
            BOOL hasFullText = example.parent.hasFullText;
            expect(hasFullText).to_not(be_truthy());
        });

        it(@"should not include its parent's text", ^{
            expect(example.fullText).to(equal(example.text));
        });
    });
} copy];

describe(@"CDRExample", ^{
    __block CDRExample *example;
    NSString *exampleText = @"Example!";

    beforeEach(^{
        example = [[CDRExample alloc] initWithText:exampleText andBlock:^{}];
    });

    afterEach(^{
        [example release];
    });

    describe(@"hasChildren", ^{
        it(@"should return false", ^{
            BOOL hasChildren = example.hasChildren;
            expect(hasChildren).to_not(be_truthy());
        });
    });

    describe(@"isFocused", ^{
        it(@"should return false by default", ^{
            example.focused = NO;
            BOOL isFocused = example.isFocused;
            expect(isFocused).to_not(be_truthy());
        });

        it(@"should return false when example is not focused", ^{
            example.focused = NO;
            BOOL isFocused = example.isFocused;
            expect(isFocused).to_not(be_truthy());
        });

        it(@"should return true when example is focused", ^{
            example.focused = YES;
            BOOL isFocused = example.isFocused;
            expect(isFocused).to(be_truthy());
        });
    });

    describe(@"hasFocusedExamples", ^{
        it(@"should return false by default", ^{
            example.focused = NO;
            BOOL hasFocusedExamples = example.hasFocusedExamples;
            expect(hasFocusedExamples).to_not(be_truthy());
        });

        it(@"should return false when example is not focused", ^{
            example.focused = NO;
            BOOL hasFocusedExamples = example.hasFocusedExamples;
            expect(hasFocusedExamples).to_not(be_truthy());
        });

        it(@"should return true when example is focused", ^{
            example.focused = YES;
            BOOL hasFocusedExamples = example.hasFocusedExamples;
            expect(hasFocusedExamples).to(be_truthy());
        });
    });

    describe(@"state", ^{
        context(@"for a newly created example", ^{
            it(@"should be CDRExampleStateIncomplete", ^{
                CDRExampleState state = example.state;
                expect(state).to(equal(CDRExampleStateIncomplete));
            });
        });

        context(@"for an example that has run and succeeded", ^{
            beforeEach(^{
                [example runOnlyFocused:NO];
            });

            it(@"should be CDRExampleStatePassed", ^{
                CDRExampleState state = example.state;
                expect(state).to(equal(CDRExampleStatePassed));
            });
        });

        describe(@"for an example that has run and failed", ^{
            beforeEach(^{
                [example release];
                example = [[CDRExample alloc] initWithText:@"I should fail" andBlock:^{ fail(@"fail"); }];
                [example runOnlyFocused:NO];
            });

            it(@"should be CDRExampleStateFailed", ^{
                CDRExampleState state = example.state;
                expect(state).to(equal(CDRExampleStateFailed));
            });
        });

        describe(@"for an example that has run and thrown an NSException", ^{
            beforeEach(^{
                [example release];
                example = [[CDRExample alloc] initWithText:@"I should throw an NSException" andBlock:^{ [[NSException exceptionWithName:@"name" reason:@"reason" userInfo:nil] raise]; }];
                [example runOnlyFocused:NO];
            });

            it(@"should be CDRExceptionStateError", ^{
                CDRExampleState state = example.state;
                expect(state).to(equal(CDRExampleStateError));
            });
        });

        describe(@"for an example that has run and thrown something other than an NSException", ^{
            beforeEach(^{
                [example release];
                example = [[CDRExample alloc] initWithText:@"I should throw some nonsense" andBlock:^{ @throw @"Some nonsense"; }];
                [example runOnlyFocused:NO];
            });

            it(@"should be CDRExceptionStateError", ^{
                CDRExampleState state = example.state;
                expect(state).to(equal(CDRExampleStateError));
            });
        });

        describe(@"for a pending example", ^{
            beforeEach(^{
                [example release];
                example = [[CDRExample alloc] initWithText:@"I should be pending" andBlock:PENDING];
                [example runOnlyFocused:NO];
            });

            it(@"should be CDRExceptionStatePending", ^{
                CDRExampleState state = example.state;
                expect(state).to(equal(CDRExampleStatePending));
            });
        });

        context(@"when running focused specs", ^{
            context(@"for an example that has run and was not focused on", ^{
                beforeEach(^{
                    [example release];
                    example = [[CDRExample alloc] initWithText:@"I should be skipped" andBlock:^{}];
                    [example runOnlyFocused:YES];
                });

                it(@"should be CDRExceptionStateSkipped", ^{
                    CDRExampleState state = example.state;
                    expect(state).to(equal(CDRExampleStateSkipped));
                });
            });

            context(@"for an example that has run and was focused on", ^{
                beforeEach(^{
                    [example release];
                    example = [[CDRExample alloc] initWithText:@"I should not be skipped" andBlock:^{}];
                    example.focused = YES;
                    [example runOnlyFocused:YES];
                });

                it(@"should be CDRExceptionStatePassed", ^{
                    CDRExampleState state = example.state;
                    expect(state).to(equal(CDRExampleStatePassed));
                });
            });
        });

        describe(@"KVO", ^{
            it(@"should report when the state changes", ^{
                id mockObserver = [OCMockObject niceMockForClass:[NSObject class]];
                [[mockObserver expect] observeValueForKeyPath:@"state" ofObject:example change:[OCMArg any] context:NULL];

                [example addObserver:mockObserver forKeyPath:@"state" options:0 context:NULL];
                [example runOnlyFocused:NO];
                [example removeObserver:mockObserver forKeyPath:@"state"];

                [mockObserver verify];
            });
        });
    });

    describe(@"progress", ^{
        describe(@"when the state is incomplete", ^{
            beforeEach(^{
                CDRExampleState state = example.state;
                expect(state).to(equal(CDRExampleStateIncomplete));
            });

            it(@"should return 0", ^{
                float progress = example.progress;
                expect(progress).to(equal(0.0));
            });
        });

        describe(@"when the state is passed", ^{
            beforeEach(^{
                [example runOnlyFocused:NO];
                CDRExampleState state = example.state;
                expect(state).to(equal(CDRExampleStatePassed));
            });

            it(@"should return 1", ^{
                float progress = example.progress;
                expect(progress).to(equal(1.0));
            });
        });
    });

    describe(@"fullText", ^{
        __block NSMutableDictionary *sharedExampleContext = [[NSMutableDictionary alloc] init];

        beforeEach(^{
            [sharedExampleContext setObject:example forKey:@"example"];
            [sharedExampleContext setObject:exampleText forKey:@"exampleText"];
        });

        sharedExampleMethod(sharedExampleContext);
    });

    describe(@"message", ^{
        describe(@"for an incomplete example", ^{
            beforeEach(^{
                CDRExampleState state = example.state;
                expect(state).to(equal(CDRExampleStateIncomplete));
            });

            it(@"should return an empty string", ^{
                NSString *message = example.message;
                expect(message).to(equal(@""));
            });
        });

        describe(@"for a passing example", ^{
            beforeEach(^{
                [example release];
                example = [[CDRExample alloc] initWithText:@"I should pass" andBlock:^{}];
                [example runOnlyFocused:NO];
            });

            it(@"should return an empty string", ^{
                NSString *message = example.message;
                expect(message).to(equal(@""));
            });
        });

        describe(@"for a pending example", ^{
            beforeEach(^{
                [example release];
                example = [[CDRExample alloc] initWithText:@"I should pend" andBlock:nil];
                [example runOnlyFocused:NO];
            });

            it(@"should return an empty string", ^{
                NSString *message = example.message;
                expect(message).to(equal(@""));
            });
        });

        describe(@"for a skipped example", ^{
            beforeEach(^{
                [example release];
                example = [[CDRExample alloc] initWithText:@"I should pend" andBlock:nil];
                example.focused = NO;
                [example runOnlyFocused:YES];
            });

            it(@"should return an empty string", ^{
                NSString *message = example.message;
                expect(message).to(equal(@""));
            });
        });

        describe(@"for a failing example", ^{
            __block NSString *failureMessage = @"I should fail";

            beforeEach(^{
                [example release];
                example = [[CDRExample alloc] initWithText:@"I should fail" andBlock:^{[[CDRSpecFailure specFailureWithReason:failureMessage] raise];}];
                [example runOnlyFocused:NO];
            });

            it(@"should return the failure message", ^{
                NSString *message = example.message;
                expect(message).to(equal(failureMessage));
            });
        });

        describe(@"for an example that throws an NSException", ^{
            __block NSException *exception;

            beforeEach(^{
                exception = [NSException exceptionWithName:@"name" reason:@"reason" userInfo:nil];

                [example release];
                example = [[CDRExample alloc] initWithText:@"I should throw an exception" andBlock:^{ [exception raise]; }];
                [example runOnlyFocused:NO];
            });

            it(@"should return the description of the exception", ^{
                expect(example.message).to(equal(exception.description));
            });
        });

        describe(@"for an example that throws a non-NSException", ^{
            __block NSString *failureMessage = @"wibble wobble";

            beforeEach(^{
                [example release];
                example = [[CDRExample alloc] initWithText:@"I should throw an exception" andBlock:^{ @throw failureMessage; }];
                [example runOnlyFocused:NO];
            });

            it(@"should return the description of whatever was thrown", ^{
                NSString *message = example.message;
                expect(message).to(equal(failureMessage));
            });
        });
    });
});

SPEC_END
