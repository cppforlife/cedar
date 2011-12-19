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

@interface MyObj : NSObject
- (void)lolz;
- (id)lolzWithInt:(int)lol aChar:(char)c anObj:(id)obj;
@end

@implementation MyObj
- (void)lolz {}
- (id)lolzWithInt:(int)lol aChar:(char)c anObj:(id)obj {}
@end

using namespace Cedar::Matchers;

SPEC_BEGIN(FocusedSpec22)

//fit(@"expect success", ^{
//    MyObj *o = [[[MyObj alloc] init] autorelease];
//    o should receive(@selector(lolz));
//    [o lolz];
//});
//
//fit(@"expect success with arguments", ^{
//    MyObj *o = [[[MyObj alloc] init] autorelease];
//    o should receive(@selector(lolzWithInt:something:));
//    [o lolzWithInt:3 something:nil];
//});

fit(@"expect success with argumentsssss", ^{
    MyObj *o = [[[MyObj alloc] init] autorelease];
    o should receive("lolzWithInt:aChar:anObj:").with_args(3, '2', o);
//    o should receive("lolz");
    [o lolzWithInt:3 aChar:'2' anObj:o];
//    [o lolz];
});

//fit(@"expect failure", ^{
//    MyObj *o = [[[MyObj alloc] init] autorelease];
//    o should receive(@selector(lolz));
//});
//
//fit(@"expect failure with arguments", ^{
//    MyObj *o = [[[MyObj alloc] init] autorelease];
//    o should receive(@selector(lolzWithInt:something:));
//    [o lolz];
//});

SPEC_END
