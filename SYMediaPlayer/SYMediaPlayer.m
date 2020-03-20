//
//  SYMediaPlayer.m
//  SYMediaPlayer
//
//  Created by RYB_iMAC on 2020/3/15.
//  Copyright © 2020 RYB. All rights reserved.
//

#import "SYMediaPlayer.h"
#import "SYPlayerRenderingView.h"


@interface SYMediaPlayer ()

@property (nonatomic, assign) SYVideoType videoType;
@property (nonatomic, assign) SYDecoderType decoderType;
@property (nonatomic, strong) SYFFMpegPlayer * ffPlayer;
@property (nonatomic, strong) SYAVPlayer * avPlayer;

@property (nonatomic, copy) NSURL * contentURL;
@property (nonatomic, assign) BOOL needAutoPlay;
@property (nonatomic, assign) NSTimeInterval lastForegroundTimeInterval;

@end


@implementation SYMediaPlayer

+ (instancetype)player
{
    return [[self alloc] init];
}

- (instancetype)init
{
    if (self = [super init]) {
        self.decoder = [SYPlayerDecoder decoderByDefault];
        self.contentURL = nil;
        self.videoType = SYVideoTypeNormal;
        self.displayMode = SYDisplayModeNormal;
        self.viewGravityMode = SYGravityModeResizeAspect;
        self.playableBufferInterval = 2.f;
        self.viewAnimationHidden = YES;
        self.volume = 1.f;
        self.rate = 1.f;
        self.displayView = [SYPlayerRenderingView displayViewWithAbstractPlayer:self];
    }
    return self;
}

- (void)replaceVideoWithURL:(nullable NSURL *)contentURL
{
    [self replaceVideoWithURL:contentURL videoType:SYVideoTypeNormal];
}

- (void)replaceVideoWithURL:(nullable NSURL *)contentURL videoType:(SYVideoType)videoType
{
    self.error = nil;
    self.contentURL = contentURL;
    self.decoderType = [self.decoder decoderTypeForContentURL:self.contentURL];
    self.videoType = videoType;
    switch (self.videoType)
    {
        case SYVideoTypeNormal:
        case SYVideoTypeVR:
            break;
        default:
            self.videoType = SYVideoTypeNormal;
            break;
    }
    
    switch (self.decoderType)
    {
        case SYDecoderTypeAVPlayer:
        {
            [self.ffPlayer stop];
            
            if (!self.avPlayer) {
                self.avPlayer =[SYAVPlayer playerWithAbstractPlayer:self];
            }
            [self.avPlayer replaceVideo];
        }
            break;
        case SYDecoderTypeFFmpeg:
        {
            [self.avPlayer stop];
            
            if (!self.ffPlayer) {
                self.ffPlayer = [SYFFMpegPlayer playerWithAbstractPlayer:self];
                self.ffPlayer.rate = self.rate;
            }
            [self.ffPlayer replaceVideo];
        }
            break;
        case SYDecoderTypeError:
        {
            [self.avPlayer stop];
            [self.ffPlayer stop];
        }
            break;
    }
}

- (void)play
{
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    
    switch (self.decoderType)
    {
        case SYDecoderTypeAVPlayer:
            [self.avPlayer play];
            break;
        case SYDecoderTypeFFmpeg:
            [self.ffPlayer play];
            break;
        case SYDecoderTypeError:
            break;
    }
}

- (void)pause
{
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    
    switch (self.decoderType)
    {
        case SYDecoderTypeAVPlayer:
            [self.avPlayer pause];
            break;
        case SYDecoderTypeFFmpeg:
            [self.ffPlayer pause];
            break;
        case SYDecoderTypeError:
            break;
    }
}

- (void)stop
{
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    
    [self replaceVideoWithURL:nil];
}

- (BOOL)seekEnable
{
    switch (self.decoderType)
    {
        case SYDecoderTypeAVPlayer:
            return self.avPlayer.seekEnable;
            break;
        case SYDecoderTypeFFmpeg:
            return self.ffPlayer.seekEnable;
        case SYDecoderTypeError:
            return NO;
    }
}

- (BOOL)seeking
{
    switch (self.decoderType)
    {
        case SYDecoderTypeAVPlayer:
            return self.avPlayer.seeking;
        case SYDecoderTypeFFmpeg:
            return self.ffPlayer.seeking;
        case SYDecoderTypeError:
            return NO;
    }
}

- (void)seekToTime:(NSTimeInterval)time
{
    [self seekToTime:time completeHandler:nil];
}

- (void)seekToTime:(NSTimeInterval)time completeHandler:(nullable void (^)(BOOL))completeHandler
{
    switch (self.decoderType)
    {
        case SYDecoderTypeAVPlayer:
            [self.avPlayer seekToTime:time completeHandler:completeHandler];
            break;
        case SYDecoderTypeFFmpeg:
            [self.ffPlayer seekToTime:time completeHandler:completeHandler];
            break;
        case SYDecoderTypeError:
            break;
    }
}

- (void)setBackgroundMode:(BOOL)backgroundMode
{
    if (_backgroundMode != backgroundMode) {
        if (backgroundMode) {
            [self.displayView playerOutputTypeEmpty];
            [self.displayView rendererTypeEmpty];
        }
        else {
            [self.displayView playerOutputTypeFF];
            [self.displayView rendererTypeOpenGL];
        }
    }
    
    _backgroundMode = backgroundMode;
}

- (void)setVolume:(CGFloat)volume
{
    _volume = volume;
    [self.avPlayer reloadVolume];
    [self.ffPlayer reloadVolume];
}

- (void)setRate:(float)rate
{
    _rate = rate;
    self.ffPlayer.rate = rate;
}

- (void)setPlayableBufferInterval:(NSTimeInterval)playableBufferInterval
{
    _playableBufferInterval = playableBufferInterval;
    [self.ffPlayer reloadPlayableBufferInterval];
}

- (void)setViewGravityMode:(SYGravityMode)viewGravityMode
{
    _viewGravityMode = viewGravityMode;
    [self.displayView reloadGravityMode];
}

- (SYPlayerState)state
{
    switch (self.decoderType)
    {
        case SYDecoderTypeAVPlayer:
            return self.avPlayer.state;
        case SYDecoderTypeFFmpeg:
            return self.ffPlayer.state;
        case SYDecoderTypeError:
            return SYPlayerStateNone;
    }
}

- (CGSize)presentationSize
{
    switch (self.decoderType)
    {
        case SYDecoderTypeAVPlayer:
            return self.avPlayer.presentationSize;
        case SYDecoderTypeFFmpeg:
            return self.ffPlayer.presentationSize;
        case SYDecoderTypeError:
            return CGSizeZero;
    }
}

- (NSTimeInterval)bitrate
{
    switch (self.decoderType)
    {
        case SYDecoderTypeAVPlayer:
            return self.avPlayer.bitrate;
        case SYDecoderTypeFFmpeg:
            return self.ffPlayer.bitrate;
        case SYDecoderTypeError:
            return 0;
    }
}

- (NSTimeInterval)progress
{
    switch (self.decoderType)
    {
        case SYDecoderTypeAVPlayer:
            return self.avPlayer.progress;
        case SYDecoderTypeFFmpeg:
            return self.ffPlayer.progress;
        case SYDecoderTypeError:
            return 0;
    }
}

- (NSTimeInterval)duration
{
    switch (self.decoderType)
    {
        case SYDecoderTypeAVPlayer:
            return self.avPlayer.duration;
        case SYDecoderTypeFFmpeg:
            return self.ffPlayer.duration;
        case SYDecoderTypeError:
            return 0;
    }
}

- (NSTimeInterval)playableTime
{
    switch (self.decoderType)
    {
        case SYDecoderTypeAVPlayer:
            return self.avPlayer.playableTime;
        case SYDecoderTypeFFmpeg:
            return self.ffPlayer.playableTime;
        case SYDecoderTypeError:
            return 0;
    }
}

- (UIImage *)snapshot
{
    return self.displayView.snapshot;
}

- (void)setError:(NSError * _Nullable)error
{
    if (self.error != error) {
        self->_error = error;
    }
}

- (void)cleanPlayer
{
    [self.avPlayer stop];
    self.avPlayer = nil;
    
    [self.ffPlayer stop];
    self.ffPlayer = nil;
    
    [self cleanPlayerView];
    
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    
    self.needAutoPlay = NO;
    self.error = nil;
}

- (void)cleanPlayerView
{
    [self.displayView.subviews enumerateObjectsUsingBlock:^(__kindof UIView *obj, NSUInteger idx, BOOL *stop) {
        [obj removeFromSuperview];
    }];
}

- (void)dealloc
{
    NSLog(@"SYMediaPlayer dealloc");
    [self cleanPlayer];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end


#pragma mark - Tracks Category

@implementation SYMediaPlayer (Tracks)

- (BOOL)videoEnable
{
    switch (self.decoderType)
    {
        case SYDecoderTypeAVPlayer:
            return self.avPlayer.videoEnable;
        case SYDecoderTypeFFmpeg:
            return self.ffPlayer.videoEnable;
        case SYDecoderTypeError:
            return NO;
    }
}

- (BOOL)audioEnable
{
    switch (self.decoderType)
    {
        case SYDecoderTypeAVPlayer:
            return self.avPlayer.audioEnable;
        case SYDecoderTypeFFmpeg:
            return self.ffPlayer.audioEnable;
        case SYDecoderTypeError:
            return NO;
    }
}

- (SYPlayerTrack *)videoTrack
{
    switch (self.decoderType)
    {
        case SYDecoderTypeAVPlayer:
            return self.avPlayer.videoTrack;
        case SYDecoderTypeFFmpeg:
            return self.ffPlayer.videoTrack;
        case SYDecoderTypeError:
            return [[SYPlayerTrack alloc] init];
    }
}

- (SYPlayerTrack *)audioTrack
{
    switch (self.decoderType)
    {
        case SYDecoderTypeAVPlayer:
            return self.avPlayer.audioTrack;
        case SYDecoderTypeFFmpeg:
            return self.ffPlayer.audioTrack;
        case SYDecoderTypeError:
            return [[SYPlayerTrack alloc] init];
    }
}

- (NSArray <SYPlayerTrack *> *)videoTracks
{
    switch (self.decoderType)
    {
        case SYDecoderTypeAVPlayer:
            return self.avPlayer.videoTracks;
        case SYDecoderTypeFFmpeg:
            return self.ffPlayer.videoTracks;
        case SYDecoderTypeError:
            return @[[[SYPlayerTrack alloc] init]];
    }
}

- (NSArray <SYPlayerTrack *> *)audioTracks
{
    switch (self.decoderType)
    {
        case SYDecoderTypeAVPlayer:
            return self.avPlayer.audioTracks;
        case SYDecoderTypeFFmpeg:
            return self.ffPlayer.audioTracks;
        case SYDecoderTypeError:
            return @[[[SYPlayerTrack alloc] init]];
    }
}

- (void)selectAudioTrack:(SYPlayerTrack *)audioTrack
{
    [self selectAudioTrackIndex:audioTrack.index];
}

- (void)selectAudioTrackIndex:(int)audioTrackIndex
{
    switch (self.decoderType)
    {
        case SYDecoderTypeAVPlayer:
            [self.avPlayer selectAudioTrackIndex:audioTrackIndex];
        case SYDecoderTypeFFmpeg:
            [self.ffPlayer selectAudioTrackIndex:audioTrackIndex];
            break;
        case SYDecoderTypeError:
            break;
    }
}

@end


#pragma mark - Thread Category

@implementation SYMediaPlayer (Thread)

- (BOOL)videoDecodeOnMainThread
{
    switch (self.decoderType)
    {
        case SYDecoderTypeAVPlayer:
            return NO;
        case SYDecoderTypeFFmpeg:
            return self.ffPlayer.videoDecodeOnMainThread;
        case SYDecoderTypeError:
            return NO;
    }
}

- (BOOL)audioDecodeOnMainThread
{
    return NO;
}

@end
