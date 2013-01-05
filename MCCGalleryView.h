//
//  MCCGalleryView.h
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

#import <UIKit/UIKit.h>

/*
 
  MCCGalleryView
  ==============
  
  MCCGalleryView doesn't rely on the delegation paradigm. 
  Basically, you just need to set 2 callback blocks, the number of pages and you are good to go.
 
  Moreover, MCCGalleryView doesn't enforce you to create pages of a particular class
  with mandatory properties like the page index or anything... 
  The pages only need to be of UIView kind.
 
  MCCGalleryView allows you to register for some events using callbacks:
    * onScrollViewDidScroll
    * onVisibleRangeChanged
    * onSingleTap
    * onDoubleTap
  
  MCCGalleryView uses MCCActiveRangeCache as backend.
  For more details check the MCCActiveRangeCache documentation.
 
 
  MCC stands for Monte-Carlo Computing, and is a good prefix to avoid naming collision.
 
 
 Example usage in a view controller:
 -----------------------------------
 
 - (void)viewDidLoad {
   [super viewDidLoad];
 
   static NSString *identifier = @"MyPagesCache"; // a reuse identifier
   
   __block MCCGalleryView *gv = [[[MCCGalleryView alloc]initWithFrame:self.view.bounds]autorelease];
 
   gv.pagesCount = 10;
   
   gv.pageBlock = ^UIView *(NSUInteger pageIndex) {
     UIView *page = [gv dequeueReusablePageWithIdentifier:identifier];
   
     if (!page) {
       UILabel *label = [[UILabel alloc]initWithFrame:CGRectZero];
       label.backgroundColor = [UIColor blueColor];
       label.textColor = [UIColor whiteColor];
       label.textAlignment = UITextAlignmentCenter;
       label.font = [UIFont boldSystemFontOfSize:18.0];
 
       page = label;
     }
   
     ((UILabel*)page).text = [NSString stringWithFormat:@"Page: %u", pageIndex];
    
     return page;
   };
   
   gv.recycleBlock = ^NSString *(UIView *page) {
     ((UILabel*)page).text = nil; // release memory
     return identifier;
   };
   
   // Let's load the pages.
   [gv loadPages];
   
   [self.view addSubview:gv];
 }
 
 */

@interface MCCGalleryView : UIScrollView <UIScrollViewDelegate>

/* Visual properties */
@property (assign, nonatomic) NSUInteger pageWidth;                 /* width of each page in pixels, default is the bounds width - horizontal padding */
@property (assign, nonatomic) NSUInteger horizontalPadding;         /* total padding in pixels, each side will have half the value of this padding */
@property (assign, nonatomic) NSUInteger pagesCount;                /* number of pages in the view */

/* Events */
@property (copy, nonatomic) void(^onVisibleRangeChanged)(NSRange);  /* called when the visible pages range changed */
@property (copy, nonatomic) void(^onScrollViewDidScroll)(void);     /* called when the scrollview did scroll */
@property (copy, nonatomic) void(^onSingleTap)(void);               /* called when a single tap is detected */
@property (copy, nonatomic) void(^onDoubleTap)(void);               /* called when a double tap is detected */

/* callback setters */
- (void)setPageBlock:(UIView *(^)(NSUInteger pageIndex))pageBlock;  /* A block called when a page is needed,
                                                                       it must return a UIView * page,
                                                                       obviously this block should either create a new page or reuse one
                                                                       as provided by -[MCCGalleryView dequeueReusablePageWithIdentifier:] */
- (void)setRecycleBlock:(NSString *(^)(UIView *page))recycleBlock;  /* A block called when a page is about to be recycled,
                                                                       it must return a NSString * reuse identifier for the page passed as parameter,
                                                                       such that you get the opportunity to release unnecessary retained data for this page */

/* Tool methods */
- (NSRange)pagesRangeForFrame:(CGRect)frame;
- (NSRange)visiblePagesRange;
- (void)enumerateCachedIndexesAndPagesUsingBlock:(void (^)(NSInteger index, UIView *page, BOOL *stop))block;
- (NSInteger)innerWidth;
- (NSInteger)outerWidth;

/* Caching methods */
- (void)loadPages;
- (UIView *)dequeueReusablePageWithIdentifier:(NSString *)identifier;
- (void)setHalfPreload:(NSUInteger)amount;

- (void)reload;
@end
