#import "CDRSymbolicator.h"
#import <libunwind.h>
#import <regex.h>

NSUInteger CDRCallerStackAddress() {
#if __arm__ // libunwind functions are not available
    return 0;
#else
    unw_context_t uc;
    if (unw_getcontext(&uc) != 0) return 0;

    unw_cursor_t cursor;
    if (unw_init_local(&cursor, &uc) != 0) return 0;

    NSUInteger stackAddress = 0;
    int depth = 2; // caller of caller of CDRCallerStackAddress

    while (unw_step(&cursor) > 0 && depth-- > 0) {
        unw_word_t ip;
        if (unw_get_reg(&cursor, UNW_REG_IP, &ip) != 0) return 0;
        stackAddress = (NSUInteger)(ip - 4);
    }
    return stackAddress;
#endif
}

@interface CDRSymbolicator ()
@property (nonatomic, retain) NSArray *addresses;
@property (nonatomic, retain) NSMutableArray *fileNames, *lineNumbers;
@end

@interface CDRSymbolicator (Stubs)
- (void)setLaunchPath:(NSString *)path;
- (void)setArguments:(NSArray *)arguments;
- (void)setEnvironment:(NSDictionary *)dict;

- (void)setStandardOutput:(NSPipe *)pipe;
- (void)launch;
@end

@implementation CDRSymbolicator
@synthesize
    addresses = addresses_,
    fileNames = fileNames_,
    lineNumbers = lineNumbers_;

- (id)initWithStackAddresses:(NSArray *)addresses {
    if (self = [super init]) {
        self.addresses = [self validAddresses:addresses];
        [self symbolicate];
    }
    return self;
}

- (void)dealloc {
    self.addresses = nil;
    self.fileNames = nil;
    self.lineNumbers = nil;
    [super dealloc];
}

- (NSString *)fileNameForStackAddress:(NSUInteger)address {
    [self symbolicate];
    NSUInteger index = [self.addresses indexOfObject:[NSNumber numberWithUnsignedInteger:address]];
    return [self.fileNames objectAtIndex:index];
}

- (NSUInteger)lineNumberForStackAddress:(NSUInteger)address {
    [self symbolicate];
    NSUInteger index = [self.addresses indexOfObject:[NSNumber numberWithUnsignedInteger:address]];
    if (index != NSNotFound) {
        return [[self.lineNumbers objectAtIndex:index] unsignedIntegerValue];
    }
    return 0;
}

- (void)symbolicate {
    if (!self.fileNames)
        [self parseAtosOutput:[self.class atosForAddresses:self.addresses]];
}

- (void)parseAtosOutput:(NSString *)atosOutput {
    NSArray *lines = [atosOutput componentsSeparatedByString:@"\n"];
    self.fileNames = [NSMutableArray array];
    self.lineNumbers = [NSMutableArray array];

    for (NSString *line in lines) {
        NSString *fileName = @"";
        NSNumber *lineNumber = [NSNumber numberWithInt:0];
        [self.class parseAtosLine:line fileName:&fileName lineNumber:&lineNumber];
        [self.fileNames addObject:fileName];
        [self.lineNumbers addObject:lineNumber];
    }
}

#pragma mark - Address filtering

- (NSArray *)validAddresses:(NSArray *)addresses {
    NSMutableArray *validAddresses = [NSMutableArray array];
    for (NSNumber *address in addresses) {
        if (address.unsignedIntegerValue > 0)
            [validAddresses addObject:address];
    }
    return validAddresses;
}

#pragma mark - Atos parsing

+ (void)parseAtosLine:(NSString *)line fileName:(NSString **)fileName lineNumber:(NSNumber **)lineNumber {
    static const char *regexPattern = "^.+\\((.+):([[:digit:]]+)\\)$"; // __block_global_1 (in Specs) (SpecSpec2.m:12)
    const char *buf = [line UTF8String];

    regex_t rx;
    regmatch_t *matches;

    regcomp(&rx, regexPattern, REG_EXTENDED);
    matches = (regmatch_t *)malloc((rx.re_nsub+1) * sizeof(regmatch_t));

    if (regexec(&rx, buf, rx.re_nsub+1, matches, 0) == 0) {
        *fileName = [[[NSString alloc] initWithBytes:(buf + matches[1].rm_so)
                                              length:(NSInteger)(matches[1].rm_eo - matches[1].rm_so)
                                            encoding:NSUTF8StringEncoding] autorelease];

        NSString *lineNumberStr =
            [[[NSString alloc] initWithBytes:(buf + matches[2].rm_so)
                                      length:(NSInteger)(matches[2].rm_eo - matches[2].rm_so)
                                    encoding:NSUTF8StringEncoding] autorelease];

        *lineNumber = [NSNumber numberWithInteger:lineNumberStr.integerValue];
    }
    free(matches);
    regfree(&rx);
}

+ (NSString *)atosForAddresses:(NSArray *)addresses {
    NSString *path = [[NSBundle mainBundle] executablePath];
    NSMutableArray *arguments = [NSMutableArray arrayWithObjects:@"-o", path, nil];

    for (NSNumber *address in addresses) {
        [arguments addObject:[NSString stringWithFormat:@"%lx", (long)address.unsignedIntegerValue]];
    }
    return [self shellOutWithCommand:@"/usr/bin/atos" arguments:arguments];
}

+ (NSString *)shellOutWithCommand:(NSString *)command arguments:(NSArray *)arguments {
    id task = [[NSClassFromString(@"NSTask") alloc] init]; // trick iOS SDK in simulator
    [task setEnvironment:[NSDictionary dictionary]];
    [task setLaunchPath:command];
    [task setArguments:arguments];

    NSPipe *pipe = [NSPipe pipe];
    [task setStandardOutput:pipe];
    [task launch];

    NSData *data = [[pipe fileHandleForReading] readDataToEndOfFile];
    NSString *string = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
    [task release];

    return string;
}
@end
