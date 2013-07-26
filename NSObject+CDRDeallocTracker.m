#import "NSObject+CDRDeallocTracker.h"
#import "NSObject+CDRChainSelector.h"
#import <objc/runtime.h>

@interface NSObject (CDRDeallocTrackerTypes)
- (void)withoutCDRDeallocTracker_dealloc;
@end

@implementation NSObject (CDRDeallocTracker)

static int _cdr_deallocTrackerStarted = NO;
static int _cdr_deallocTrackerFound = 0;

+ (void)cdr_startDeallocTracker {
    _cdr_deallocTrackerStarted = YES;
    [NSObject cdr_chainSelector:@selector(dealloc) inClass:[NSObject class] prefix:@"CDRDeallocTracker"];
}

+ (int)cdr_deallocTrackerFound {
    if (_cdr_deallocTrackerStarted == -1) {
        @throw @"Dealloc tracker must be started";
    }
    return _cdr_deallocTrackerFound;
}

- (void)withCDRDeallocTracker_dealloc {
    const char *name  = class_getName([self class]);

    // Reporters are most likely created in outermost AR pool
    // e.g. CDRDefaultReporter
    BOOL isReporter = strstr(name, "Reporter") != NULL;

    // Actual test objects are released since reporters are released
    // e.g. CDRExampleBase, CDRExample
    BOOL isExample = strstr(name, "CDRExample") != NULL;

    // Same as actual test objects
    // e.g. CDRSymbolicatorSpec
    BOOL isSpec = strstr(name, "Spec") != NULL;

    // No CDR/Cedar... object should be released at this point
    // unless they are in one of the above categories
    BOOL isCDRClass   = strncmp("CDR", name, 3)    == 0;
    BOOL isCedarClass = strncmp("Cedar", name, 5)  == 0;

    if (!isReporter && !isExample && !isSpec && (isCDRClass || isCedarClass)) {
        _cdr_deallocTrackerFound++;
        printf("\nCalled -dealloc for %s (%p).\nMost likely one of the test variables "
               "is not properly declared/released (e.g. missing __unsafe_unretained).\n",
               name, self);
    }

    [self withoutCDRDeallocTracker_dealloc];
}
@end
