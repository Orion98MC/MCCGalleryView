//
//  MCCActiveRangeCache.h
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

/* 

  MCCActiveRangeCache is a cache that stores objects associated with an index range.
  It delayes the creation of objects to the setting of an active range.
 
  First, you create a cache object and set the createBlock that will be used to create the cached objects.
 
    MCCActiveRangeCache *cache = [[MCCActiveRangeCache alloc]init];
    cache.createBlock = ^id(NSUInteger index) {
      return [NSString stringWithFormat:"%u", index];
    };
  
  Then, you set the activeRange and the cache will trigger the building of the missing objects in
  that active range.
 
    cache.activeRange = NSMakeRange(0, 2);
 
  At this point the cached content would look like: @[ @"0", @"1" ]
 

  Since MCCActiveRangeCache is a MCCIndexedCache which provides a recycling mecanism, you
  may enable the recycling by providing a recycleBlock and thus use the dequeueReusableObjectWithIdentifier method
  to retrieve recycled objects in your createBlock.
 
    cache.createBlock = ^id(NSUInteger index) {
      id obj = [cache dequeueReusableObjectWithIdentifier:@"identifier"];
      if (!obj) {
        obj = ...
      }
      return obj;
    };
 
    cache.recycleBlock = ^NSString*(id object, NSUInteger index) {
      // release memory in object
      return @"identifier";
    };
 
*/

#import "MCCIndexedCache.h"

@interface MCCActiveRangeCache : MCCIndexedCache

@property (copy, nonatomic) id(^createBlock)(NSUInteger index);

- (void)setActiveRange:(NSRange)range;
- (NSRange)activeRange;

@end
