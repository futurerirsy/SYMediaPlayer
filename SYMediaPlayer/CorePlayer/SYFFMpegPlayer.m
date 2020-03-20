//
//  SYFFMpegPlayer.m
//  SYMediaPlayer
//
//  Created by RYB_iMAC on 2020/3/17.
//  Copyright © 2020 RYB. All rights reserved.
//

#import "SYFFMpegPlayer.h"
#import "SYFFDecoder.h"
#import "SYMediaPlayer.h"
#import "SYPlayerAudioManager.h"


@interface SYFFMpegPlayer () <SYFFDecoderDelegate, SYFFDecoderVideoOutputConfig, SYFFDecoderAudioOutputConfig, SYPlayerAudioManagerDelegate>

@property (nonatomic, strong) NSLock * stateLock;
@property (nonatomic, strong) SYFFDecoder * decoder;
@property (nonatomic, strong) SYPlayerAudioManager * audioManager;
@property (nonatomic, weak) SYMediaPlayer * abstractPlayer;

@property (nonatomic, assign) BOOL playing;
@property (nonatomic, assign) BOOL prepareToken;
@property (nonatomic, assign) SYPlayerState state;
@property (nonatomic, assign) NSTimeInterval progress;
@property (nonatomic, assign) NSTimeInterval lastPostProgressTime;
@property (nonatomic, assign) NSTimeInterval lastPostPlayableTime;
@property (nonatomic, strong) SYPlayerAudioFrame * currentAudioFrame;

@end


@implementation SYFFMpegPlayer

+ (instancetype)playerWithAbstractPlayer:(id)abstractPlayer
{
    return [[self alloc] initWithAbstractPlayer:abstractPlayer];
}

- (instancetype)initWithAbstractPlayer:(id)abstractPlayer
{
    if (self = [super init]) {
        self.abstractPlayer = (SYMediaPlayer *)abstractPlayer;
        self.stateLock = [[NSLock alloc] init];
        self.abstractPlayer.displayView.playerOutputFF = self;
        self.audioManager = [[SYPlayerAudioManager alloc] init];
        self.audioManager.delegate = self;
    }
    return self;
}

- (void)play
{
    self.playing = YES;
    [self.decoder resume];
    
    switch (self.state) {
        case SYPlayerStateFinished:
            [self seekToTime:0];
            break;
        case SYPlayerStateNone:
        case SYPlayerStateFailed:
        case SYPlayerStateBuffering:
            self.state = SYPlayerStateBuffering;
            break;
        case SYPlayerStateSuspend:
            if (self.decoder.buffering) {
                self.state = SYPlayerStateBuffering;
            }
            else {
                self.state = SYPlayerStatePlaying;
            }
            break;
        case SYPlayerStateReadyToPlay:
        case SYPlayerStatePlaying:
            self.state = SYPlayerStatePlaying;
            break;
    }
}

- (void)pause
{
    self.playing = NO;
    [self.decoder pause];
    
    switch (self.state) {
        case SYPlayerStateNone:
        case SYPlayerStateSuspend:
            break;
        case SYPlayerStateFailed:
        case SYPlayerStateReadyToPlay:
        case SYPlayerStateFinished:
        case SYPlayerStatePlaying:
        case SYPlayerStateBuffering:
        {
            self.state = SYPlayerStateSuspend;
        }
            break;
    }
}

- (void)stop
{
    [self clean];
}

- (BOOL)seekEnable
{
    return self.decoder.seekEnable;
}

- (void)seekToTime:(NSTimeInterval)time
{
    [self seekToTime:time completeHandler:^(BOOL finished) {
        ;
    }];
}

- (void)seekToTime:(NSTimeInterval)time completeHandler:(void (^)(BOOL finished))completeHandler
{
    if (!self.decoder.prepareToDecode) {
        if (completeHandler) {
            completeHandler(NO);
        }
        return;
    }
    [self.decoder seekToTime:time completeHandler:completeHandler];
}

- (void)setRate:(float)rate
{
    _rate = rate;
    
    if (self.decoder) {
        self.decoder.rate = rate;
        self.audioManager.rate = rate;
    }
}

- (void)setState:(SYPlayerState)state
{
    [self.stateLock lock];
    
    if (_state != state) {
        SYPlayerState temp = _state;
        _state = state;
        
        if (_state != SYPlayerStateFailed) {
            self.abstractPlayer.error = nil;
        }
        
        if (_state == SYPlayerStatePlaying) {
            [self.audioManager play];
        }
        else {
            [self.audioManager pause];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSDictionary * userInfo = @{ SYMediaPlayerPreviousNotificationKey : @(temp),
                                         SYMediaPlayerCurrentNotificationKey : @(state) };
            [[NSNotificationCenter defaultCenter] postNotificationName:SYMediaPlayerStateChangeNotification object:userInfo];
        });
    }
    
    [self.stateLock unlock];
}

- (double)percentForTime:(NSTimeInterval)time duration:(NSTimeInterval)duration
{
    double percent = 0;
    if (time > 0) {
        if (duration <= 0) {
            percent = 1;
        }
        else {
            percent = time / duration;
        }
    }
    return percent;
}

- (void)setProgress:(NSTimeInterval)progress
{
    if (_progress != progress) {
        _progress = progress;
        NSTimeInterval duration = self.duration;
        double percent = [self percentForTime:_progress duration:duration];
        if (_progress <= 0.000001 || _progress == duration) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSDictionary * userInfo = @{ SYMediaPlayerPercentNotificationKey : @(percent),
                                             SYMediaPlayerCurrentNotificationKey : @(progress),
                                             SYMediaPlayerTotalNotificationKey : @(duration) };
                [[NSNotificationCenter defaultCenter] postNotificationName:SYMediaPlayerProgressChangeNotification object:userInfo];
            });
        }
        else {
            NSTimeInterval currentTime = [NSDate date].timeIntervalSince1970;
            if (currentTime - self.lastPostProgressTime >= 1) {
                self.lastPostProgressTime = currentTime;
                /*
                if (!self.decoder.seekEnable && duration <= 0) {
                    duration = _progress;
                }
                 */
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSDictionary * userInfo = @{ SYMediaPlayerPercentNotificationKey : @(percent),
                                                 SYMediaPlayerCurrentNotificationKey : @(progress),
                                                 SYMediaPlayerTotalNotificationKey : @(duration) };
                    [[NSNotificationCenter defaultCenter] postNotificationName:SYMediaPlayerProgressChangeNotification object:userInfo];
                });
            }
        }
    }
}

- (void)setPlayableTime:(NSTimeInterval)playableTime
{
    NSTimeInterval duration = self.duration;
    if (playableTime > duration) {
        playableTime = duration;
    }
    else if (playableTime < 0) {
        playableTime = 0;
    }
    
    if (_playableTime != playableTime) {
        _playableTime = playableTime;
        double percent = [self percentForTime:_playableTime duration:duration];
        if (_playableTime == 0 || _playableTime == duration) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSDictionary * userInfo = @{ SYMediaPlayerPercentNotificationKey : @(percent),
                                             SYMediaPlayerCurrentNotificationKey : @(playableTime),
                                             SYMediaPlayerTotalNotificationKey : @(duration) };
                [[NSNotificationCenter defaultCenter] postNotificationName:SYMediaPlayerPlayableChangeNotification object:userInfo];
            });
        }
        else if (!self.decoder.endOfFile && self.decoder.seekEnable) {
            NSTimeInterval currentTime = [NSDate date].timeIntervalSince1970;
            if (currentTime - self.lastPostPlayableTime >= 1) {
                self.lastPostPlayableTime = currentTime;
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSDictionary * userInfo = @{ SYMediaPlayerPercentNotificationKey : @(percent),
                                                 SYMediaPlayerCurrentNotificationKey : @(playableTime),
                                                 SYMediaPlayerTotalNotificationKey : @(duration) };
                    [[NSNotificationCenter defaultCenter] postNotificationName:SYMediaPlayerPlayableChangeNotification object:userInfo];
                });
            }
        }
    }
}

- (NSTimeInterval)duration
{
    return self.decoder.duration;
}

- (CGSize)presentationSize
{
    if (self.decoder.prepareToDecode) {
        return self.decoder.presentationSize;
    }
    return CGSizeZero;
}

- (NSTimeInterval)bitrate
{
    if (self.decoder.prepareToDecode) {
        return self.decoder.bitrate;
    }
    return 0;
}

- (BOOL)videoDecodeOnMainThread
{
    return self.decoder.videoDecodeOnMainThread;
}

- (void)reloadVolume
{
    self.audioManager.volume = self.abstractPlayer.volume;
}

- (void)reloadPlayableBufferInterval
{
    self.decoder.minBufferedDruation = self.abstractPlayer.playableBufferInterval;
}

- (void)replaceVideo
{
    [self clean];
    
    if (!self.abstractPlayer.contentURL)
        return;
    
    [self.abstractPlayer.displayView playerOutputTypeFF];
    self.decoder = [SYFFDecoder decoderWithContentURL:self.abstractPlayer.contentURL
                                             delegate:self videoOutputConfig:self audioOutputConfig:self];
    self.decoder.formatContextOptions = [self.abstractPlayer.decoder FFmpegFormatContextOptions];
    self.decoder.codecContextOptions = [self.abstractPlayer.decoder FFmpegCodecContextOptions];
    self.decoder.hardwareAccelerateEnable = self.abstractPlayer.decoder.hardwareAccelerateEnableForFFmpeg;
    self.decoder.rate = _rate;
    [self.decoder open];
    [self reloadVolume];
    [self reloadPlayableBufferInterval];
}

#pragma mark - SGFFDecoderDelegate

- (void)decoderWillOpenInputStream:(SYFFDecoder *)decoder
{
    self.state = SYPlayerStateBuffering;
}

- (void)decoderDidPrepareToDecodeFrames:(SYFFDecoder *)decoder
{
    if (self.decoder.videoEnable) {
        [self.abstractPlayer.displayView rendererTypeOpenGL];
    }
}

- (void)decoderDidEndOfFile:(SYFFDecoder *)decoder
{
    self.playableTime = self.duration;
}

- (void)decoderDidPlaybackFinished:(SYFFDecoder *)decoder
{
    self.state = SYPlayerStateFinished;
}

- (void)decoder:(SYFFDecoder *)decoder didChangeValueOfBuffering:(BOOL)buffering
{
    if (buffering) {
        self.state = SYPlayerStateBuffering;
    }
    else {
        if (self.playing) {
            self.state = SYPlayerStatePlaying;
        }
        else if (!self.prepareToken) {
            self.state = SYPlayerStateReadyToPlay;
            self.prepareToken = YES;
        }
        else {
            self.state = SYPlayerStateSuspend;
        }
    }
}

- (void)decoder:(SYFFDecoder *)decoder didChangeValueOfBufferedDuration:(NSTimeInterval)bufferedDuration
{
    self.playableTime = self.progress + bufferedDuration;
}

- (void)decoder:(SYFFDecoder *)decoder didChangeValueOfProgress:(NSTimeInterval)progress
{
    self.progress = progress;
}

- (void)decoder:(SYFFDecoder *)decoder didError:(NSError *)error
{
    [self errorHandler:error];
}

- (void)errorHandler:(NSError *)error
{
    self.abstractPlayer.error = error;
    self.state = SYPlayerStateFailed;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSDictionary * userInfo = @{ SYMediaPlayerErrorNotificationKey : error };
        [[NSNotificationCenter defaultCenter] postNotificationName:SYMediaPlayerErrorNotification object:userInfo];
    });
}

#pragma mark - clean

- (void)clean
{
    [self cleanDecoder];
    [self cleanFrame];
    [self cleanPlayer];
}

- (void)cleanPlayer
{
    self.playing = NO;
    self.state = SYPlayerStateNone;
    self.progress = 0;
    self.playableTime = 0;
    self.prepareToken = NO;
    self.lastPostProgressTime = 0;
    self.lastPostPlayableTime = 0;
    [self.abstractPlayer.displayView playerOutputTypeEmpty];
    [self.abstractPlayer.displayView rendererTypeEmpty];
}

- (void)cleanFrame
{
    [self.currentAudioFrame stopPlaying];
    self.currentAudioFrame = nil;
}

- (void)cleanDecoder
{
    if (self.decoder) {
        [self.decoder closeFile];
        self.decoder = nil;
    }
}

- (void)dealloc
{
    [self clean];
    
    if (self.audioManager) {
        [self.audioManager pause];
        self.audioManager = nil;
    }
    
    self.stateLock = nil;
    self.abstractPlayer = nil;
    
    NSLog(@"SYFFMpegPlayer dealloc");
}


#pragma mark - SGFFPlayerOutput

- (SYPlayerVideoFrame *)playerOutputGetVideoFrameWithCurrentPostion:(NSTimeInterval)currentPostion
                                                    currentDuration:(NSTimeInterval)currentDuration
{
    if (self.decoder) {
        return [self.decoder decoderVideoOutputGetVideoFrameWithCurrentPostion:currentPostion
                                                               currentDuration:currentDuration];
    }
    return nil;
}


#pragma mark - Video Config

- (void)decoderVideoOutputConfigDidUpdateMaxPreferredFramesPerSecond:(NSInteger)preferredFramesPerSecond
{
    
}

- (BOOL)decoderVideoOutputConfigAVCodecContextDecodeAsync
{
    if (self.abstractPlayer.videoType == SYVideoTypeVR) {
        return NO;
    }
    return YES;
}


#pragma mark - Audio Config

- (Float64)decoderAudioOutputConfigGetSamplingRate
{
    return self.audioManager.samplingRate;
}

- (UInt32)decoderAudioOutputConfigGetNumberOfChannels
{
    return self.audioManager.numberOfChannels;
}

- (void)audioManager:(SYPlayerAudioManager *)audioManager outputData:(float *)outputData
      numberOfFrames:(UInt32)numberOfFrames numberOfChannels:(UInt32)numberOfChannels
{
    if (!self.playing) {
        memset(outputData, 0, numberOfFrames * numberOfChannels * sizeof(float));
        return;
    }
    
    //. 음성프레임설정
    while (numberOfFrames > 0)
    {
        @autoreleasepool {
            if (!self.currentAudioFrame) {
                self.currentAudioFrame = [self.decoder decoderAudioOutputGetAudioFrame];
                [self.currentAudioFrame startPlaying];
            }
            if (!self.currentAudioFrame) {
                memset(outputData, 0, numberOfFrames * numberOfChannels * sizeof(float));
                return;
            }
            
            const Byte * bytes = (Byte *)self.currentAudioFrame->samples + self.currentAudioFrame->output_offset;
            const NSUInteger bytesLeft = self.currentAudioFrame->length - self.currentAudioFrame->output_offset;
            const NSUInteger frameSizeOf = numberOfChannels * sizeof(float);
            const NSUInteger bytesToCopy = MIN(numberOfFrames * frameSizeOf, bytesLeft);
            const NSUInteger framesToCopy = bytesToCopy / frameSizeOf;
            
            memcpy(outputData, bytes, bytesToCopy);
            numberOfFrames -= framesToCopy;
            outputData += framesToCopy * numberOfChannels;
            
            if (bytesToCopy < bytesLeft) {
                self.currentAudioFrame->output_offset += bytesToCopy;
            }
            else {
                [self.currentAudioFrame stopPlaying];
                self.currentAudioFrame = nil;
            }
        }
    }
    
    //. background play인 경우 음성에 맞추어 decode된 비데오프레임들을 queue에서 삭제
    if (self.abstractPlayer.backgroundMode && self.decoder) {
        if (self.currentAudioFrame.position > 1.f && self.currentAudioFrame.position < self.abstractPlayer.duration) {
            [self.decoder decoderVideoOutputGetVideoFrameWithCurrentPostion:self.currentAudioFrame.position
                                                            currentDuration:self.currentAudioFrame.duration];
        }
        else {
            [self.decoder decoderVideoOutputGetVideoFrameWithCurrentPostion:self.abstractPlayer.progress
                                                            currentDuration:0.f];
        }
    }
}


#pragma mark - Track Info

- (BOOL)videoEnable
{
    return self.decoder.videoEnable;
}

- (BOOL)audioEnable
{
    return self.decoder.audioEnable;
}

- (SYPlayerTrack *)videoTrack
{
    return [self playerTrackFromFFTrack:self.decoder.videoTrack];
}

- (SYPlayerTrack *)audioTrack
{
    return [self playerTrackFromFFTrack:self.decoder.audioTrack];
}

- (NSArray <SYPlayerTrack *> *)videoTracks
{
    return [self playerTracksFromFFTracks:self.decoder.videoTracks];
}

- (NSArray <SYPlayerTrack *> *)audioTracks
{
    return [self playerTracksFromFFTracks:self.decoder.audioTracks];;
}

- (void)selectAudioTrackIndex:(int)audioTrackIndex
{
    [self.decoder selectAudioTrackIndex:audioTrackIndex];
}

- (SYPlayerTrack *)playerTrackFromFFTrack:(SYPlayerFFTrack *)track
{
    if (track) {
        SYPlayerTrack * obj = [[SYPlayerTrack alloc] init];
        obj.index = track.index;
        obj.name = track.metadata.language;
        return obj;
    }
    return nil;
}

- (NSArray <SYPlayerTrack *> *)playerTracksFromFFTracks:(NSArray <SYPlayerFFTrack *> *)tracks
{
    NSMutableArray <SYPlayerTrack *> * array = [NSMutableArray array];
    for (SYPlayerFFTrack * obj in tracks) {
        SYPlayerTrack * track = [self playerTrackFromFFTrack:obj];
        [array addObject:track];
    }
    if (array.count > 0) {
        return array;
    }
    return nil;
}

@end
