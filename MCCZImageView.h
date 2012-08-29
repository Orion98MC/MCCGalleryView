//
//  MCCZImageView.h
//  The simplest zoomable image view... ever ;)
//
//  Created by Thierry Passeron on 18/03/12.
//  Copyright (c) 2012 Monte-Carlo Computing. All rights reserved.
//

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

@property (assign, nonatomic) UIViewContentMode contentMode; // Sets the starting zoom scale, default is UIViewContentModeScaleAspectFit

- (void)setImage:(UIImage *)image;

@end
