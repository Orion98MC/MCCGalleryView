# Description

MCCGalleryView is a simple gallery ScrollView for iOS.

MCCGalleryView allows you to easily create a Photo app kind of horizontal paging view to show pictures or any other content.


## Features

* Pages are cached and recycled, much like in UITableView.
* No delegation protocol, MCCGalleryView use callback blocks for creation and recycling of pages.
* Very easy to integrate: 2 blocks, the number of pages, you're all set!
* No protocol for pages, they only need to be of UIView kind.
* Register for scrolling event or singleTap etc... using blocks.


## Usage

```objective-c

__block MCCGalleryView *gv = [[[MCCGalleryView alloc]initWithFrame:aFrame]autorelease];
 
gv.pagesCount = numberOfPages;
   
gv.pageBlock = ^UIView *(NSUInteger pageIndex) {
  /* Return a page for pageIndex */    
};
   
gv.recycleBlock = ^NSString *(UIView *page) {
  /* Return a reuse identifier (also release memory) */
};
   
/* Load the pages */
[gv loadPages];

```


## Events

You probably don't need to subclass MCCGalleryView since you can register using block callbacks for events: 

* onScrollViewDidScroll
* onVisibleRangeChanged
* onSingleTap
* onDoubleTap

Example:

```objective-c
gv.onSingleTap = ^{
  [self togglePager];
};

gv.onVisibleRangeChanged = ^(NSRange newRange) {
  [self updatePagerWithIndex:newRange.location];
}
```


## Install

Simply add this repository as a submodule to your project or copy the required files.

MCCGalleryView.{h|m}         The GalleryView main class       [REQUIRED]
MCCActiveRangeCache.{h|m}    Backend cache                    [REQUIRED]
MCCIndexedCache.{h|m}        MCCActiveRangeCache superclass   [REQUIRED]
MCCZImageView.{h|m}          Zoomable Image View              [OPTIONAL]


## MCCZImageView

MCCZImageView is a custom zoomable image view which is a UIScrollView subclass with out of the box features required
to build an image gallery.

## Full example

This is a full example of a gallery of UILabel-s created in the -[UIViewController viewDidLoad] method.
This code creates a gallery in full screen and displays 40 pages of 130 pixels width. If you remove the pageWith statement each page will take the full screen minus the horizontal padding. By default, the gallery has pagingEnabled set to TRUE and decelerationRate to UIScrollViewDecelerationRateFast.


```
- (void)viewDidLoad
{
  [super viewDidLoad];
	
  static NSString *identifier = @"MyPagesCache"; // a reuse identifier  
  __block MCCGalleryView *gv = [[[MCCGalleryView alloc]initWithFrame:self.view.bounds]autorelease];
  
  gv.pagesCount = 40;
  
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
    
    /* Lets display a border on each page layer (requires: #import <QuartzCore/QuartzCore.h>) */
    page.layer.borderWidth = 5.0;
    page.layer.borderColor = pageIndex % 2 == 0 ?[UIColor greenColor].CGColor : [UIColor redColor].CGColor;
    
    /* set the page content */
    ((UILabel *)page).text = [NSString stringWithFormat:@"Page: %u", pageIndex];
        
    return page;
  };
  
  gv.recycleBlock = ^NSString *(UIView *page) {
    ((UILabel*)page).text = nil; // release memory
    return identifier;
  };
  
  /* extra setup [OPTIONAL] */
  gv.horizontalPadding = 20;                                /* default is 0 */
  gv.pageWidth = 130;                                       /* default is bounds.size.width - horizontalPadding */
  gv.pagingEnabled = FALSE;                                 /* default is YES */
  gv.decelerationRate = UIScrollViewDecelerationRateNormal; /* default is UIScrollViewDecelerationRateFast */
  
  /* Load the pages */
  [gv loadPages];
  
  [self.view addSubview:gv];
}

```


## License terms

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
