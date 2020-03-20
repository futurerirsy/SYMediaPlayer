//
//  SYMediaPlayer.h
//  SYMediaPlayer
//
//  Created by RYB_iMAC on 2020/3/15.
//  Copyright © 2020 RYB. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "SYPlayerDecoder.h"
#import "SYPlayerRenderingView.h"


NS_ASSUME_NONNULL_BEGIN

@interface SYMediaPlayer : NSObject

+ (instancetype)player;

@property (nonatomic, strong) SYPlayerDecoder * decoder;        // default is [SGPlayerDecoder defaultDecoder]
@property (nonatomic, copy, readonly) NSURL * contentURL;
@property (nonatomic, assign, readonly) SYVideoType videoType;
@property (nonatomic, strong, nullable) NSError * error;

- (void)replaceVideoWithURL:(nullable NSURL *)contentURL;
- (void)replaceVideoWithURL:(nullable NSURL *)contentURL videoType:(SYVideoType)videoType;

// preview
@property (nonatomic, assign) BOOL backgroundMode;
@property (nonatomic, assign) BOOL viewAnimationHidden;         // default is YES;
@property (nonatomic, assign) SYDisplayMode displayMode;        // default is SYDisplayModeNormal;
@property (nonatomic, assign) SYGravityMode viewGravityMode;    // default is SYGravityModeResizeAspect;
@property (nonatomic, strong) SYPlayerRenderingView * displayView;
@property (nonatomic, copy) void (^viewTapAction)(SYMediaPlayer * player, SYPlayerRenderingView * view);
- (UIImage *)snapshot;

// control
@property (nonatomic, assign, readonly) SYPlayerState state;
@property (nonatomic, assign, readonly) CGSize presentationSize;
@property (nonatomic, assign, readonly) NSTimeInterval bitrate;
@property (nonatomic, assign, readonly) NSTimeInterval progress;
@property (nonatomic, assign, readonly) NSTimeInterval duration;
@property (nonatomic, assign, readonly) NSTimeInterval playableTime;

@property (nonatomic, assign) NSTimeInterval playableBufferInterval;    // default is 2s
@property (nonatomic, assign) CGFloat volume;   // default is 1
@property (nonatomic, assign) float rate;       // default is 1

- (void)play;
- (void)pause;
- (void)stop;

@property (nonatomic, assign, readonly) BOOL seekEnable;
@property (nonatomic, assign, readonly) BOOL seeking;

- (void)seekToTime:(NSTimeInterval)time;
- (void)seekToTime:(NSTimeInterval)time completeHandler:(nullable void(^)(BOOL finished))completeHandler;

@end


#pragma mark - Tracks Category

@interface SYMediaPlayer (Tracks)

@property (nonatomic, assign, readonly) BOOL videoEnable;
@property (nonatomic, assign, readonly) BOOL audioEnable;

@property (nonatomic, strong, readonly) SYPlayerTrack * videoTrack;
@property (nonatomic, strong, readonly) SYPlayerTrack * audioTrack;

@property (nonatomic, strong, readonly) NSArray <SYPlayerTrack *> * videoTracks;
@property (nonatomic, strong, readonly) NSArray <SYPlayerTrack *> * audioTracks;

- (void)selectAudioTrack:(SYPlayerTrack *)audioTrack;
- (void)selectAudioTrackIndex:(int)audioTrackIndex;

@end


#pragma mark - Thread Category

@interface SYMediaPlayer (Thread)

@property (nonatomic, assign, readonly) BOOL videoDecodeOnMainThread;
@property (nonatomic, assign, readonly) BOOL audioDecodeOnMainThread;

@end

NS_ASSUME_NONNULL_END
