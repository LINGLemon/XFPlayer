//
//  XFPlayerViewController.m
//  WeChatVideoDemo
//
//  Created by xf-ling on 2017/6/16.
//  Copyright © 2017年 LXF. All rights reserved.
//

#import "XFPlayerViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>

#define kScreenWidth [UIScreen mainScreen].bounds.size.width
#define kScreenHeight [UIScreen mainScreen].bounds.size.height

@interface XFPlayerViewController ()

@property (strong, nonatomic) AVPlayer *player;
@property (strong, nonatomic) AVPlayerItem *playerItem;

@property (weak, nonatomic) IBOutlet UIImageView *thumbImageView;                 //预览图，暂时屏蔽

@property (weak, nonatomic) IBOutlet UIButton *closeButton;
@property (weak, nonatomic) IBOutlet UIButton *settingButton;

@property (weak, nonatomic) IBOutlet UIButton *startPlayButton;

@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (weak, nonatomic) IBOutlet UISlider *videoProgressSlider;
@property (weak, nonatomic) IBOutlet UILabel *videoCurrentTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *videoTotalTimeLabel;

@property (assign, nonatomic) CGFloat progressBeginToMove;
@property (assign, nonatomic) CGFloat totalVideoDuration;                         //视频总时间
@property (strong, nonatomic) UISlider *volumeSlider;                             //音量slider
@property (assign, nonatomic) float systemVolume;                                 //系统音量值
@property (assign, nonatomic) float systemBrightness;                             //系统亮度
@property (assign, nonatomic) CGPoint startPoint;                                 //起始位置坐标
@property (assign, nonatomic) BOOL isTouchBeganLeft;                              //标识位置方向是左边
@property (strong, nonatomic) NSString *slideDirection;                           //滑动方向
@property (assign, nonatomic) float startProgress;                                //起始进度条
@property (assign, nonatomic) float nowProgress;                                  //进度条当前位置
@property (assign, nonatomic) BOOL isSlideOrClick;
@property (assign, nonatomic) BOOL isPlayButtonSelectedBeforeDrag;                //拖动前播放按钮的状态

@property (strong, nonatomic) NSTimer *progressTimer;                             //监控进度
@property (strong, nonatomic) NSTimer *controlDisplayTimer;                       //控件显示计时器

@end



@implementation XFPlayerViewController

#pragma mark - 工厂方法

+ (instancetype)defaultPlayerViewControllerWithVideoUrl:(NSURL *)videoUrl
{
    XFPlayerViewController *playerViewController = [[XFPlayerViewController alloc] initWithNibName:@"XFPlayerViewController" bundle:nil];
    
    playerViewController.videoUrl = videoUrl;
    
    return playerViewController;
}

#pragma mark - 控制器方法

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // 隐藏状态栏
    [self prefersStatusBarHidden];
    [self performSelector:@selector(setNeedsStatusBarAppearanceUpdate)];
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
//    NSString *imagePath = [[NSBundle mainBundle] pathForResource:@"video_thumb" ofType:@"jpg"];
//    UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
//    [self.thumbImageView setImage:image];
//    [self.thumbImageView setHidden:YES];
    
    [self initAVPlayer];
    
    [self configDefaultUIDisplay];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self startPlayBtnFunc:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
}

- (void)dealloc
{
    NSLog(@"dealloc");
}

#pragma mark - 控件方法

- (IBAction)closeBtnFunc:(id)sender
{
    [self playOrStop:NO];
    
    __weak typeof(self) weakSelf = self;
    [self dismissViewControllerAnimated:YES completion:^{
        [weakSelf.progressTimer invalidate];
        weakSelf.progressTimer = nil;
        
        [weakSelf.controlDisplayTimer invalidate];
        weakSelf.controlDisplayTimer = nil;
    }];
}

- (IBAction)settingBtnFunc:(id)sender
{
    if (self.settionButtonBlock)
    {
        self.settionButtonBlock();
    }
}

/**
 *  开始播放按钮
 */
- (IBAction)startPlayBtnFunc:(id)sender
{
    [self playOrStop:YES];
}

/**
 *  播放暂停按钮
 */
- (IBAction)playBtnfunc:(id)sender
{
    if (!self.playButton.selected)
    {
        [self playOrStop:YES];
    }
    else
    {
        [self playOrStop:NO];
    }
}


#pragma mark - 私有方法

/**
 *  配置默认UI信息
 */
- (void)configDefaultUIDisplay
{
    [self.videoProgressSlider setThumbImage:[UIImage imageNamed:@"progressThumb"] forState:UIControlStateNormal];
    [self.videoProgressSlider addTarget:self action:@selector(scrubbingDoing) forControlEvents:UIControlEventValueChanged];
    [self.videoProgressSlider addTarget:self action:@selector(scrubbingDidEnd) forControlEvents:(UIControlEventTouchUpInside | UIControlEventTouchCancel | UIControlEventTouchDragExit | UIControlEventTouchUpOutside)];
    
    [self hideConfigControl];
    [self.startPlayButton setHidden:YES];
}


- (void)initAVPlayer
{
    //设置静音状态也可播放声音
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];
    
    AVURLAsset *asset = [AVURLAsset assetWithURL:self.videoUrl];
    
    //获取视频总时长
    Float64 duration = CMTimeGetSeconds(asset.duration);
    _totalVideoDuration = duration;
    [self.videoTotalTimeLabel setText:[self formatVideoTimeTextWithTime:_totalVideoDuration]];
    
    _playerItem = [AVPlayerItem playerItemWithAsset: asset];
    
    _player = [[AVPlayer alloc] initWithPlayerItem:_playerItem];
    
    AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:_player];
    playerLayer.frame = CGRectMake(0, 0, kScreenWidth, kScreenHeight);
    playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    [self.view.layer addSublayer:playerLayer];
    
    [self.view bringSubviewToFront:self.closeButton];
    [self.view bringSubviewToFront:self.settingButton];
    [self.view bringSubviewToFront:self.startPlayButton];
    [self.view bringSubviewToFront:self.playButton];
    [self.view bringSubviewToFront:self.videoCurrentTimeLabel];
    [self.view bringSubviewToFront:self.videoProgressSlider];
    [self.view bringSubviewToFront:self.videoTotalTimeLabel];
    
    //获取系统音量
    MPVolumeView *volumeView = [[MPVolumeView alloc] init];
    _volumeSlider = nil;
    for (UIView *view in [volumeView subviews])
    {
        if ([view.class.description isEqualToString:@"MPVolumeSlider"])
        {
            _volumeSlider = (UISlider *)view;
            break;
        }
    }
    
    //获取系统亮度
    _systemBrightness = [UIScreen mainScreen].brightness;
    
}

/**
 *  显示配置控件一段时间
 */
- (void)diaplayConfigControlInDueTime
{
    if (_controlDisplayTimer)
    {
        [_controlDisplayTimer invalidate];
        _controlDisplayTimer = nil;
    }
    
    [self.closeButton setHidden:NO];
    [self.settingButton setHidden:NO];
    [self.playButton setHidden:NO];
    [self.videoCurrentTimeLabel setHidden:NO];
    [self.videoProgressSlider setHidden:NO];
    [self.videoTotalTimeLabel setHidden:NO];
    
    _controlDisplayTimer = [NSTimer scheduledTimerWithTimeInterval:3.5 target:self selector:@selector(hideConfigControlAndStopTimer) userInfo:nil repeats:YES];
}

/**
 *  隐藏配置控件
 */
- (void)hideConfigControlAndStopTimer
{
    [self hideConfigControl];
    [_controlDisplayTimer invalidate];
    _controlDisplayTimer = nil;
}

- (void)hideConfigControl
{
    [self.closeButton setHidden:YES];
    [self.settingButton setHidden:YES];
    [self.playButton setHidden:YES];
    [self.videoCurrentTimeLabel setHidden:YES];
    [self.videoProgressSlider setHidden:YES];
    [self.videoTotalTimeLabel setHidden:YES];
}

/**
 *  规范视频时间
 */
- (NSString *)formatVideoTimeTextWithTime:(CGFloat)time
{
    if (time <= 0)
    {
        return @"00:00";
    }
    
    NSString *minuteText = @"00";
    NSString *secondText = @"00";
    NSString *totalTimeText = @"00:00";
    if (time < 60.0f)
    {
        if (time < 9.5f)
        {
            secondText = [NSString stringWithFormat:@"0%.0f", time];
        }
        else
        {
            secondText = [NSString stringWithFormat:@"%.0f", time];
        }
    }
    else
    {
        CGFloat tempMinute = time / 60;
        if (tempMinute < 9.5f)
        {
            minuteText = [NSString stringWithFormat:@"0%.0f", tempMinute];
        }
        else
        {
            minuteText = [NSString stringWithFormat:@"%.0f", tempMinute];
        }
        
        CGFloat tempSecond = time - tempMinute * 60;
        if (tempSecond < 9.5f)
        {
            secondText = [NSString stringWithFormat:@"0%.0f", tempSecond];
        }
        else
        {
            secondText = [NSString stringWithFormat:@"%.0f", tempSecond];
        }
    }
    
    totalTimeText = [NSString stringWithFormat:@"%@:%@", minuteText, secondText];
    
    return totalTimeText;
}


/**
 *  隐藏状态栏
 */
- (BOOL)prefersStatusBarHidden
{
    return YES;//隐藏为YES，显示为NO
}

#pragma mark - touch事件
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if(event.allTouches.count == 1)
    {
        //保存当前触摸的位置
        CGPoint point = [[touches anyObject] locationInView:self.view];
        _startPoint = point;
        _startProgress = _videoProgressSlider.value;
        self.systemVolume = self.volumeSlider.value;
        
        if (point.x < (self.view.frame.size.width / 2))
        {
            _isTouchBeganLeft = YES;
        }
        else
        {
            _isTouchBeganLeft = NO;
        }
    }
    
    [self diaplayConfigControlInDueTime];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    _isSlideOrClick = YES;
    //右半区调整音量
    CGPoint location = [[touches anyObject] locationInView:self.view];
    CGFloat changeY = location.y - _startPoint.y;
    CGFloat changeX = location.x - _startPoint.x;
    
    //初次滑动没有滑动方向，进行判断。已有滑动方向，直接进行操作
    if ([_slideDirection isEqualToString:@"横向"])
    {
        int index = location.x - _startPoint.x;
        if (index > 0)
        {
            _videoProgressSlider.value = _startProgress + abs(index)/10 * 0.008;
        }
        else
        {
            _videoProgressSlider.value = _startProgress - abs(index)/10 * 0.008;
        }
    }
    else if ([_slideDirection isEqualToString:@"纵向"])
    {
        int index = location.y - _startPoint.y;
        
        if (_isTouchBeganLeft)
        {
            CGFloat originalBrightness = [UIScreen mainScreen].brightness;
            CGFloat finalBrightness;
            if (index > 0)
            {
                finalBrightness = _systemBrightness - abs(index) / 10 * 0.01;
                
                if (finalBrightness < originalBrightness)
                {
                    [UIScreen mainScreen].brightness = finalBrightness;
                }
            }
            else
            {
                finalBrightness = _systemBrightness + abs(index) / 10 * 0.01;
                
                if (finalBrightness > originalBrightness)
                {
                    [UIScreen mainScreen].brightness = finalBrightness;
                }
            }
        }
        else
        {
            if (index > 0)
            {
                [_volumeSlider setValue:_systemVolume - (abs(index) / 10 * 0.05) animated:YES];
                [_volumeSlider sendActionsForControlEvents:UIControlEventTouchUpInside];
            }
            else
            {
                [_volumeSlider setValue:_systemVolume + (abs(index) / 10 * 0.05) animated:YES];
                [_volumeSlider sendActionsForControlEvents:UIControlEventTouchUpInside];
            }
        }
    }
    else
    {
        //"第一次"滑动
        if (fabs(changeX) > fabs(changeY))
        {
            _slideDirection = @"横向";//设置为横向
        }
        else if (fabs(changeY)>fabs(changeX))
        {
            _slideDirection = @"纵向";//设置为纵向
        }
        else
        {
            _isSlideOrClick = NO;
        }
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    CGPoint point = [[touches anyObject] locationInView:self.view];
        
    if (_isSlideOrClick)
    {
        _slideDirection = @"";
        _isSlideOrClick = NO;
        
        CGFloat changeY = point.y - _startPoint.y;
        CGFloat changeX = point.x - _startPoint.x;
        //如果位置改变 刷新进度条
        if (fabs(changeX) > fabs(changeY))
        {
            [self playOrStop:NO];
            
            _nowProgress = _videoProgressSlider.value;
            
            [self playOrStop:YES];
        }
        
    }
}

#pragma mark - 拖动进度条方法

/**
 *  拖动进度条
 */
- (void)scrubbingDoing
{
    [self playOrStop:NO];
    
    self.videoCurrentTimeLabel.text = [self formatVideoTimeTextWithTime:(self.totalVideoDuration * self.videoProgressSlider.value)];
    self.nowProgress = self.videoProgressSlider.value;
}

/**
 *  释放进度条
 */
- (void)scrubbingDidEnd
{
    [self playOrStop:YES];
}

- (void)playOrStop:(BOOL)isPlay
{
    [self.startPlayButton setHidden:YES];
    
    self.isPlayButtonSelectedBeforeDrag = self.playButton.selected;
    
    if (isPlay)
    {
        //1.通过实际百分比获取秒数。
        float dragedSeconds = floorf(_totalVideoDuration * _nowProgress);
        CMTime newCMTime = CMTimeMake(dragedSeconds, 1);
        //2.更新视频到实际秒数。
        [_player seekToTime:newCMTime];
        //3.play 并且重启timer
        [_player play];
        [self.playButton setSelected:YES];
        self.progressTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(updateUIWithPlayerTime) userInfo:nil repeats:YES];
    }
    else
    {
        [_player pause];
        [self.playButton setSelected:NO];
        [self.progressTimer invalidate];
    }
    
}

- (void)updateUIWithPlayerTime
{
    //1.根据播放进度与总进度计算出当前百分比
    float new = CMTimeGetSeconds(_player.currentItem.currentTime) / CMTimeGetSeconds(_player.currentItem.duration);
    //2.计算当前百分比与实际百分比的差值
    float dValue = new - _nowProgress;
    //3.实际百分比更新到当前百分比
    _nowProgress = new;
    //4.当前百分比加上差值更新到实际进度条与当前时间label
    self.videoProgressSlider.value = self.videoProgressSlider.value + dValue;
    self.videoCurrentTimeLabel.text = [self formatVideoTimeTextWithTime:(self.totalVideoDuration * new)];
    
    // 计算视频剩余时间
    CGFloat lastTime = CMTimeGetSeconds(_player.currentItem.currentTime) - CMTimeGetSeconds(_player.currentItem.duration);
    if (lastTime == 0)
    {
        [self playOrStop:NO];
        [self.startPlayButton setHidden:NO];
        
        self.videoCurrentTimeLabel.text = [self formatVideoTimeTextWithTime:0];
        self.videoProgressSlider.value = 0;
        self.nowProgress = self.videoProgressSlider.value;
    }
}


@end
