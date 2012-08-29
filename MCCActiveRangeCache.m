//
//  MCCActiveRangeCache.m
//
//  Created by Thierry Passeron on 18/08/12.
//  Copyright (c) 2012 Monte-Carlo Computing. All rights reserved.
//

#import "MCCActiveRangeCache.h"

@interface MCCActiveRangeCache ()
@property (assign, nonatomic) NSRange _activeRange;
@end

@implementation MCCActiveRangeCache
@synthesize _activeRange;
@synthesize createBlock;

- (id)init {
  if ((self = [super init])) { _activeRange = NSMakeRange(0, 0); }
  return self;
}

- (void)setRecycleBlock:(NSString *(^)(id, NSUInteger))callback {
  [super setRecycleBlock:^NSString*(id object, NSUInteger index){
    NSString *identifier = nil;
    if (!NSLocationInRange(index, _activeRange)) {
      identifier = callback(object, index);
    }
    return identifier;
  }];
}

- (void)setActiveRange:(NSRange)range {
  if (NSEqualRanges(range, _activeRange)) return;
  
  _activeRange = range;
  self.size = range.length;
  
  [self loadPages];
}

- (void)loadPages {
  NSAssert(_activeRange.length != 0, @"Active range with null length");
  self.norecycle = TRUE;
  for (NSUInteger index = _activeRange.location; index < NSMaxRange(_activeRange); index++) {
    if (![self objectAtIndex:index]) {
      id page = createBlock(index);
      NSAssert(page != nil, @"nil page for index %d", index);
      [self setObject:page atIndex:index];
    }
  }
  [self recycle];
}

- (NSRange)activeRange { return _activeRange; }

@end
