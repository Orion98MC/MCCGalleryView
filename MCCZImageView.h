//
//  MCCZImageView.h
//  The simplest zoomable image view... ever ;)
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

/*

  Usage:
  ======
 
  MCCZImageView *imageView = [[[MCCZImageView alloc]initWithFrame:self.view.bounds]autorelease];
  [imageView setImage:myImage];
 

  Example in a MCCGalleryView:
  ----------------------------
 
  static NSString *identifier = @"identifier"; // a reuse identifier
 
  __block MCCGalleryView *gv = [[[MCCGalleryView alloc]initWithFrame:aFrame]autorelease];
 
  gv.pageBlock = ^id(NSUInteger pageIndex) {
    UIView *page = [gv dequeueReusablePageWithIdentifier:identifier];
    
    if (!page) {
      MCCZImageView *imageView = [[[MCCZImageView alloc]initWithFrame:CGRectZero]autorelease];
      page = (UIView *)imageView;
    }
  
    // Avoid working for a recycled page
    NSNumber *index = [NSNumber numberWithInt:pageIndex];
    [page.layer setValue:index forKey:@"pageIndex"];
 
    // Get the image in a separate thread
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
      if ([page.layer valueForKey:@"pageIndex"] == index) { // Ok this page is living
        UIImage *image = [self imageAtPageIndex:[index intValue]];
 
        forceImageDecompression(image); // For better performances ;)
 
        dispatch_async(dispatch_get_main_queue(), ^{
          if ([page.layer valueForKey:@"pageIndex"] == index)
            [((MCCZImageView*)page)setImage:image];
        });
      }
    });
 
    return page;
  };
 
  gv.recycleBlock = ^NSString *(id page) {
    [((UIView*)page).layer setValue:nil forKey:@"pageIndex"];
    [((MCCZImageView *)page)setImage:nil]; // Release memory
 
    return identifier;
  };

 
*/

#import <UIKit/UIKit.h>

@interface MCCZImageView : UIScrollView <UIScrollViewDelegate>

@property (assign, nonatomic) UIViewContentMode contentMode; // Sets the contentMode of the image, default is UIViewContentModeScaleAspectFit

- (void)setImage:(UIImage *)image;
- (void)setZoomScaleForContentMode:(UIViewContentMode)mode animated:(BOOL)animated;

@end
