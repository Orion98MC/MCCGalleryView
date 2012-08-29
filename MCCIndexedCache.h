//
//  MCCIndexedCache.h
//
//  Created by Thierry Passeron on 18/08/12.
//  Copyright (c) 2012 Monte-Carlo Computing. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MCCIndexedCache : NSObject

/* Recycling properties and methods */

@property (copy, nonatomic) NSString*(^recycleBlock)(id object, NSUInteger index); /* set a block for the recycling of cached objects */
@property (assign, nonatomic) NSUInteger size;                                     /* Set the maximum number of cached objects before recycling */
@property (assign, nonatomic) BOOL norecycle;                                      /* momentarily disable the recycling */

- (id)dequeueReusableObjectWithIdentifier:(NSString *)identifier;
- (void)clean;    // Clear the recycled
- (void)recycle;  // force the recycling


/* Getter and setters for cached objects */

- (void)setObject:(id)object atIndex:(NSUInteger)index;
- (id)objectAtIndex:(NSUInteger)index;

- (void)enumerateIndexesAndObjectsUsingBlock:(void (^)(NSInteger index, id obj, BOOL *stop))block;
- (NSArray *)objectsForKeysPassingTest:(BOOL (^)(id key, id obj, BOOL *stop))block;

- (void)flush;    // Clear the cache

@end
