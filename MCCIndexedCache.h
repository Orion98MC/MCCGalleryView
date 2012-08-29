//
//  MCCIndexedCache.h
//
//  Created by Thierry Passeron on 18/08/12.
//  Copyright (c) 2012 Monte-Carlo Computing. All rights reserved.
//

/*

  Copyright (c), 2012 Thierry Passeron

  The MIT License

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to
  deal in the Software without restriction, including without limitation the
  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
  sell copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in
  all copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
  IN THE SOFTWARE.

*/

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
