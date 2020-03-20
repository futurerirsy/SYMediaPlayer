//
//  SYPlayerViewController.m
//  SYMediaPlayerDemo
//
//  Created by RYB_iMAC on 2020/3/19.
//  Copyright © 2020 RYB. All rights reserved.
//

#import "SYPlayerViewController.h"
#import "SYMediaPlayer.h"


@interface SYPlayerViewController ()

@property (nonatomic, strong) SYMediaPlayer * player;
@property (nonatomic, assign) BOOL isHiddenControls;
@property (nonatomic, assign) BOOL isScrubbing;
@property (nonatomic, assign) BOOL isSeeking;

@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UIButton *speedUpButton;
@property (weak, nonatomic) IBOutlet UIButton *speedDownButton;
@property (weak, nonatomic) IBOutlet UILabel *speedLabel;

@property (weak, nonatomic) IBOutlet UIToolbar *playerControlToolbar;
@property (weak, nonatomic) IBOutlet UILabel *currentTimeLabel;
@property (weak, nonatomic) IBOutlet UISlider *progressSilder;
@property (weak, nonatomic) IBOutlet UILabel *totalTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *playPauseButton;

@end


@implementation SYPlayerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //.
    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
    [defaultCenter addObserver:self selector:@selector(errorAction:)
                          name:SYMediaPlayerErrorNotification object:nil];
    [defaultCenter addObserver:self selector:@selector(stateAction:)
                          name:SYMediaPlayerStateChangeNotification object:nil];
    [defaultCenter addObserver:self selector:@selector(playableAction:)
                          name:SYMediaPlayerPlayableChangeNotification object:nil];
    [defaultCenter addObserver:self selector:@selector(progressAction:)
                          name:SYMediaPlayerProgressChangeNotification object:nil];
    
    //.
    self.player = [SYMediaPlayer player];
    self.player.decoder = [SYPlayerDecoder decoderByFFmpeg];
    [self.view insertSubview:self.player.displayView atIndex:0];
    
    //.
    [self.player replaceVideoWithURL:self.selectedURL];
    
    __weak typeof(self) weakSelf = self;
    [self.player setViewTapAction:^(SYMediaPlayer *player, SYPlayerRenderingView *view) {
        weakSelf.isHiddenControls = !weakSelf.isHiddenControls;
        [weakSelf hidePlayerControls];
    }];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    self.player.displayView.frame = self.view.bounds;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.player = nil;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (BOOL)prefersStatusBarHidden
{
    return _isHiddenControls;
}

- (void)hidePlayerControls
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"player controls status - [%d]", (int)self.isHiddenControls);
        
        CGFloat targetAlpha = 0.f;
        UIViewAnimationOptions options;
        if (self.isHiddenControls) {
            targetAlpha = 0.f;
            options = UIViewAnimationOptionCurveEaseIn;
        }
        else {
            targetAlpha = 1.f;
            options = UIViewAnimationOptionCurveEaseOut;
            [self setNeedsStatusBarAppearanceUpdate];
        }
        
        [UIView animateWithDuration:0.2f delay:0 options:options animations:^(void) {
            self.currentTimeLabel.alpha = targetAlpha;
            self.progressSilder.alpha = targetAlpha;
            self.totalTimeLabel.alpha = targetAlpha;
            self.statusLabel.alpha = targetAlpha;
            
            self.speedLabel.alpha = targetAlpha;
            self.speedUpButton.alpha = targetAlpha;
            self.speedDownButton.alpha = targetAlpha;
            
            self.backButton.alpha = targetAlpha;
            self.playerControlToolbar.alpha = targetAlpha;
        } completion:^(BOOL finished) {
            if (self.isHiddenControls) {
                [self setNeedsStatusBarAppearanceUpdate];
            }
        }];
    });
}


#pragma mark - Player Notification

- (NSString *)timeStringFromSeconds:(CGFloat)seconds
{
    return [NSString stringWithFormat:@"%ld:%.2ld", (long)seconds / 60, (long)seconds % 60];
}

- (void)stateAction:(NSNotification *)notification
{
    NSDictionary *userInfo = notification.object;
//    SYPlayerState previous = [[userInfo objectForKey:SYMediaPlayerPreviousNotificationKey] integerValue];
    SYPlayerState current = [[userInfo objectForKey:SYMediaPlayerCurrentNotificationKey] integerValue];
    
    NSString * text;
    switch (current) {
        case SYPlayerStateNone:
            text = @"None";
            break;
        case SYPlayerStateBuffering:
            text = @"Buffering...";
            break;
        case SYPlayerStateReadyToPlay:
            text = @"Prepare";
            self.totalTimeLabel.text = [self timeStringFromSeconds:self.player.duration];
            [self.player play];
            break;
        case SYPlayerStatePlaying:
            text = @"Playing";
            if (self.isSeeking) {
                [self performSelector:@selector(updateSeekingStatus) withObject:nil afterDelay:0.1f];
            }
            break;
        case SYPlayerStateSuspend:
            text = @"Suspend";
            if (self.isSeeking) {
                [self performSelector:@selector(updateSeekingStatus) withObject:nil afterDelay:0.1f];
            }
            break;
        case SYPlayerStateFinished:
            text = @"Finished";
            break;
        case SYPlayerStateFailed:
            text = @"Error";
            break;
    }
    self.statusLabel.text = text;
}

- (void)progressAction:(NSNotification *)notification
{
    NSDictionary *userInfo = notification.object;
    double percent = [[userInfo objectForKey:SYMediaPlayerPercentNotificationKey] doubleValue];
    double current = [[userInfo objectForKey:SYMediaPlayerCurrentNotificationKey] doubleValue];
    if (!self.isScrubbing) {
        self.progressSilder.value = percent;
    }
    self.currentTimeLabel.text = [self timeStringFromSeconds:current];
}

- (void)playableAction:(NSNotification *)notification
{
    NSDictionary *userInfo = notification.object;
    double current = [[userInfo objectForKey:SYMediaPlayerCurrentNotificationKey] doubleValue];
    NSLog(@"playable time : %f", current);
}

- (void)errorAction:(NSNotification *)notification
{
    NSDictionary *userInfo = notification.object;
    NSError * error = [userInfo objectForKey:SYMediaPlayerErrorNotificationKey];
    NSLog(@"player did error : %@", error);
}


#pragma mark - Button Actions

- (IBAction)back:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)speedUp:(id)sender
{
    CGFloat speedValue = self.player.rate;
    speedValue += 0.1f;
    if (speedValue > 4.f)
        speedValue = 4.f;
    
    self.player.rate = speedValue;
    self.speedLabel.text = [NSString stringWithFormat:@"speed : %.1fx", speedValue];
}

- (IBAction)speedDown:(id)sender
{
    CGFloat speedValue = self.player.rate;
    speedValue -= 0.1f;
    if (speedValue < 0.1f)
        speedValue = 0.1f;
    
    self.player.rate = speedValue;
    self.speedLabel.text = [NSString stringWithFormat:@"speed : %.1fx", speedValue];
}

- (IBAction)positionSliderAction:(id)sender
{
    if (self.isScrubbing)
        [self timeSliderPosChanged:sender];
    else
        [self seekPlayerWithSliderPosition:sender];
    
    CGFloat fPos = self.progressSilder.value;
    CGFloat scrubbingValue = self.player.duration * fPos;
    self.currentTimeLabel.text = [self timeStringFromSeconds:scrubbingValue];
}

- (IBAction)positionSliderTouchDown:(id)sender
{
    self.isScrubbing = YES;
}

- (IBAction)positionSliderTouchUp:(id)sender
{
    if (self.isScrubbing) {
        self.isScrubbing = NO;
        [self seekPlayerWithSliderPosition:sender];
    }
}

- (IBAction)positionSliderDrag:(id)sender
{
    self.isScrubbing = YES;
}

- (void)updateSeekingStatus
{
    self.isSeeking = NO;
}

- (void)timeSliderPosChanged:(id)sender
{
    if (self.isSeeking)
        return;
    
    self.isSeeking = YES;
    
    CGFloat fPos = self.progressSilder.value;
    CGFloat destSeekingValue = self.player.duration * fPos;
    [self.player seekToTime:destSeekingValue completeHandler:^(BOOL finished) {
        if (!finished) {
            NSLog(@"seek failed!!!");
        }
    }];
}

- (void)seekPlayerWithSliderPosition:(id)sender
{
    CGFloat fPos = self.progressSilder.value;
    CGFloat destSeekingValue = self.player.duration * fPos;
    [self.player seekToTime:destSeekingValue completeHandler:^(BOOL finished) {
        if (!finished) {
            NSLog(@"seek failed!!!");
        }
    }];
}

- (IBAction)onPlayPause:(id)sender
{
    if (self.player.state == SYPlayerStatePlaying) {
        [self.player pause];
        
        UIImage *playImage = [UIImage imageNamed:@"panel_btn_play"];
        self.playPauseButton.image = playImage;
        [self.playPauseButton setBackButtonBackgroundImage:playImage
                                                  forState:UIControlStateNormal
                                                barMetrics:UIBarMetricsDefault];
    }
    else {
        [self.player play];
        
        UIImage *pauseImage = [UIImage imageNamed:@"panel_btn_pause"];
        self.playPauseButton.image = pauseImage;
        [self.playPauseButton setBackButtonBackgroundImage:pauseImage
                                                  forState:UIControlStateNormal
                                                barMetrics:UIBarMetricsDefault];
    }
}

- (IBAction)onBackward:(id)sender
{
    CGFloat currentValue = self.player.progress;
    CGFloat destSeekingValue = currentValue - 10.f;
    if (destSeekingValue < 0.f)
        destSeekingValue = 0.f;
    
    self.progressSilder.value = destSeekingValue / self.player.duration;
    self.currentTimeLabel.text = [self timeStringFromSeconds:destSeekingValue];
    
    [self.player seekToTime:destSeekingValue completeHandler:^(BOOL finished) {
        if (!finished) {
            NSLog(@"seek failed!!!");
        }
    }];
}

- (IBAction)onforward:(id)sender
{
    CGFloat currentValue = self.player.progress;
    CGFloat destSeekingValue = currentValue + 10.f;
    if (destSeekingValue > (self.player.duration - 3.f))
        destSeekingValue = self.player.duration - 3.f;
    
    self.progressSilder.value = destSeekingValue / self.player.duration;
    self.currentTimeLabel.text = [self timeStringFromSeconds:destSeekingValue];
    
    [self.player seekToTime:destSeekingValue completeHandler:^(BOOL finished) {
        if (!finished) {
            NSLog(@"seek failed!!!");
        }
    }];
}

@end
