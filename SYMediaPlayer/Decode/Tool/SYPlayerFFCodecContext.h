//
//  SYPlayerFFCodecContext.h
//  SYMediaPlayer
//
//  Created by RYB_iMAC on 2020/3/18.
//  Copyright © 2020 RYB. All rights reserved.
//

#import <CoreGraphics/CoreGraphics.h>
#import <Foundation/Foundation.h>
#import "SYPlayerVideoFrame.h"
#import "SYPlayerFFTrack.h"

@class SYPlayerFFCodecContext;


NS_ASSUME_NONNULL_BEGIN

@protocol SYPlayerFFCodecContextDelegate <NSObject>

- (BOOL)formatContextNeedInterrupt:(SYPlayerFFCodecContext *)formatContext;

@end


@interface SYPlayerFFCodecContext : NSObject
{
@public
    AVFormatContext * _format_context;
    AVCodecContext * _video_codec_context;
    AVCodecContext * _audio_codec_context;
}

+ (instancetype)formatContextWithContentURL:(NSURL *)contentURL
                                   delegate:(id <SYPlayerFFCodecContextDelegate>)delegate;

@property (nonatomic, weak) id <SYPlayerFFCodecContextDelegate> delegate;

@property (nonatomic, copy, readonly) NSError * error;
@property (nonatomic, copy, readonly) NSDictionary * metadata;
@property (nonatomic, assign, readonly) NSTimeInterval bitrate;
@property (nonatomic, assign, readonly) NSTimeInterval duration;
@property (nonatomic, assign, readonly) BOOL videoEnable;
@property (nonatomic, assign, readonly) BOOL audioEnable;

@property (nonatomic, strong, readonly) SYPlayerFFTrack * videoTrack;
@property (nonatomic, strong, readonly) SYPlayerFFTrack * audioTrack;
@property (nonatomic, strong, readonly) NSArray <SYPlayerFFTrack *> * videoTracks;
@property (nonatomic, strong, readonly) NSArray <SYPlayerFFTrack *> * audioTracks;

@property (nonatomic, assign, readonly) NSTimeInterval videoTimebase;
@property (nonatomic, assign, readonly) NSTimeInterval videoFPS;
@property (nonatomic, assign, readonly) CGSize videoPresentationSize;
@property (nonatomic, assign, readonly) CGFloat videoAspect;
@property (nonatomic, assign, readonly) SYPlayerVideoFrameRotateType videoFrameRotateType;

@property (nonatomic, assign, readonly) NSTimeInterval audioTimebase;
@property (nonatomic, strong) NSDictionary * formatContextOptions;
@property (nonatomic, strong) NSDictionary * codecContextOptions;

- (void)setupSync;
- (void)destroy;

- (BOOL)seekEnable;
- (void)seekFileWithFFTimebase:(NSTimeInterval)time;

- (int)readFrame:(AVPacket *)packet;

- (BOOL)containAudioTrack:(int)audioTrackIndex;
- (NSError *)selectAudioTrackIndex:(int)audioTrackIndex;

@end

NS_ASSUME_NONNULL_END
