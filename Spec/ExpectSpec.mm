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
- (id)lolzWithObj:(id)obj;
- (id)lolzWithInt:(int)lol aChar:(char)c anObj:(id)obj;
@end

@implementation MyObj
- (void)lolz {}
- (id)lolzWithObj:(id)obj {}
- (id)lolzWithInt:(int)lol aChar:(char)c anObj:(id)obj {}
@end

using namespace Cedar::Matchers;

SPEC_BEGIN(ShouldReceive)

fit(@"expect success", ^{
    MyObj *obj = [[[MyObj alloc] init] autorelease];

    obj should receive("lolzWithInt:aChar:anObj:").with(3, '2', obj);
    obj should receive("lolzWithObj:");
    obj should receive(@selector(lolz));

    [obj lolzWithInt:3 aChar:'2' anObj:obj];
    [obj lolzWithObj:obj];
    [obj lolz];
});

SPEC_END
