#import <Foundation/Foundation.h>

@interface NSObject (CDRDeallocTracker)
+ (void)cdr_startDeallocTracker;
+ (int)cdr_deallocTrackerFound;
@end
