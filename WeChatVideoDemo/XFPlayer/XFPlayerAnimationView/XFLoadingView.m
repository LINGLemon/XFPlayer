//
//  XFLoadingViewXFLoadingHUD.m
//  XFLoadingViewExample
//
//  Created by LXF on 2017/4/6.
//  Copyright © 2017年 LXF. All rights reserved.
//

#import "XFLoadingView.h"

#define LineWidth 4.0f
#define LoadingViewDiameter 60
#define BlueColor [UIColor colorWithRed:16/255.0 green:142/255.0 blue:233/255.0 alpha:1]

@implementation XFLoadingView
{
    CADisplayLink *_link;
    CAShapeLayer *_animationLayer;
    
    CGFloat _startAngle;
    CGFloat _endAngle;
    CGFloat _progress;
}

+ (XFLoadingView *)showIn:(UIView*)view
{
    [self hideIn:view];
    XFLoadingView *loadingView = [[XFLoadingView alloc] init];
    loadingView.frame = CGRectMake((view.bounds.size.width / 2), (view.bounds.size.height / 2), LoadingViewDiameter, LoadingViewDiameter);
    [loadingView start];
    [view addSubview:loadingView];
    return loadingView;
}

+ (XFLoadingView *)hideIn:(UIView *)view
{
    XFLoadingView *loadingView = nil;
    for (XFLoadingView *subView in view.subviews)
    {
        if ([subView isKindOfClass:[XFLoadingView class]])
        {
            [subView hide];
            [subView removeFromSuperview];
            loadingView = subView;
        }
    }
    return loadingView;
}

- (void)start
{
    _link.paused = false;
}

- (void)hide
{
    _link.paused = true;
    _progress = 0;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        [self buildUI];
    }
    return self;
}

- (void)buildUI
{
    _animationLayer = [CAShapeLayer layer];
    _animationLayer.bounds = CGRectMake(0, 0, LoadingViewDiameter, LoadingViewDiameter);
    _animationLayer.position = CGPointMake(self.bounds.size.width/2.0f, self.bounds.size.height/2.0);
    _animationLayer.fillColor = [UIColor clearColor].CGColor;
    _animationLayer.strokeColor = BlueColor.CGColor;
    _animationLayer.lineWidth = LineWidth;
    _animationLayer.lineCap = kCALineCapRound;
    [self.layer addSublayer:_animationLayer];

    
    _link = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayLinkAction)];
    [_link addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    _link.paused = true;

}

- (void)displayLinkAction
{
    _progress += [self speed];
    if (_progress >= 1)
    {
        _progress = 0;
    }
    [self updateAnimationLayer];
}

- (void)updateAnimationLayer
{
    _startAngle = -M_PI_2;
    _endAngle = -M_PI_2 +_progress * M_PI * 2;
    if (_endAngle > M_PI)
    {
        CGFloat progress1 = 1 - (1 - _progress)/0.25;
        _startAngle = -M_PI_2 + progress1 * M_PI * 2;
    }
    CGFloat radius = _animationLayer.bounds.size.width/2.0f - LineWidth/2.0f;
    CGFloat centerX = _animationLayer.bounds.size.width/2.0f;
    CGFloat centerY = _animationLayer.bounds.size.height/2.0f;
    UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:CGPointMake(centerX, centerY) radius:radius startAngle:_startAngle endAngle:_endAngle clockwise:true];
    path.lineCapStyle = kCGLineCapRound;
    
    _animationLayer.path = path.CGPath;
}

- (CGFloat)speed
{
    if (_endAngle > M_PI)
    {
        return 0.3/60.0f;
    }
    return 2/60.0f;
}

@end
