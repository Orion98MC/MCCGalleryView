//
//  MCCGalleryView.m
//  The simplest gallery view... ever ;)
//
//  Created by Thierry Passeron on 18/03/12.
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

#import "MCCGalleryView.h"
#import "MCCActiveRangeCache.h"

@interface MCCGalleryView ()
@property (retain, nonatomic) MCCActiveRangeCache *_cache;
@property (assign, nonatomic) NSRange _visiblePagesRange;
@property (assign, nonatomic) NSUInteger preload;
@property (assign, nonatomic) NSUInteger halfPreload;
                                                    /*  padding/2             padding/2
                                                         v                         v   */
@property (assign, nonatomic) NSInteger innerWidth; /* |<-->| <- inner width -> |<-->| */
@property (assign, nonatomic) NSInteger outerWidth; /* |<------- outer width ------->| */
@property (assign, nonatomic) BOOL avoidScrollingComputation;

// Single Tap detection
@property (retain, nonatomic) NSTimer *singleTapTimer;
@end

@implementation MCCGalleryView
@synthesize pagesCount, _visiblePagesRange, innerWidth, outerWidth, avoidScrollingComputation, singleTapTimer, preload, halfPreload;
@synthesize pageWidth, horizontalPadding, onVisibleRangeChanged, _cache, onSingleTap, onDoubleTap, onScrollViewDidScroll;

- (id)initWithFrame:(CGRect)frame {
  if ((self = [super initWithFrame:frame])) {
    
    /* Scrollview mandatory settings, do not change these unless you know what you are doing */
    self.autoresizesSubviews = NO; /* Important! we will resize the pages ourselves when frame changes */
    self.delegate = self; /* We handle the scolling, you may register for onScollViewDidScroll event if you need better scrolling awareness */
    
    /* ScrollView default settings. You may need to change them to whatever you prefere after instanciation... */
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.bounces = YES;
    self.showsHorizontalScrollIndicator = NO;
    self.showsVerticalScrollIndicator = NO;
    self.backgroundColor = [UIColor clearColor];
    self.decelerationRate = UIScrollViewDecelerationRateFast;
    self.pagingEnabled = YES;
    
    /* internal setup */
    pageWidth = 0;
    innerWidth = 0;
    outerWidth = 0;
    preload = 0;
    halfPreload = 0;
    pagesCount = 0;
    horizontalPadding = 0;
    avoidScrollingComputation = FALSE;
    _visiblePagesRange = NSMakeRange(0, 0);
    
    /* Gestures setup */
    
    // Single tap
    UITapGestureRecognizer *singleTapGestureRecognizer = [[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(singleTapDetected:)]autorelease];
    singleTapGestureRecognizer.numberOfTapsRequired = 1;
    singleTapGestureRecognizer.numberOfTouchesRequired = 1;
    [self addGestureRecognizer:singleTapGestureRecognizer];
    
    // Double tap
    UITapGestureRecognizer *doubleTapGestureRecognizer = [[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(doubleTapDetected:)]autorelease];
    doubleTapGestureRecognizer.numberOfTapsRequired = 2;
    doubleTapGestureRecognizer.numberOfTouchesRequired = 1;
    [self addGestureRecognizer:doubleTapGestureRecognizer];
    
  }
  return self;
}

- (void)dealloc {
  [singleTapTimer invalidate];
  self.singleTapTimer = nil;
  self.onVisibleRangeChanged = nil;
  self.onScrollViewDidScroll = nil;
  self.onSingleTap = nil;
  self.onDoubleTap = nil;
  self._cache = nil;
  [super dealloc];
}

- (MCCActiveRangeCache *)cache {
  NSAssert(outerWidth != 0, @"oups setup is not done!");
  if (_cache == nil) { /* if we get here then no setup has been done yet */
    if (outerWidth == 0) [self setup];
    self._cache = [[[MCCActiveRangeCache alloc]init]autorelease];
  }
  return _cache;
}

- (void)setup {
  /* Inner and outer page widths */
  innerWidth = pageWidth > 0 ? pageWidth : self.bounds.size.width - horizontalPadding; /* if no pageWidth is given make each page fit in the bounds */
  outerWidth = innerWidth + horizontalPadding;
  
  /* initial visible pages range */
  _visiblePagesRange = pagesRangeForFrame((CGRect){{self.contentOffset.x, 0}, {self.bounds.size.width, 0}}, outerWidth);
  
  /* Preloaded pages */
  NSInteger maxVisiblePages = maxVisiblePagesInFrame(self.bounds, outerWidth);
  preload = MAX(maxVisiblePages + 1 - _visiblePagesRange.length, 2); /* number of pages to also preload */
  halfPreload = floorf((float)preload / 2.0f); /* cache the half */
  
  /* Content size */
  self.contentSize = CGSizeMake(outerWidth * pagesCount, self.bounds.size.height);
}



#pragma mark pages

NS_INLINE void _loadPages(NSRange visiblePagesRange, NSUInteger pagesCount, NSUInteger preload, NSUInteger halfPreload, MCCActiveRangeCache *cache) {
  //  NSLog(@"_loadPages(%@, %u, %u, %u, %p)", NSStringFromRange(visiblePagesRange), pagesCount, preload, halfPreload, cache);
  NSInteger firstIndex = visiblePagesRange.location;
  NSInteger lastIndex = NSMaxRange(visiblePagesRange) - 1;
  firstIndex = MAX(0, firstIndex - (NSInteger)halfPreload);
  lastIndex = MIN(pagesCount - 1, lastIndex + (NSInteger)preload - (NSInteger)halfPreload);
  
  NSRange range = NSMakeRange((NSUInteger)firstIndex, (NSUInteger)(lastIndex - firstIndex + 1));
  //  NSLog(@"Active Range: %@", NSStringFromRange(range));
  [cache setActiveRange:range];
}

- (void)loadPages { /* load the visible pages and the preloadable pages */
  _loadPages(_visiblePagesRange, pagesCount, preload, halfPreload, [self cache]);
}

- (void)setPagesCount:(NSUInteger)count {
  pagesCount = count;
  [self setup];
}

- (void)setPageWidth:(NSUInteger)width {
  pageWidth = width;
  [self setup];
}

- (void)setHorizontalPadding:(NSUInteger)padding {
  horizontalPadding = padding;
  [self setup]; 
}

- (NSInteger)innerWidth { return innerWidth; }


NS_INLINE NSRange visiblePagesRangeInScrollview(UIScrollView *scrollview, NSInteger pagewidth, NSUInteger pagescount) {
  CGFloat offset = scrollview.contentOffset.x;
  NSUInteger start = floor(fabs(offset) / (CGFloat)pagewidth);
  NSUInteger last = ceil(fabs(offset + pagewidth) / (CGFloat)pagewidth);
  
  NSRange range = NSMakeRange(start, MIN(last - start, pagescount - start));
  return range;
}

- (NSRange)visiblePagesRange {
  return pagesRangeForFrame((CGRect){{self.contentOffset.x, 0.0f}, {self.bounds.size.width, 0.0f}}, outerWidth);
}

NS_INLINE CGRect frameForPageAtIndex(NSUInteger pageindex, NSInteger outerwidth, NSInteger horizontalpadding, NSInteger height) {
  return CGRectMake((CGFloat)(pageindex * outerwidth) + (CGFloat)horizontalpadding / 2.0f, 0.0f,
                    (CGFloat)(outerwidth - horizontalpadding), (CGFloat)height);
}

NS_INLINE NSRange pagesRangeForFrame(CGRect pageframe, NSUInteger outerwidth) {
  CGFloat offset = pageframe.origin.x;
  NSUInteger start = floor(fabs(offset) / (CGFloat)outerwidth);
  NSUInteger last = ceil(fabs(offset + pageframe.size.width) / (CGFloat)outerwidth);
  
  return NSMakeRange(start, last - start);
}

- (NSRange)pagesRangeForFrame:(CGRect)frame {
  return pagesRangeForFrame(frame, outerWidth);
}

NS_INLINE NSUInteger maxVisiblePagesInFrame(CGRect frame, NSUInteger pagesize) {
  NSUInteger max = ceilf(frame.size.width / (CGFloat)pagesize) + 1;
  //  NSLog(@"Max visible pages: %u", max);
  return max;
}

/*
- (NSArray *)cachedPagesAtIndexPassingTest:(BOOL (^)(NSUInteger index, BOOL *stop))block {
  return [_cache objectsForKeysPassingTest:^BOOL(id key, id obj, BOOL *stop) {
    return block((NSUInteger)[key integerValue], stop);
  }];
}
*/

- (void)enumerateCachedIndexesAndPagesUsingBlock:(void (^)(NSInteger index, UIView *page, BOOL *stop))block {
  return [_cache enumerateIndexesAndObjectsUsingBlock:^(NSInteger index, id obj, BOOL *stop) {
    block(index, (UIView *)obj, stop);
  }];
}


#pragma mark Cache methods

- (UIView *)dequeueReusablePageWithIdentifier:(NSString *)identifier {
  return (UIView *)[_cache dequeueReusableObjectWithIdentifier:identifier];
}

- (void)setRecycleBlock:(NSString *(^)(UIView *))recycleBlock {
  [[self cache]setRecycleBlock:^NSString*(id page, NSUInteger index) {
    ((UIView *)page).hidden = TRUE;
    return recycleBlock(page);
  }];
}

- (void)setPageBlock:(UIView *(^)(NSUInteger))pageBlock {
  [[self cache]setCreateBlock:^id(NSUInteger pageIndex) {
    
    // Get the page
    UIView *page = pageBlock(pageIndex);
    
    // Set the target frame
    if (page.superview) {
      [UIView setAnimationsEnabled:FALSE];
      page.hidden = TRUE;
    }
    
    page.frame = frameForPageAtIndex(pageIndex, outerWidth, horizontalPadding, self.bounds.size.height);;
    
    if (page.superview) {
      [UIView setAnimationsEnabled:TRUE];
    } else {
      [self addSubview:page];
    }
    
    // Reveal the page
    page.hidden = FALSE;
          
    return page;
    
  }];
}



#pragma mark UIScrollView delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
  if (pagesCount == 0) return;
  if (avoidScrollingComputation) return;
  
  if (onScrollViewDidScroll) onScrollViewDidScroll();
  
  NSRange range = pagesRangeForFrame((CGRect){{self.contentOffset.x, 0.0f}, {self.bounds.size.width, 0.0f}}, outerWidth);
  
  if ((range.location > _visiblePagesRange.location) || ((range.location == _visiblePagesRange.location) && (range.length > _visiblePagesRange.length))) {
    _visiblePagesRange = range;
    _loadPages(_visiblePagesRange, pagesCount, preload, halfPreload, _cache);
    if (onVisibleRangeChanged) onVisibleRangeChanged(range);
    return;
  }
  
  if ((range.location < _visiblePagesRange.location)) {
    _visiblePagesRange = range;
    _loadPages(_visiblePagesRange, pagesCount, preload, halfPreload, _cache);
    if (onVisibleRangeChanged) onVisibleRangeChanged(range);
    return;
  }
  
  //  NSLog(@"range not considered changed: %@", NSStringFromRange(range));
}



#pragma mark rotation/resizing

- (void)setFrame:(CGRect)newFrame {
  avoidScrollingComputation = TRUE; // We don't want the scrolling computation
  
  // Keep old values for delta computation
  CGFloat _contentWidth = self.contentSize.width;
  CGFloat _contentOffsetX = self.contentOffset.x;
  
  [super setFrame:newFrame];

  if (outerWidth == 0) { // Enough for the moment, no need to do the rest until the setup is complete
    avoidScrollingComputation = FALSE;
    return;
  }
  
  // Re compute things
  [self setup];
    
  // Re position the content offset of the scrollView
  CGFloat maxContentOffsetX = self.contentSize.width - self.bounds.size.width;
  CGFloat deltaWidth = self.contentSize.width / _contentWidth;
  self.contentOffset = (CGPoint){(CGFloat)MIN(_contentOffsetX * deltaWidth, maxContentOffsetX), 0.0f};
  
  // Now fix the visible pages range and load missings
  _visiblePagesRange = pagesRangeForFrame((CGRect){{self.contentOffset.x, 0.0f}, {self.bounds.size.width, 0.0f}}, outerWidth);
  [self loadPages];
  
  // Set the new frame of all cached pages
  [_cache enumerateIndexesAndObjectsUsingBlock:^(NSInteger index, UIView* page, BOOL *stop) {
    page.frame = frameForPageAtIndex(index, outerWidth, horizontalPadding, self.bounds.size.height);
  }];
  
  avoidScrollingComputation = FALSE;
}



#pragma mark Tap events handling

/* 
 
 Rem:

 If you implement gesture recognizers in your page views, you should
 forward the gesture recognizer message to either singleTapDetected: or doubleTapDetected: method in MCCGalleryView
 
 Example in pageView.m:
 
 - (void)myDoubleTapHandler:(UITapGestureRecognizer*)sender {
    ...
 
    if (self.nextResponder && [self.nextResponder respondsToSelector:@selector(doubleTapDetected:)]) {
      [self.nextResponder performSelector:@selector(doubleTapDetected:) withObject:(sender)];
    }
 }
 
*/

- (void)singleTapDetected:(UITapGestureRecognizer *)sender {
  if (sender.state == UIGestureRecognizerStateEnded) {
    if (singleTapTimer) [singleTapTimer invalidate];

    void(^callback)(void) = ^{
      if (self.onSingleTap) self.onSingleTap();
      self.singleTapTimer = nil;
    };
    
    // Set a timer to execute the callback block ;)
    self.singleTapTimer = [NSTimer scheduledTimerWithTimeInterval:0.4 /* We wait a little for an other tap to determine if it was indeed a single tap */
                                                           target:[NSBlockOperation blockOperationWithBlock:callback]
                                                         selector:@selector(main)
                                                         userInfo:nil
                                                          repeats:NO];
  }
}

- (void)doubleTapDetected:(UITapGestureRecognizer *)sender {
  if (sender.state == UIGestureRecognizerStateEnded) {
    
    // In case a single tap detection is ongoing, let's stop it
    if (singleTapTimer) {
      [singleTapTimer invalidate];
      self.singleTapTimer = nil;
    }
    
    if (onDoubleTap) onDoubleTap();
  }
}

@end
