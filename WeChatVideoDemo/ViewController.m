//
//  ViewController.m
//  WeChatVideoDemo
//
//  Created by xf-ling on 2017/6/14.
//  Copyright © 2017年 LXF. All rights reserved.
//

#import "ViewController.h"
#import "XFPlayerViewController.h"
#import "XFLoadingView.h"
#import "WLCircleProgressView.h"


@interface ViewController ()

@property (nonatomic, assign) Boolean isDownloading;

@property (nonatomic, strong) WLCircleProgressView *circleProgressView;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _isDownloading = false;
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
}

- (IBAction)playerBtnFunc:(id)sender
{
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"video" withExtension:@"mp4"];
    
    XFPlayerViewController *playerViewController = [XFPlayerViewController defaultPlayerViewControllerWithVideoUrl:url];
    
    [playerViewController setModalTransitionStyle:UIModalTransitionStyleCrossDissolve];
    
    [self presentViewController:playerViewController animated:YES completion:nil];
}

- (IBAction)downloadingBtnFunc:(id)sender
{
    if (_isDownloading)
    {
        _isDownloading = false;
        [XFLoadingView hideIn:self.view];
    }
    else
    {
        _isDownloading = true;
        [XFLoadingView showIn:self.view];
    }
}

- (IBAction)sliderValueChangeFunc:(UISlider *)sender
{
    if (sender.value <= 0)
    {
        self.circleProgressView.progressValue = sender.value;
        
        [WLCircleProgressView hideIn:self.view];
        self.circleProgressView = nil;
    }
    else
    {
        if (self.circleProgressView == nil)
        {
            self.circleProgressView = [WLCircleProgressView showIn:self.view];
        }
        
        self.circleProgressView.progressValue = sender.value;
    }
    
}



@end









