//
//  SYAVPlayer.h
//  SYMediaPlayer
//
//  Created by RYB_iMAC on 2020/3/17.
//  Copyright © 2020 RYB. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "ParamsDefine.h"
#import "SYPlayerTrack.h"


NS_ASSUME_NONNULL_BEGIN

@protocol SYAVPlayerOutput <NSObject>

- (AVPlayer *)playerOutputGetAVPlayer;
- (CVPixelBufferRef)playerOutputGetPixelBufferAtCurrentTime;
- (UIImage *)playerOutputGetSnapshotAtCurrentTime;

@end


@interface SYAVPlayer : NSObject <SYAVPlayerOutput>

+ (instancetype)playerWithAbstractPlayer:(id)abstractPlayer;

@property (nonatomic, strong, readonly) AVPlayer * avPlayer;
@property (nonatomic, assign, readonly) SYPlayerState state;
@property (nonatomic, assign, readonly) CGSize presentationSize;
@property (nonatomic, assign, readonly) NSTimeInterval bitrate;
@property (nonatomic, assign, readonly) NSTimeInterval progress;
@property (nonatomic, assign, readonly) NSTimeInterval duration;
@property (nonatomic, assign, readonly) NSTimeInterval playableTime;
@property (nonatomic, assign, readonly) BOOL seeking;

- (void)replaceVideo;
- (void)reloadVolume;

- (void)play;
- (void)pause;
- (void)stop;

@property (nonatomic, assign, readonly) BOOL seekEnable;
- (void)seekToTime:(NSTimeInterval)time;
- (void)seekToTime:(NSTimeInterval)time completeHandler:(void(^)(BOOL finished))completeHandler;


#pragma mark - track info

@property (nonatomic, assign, readonly) BOOL videoEnable;
@property (nonatomic, assign, readonly) BOOL audioEnable;

@property (nonatomic, strong, readonly) SYPlayerTrack * videoTrack;
@property (nonatomic, strong, readonly) SYPlayerTrack * audioTrack;

@property (nonatomic, strong, readonly) NSArray <SYPlayerTrack *> * videoTracks;
@property (nonatomic, strong, readonly) NSArray <SYPlayerTrack *> * audioTracks;

- (void)selectAudioTrackIndex:(int)audioTrackIndex;

@end

NS_ASSUME_NONNULL_END
