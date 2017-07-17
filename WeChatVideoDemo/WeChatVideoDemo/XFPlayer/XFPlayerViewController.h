//
//  XFPlayerViewController.h
//  WeChatVideoDemo
//
//  Created by xf-ling on 2017/6/16.
//  Copyright © 2017年 LXF. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^SettingButtonBlock)();

@interface XFPlayerViewController : UIViewController

@property (copy, nonatomic) SettingButtonBlock settionButtonBlock;

@property (strong, nonatomic) NSString *thumbImageUrl;                       //视频缩略图
@property (strong, nonatomic) NSURL *videoUrl;                               //视频的url

+ (instancetype)defaultPlayerViewControllerWithVideoUrl:(NSURL *)videoUrl;

@end
