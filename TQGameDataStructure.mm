//
//  TQGameDataStructure.mm
//  TumeriQ
//
//  Created by Muhammad Lukman Nasaruddin on 6/15/11.
//  Copyright 2011 Nusantara Software. All rights reserved.
//

#import "TQGameDataStructure.h"

@implementation TQStackQueue
@synthesize array = array_;

- (id)init {
    self = [super init];
    if (self) {
        array_ = [[NSMutableArray alloc] init];
        lock_ = [[NSLock alloc] init];
    }
    return self;
}

- (void)dealloc {
    [objectRemover_ release];
    [array_ release];
    [lock_ release];
    [super dealloc];
}

- (id)initWithArray:(NSArray *)array {
    self = [self init];
    if (self) {
        [array_ addObjectsFromArray:array];
    }
    return self;
}

- (id)first {
    return [array_ count] > 0 ? [array_ objectAtIndex:0] : nil;
}

- (id)last {
    return [array_ lastObject];
}

- (void)push:(id)item {
    [self enqueue:item];
}

- (id)pop {
    [lock_ lock];
    id r = [array_ lastObject];
    [array_ removeLastObject];
    [lock_ unlock];
    return r;
}

- (void)enqueue:(id)item {
    [lock_ lock];
    [array_ insertObject:item atIndex:[self count]];
    [lock_ unlock];
}

- (id)dequeue {
    [lock_ lock];
    id anItem = nil;
    if ([array_ count] > 0) {
        anItem = [array_ objectAtIndex:0];
        [array_ removeObjectAtIndex:0];
    }
    [lock_ unlock];
    return anItem;
}

- (NSUInteger)count {
    return [array_ count];
}

- (void)insert:(id)item at:(uint)pos {
    [lock_ lock];
    [array_ insertObject:item atIndex:pos];
    [lock_ unlock];
}

- (void)remove:(id)item {
    [lock_ lock];
    [array_ removeObject:item];
    [lock_ unlock];
}

- (void)removeAll {
    [lock_ lock];
    [array_ removeAllObjects];
    [lock_ unlock];
}

- (void)removeAllObjects {
    [self removeAll];
}

- (TQCollectionObjectRemover *)objectRemover {
    if (!objectRemover_) {
        objectRemover_ = [[TQCollectionObjectRemover alloc] initWithCollection:array_ andRemoveSelector:@selector(removeObject:)];
    }
    return objectRemover_;
}

@end

TQTimeAndLocation TQTimeAndLocationCreate(CGPoint location, float time) {
    TQTimeAndLocation tnl;
    tnl.location = location;
    if (time > 0.0f) {
        tnl.time = time;
    }
    else {
        tnl.time = [[NSDate date] timeIntervalSince1970];
    }
    return tnl;
}

@implementation TQStageAndLevelNumber
@synthesize mode = mode_, stage = stage_, level = level_;
@synthesize max_stage = max_stage_, max_level = max_level_;

- (id)initWithMode:(uint)mode stage:(uint)stage level:(uint)level maxStage:(uint)maxStage maxLevel:(uint)maxLevel {
    if ((self = [super init])) {
        mode_ = mode;
        stage_ = stage;
        level_ = level;
        max_stage_ = MAX(maxStage, stage);
        max_level_ = MAX(maxLevel, level);
    }
    return self;
}

+ (TQStageAndLevelNumber *)stageAndLevelNumberWithMode:(uint)mode stage:(uint)stage level:(uint)level maxStage:(uint)maxStage maxLevel:(uint)maxLevel {
    return [[[TQStageAndLevelNumber alloc] initWithMode:mode stage:stage level:level maxStage:maxStage maxLevel:maxLevel] autorelease];
}

- (id)copyWithZone:(NSZone *)zone {
    return [[TQStageAndLevelNumber allocWithZone:zone] initWithMode:mode_ stage:stage_ level:level_ maxStage:max_stage_ maxLevel:max_level_];
}

- (id)copy {
    return [[TQStageAndLevelNumber alloc] initWithMode:mode_ stage:stage_ level:level_ maxStage:max_stage_ maxLevel:max_level_];
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeInteger:mode_ forKey:@"mode"];
    [aCoder encodeInteger:stage_ forKey:@"stage"];
    [aCoder encodeInteger:level_ forKey:@"level"];
    [aCoder encodeInteger:max_stage_ forKey:@"maxStage"];
    [aCoder encodeInteger:max_level_ forKey:@"maxLevel"];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    return [self initWithMode:[aDecoder decodeIntegerForKey:@"mode"]
                        stage:[aDecoder decodeIntegerForKey:@"stage"] 
                        level:[aDecoder decodeIntegerForKey:@"level"] 
                     maxStage:[aDecoder decodeIntegerForKey:@"maxStage"]
                     maxLevel:[aDecoder decodeIntegerForKey:@"maxLevel"]];
}

- (BOOL)increaseLevel {
    if (level_ >= max_level_) {
        if (stage_ >= max_stage_) {
            return NO;
        }
        stage_++;
        level_ = 0;
    }
    else {
        level_++;
    }
    return YES;
}

- (BOOL)decreaseLevel {
    if (level_ == 0) {
        if (stage_ == 0) {
            return NO;
        }
        stage_--;
        level_ = max_level_;
    }
    else {
        level_--;
    }
    return YES;
}

- (BOOL)increaseStage {
    if (stage_ >= max_stage_) {
        return NO;
    }
    stage_++;
    level_ = 0;
    return YES;
}

- (BOOL)decreaseStage {
    if (stage_ == 0) {
        return NO;
    }
    stage_--;
    level_ = max_level_;
    return YES;
}

- (TQStageAndLevelNumber *)nextLevel {
    TQStageAndLevelNumber *newLevel = [[self copy] autorelease];
    if ([newLevel increaseLevel]) {
        return newLevel;
    }
    else {
        return nil;
    }
}

- (TQStageAndLevelNumber *)nextStage {
    TQStageAndLevelNumber *newLevel = [[self copy] autorelease];
    if ([newLevel increaseStage]) {
        return newLevel;
    }
    else {
        return nil;
    }
}

- (TQStageAndLevelNumber *)previousLevel {
    TQStageAndLevelNumber *newLevel = [[self copy] autorelease];
    if ([newLevel decreaseLevel]) {
        return newLevel;
    }
    else {
        return nil;
    }
}

- (TQStageAndLevelNumber *)previousStage {
    TQStageAndLevelNumber *newLevel = [[self copy] autorelease];
    if ([newLevel decreaseStage]) {
        return newLevel;
    }
    else {
        return nil;
    }
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%02d.%02d.%02d", mode_, stage_, level_];
}

@end

@implementation NSObject (TumeriQ)

- (NSValue *)pointerValue {
    return [NSValue valueWithPointer:self];
}

- (NSString *)pointerString {
    return [NSString stringWithFormat:@"%p", self];
}

- (TQCObject *)performSelector:(SEL)selector withValues:(void *)value, ... {
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:selector]];
    [invocation setSelector:selector];
    [invocation setTarget:self];
    
    va_list args;
    va_start(args, value);
    int index = 2;
    while (value) {
        [invocation setArgument:value atIndex:index];
        value = va_arg(args, void *);
        index++;
    }
    va_end(args);
    
    [invocation invoke];
    
    NSUInteger length = [[invocation methodSignature] methodReturnLength];
    
    // If method is non-void:
    if (length > 0) {
        void *buffer = (void *)malloc(length);
        [invocation getReturnValue:buffer];
        return [TQCObject cObject:buffer];
    }
    
    // If method is void:
    return NULL;
}

@end


@implementation NSMutableDictionary (TumeriQ)

- (void)removeObject:(id)anObject {
    for (id key in [self allKeysForObject:anObject]) {
        [self removeObjectForKey:key];
    }
}

- (void)addObject:(id)anObject intoArrayForKey:(id)aKey {
    NSMutableArray *array = (NSMutableArray *)[self objectForKey:aKey];
    if (!array) {
        array = [NSMutableArray array];
        [self setObject:array forKey:aKey];
    }
    if (!anObject) {
        [array removeAllObjects];
    }
    else {
        [array addObject:anObject];
    }
}

@end

@implementation NSDictionary (TumeriQ)

+ (NSDictionary *)dictionaryWithContentsOfPlistFile:(NSString *)plistFile {
	NSString *plistFullPath = [[NSBundle mainBundle] pathForResource:plistFile ofType:@"plist"];
    return [NSDictionary dictionaryWithContentsOfFile:plistFullPath];
}

- (id)traversePath:(NSString *)path {
    id traversal = self;
    NSArray *pathComponents = [path componentsSeparatedByString:@"/"];
    NSRegularExpression *regex = [NSRegularExpression
                                  regularExpressionWithPattern:@"^\\[(\\d+)\\]$"
                                  options:NSRegularExpressionCaseInsensitive
                                  error:nil];
    for (NSString *pathComponent in pathComponents) {
        NSArray *matches = [regex matchesInString:pathComponent options:0 range:NSMakeRange(0, [pathComponent length])];
        if ([matches count] == 1) {
            NSTextCheckingResult *match = [matches lastObject];
            NSUInteger index = [[pathComponent substringWithRange:[match rangeAtIndex:1]] integerValue];
            traversal = [(NSArray *)traversal objectAtIndex:index];
        }
        else {
            traversal = [(NSDictionary *)traversal objectForKey:pathComponent];
        }
    }
    return traversal;
}

@end

@implementation TQCObject
@synthesize cObject = cObject_;

+ (TQCObject *)cObject:(void *)cObject {
    return [[[self alloc] initWithCObject:cObject] autorelease];
}

- (id)initWithCObject:(void *)cObject {
    self = [self init];
    if (self) {
        cObject_ = cObject;
    }
    return self;
}

- (void)dealloc {
    free(cObject_);
    cObject_ = NULL;
    [super dealloc];
}

@end

@implementation NSString (TumeriQ)

- (NSString *)titlecaseString {
    return [NSString stringWithFormat:@"%@%@", [[self substringToIndex:1] uppercaseString], [self substringFromIndex:1]];
}

@end

@implementation TQCollectionObjectRemover

- (id)initWithCollection:(id<NSObject>)collection andRemoveSelector:(SEL)removeSelector {
    if ((self = [self init])) {
        objects_ = [[NSMutableSet alloc] init];
        collection_ = [collection retain];
        removeSelector_ = removeSelector;
    }
    return self;
}

- (void)dealloc {
    [self purge];
    [objects_ release];
    [collection_ release];
    [super dealloc];
}

+ (TQCollectionObjectRemover *)removerWithCollection:(id<NSObject>)collection andRemoveSelector:(SEL)removeSelector {
    return [[[self alloc] initWithCollection:collection andRemoveSelector:removeSelector] autorelease];
}

- (void)addObject:(id)object {
    [objects_ addObject:object];
}

- (void)purge {
    for (id object in objects_) {
        [collection_ performSelector:removeSelector_ withObject:object];
    }
    [objects_ removeAllObjects];
}

@end
