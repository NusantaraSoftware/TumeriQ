//
//  TQGameDataStructure.h
//  TumeriQ
//
//  Created by Muhammad Lukman Nasaruddin on 6/15/11.
//  Copyright 2011 Nusantara Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/** @defgroup datastruct Data Structure
 *  @brief Custom and extension of existing data structures
 *  @{
 */

typedef enum {
    NO_DIRECTION = 0,
    DIRECTION_UP,
    DIRECTION_DOWN,
    DIRECTION_LEFT,
    DIRECTION_RIGHT
} FourDirection;

typedef struct {
    CGPoint location;
    float time;
} TQTimeAndLocation;

TQTimeAndLocation TQTimeAndLocationCreate(CGPoint location, float time);

@interface TQCollectionObjectRemover : NSObject {
    NSMutableSet *objects_;
    id<NSObject> collection_;
    SEL removeSelector_;
}

- (id)initWithCollection:(id<NSObject>)collection andRemoveSelector:(SEL)removeSelector;
+ (TQCollectionObjectRemover *)removerWithCollection:(id<NSObject>)collection andRemoveSelector:(SEL)removeSelector;
- (void)addObject:(id)object;
- (void)purge;
@end

@interface TQStackQueue : NSObject {
    NSMutableArray *array_;
    NSLock *lock_;
    TQCollectionObjectRemover *objectRemover_;
}
@property (nonatomic, readonly) NSArray *array;
@property (nonatomic, readonly) TQCollectionObjectRemover *objectRemover;

/**
 * Init the TQStackQueue using items from array
 *  @param array NSArray that contains items
 */
- (id)initWithArray:(NSArray *)array;

/**
 * Get first item in the stack/queue
 *  @return The first item
 */
- (id)first;

/**
 * Get last item in the stack/queue
 *  @return The last item
 */
- (id)last;

/**
 * Pushes item into the end of the array
 *  @param item The item
 */
- (void)push:(id)item;

/**
 * Pops item from the end of the array
 *  @return The item
 */
- (id)pop;

/**
 * Enqueues item to the end of the array
 *  @param item The item
 */
- (void)enqueue:(id)item;

/**
 * Dequeues item from the front of the array
 *  @return The item
 */
- (id)dequeue;

/**
 * Inserts item at specified position
 *  @param item The item
 *  @param pos The position
 */
- (void)insert:(id)item at:(uint)pos;

/**
 * Removes an item
 *  @param item The item
 */
- (void)remove:(id)item;

/**
 * Removes all items
 */
- (void)removeAll;

/**
 * Alias for TQStackQueue::removeAll
 */
- (void)removeAllObjects;

/**
 * @return The number of items
 */
- (NSUInteger)count;

@end

#pragma mark -

@interface TQStageAndLevelNumber : NSObject <NSCoding, NSCopying> {
    uint mode_, stage_, level_;
    uint max_stage_, max_level_;
}
@property (nonatomic, readonly) uint mode, stage, level;
@property (nonatomic, assign) uint max_stage, max_level;

- (id)initWithMode:(uint)mode stage:(uint)stage level:(uint)level maxStage:(uint)maxStage maxLevel:(uint)maxLevel;
+ (TQStageAndLevelNumber *)stageAndLevelNumberWithMode:(uint)mode stage:(uint)stage level:(uint)level maxStage:(uint)maxStage maxLevel:(uint)maxLevel;

/**
 * Increase level number
 *  @return TRUE if level number has been increased, FALSE if current level is the last level
 */
- (BOOL)increaseLevel;

/**
 * Decrease level number
 *  @return TRUE if level number has been decreased, FALSE if current level is the first level
 */
- (BOOL)decreaseLevel;

/**
 * Increase stage number and set level number to 0
 *  @return TRUE if stage number has been increased, FALSE if current stage is the last stage
 */
- (BOOL)increaseStage;

/**
 * Decrease stage number and set level number to 0
 *  @return TRUE if stage number has been decreased, FALSE if current stage is the first stage
 */
- (BOOL)decreaseStage;

/**
 *  @return New instance of TQStageAndLevelNumber for the next level number, nil if current level is the last level
 */
- (TQStageAndLevelNumber *)nextLevel;

/**
 *  @return New instance of TQStageAndLevelNumber for the next stage number, nil if current stage is the last stage
 */
- (TQStageAndLevelNumber *)nextStage;

/**
 *  @return New instance of TQStageAndLevelNumber for the previous level number, nil if current level is the first level
 */
- (TQStageAndLevelNumber *)previousLevel;

/**
 *  @return New instance of TQStageAndLevelNumber for the previous stage number, nil if current stage is the first stage
 */
- (TQStageAndLevelNumber *)previousStage;

@end

/**
 *  An Objective-C class that holds a C object.
 *   The main purpose of this class is so that the C object is freed from memory
 *   when this class is dealloc'ed, therefore the C object that this class holds
 *   should never be stored in other variables. All accesses must be via this
 *   Objective C object
 */
@interface TQCObject : NSObject {
    void *cObject_;
}
@property (nonatomic, readonly) void *cObject;

+ (TQCObject *)cObject:(void *)cObject;
- (id)initWithCObject:(void *)cObject;

@end

@interface NSObject (TumeriQ)

/** 
 * @return NSValue object that holds the pointer to this object
 */
- (NSValue *)pointerValue;

/**
 * @return NSString representation of the pointer to this object
 */
- (NSString *)pointerString;

/**
 * Performs a selector using non-object values
 *  @param selector The selector to perform
 *  @param value... The comma-delimited-nil-terminated values to pass to the selector
 *  @return The return value of the selector, NULL of void return type
 */
- (TQCObject *)performSelector:(SEL)selector withValues:(void *)value, ... NS_REQUIRES_NIL_TERMINATION;

@end

@interface NSMutableDictionary (TumeriQ)

/**
 * Remove an object
 *  @param anObject The object to remove
 */
- (void)removeObject:(id)anObject;

/**
 * Add an object into array for the given key
 *  @param anObject The object to add
 *  @param aKey The key
 */
- (void)addObject:(id)anObject intoArrayForKey:(id)aKey;

@end

@interface NSDictionary (TumeriQ)

/**
 * Load an NSDictionary from plist file
 *  @param plistFile The plist filename (without the .plist extension)
 *  @return The loaded NSDictionary
 */
+ (NSDictionary *)dictionaryWithContentsOfPlistFile:(NSString *)plistFile;

- (id)traversePath:(NSString *)path;

@end

@interface NSString (TumeriQ);

/**
 * @return Title-cased string
 */
- (NSString *)titlecaseString;

@end

/** @} */ // end of datastruct
