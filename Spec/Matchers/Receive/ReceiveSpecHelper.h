#import "CDRExampleBase.h"

void expectReceivePasses(CDRSpecBlock block);
void expectReceiveFails(NSString *containedFailureReason, CDRSpecBlock block);

@interface MyObj : NSObject
- (void)callWithoutArgs;
- (void)callWithArg:(id)arg;
- (void)callWithArg2:(id)arg;
- (void)callWithArg:(id)arg arg:(id)arg2;
- (void)callWithArg2:(id)arg arg:(id)arg2;
@end
