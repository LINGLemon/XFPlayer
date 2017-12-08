//
//  XFLoadingView.h
//  XFLoadingViewExample
//
//  Created by LXF on 2017/4/6.
//  Copyright © 2017年 LXF. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface XFLoadingView : UIView

- (void)start;

- (void)hide;

+ (XFLoadingView *)showIn:(UIView *)view;

+ (XFLoadingView *)hideIn:(UIView *)view;

@end
