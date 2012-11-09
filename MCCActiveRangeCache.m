//
//  MCCActiveRangeCache.m
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

- (void)dealloc {
  self.createBlock = nil;
  [super dealloc];
}

- (void)setRecycleBlock:(NSString *(^)(id, NSUInteger))callback {
  __block typeof(self) __self = self;
  
  [super setRecycleBlock:^NSString*(id object, NSUInteger index){
    NSString *identifier = nil;
    if (!NSLocationInRange(index, __self._activeRange)) {
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
  if (_activeRange.length == 0) return;
  self.norecycle = TRUE;
  for (NSUInteger index = _activeRange.location; index < NSMaxRange(_activeRange); index++) {
    if (![self objectAtIndex:index]) {
      //      NSLog(@"Load page at index: %d", index);
      id page = createBlock(index);
      NSAssert(page != nil, @"nil page for index %d", index);
      [self setObject:page atIndex:index];
    }
  }
  [self recycle];
}

- (NSRange)activeRange { return _activeRange; }

@end
