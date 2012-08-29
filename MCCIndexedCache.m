//
//  MCCIndexedCache.m
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

#import "MCCIndexedCache.h"

@interface MCCIndexedCache ()

@property (retain, nonatomic) NSMutableDictionary *cached;
@property (retain, nonatomic) NSMutableDictionary *recycled;

@end


@implementation MCCIndexedCache
@synthesize recycled, cached;
@synthesize recycleBlock, size, norecycle;


- (id)init {
  if ((self = [super init])) {
    self.cached = [NSMutableDictionary dictionary];
    self.recycled = [NSMutableDictionary dictionary];
    size = 1;
  }
  return self;
}

- (void)dealloc {
  self.recycled = nil;
  self.cached = nil;
  self.recycleBlock = nil;
  [super dealloc];
}

- (void)setObject:(id)object atIndex:(NSUInteger)index {
  [cached setObject:object forKey:[NSString stringWithFormat:@"%u", index]];
  if (!norecycle && recycleBlock) [self recycle];
}

- (id)objectAtIndex:(NSUInteger)index {
  return [cached objectForKey:[NSString stringWithFormat:@"%u", index]];
}

- (id)dequeueReusableObjectWithIdentifier:(NSString *)identifier {
  NSAssert(recycleBlock != nil, @"recycleBlock missing"); // Avoid forgetting to set the recycle block
  
  NSMutableSet *_recycled = [recycled objectForKey:identifier];
  
  if (!_recycled) { return nil; }
  if (_recycled.count == 0) { return nil; }
  
  id obj = [_recycled anyObject];
  [obj retain];
  [_recycled removeObject:obj];
  
  return [obj autorelease];
}

- (void)flush { [cached removeAllObjects]; }

- (void)clean { [recycled removeAllObjects]; }

- (void)recycle {
  NSAssert(recycleBlock != nil, @"recycleBlock missing");
  
  norecycle = FALSE;
  
  __block int _left = [cached count] - size;
  if (_left <= 0) return;
  
  [cached enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
    NSString *identifier = recycleBlock(obj, [key integerValue]);
    if (identifier) {
      [self recycleObject:obj key:key identifier:identifier];
      _left--;
    }
    
    if (_left == 0) *stop = TRUE;
  }];
  
  NSAssert([cached count] <= size, @"after recycle the number of cached object %d should be less or equal to the cache size %d", [cached count], size);
}

- (void)recycleObject:(id)obj key:(id)key identifier:(NSString *)identifier {
  NSMutableSet *_recycled = [recycled objectForKey:identifier];
  if (!_recycled) {
    _recycled = [NSMutableSet setWithCapacity:2];
    [recycled setObject:_recycled forKey:identifier];
  }
  [_recycled addObject:obj];
  [cached removeObjectForKey:key];
}

- (void)enumerateIndexesAndObjectsUsingBlock:(void (^)(NSInteger index, id obj, BOOL *stop))block {
  [cached enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
    block([key integerValue], obj, stop);
  }];
}

- (NSArray *)objectsForKeysPassingTest:(BOOL (^)(id key, id obj, BOOL *stop))block {
  NSSet * keys = [cached keysOfEntriesPassingTest:block];
  return [cached objectsForKeys:[keys allObjects] notFoundMarker:[NSNull null]];
}

@end
