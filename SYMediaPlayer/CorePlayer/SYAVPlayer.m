//
//  SYAVPlayer.m
//  SYMediaPlayer
//
//  Created by RYB_iMAC on 2020/3/17.
//  Copyright © 2020 RYB. All rights reserved.
//

#import "SYAVPlayer.h"
#import "SYMediaPlayer.h"

static CGFloat const PixelBufferRequestInterval = 0.03f;
static NSString * const AVMediaSelectionOptionTrackIDKey = @"MediaSelectionOptionsPersistentID";


@interface SYAVPlayer ()

@property (nonatomic, weak) SYMediaPlayer * abstractPlayer;
@property (nonatomic, assign) SYPlayerState bufferingState;
@property (nonatomic, assign) SYPlayerState state;
@property (nonatomic, assign) NSTimeInterval playableTime;
@property (nonatomic, assign) BOOL seeking;

@property (atomic, strong) AVURLAsset * avAsset;
@property (nonatomic, strong) AVPlayer * avPlayer;
@property (nonatomic, strong) AVPlayerItem * avPlayerItem;
@property (atomic, strong) AVPlayerItemVideoOutput * avOutput;
@property (atomic, assign) NSTimeInterval readyToPlayTime;
@property (atomic, strong) id playBackTimeObserver;

@property (atomic, assign) BOOL playing;
@property (atomic, assign) BOOL buffering;
@property (atomic, assign) BOOL hasPixelBuffer;

//. track
@property (nonatomic, assign) BOOL videoEnable;
@property (nonatomic, assign) BOOL audioEnable;

@property (nonatomic, strong) SYPlayerTrack * videoTrack;
@property (nonatomic, strong) SYPlayerTrack * audioTrack;

@property (nonatomic, strong) NSArray <SYPlayerTrack *> * videoTracks;
@property (nonatomic, strong) NSArray <SYPlayerTrack *> * audioTracks;

@end


@implementation SYAVPlayer

+ (instancetype)playerWithAbstractPlayer:(id)abstractPlayer
{
    return [[self alloc] initWithAbstractPlayer:abstractPlayer];
}

- (instancetype)initWithAbstractPlayer:(id)abstractPlayer
{
    if (self = [super init]) {
        self.abstractPlayer = (SYMediaPlayer *)abstractPlayer;
        self.abstractPlayer.displayView.playerOutputAV = self;
    }
    return self;
}


#pragma mark - play control

- (void)play
{
    self.playing = YES;
    
    switch (self.state) {
        case SYPlayerStateFinished:
            [self.avPlayer seekToTime:kCMTimeZero];
            self.state = SYPlayerStatePlaying;
            break;
        case SYPlayerStateFailed:
            [self replaceEmpty];
            [self replaceVideo];
            break;
        case SYPlayerStateNone:
            self.state = SYPlayerStateBuffering;
            break;
        case SYPlayerStateSuspend:
            if (self.buffering) {
                self.state = SYPlayerStateBuffering;
            }
            else {
                self.state = SYPlayerStatePlaying;
            }
            break;
        case SYPlayerStateReadyToPlay:
            self.state = SYPlayerStatePlaying;
            break;
        default:
            break;
    }
    
    [self.avPlayer play];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        switch (self.state) {
            case SYPlayerStateBuffering:
            case SYPlayerStatePlaying:
            case SYPlayerStateReadyToPlay:
                [self.avPlayer play];
            default:
                break;
        }
    });
}

- (void)startBuffering
{
    if (self.playing) {
        [self.avPlayer pause];
    }
    self.buffering = YES;
    if (self.state != SYPlayerStateBuffering) {
        self.bufferingState = self.state;
    }
    self.state = SYPlayerStateBuffering;
}

- (void)stopBuffering
{
    self.buffering = NO;
}

- (void)resumeStateAfterBuffering
{
    if (self.playing) {
        [self.avPlayer play];
        self.state = SYPlayerStatePlaying;
    }
    else if (self.state == SYPlayerStateBuffering) {
        self.state = self.bufferingState;
    }
}

- (BOOL)playIfNeed
{
    if (self.playing) {
        [self.avPlayer play];
        self.state = SYPlayerStatePlaying;
        return YES;
    }
    return NO;
}

- (void)pause
{
    [self.avPlayer pause];
    self.playing = NO;
    if (self.state == SYPlayerStateFailed) return;
    self.state = SYPlayerStateSuspend;
}

- (BOOL)seekEnable
{
    if (self.duration <= 0 || self.avPlayerItem.status != AVPlayerItemStatusReadyToPlay) {
        return NO;
    }
    return YES;
}

- (void)seekToTime:(NSTimeInterval)time
{
    [self seekToTime:time completeHandler:^(BOOL finished) {
        ;
    }];
}

- (void)seekToTime:(NSTimeInterval)time completeHandler:(void (^)(BOOL))completeHandler
{
    if (!self.seekEnable || self.avPlayerItem.status != AVPlayerItemStatusReadyToPlay) {
        if (completeHandler) {
            completeHandler(NO);
        }
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.seeking = YES;
        [self startBuffering];
        
        __weak typeof(self) weakSelf = self;
        [self.avPlayerItem seekToTime:CMTimeMakeWithSeconds(time, NSEC_PER_SEC) completionHandler:^(BOOL finished) {
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong typeof(weakSelf) strongSelf = weakSelf;
                self.seeking = NO;
                [strongSelf stopBuffering];
                [strongSelf resumeStateAfterBuffering];
                if (completeHandler) {
                    completeHandler(finished);
                }
            });
        }];
    });
}

- (void)stop
{
    [self replaceEmpty];
}

- (NSTimeInterval)progress
{
    CMTime currentTime = self.avPlayerItem.currentTime;
    Boolean indefinite = CMTIME_IS_INDEFINITE(currentTime);
    Boolean invalid = CMTIME_IS_INVALID(currentTime);
    if (indefinite || invalid) {
        return 0;
    }
    return CMTimeGetSeconds(self.avPlayerItem.currentTime);
}

- (NSTimeInterval)duration
{
    CMTime duration = self.avPlayerItem.duration;
    Boolean indefinite = CMTIME_IS_INDEFINITE(duration);
    Boolean invalid = CMTIME_IS_INVALID(duration);
    if (indefinite || invalid) {
        return 0;
    }
    return CMTimeGetSeconds(self.avPlayerItem.duration);;
}

- (double)percentForTime:(NSTimeInterval)time duration:(NSTimeInterval)duration
{
    double percent = 0;
    if (time > 0) {
        if (duration <= 0) {
            percent = 1;
        } else {
            percent = time / duration;
        }
    }
    return percent;
}

- (NSTimeInterval)bitrate
{
    return 0;
}

#pragma mark - Setter/Getter

- (void)setState:(SYPlayerState)state
{
    if (_state != state) {
        SYPlayerState temp = _state;
        _state = state;
        switch (self.state) {
            case SYPlayerStateFinished:
                self.playing = NO;
                break;
            case SYPlayerStateFailed:
                self.playing = NO;
                break;
            default:
                break;
        }
        
        if (_state != SYPlayerStateFailed) {
            self.abstractPlayer.error = nil;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSDictionary * userInfo = @{ SYMediaPlayerPreviousNotificationKey : @(temp),
                                         SYMediaPlayerCurrentNotificationKey : @(state) };
            [[NSNotificationCenter defaultCenter] postNotificationName:SYMediaPlayerStateChangeNotification object:userInfo];
        });
    }
}

- (void)reloadVolume
{
    self.avPlayer.volume = self.abstractPlayer.volume;
}

- (void)reloadPlayableTime
{
    if (self.avPlayerItem.status == AVPlayerItemStatusReadyToPlay) {
        CMTimeRange range = [self.avPlayerItem.loadedTimeRanges.firstObject CMTimeRangeValue];
        if (CMTIMERANGE_IS_VALID(range)) {
            NSTimeInterval start = CMTimeGetSeconds(range.start);
            NSTimeInterval duration = CMTimeGetSeconds(range.duration);
            self.playableTime = (start + duration);
        }
    } else {
        self.playableTime = 0;
    }
}

- (void)setPlayableTime:(NSTimeInterval)playableTime
{
    if (_playableTime != playableTime) {
        _playableTime = playableTime;
        
        CGFloat duration = self.duration;
        double percent = [self percentForTime:playableTime duration:duration];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSDictionary * userInfo = @{ @"percent" : @(percent),
                                         SYMediaPlayerCurrentNotificationKey : @(playableTime),
                                         SYMediaPlayerTotalNotificationKey : @(duration) };
            [[NSNotificationCenter defaultCenter] postNotificationName:SYMediaPlayerPlayableChangeNotification object:userInfo];
        });
    }
}

- (CGSize)presentationSize
{
    if (self.avPlayerItem) {
        return self.avPlayerItem.presentationSize;
    }
    return CGSizeZero;
}


#pragma mark - SGAVPlayerOutput

- (AVPlayer *)playerOutputGetAVPlayer
{
    return self.avPlayer;
}

- (CVPixelBufferRef)playerOutputGetPixelBufferAtCurrentTime
{
    if (self.seeking) return nil;
    
    BOOL hasNewPixelBuffer = [self.avOutput hasNewPixelBufferForItemTime:self.avPlayerItem.currentTime];
    if (!hasNewPixelBuffer) {
        if (self.hasPixelBuffer) return nil;
        [self trySetupOutput];
        return nil;
    }
    
    CVPixelBufferRef pixelBuffer = [self.avOutput copyPixelBufferForItemTime:self.avPlayerItem.currentTime itemTimeForDisplay:nil];
    if (!pixelBuffer) {
        [self trySetupOutput];
    } else {
        self.hasPixelBuffer = YES;
    }
    return pixelBuffer;
}

- (UIImage *)playerOutputGetSnapshotAtCurrentTime
{
    switch (self.abstractPlayer.videoType) {
        case SYVideoTypeNormal:
        {
            AVAssetImageGenerator * imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:self.avAsset];
            imageGenerator.appliesPreferredTrackTransform = YES;
            imageGenerator.requestedTimeToleranceBefore = kCMTimeZero;
            imageGenerator.requestedTimeToleranceAfter = kCMTimeZero;
            
            NSError * error = nil;
            CMTime time = self.avPlayerItem.currentTime;
            CMTime actualTime;
            CGImageRef cgImage = [imageGenerator copyCGImageAtTime:time actualTime:&actualTime error:&error];
            UIImage * image = [UIImage imageWithCGImage:cgImage];
            CGImageRelease(cgImage);
            return image;
        }
            break;
        case SYVideoTypeVR:
        {
            return nil;
        }
            break;
    }
}


#pragma mark - play state change

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    if (object == self.avPlayerItem) {
        if ([keyPath isEqualToString:@"status"])
        {
            switch (self.avPlayerItem.status) {
                case AVPlayerItemStatusUnknown:
                {
                    [self startBuffering];
                }
                    break;
                case AVPlayerItemStatusReadyToPlay:
                {
                    [self stopBuffering];
                    [self setupTrackInfo];
                    
                    self.readyToPlayTime = [NSDate date].timeIntervalSince1970;
                    if (![self playIfNeed]) {
                        switch (self.state) {
                            case SYPlayerStateSuspend:
                            case SYPlayerStateFinished:
                            case SYPlayerStateFailed:
                                break;
                            default:
                                self.state = SYPlayerStateReadyToPlay;
                                break;
                        }
                    }
                }
                    break;
                case AVPlayerItemStatusFailed:
                {
                    [self stopBuffering];
                    
                    NSError * error;
                    self.readyToPlayTime = 0;
                    if (self.avPlayerItem.error) {
                        error = self.avPlayerItem.error;
                    }
                    else if (self.avPlayer.error) {
                        error = self.avPlayer.error;
                    }
                    else {
                        error = [NSError errorWithDomain:@"AVPlayer playback error" code:-1 userInfo:nil];
                    }
                    self.abstractPlayer.error = error;
                    self.state = SYPlayerStateFailed;
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSDictionary * userInfo = @{ SYMediaPlayerErrorNotificationKey : error };
                        [[NSNotificationCenter defaultCenter] postNotificationName:SYMediaPlayerErrorNotification object:userInfo];
                    });
                }
                    break;
            }
        }
        else if ([keyPath isEqualToString:@"playbackBufferEmpty"])
        {
            if (self.avPlayerItem.playbackBufferEmpty) {
                [self startBuffering];
            }
        }
        else if ([keyPath isEqualToString:@"loadedTimeRanges"])
        {
            [self reloadPlayableTime];
            
            NSTimeInterval residue = self.duration - self.progress;
            if (residue <= -1.5) {
                residue = 2;
            }
            
            NSTimeInterval interval = self.playableTime - self.progress;
            if (interval > self.abstractPlayer.playableBufferInterval) {
                [self stopBuffering];
                [self resumeStateAfterBuffering];
            }
            else if (interval < 0.3 && residue > 1.5) {
                [self startBuffering];
            }
        }
    }
}

- (void)avplayerItemDidPlayToEnd:(NSNotification *)notification
{
    self.state = SYPlayerStateFinished;
}

- (void)avAssetPrepareFailed:(NSError *)error
{
    NSLog(@"%s", __func__);
}

#pragma mark - replace video

- (void)replaceVideo
{
    [self replaceEmpty];
    
    if (!self.abstractPlayer.contentURL)
        return;
    
    [self.abstractPlayer.displayView playerOutputTypeAV];
    [self startBuffering];
    self.avAsset = [AVURLAsset assetWithURL:self.abstractPlayer.contentURL];
    switch (self.abstractPlayer.videoType) {
        case SYVideoTypeNormal:
            [self setupAVPlayerItemAutoLoadedAsset:YES];
            [self setupAVPlayer];
            [self.abstractPlayer.displayView rendererTypeAVPlayerLayer];
            break;
        case SYVideoTypeVR:
        {
            [self setupAVPlayerItemAutoLoadedAsset:NO];
            [self setupAVPlayer];
            [self.abstractPlayer.displayView rendererTypeOpenGL];
            
            __weak typeof(self) weakSelf = self;
            NSArray * keys =@[@"tracks", @"playable"];
            [self.avAsset loadValuesAsynchronouslyForKeys:keys completionHandler:^{
                __strong typeof(weakSelf) strongSelf = weakSelf;
                dispatch_async(dispatch_get_main_queue(), ^{
                    for (NSString * loadKey in keys) {
                        NSError * error = nil;
                        AVKeyValueStatus keyStatus = [strongSelf.avAsset statusOfValueForKey:loadKey error:&error];
                        if (keyStatus == AVKeyValueStatusFailed) {
                            [strongSelf avAssetPrepareFailed:error];
                            NSLog(@"AVAsset load failed");
                            return;
                        }
                    }
                    NSError * error = nil;
                    AVKeyValueStatus trackStatus = [strongSelf.avAsset statusOfValueForKey:@"tracks" error:&error];
                    if (trackStatus == AVKeyValueStatusLoaded) {
                        [strongSelf setupOutput];
                    } else {
                        NSLog(@"AVAsset load failed");
                    }
                });
            }];
        }
            break;
    }
}


#pragma mark - setup/clean

- (void)setupAVPlayer
{
    self.avPlayer = [AVPlayer playerWithPlayerItem:self.avPlayerItem];
    /*
    if ([UIDevice currentDevice].systemVersion.floatValue >= 10.0) {
        self.avPlayer.automaticallyWaitsToMinimizeStalling = NO;
    }
     */
    __weak typeof(self) weakSelf = self;
    self.playBackTimeObserver = [self.avPlayer addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf.state == SYPlayerStatePlaying) {
            CGFloat current = CMTimeGetSeconds(time);
            CGFloat duration = strongSelf.duration;
            double percent = [strongSelf percentForTime:current duration:duration];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                NSDictionary * userInfo = @{ SYMediaPlayerPercentNotificationKey : @(percent),
                                             SYMediaPlayerCurrentNotificationKey : @(current),
                                             SYMediaPlayerTotalNotificationKey : @(duration) };
                [[NSNotificationCenter defaultCenter] postNotificationName:SYMediaPlayerProgressChangeNotification object:userInfo];
            });
        }
    }];
    [self.abstractPlayer.displayView reloadPlayerConfig];
    [self reloadVolume];
}

- (void)cleanAVPlayer
{
    [self.avPlayer pause];
    [self.avPlayer cancelPendingPrerolls];
    [self.avPlayer replaceCurrentItemWithPlayerItem:nil];
    
    if (self.playBackTimeObserver) {
        [self.avPlayer removeTimeObserver:self.playBackTimeObserver];
        self.playBackTimeObserver = nil;
    }
    self.avPlayer = nil;
    [self.abstractPlayer.displayView reloadPlayerConfig];
}

- (void)setupAVPlayerItemAutoLoadedAsset:(BOOL)autoLoadedAsset
{
    if (autoLoadedAsset) {
        NSArray * keys =@[@"tracks", @"playable"];
        self.avPlayerItem = [AVPlayerItem playerItemWithAsset:self.avAsset automaticallyLoadedAssetKeys:keys];
    }
    else {
        self.avPlayerItem = [AVPlayerItem playerItemWithAsset:self.avAsset];
    }
    
    [self.avPlayerItem addObserver:self forKeyPath:@"status" options:0 context:NULL];
    [self.avPlayerItem addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew context:NULL];
    [self.avPlayerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:NULL];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(avplayerItemDidPlayToEnd:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification object:_avPlayerItem];
}

- (void)cleanAVPlayerItem
{
    if (self.avPlayerItem) {
        [self.avPlayerItem cancelPendingSeeks];
        [self.avPlayerItem removeObserver:self forKeyPath:@"status"];
        [self.avPlayerItem removeObserver:self forKeyPath:@"playbackBufferEmpty"];
        [self.avPlayerItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
        [self.avPlayerItem removeOutput:self.avOutput];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:self.avPlayerItem];
        self.avPlayerItem = nil;
    }
}

- (void)trySetupOutput
{
    BOOL isReadyToPlay = self.avPlayerItem.status == AVPlayerStatusReadyToPlay && self.readyToPlayTime > 10 && (([NSDate date].timeIntervalSince1970 - self.readyToPlayTime) > 0.3);
    if (isReadyToPlay) {
        [self setupOutput];
    }
}

- (void)setupOutput
{
    [self cleanOutput];
    
    NSDictionary * pixelBuffer = @{(id)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange)};
    self.avOutput = [[AVPlayerItemVideoOutput alloc] initWithPixelBufferAttributes:pixelBuffer];
    [self.avOutput requestNotificationOfMediaDataChangeWithAdvanceInterval:PixelBufferRequestInterval];
    [self.avPlayerItem addOutput:self.avOutput];
    
    NSLog(@"SGAVPlayer add output success");
}

- (void)cleanOutput
{
    if (self.avPlayerItem) {
        [self.avPlayerItem removeOutput:self.avOutput];
    }
    self.avOutput = nil;
    self.hasPixelBuffer = NO;
}

- (void)replaceEmpty
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSDictionary * userInfo1 = @{ SYMediaPlayerPercentNotificationKey : @(0),
                                      SYMediaPlayerCurrentNotificationKey : @(0),
                                      SYMediaPlayerTotalNotificationKey : @(0) };
        [[NSNotificationCenter defaultCenter] postNotificationName:SYMediaPlayerPlayableChangeNotification object:userInfo1];
        
        NSDictionary * userInfo2 = @{ SYMediaPlayerPercentNotificationKey : @(0),
                                      SYMediaPlayerCurrentNotificationKey : @(0),
                                      SYMediaPlayerTotalNotificationKey : @(0) };
        [[NSNotificationCenter defaultCenter] postNotificationName:SYMediaPlayerProgressChangeNotification object:userInfo2];
    });
    
    [self.avAsset cancelLoading];
    self.avAsset = nil;
    [self cleanOutput];
    [self cleanAVPlayerItem];
    [self cleanAVPlayer];
    [self cleanTrackInfo];
    self.state = SYPlayerStateNone;
    self.bufferingState = SYPlayerStateNone;
    self.seeking = NO;
    self.playableTime = 0;
    self.readyToPlayTime = 0;
    self.buffering = NO;
    self.playing = NO;
    [self.abstractPlayer.displayView playerOutputTypeEmpty];
    [self.abstractPlayer.displayView rendererTypeEmpty];
}

- (void)dealloc
{
    NSLog(@"SYAVPlayer dealloc");
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self replaceEmpty];
    [self cleanAVPlayer];
}


#pragma mark - track info

- (void)setupTrackInfo
{
    if (self.videoEnable || self.audioEnable) return;
    
    NSMutableArray <SYPlayerTrack *> * videoTracks = [NSMutableArray array];
    NSMutableArray <SYPlayerTrack *> * audioTracks = [NSMutableArray array];
    
    for (AVAssetTrack * obj in self.avAsset.tracks) {
        if ([obj.mediaType isEqualToString:AVMediaTypeVideo]) {
            self.videoEnable = YES;
            [videoTracks addObject:[self playerTrackFromAVTrack:obj]];
        } else if ([obj.mediaType isEqualToString:AVMediaTypeAudio]) {
            self.audioEnable = YES;
            [audioTracks addObject:[self playerTrackFromAVTrack:obj]];
        }
    }
    
    if (videoTracks.count > 0) {
        self.videoTracks = videoTracks;
        AVMediaSelectionGroup * videoGroup = [self.avAsset mediaSelectionGroupForMediaCharacteristic:AVMediaCharacteristicVisual];
        if (videoGroup) {
            int trackID = [[videoGroup.defaultOption.propertyList objectForKey:AVMediaSelectionOptionTrackIDKey] intValue];
            for (SYPlayerTrack * obj in self.audioTracks) {
                if (obj.index == (int)trackID) {
                    self.videoTrack = obj;
                }
            }
            if (!self.videoTrack) {
                self.videoTrack = self.videoTracks.firstObject;
            }
        } else {
            self.videoTrack = self.videoTracks.firstObject;
        }
    }
    if (audioTracks.count > 0) {
        self.audioTracks = audioTracks;
        AVMediaSelectionGroup * audioGroup = [self.avAsset mediaSelectionGroupForMediaCharacteristic:AVMediaCharacteristicAudible];
        if (audioGroup) {
            int trackID = [[audioGroup.defaultOption.propertyList objectForKey:AVMediaSelectionOptionTrackIDKey] intValue];
            for (SYPlayerTrack * obj in self.audioTracks) {
                if (obj.index == (int)trackID) {
                    self.audioTrack = obj;
                }
            }
            if (!self.audioTrack) {
                self.audioTrack = self.audioTracks.firstObject;
            }
        } else {
            self.audioTrack = self.audioTracks.firstObject;
        }
    }
}

- (void)cleanTrackInfo
{
    self.videoEnable = NO;
    self.videoTrack = nil;
    self.videoTracks = nil;
    
    self.audioEnable = NO;
    self.audioTrack = nil;
    self.audioTracks = nil;
}

- (void)selectAudioTrackIndex:(int)audioTrackIndex
{
    if (self.audioTrack.index == audioTrackIndex) return;
    AVMediaSelectionGroup * group = [self.avAsset mediaSelectionGroupForMediaCharacteristic:AVMediaCharacteristicAudible];
    if (group) {
        for (AVMediaSelectionOption * option in group.options) {
            int trackID = [[option.propertyList objectForKey:AVMediaSelectionOptionTrackIDKey] intValue];
            if (audioTrackIndex == trackID) {
                [self.avPlayerItem selectMediaOption:option inMediaSelectionGroup:group];
                for (SYPlayerTrack * track in self.audioTracks) {
                    if (track.index == audioTrackIndex) {
                        self.audioTrack = track;
                        break;
                    }
                }
                break;
            }
        }
    }
}

- (SYPlayerTrack *)playerTrackFromAVTrack:(AVAssetTrack *)track
{
    if (track) {
        SYPlayerTrack * obj = [[SYPlayerTrack alloc] init];
        obj.index = (int)track.trackID;
        obj.name = track.languageCode;
        return obj;
    }
    return nil;
}

@end
