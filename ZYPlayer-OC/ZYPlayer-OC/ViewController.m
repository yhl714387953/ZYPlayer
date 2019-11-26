//
//  ViewController.m
//  ZYPlayer-OC
//
//  Created by 嘴爷 on 2019/11/26.
//  Copyright © 2019 嘴爷. All rights reserved.
//

#import "ViewController.h"

#import "VideoListController.h"
#import <AVKit/AVKit.h>

@interface ViewController ()<VideoListControllerDelegate>
{
    BOOL _isDragging;
    NSArray* _observerKeyPathes;
    NSDictionary* _notificationInfos;
}

/** <#description#> */
@property (nonatomic, strong) AVPlayerLayer* playerLayer;

/** <#description#> */
@property (nonatomic, strong) AVPlayer* player;

/** <#description#> */
@property (nonatomic, strong) AVPlayerItem* playerItem;

/** <#description#> */
@property (nonatomic, strong) CADisplayLink* disPlayLink;

@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@property (weak, nonatomic) IBOutlet UILabel *songTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *artistLabel;
@property (weak, nonatomic) IBOutlet UILabel *albumLabel;
/** <#description#> */
@property (weak, nonatomic) IBOutlet UIProgressView* progressView;


@property (weak, nonatomic) IBOutlet UILabel *currentTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *totalTimeLabel;
@property (weak, nonatomic) IBOutlet UISlider *slider;

@property (weak, nonatomic) IBOutlet UIButton *playButton;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSURL* fileUrl = [NSURL URLWithString:@"http://txmov2.a.yximgs.com/bs2/newWatermark/MTE3NjcxNzQ4MTg_zh_3.mp4"];
    self.playerItem = [AVPlayerItem playerItemWithURL:fileUrl];
    self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
    
    //* 视频播放
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;//填充模式
    self.playerLayer.backgroundColor = [UIColor blackColor].CGColor;
    CGFloat originY = [UIApplication sharedApplication].statusBarFrame.size.height;
    self.playerLayer.frame = CGRectMake(0, originY, self.view.frame.size.width, 300);//需要给一个初始值
    [self.view.layer addSublayer:self.playerLayer ];
    //*/
    
    [self addObserverForPlayerItem];
    [self addNotification];
    
    self.disPlayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateUI:)];
    [self.disPlayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    // Do any additional setup after loading the view.
}

-(void)addNotification{
    _notificationInfos = @{UIDeviceOrientationDidChangeNotification: @"screenRotate:",
                           AVPlayerItemDidPlayToEndTimeNotification: @"playToEnd:",
                           AVPlayerItemFailedToPlayToEndTimeNotification: @"failedToPlay:",
                           AVPlayerItemPlaybackStalledNotification: @"playbackStalled:",
                           AVAudioSessionInterruptionNotification: @"audioSessionInterruption:",
                           AVAudioSessionRouteChangeNotification: @"audioSessionRouteChange:",
                           UIApplicationWillResignActiveNotification: @"applicationWillResignActive:",
                           UIApplicationDidBecomeActiveNotification: @"applicationDidBecomeActive:"
                           };
    for (NSString* notificationName in _notificationInfos.allKeys) {
        NSString* method = _notificationInfos[notificationName];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:NSSelectorFromString(method) name:notificationName object:nil];
    }
}

#pragma mark - notification
//返回前台
-(void)applicationDidBecomeActive:(NSNotification*)notification{
    NSLog(@"applicationDidBecomeActive");
}

//进入后台
-(void)applicationWillResignActive:(NSNotification*)notification{
    NSLog(@"applicationWillResignActive");
}

//耳机插入和拔出的通知
-(void)audioSessionRouteChange:(NSNotification*)notification{
    NSLog(@"audioSessionRouteChange");
}

//声音被打断的通知（电话打来）
-(void)audioSessionInterruption:(NSNotification*)notification{
    NSLog(@"audioSessionInterruption");
}

//播放失败
-(void)playbackStalled:(NSNotification*)notification{
    NSLog(@"playbackStalled");
}

//异常中断
-(void)failedToPlay:(NSNotification*)notification{
    NSLog(@"failedToPlay");
}

//播放完成
-(void)playToEnd:(NSNotification*)notification{
    NSLog(@"播放完了");
    CMTime time = self.player.currentTime;
    time.value = 0;
    [self.player seekToTime:time completionHandler:^(BOOL finished) {
        NSLog(@"seek到初始位置");
        [self.player play];
    }];
}

//屏幕旋转
-(void)screenRotate:(NSNotification*)notification{
    
    /*
     UIDeviceOrientationPortrait,            // Device oriented vertically, home button on the bottom
     UIDeviceOrientationPortraitUpsideDown,  // Device oriented vertically, home button on the top
     UIDeviceOrientationLandscapeLeft,       // Device oriented horizontally, home button on the right
     UIDeviceOrientationLandscapeRight,      // Device oriented horizontally, home button on the left
     */
    
    //    UIDevice* device = notification.object;
    //    NSLog(@"notification:::%@", @(device.orientation));
}

-(void)addObserverForPlayerItem{
    _observerKeyPathes = @[@"status",                   //播放器状态变化
                           @"loadedTimeRanges",         //缓冲进度
                           @"playbackBufferEmpty",      // 缓冲区空了，需要等待数据
                           @"playbackLikelyToKeepUp"    //缓存足够播放的状态
                           ];
    for (NSString* keyPath in _observerKeyPathes) {
        [self.playerItem addObserver:self forKeyPath:keyPath options:NSKeyValueObservingOptionNew context:nil];
    }
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    if ([keyPath isEqualToString:@"status"]) {
        
        if (self.playerItem.status == AVPlayerStatusReadyToPlay) {
            
            CGFloat duration = CMTimeGetSeconds(self.playerItem.duration);
            NSLog(@"媒体就绪，播放时长：%f", duration);
            NSLog(@"播放视图大小：%@", @(self.playerLayer.videoRect));
            //            self.playerLayer.frame = self.playerLayer.videoRect;
            self.totalTimeLabel.text = [NSString stringWithFormat:@"%02d:%02d", (int)duration / 60, (int)duration % 60];
            
            [self mp3Info];
            if ([self.playerItem.asset isKindOfClass:[AVURLAsset class]]) {
                self.imageView.image = [self getVideoPreViewAVAsset:(AVURLAsset*)self.playerItem.asset];
            }
            
        }
    }else if ([keyPath isEqualToString:@"loadedTimeRanges"]){
        
        NSArray* ranges = change[@"new"];
        
        if ([ranges isKindOfClass:[NSArray class]] && ranges.count > 0) {
            CMTimeRange range = [[ranges firstObject] CMTimeRangeValue];
            CMTime bufferDuration = CMTimeAdd(range.start, range.duration);
            NSLog(@"缓冲进度%f", CMTimeGetSeconds(bufferDuration));
            self.progressView.progress = CMTimeGetSeconds(bufferDuration) / CMTimeGetSeconds(self.playerItem.duration);
        }
        
    }else if ([keyPath isEqualToString:@"playbackBufferEmpty"]){//视频缓冲开始
        NSLog(@"缓冲区空了，需要等待数据playbackBufferEmpty:%@", change);
    }else if ([keyPath isEqualToString:@"playbackLikelyToKeepUp"]){//视频缓冲结束
        NSLog(@"缓存足够播放的状态playbackLikelyToKeepUp:%@", change);
    }
}

-(void)mp3Info{
    AVAsset* asset = self.playerItem.asset;
    NSString *title = @"";
    UIImage* image = nil;
    NSString *artist = @"";
    NSString *albumName = @"";
    
    for (NSString *format in [asset availableMetadataFormats]) {
        
        for (AVMetadataItem *metadataItem in [asset metadataForFormat:format]) {
            
            //            NSLog(@"commonKey:-----------:%@", metadataItem.commonKey);
            if ([metadataItem.commonKey isEqualToString:@"artwork"]) {
                if ([metadataItem.value isKindOfClass:[NSData class]]) {
                    NSData *data = (NSData *)metadataItem.value;
                    image = [UIImage imageWithData:data];
                }
                
            }else if([metadataItem.commonKey isEqualToString:@"title"]){
                title = (NSString *)metadataItem.value;
                NSLog(@"title: %@",title);
                
            }else if([metadataItem.commonKey isEqualToString:@"artist"]){
                artist = (NSString *)metadataItem.value;
                NSLog(@"artist: %@",artist);
                
            }else if([metadataItem.commonKey isEqualToString:@"albumName"]){
                albumName = (NSString *)metadataItem.value;
                NSLog(@"albumName: %@",albumName);
                
            }
        }
    }
    
    self.imageView.image = image;
    self.songTitleLabel.text = title ? : @"";
    self.artistLabel.text = [NSString stringWithFormat:@"歌手：%@", artist];
    self.albumLabel.text = [NSString stringWithFormat:@"专辑：%@", albumName];
}

-(void)updateUI:(CADisplayLink*)displayLink{
    
    if (_isDragging) {
        return;
    }
    
    CGFloat duration = CMTimeGetSeconds(self.playerItem.duration);
    if (duration <= 0) {
        return;
    }
    
    CGFloat currentTime = CMTimeGetSeconds(self.playerItem.currentTime);
    
    self.currentTimeLabel.text = [NSString stringWithFormat:@"%02d:%02d", (int)currentTime / 60, (int)currentTime % 60];
    
    self.slider.value = currentTime / duration;
    
}

-(void)dealloc{
    
    for (NSString* keyPath in _observerKeyPathes) {
        [self.playerItem removeObserver:self forKeyPath:keyPath];
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    self.disPlayLink.paused = YES;
    [self.disPlayLink removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    self.disPlayLink = nil;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -IBAction
- (IBAction)play:(UIButton *)sender {
    if (sender.isSelected) {
        [self.player pause];
    }else{
        [self.player play];
    }
    
    sender.selected = !sender.isSelected;
}
- (IBAction)sliderTouchDown:(UISlider *)sender {
    _isDragging = YES;
}

- (IBAction)sliderTouchUpInside:(UISlider *)sender {
    _isDragging = NO;
    [self seekToPosion];
}

- (IBAction)sliderTouchUpOutSide:(UISlider *)sender {
    _isDragging = NO;
    [self seekToPosion];
}

- (IBAction)sliderDrag:(UISlider *)sender {
    
    CGFloat duration = CMTimeGetSeconds(self.playerItem.duration);
    if (duration <= 0) {
        
        return;
    }
    
    CGFloat currentTime = duration * sender.value;
    self.currentTimeLabel.text = [NSString stringWithFormat:@"%02d:%02d", (int)currentTime / 60, (int)currentTime % 60];
}

-(void)seekToPosion{
    CGFloat duration = CMTimeGetSeconds(self.playerItem.duration);
    CGFloat currentTime = duration * self.slider.value;
    CMTime time = self.player.currentTime;
    time.value = currentTime * time.timescale;
    [self.player seekToTime:time completionHandler:^(BOOL finished) {
        NSLog(@"seek到 %f 位置", currentTime);
    }];
}

- (void)changeVideo:(NSDictionary *)info {
    
    NSURL* fileUrl = [NSURL URLWithString:info[@"url"]];
    self.playerItem = [AVPlayerItem playerItemWithURL:fileUrl];
    [self.player replaceCurrentItemWithPlayerItem:self.playerItem];
}

- (IBAction)setRate:(UISlider *)sender {
    
    NSLog(@"播放速度%f", sender.value);
    self.player.rate = sender.value;//0暂停，超过2之后视频会卡住，音频不影响
}



// 获取视频第一帧
-(UIImage*)getVideoPreViewAVAsset:(AVURLAsset *)asset{
    //    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:path options:nil];
    AVAssetImageGenerator *assetGen = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    
    assetGen.appliesPreferredTrackTransform = YES;
    CMTime time = CMTimeMakeWithSeconds(0.0, 600);
    NSError *error = nil;
    CMTime actualTime;
    CGImageRef image = [assetGen copyCGImageAtTime:time actualTime:&actualTime error:&error];
    UIImage *videoImage = [[UIImage alloc] initWithCGImage:image];
    CGImageRelease(image);
    return videoImage;
}


#pragma mark - VideoListControllerDelegate
-(void)videoListController:(VideoListController *)videoController selectInfo:(NSDictionary *)info{
    
    [self changeVideo:info];
}

#pragma mark - Navigation
// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    if ([segue.destinationViewController isKindOfClass:[VideoListController class]]) {
        VideoListController* vc = (VideoListController*)segue.destinationViewController;
        vc.delegate = self;
    }
}



@end
