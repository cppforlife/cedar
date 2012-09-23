#import "CDRSpec.h"
#import "CDRExample.h"
#import "CDRExampleGroup.h"
#import "CDRSpecFailure.h"
#import "SpecHelper.h"
#import "CDRSymbolicator.h"

CDRSpec *currentSpec;

void beforeEach(CDRSpecBlock block) {
    [currentSpec.currentGroup addBefore:block];
}

void afterEach(CDRSpecBlock block) {
    [currentSpec.currentGroup addAfter:block];
}

CDRExampleGroup * describe(NSString *text, CDRSpecBlock block) {
    CDRExampleGroup *parentGroup = currentSpec.currentGroup;

    CDRExampleGroup *group = [CDRExampleGroup groupWithText:text];
    group.stackAddress = CDRCallerStackAddress();
    [parentGroup add:group];

    if (block) {
        currentSpec.currentGroup = group;
        block();
        currentSpec.currentGroup = parentGroup;
    }
    return group;
}

CDRExampleGroup * context(NSString *text, CDRSpecBlock block) {
    CDRExampleGroup *group = describe(text, block);
    group.stackAddress = CDRCallerStackAddress();
    return group;
}

CDRExample * it(NSString *text, CDRSpecBlock block) {
    CDRExample *example = [CDRExample exampleWithText:text andBlock:block];
    example.stackAddress = CDRCallerStackAddress();
    [currentSpec.currentGroup add:example];
    return example;
}

CDRExampleGroup * xdescribe(NSString *text, CDRSpecBlock block) {
    return describe(text, ^{});
}

CDRExampleGroup * xcontext(NSString *text, CDRSpecBlock block) {
    return xdescribe(text, block);
}

CDRExample * xit(NSString *text, CDRSpecBlock block) {
    return it(text, PENDING);
}

CDRExampleGroup * fdescribe(NSString *text, CDRSpecBlock block) {
    CDRExampleGroup *group = describe(text, block);
    group.focused = YES;
    return group;
}

CDRExampleGroup * fcontext(NSString *text, CDRSpecBlock block) {
    return fdescribe(text, block);
}

CDRExample * fit(NSString *text, CDRSpecBlock block) {
    CDRExample *example = it(text, block);
    example.focused = YES;
    return example;
}

void fail(NSString *reason) {
    [[CDRSpecFailure specFailureWithReason:[NSString stringWithFormat:@"Failure: %@", reason]] raise];
}

@implementation CDRSpec

@synthesize currentGroup = currentGroup_, rootGroup = rootGroup_, fileName = fileName_;

#pragma mark Memory
- (id)init {
    if (self = [super init]) {
        self.rootGroup = [[[CDRExampleGroup alloc] initWithText:[[self class] description] isRoot:YES] autorelease];
        self.rootGroup.parent = [SpecHelper specHelper];
        self.currentGroup = self.rootGroup;
    }
    return self;
}

- (void)dealloc {
    self.rootGroup = nil;
    self.currentGroup = nil;
    self.fileName = nil;
    [super dealloc];
}

- (void)defineBehaviors {
    currentSpec = self;
    [self declareBehaviors];
    currentSpec = nil;
}

- (void)failWithException:(NSException *)exception {
    [[CDRSpecFailure specFailureWithReason:[exception reason]] raise];
}

- (void)markAsFocusedClosestToLineNumber:(NSUInteger)lineNumber {
    NSArray *children = self.allChildren;
    if (children.count == 0) return;

    NSMutableArray *addresses = [NSMutableArray array];
    for (CDRExampleBase *child in children) {
        [addresses addObject:[NSNumber numberWithUnsignedInteger:child.stackAddress]];
    }

    // Use symbolication to find out locations of examples.
    // We cannot turn describe/it/context into macros because:
    //  - making them non-function macros pollutes namespace
    //  - making them function macros causes xcode to highlight
    //    wrong lines of code if there are errors present in the code
    //  - also __LINE__ is unrolled from the outermost block
    //    which causes incorrect values
    CDRSymbolicator *symbolicator =
        [[[CDRSymbolicator alloc] initWithStackAddresses:addresses] autorelease];

    int bestAddressIndex = [children indexOfObject:self.rootGroup];

    // Matches closest example/group located on or below specifed line number
    // (only takes into account start of an example/group)
    for (int i = 0, shortestDistance = -1; i < addresses.count; i++) {
        NSUInteger address = [[addresses objectAtIndex:i] unsignedIntegerValue];
        int distance = lineNumber - [symbolicator lineNumberForStackAddress:address];

        if (distance >= 0 && (distance < shortestDistance || shortestDistance == -1) ) {
            bestAddressIndex = i;
            shortestDistance = distance;
        }
    }
    [[children objectAtIndex:bestAddressIndex] setFocused:YES];
}

- (NSArray *)allChildren {
    NSMutableArray *unseenChildren = [NSMutableArray arrayWithObject:self.rootGroup];
    NSMutableArray *seenChildren = [NSMutableArray array];

    while (unseenChildren.count > 0) {
        CDRExampleBase *child = [unseenChildren lastObject];
        [unseenChildren removeLastObject];

        if (child.hasChildren) {
            [unseenChildren addObjectsFromArray:[(CDRExampleGroup *)child examples]];
        }
        [seenChildren addObject:child];
    }
    return seenChildren;
}
@end
