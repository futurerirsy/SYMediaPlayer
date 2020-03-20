//
//  SYFFDecoder.h
//  SYMediaPlayer
//
//  Created by RYB_iMAC on 2020/3/18.
//  Copyright © 2020 RYB. All rights reserved.
//

#import <CoreGraphics/CoreGraphics.h>
#import <Foundation/Foundation.h>
#import "SYPlayerAudioFrame.h"
#import "SYPlayerVideoFrame.h"
#import "SYPlayerFFTrack.h"

@class SYFFDecoder;


NS_ASSUME_NONNULL_BEGIN

//. Protocols
@protocol SYFFDecoderAudioOutput <NSObject>

- (SYPlayerAudioFrame *)decoderAudioOutputGetAudioFrame;

@end

@protocol SYFFDecoderAudioOutputConfig <NSObject>

- (Float64)decoderAudioOutputConfigGetSamplingRate;
- (UInt32)decoderAudioOutputConfigGetNumberOfChannels;

@end


@protocol SYFFDecoderVideoOutput <NSObject>

- (SYPlayerVideoFrame *)decoderVideoOutputGetVideoFrameWithCurrentPostion:(NSTimeInterval)currentPostion
                                                          currentDuration:(NSTimeInterval)currentDuration;

@end

@protocol SYFFDecoderVideoOutputConfig <NSObject>

- (void)decoderVideoOutputConfigDidUpdateMaxPreferredFramesPerSecond:(NSInteger)preferredFramesPerSecond;
- (BOOL)decoderVideoOutputConfigAVCodecContextDecodeAsync;

@end


//. delegate
@protocol SYFFDecoderDelegate <NSObject>

@optional
- (void)decoderWillOpenInputStream:(SYFFDecoder *)decoder;          // open input stream
- (void)decoderDidPrepareToDecodeFrames:(SYFFDecoder *)decoder;     // prepare decode frames
- (void)decoderDidEndOfFile:(SYFFDecoder *)decoder;                 // end of file
- (void)decoderDidPlaybackFinished:(SYFFDecoder *)decoder;          // play finish
- (void)decoder:(SYFFDecoder *)decoder didError:(NSError *)error;   // error callback

// value change
- (void)decoder:(SYFFDecoder *)decoder didChangeValueOfBuffering:(BOOL)buffering;
- (void)decoder:(SYFFDecoder *)decoder didChangeValueOfBufferedDuration:(NSTimeInterval)bufferedDuration;
- (void)decoder:(SYFFDecoder *)decoder didChangeValueOfProgress:(NSTimeInterval)progress;

@end


//. FFDecoder
@interface SYFFDecoder : NSObject <SYFFDecoderAudioOutput, SYFFDecoderVideoOutput>

+ (instancetype)decoderWithContentURL:(NSURL *)contentURL
                             delegate:(id <SYFFDecoderDelegate>)delegate
                    videoOutputConfig:(id <SYFFDecoderVideoOutputConfig>)videoOutputConfig
                    audioOutputConfig:(id <SYFFDecoderAudioOutputConfig>)audioOutputConfig;

@property (nonatomic, strong, readonly) NSError * error;
@property (nonatomic, copy, readonly) NSURL * contentURL;
@property (nonatomic, copy, readonly) NSDictionary * metadata;

@property (nonatomic, assign, readonly) CGFloat aspect;
@property (nonatomic, assign, readonly) CGSize presentationSize;
@property (nonatomic, assign, readonly) NSTimeInterval bitrate;
@property (nonatomic, assign, readonly) NSTimeInterval progress;
@property (nonatomic, assign, readonly) NSTimeInterval duration;
@property (nonatomic, assign, readonly) NSTimeInterval bufferedDuration;

@property (nonatomic, assign) NSTimeInterval minBufferedDruation;
@property (nonatomic, assign) BOOL hardwareAccelerateEnable;    // default is YES;
@property (nonatomic, assign) float rate;

@property (nonatomic, assign, readonly) BOOL buffering;
@property (nonatomic, assign, readonly) BOOL playbackFinished;
@property (atomic, assign, readonly) BOOL closed;
@property (atomic, assign, readonly) BOOL endOfFile;
@property (atomic, assign, readonly) BOOL paused;
@property (atomic, assign, readonly) BOOL seeking;
@property (atomic, assign, readonly) BOOL reading;
@property (atomic, assign, readonly) BOOL prepareToDecode;
@property (nonatomic, assign, readonly) BOOL videoDecodeOnMainThread;

@property (nonatomic, strong) NSDictionary * formatContextOptions;
@property (nonatomic, strong) NSDictionary * codecContextOptions;

- (void)pause;
- (void)resume;

@property (nonatomic, assign, readonly) BOOL seekEnable;
- (void)seekToTime:(NSTimeInterval)time;
- (void)seekToTime:(NSTimeInterval)time completeHandler:(void (^)(BOOL finished))completeHandler;

- (void)open;
- (void)closeFile;      // when release of active calls, or when called in dealloc might block the thread


#pragma mark - track info

@property (nonatomic, assign, readonly) BOOL videoEnable;
@property (nonatomic, assign, readonly) BOOL audioEnable;

@property (nonatomic, strong, readonly) SYPlayerFFTrack * videoTrack;
@property (nonatomic, strong, readonly) SYPlayerFFTrack * audioTrack;

@property (nonatomic, strong, readonly) NSArray <SYPlayerFFTrack *> * videoTracks;
@property (nonatomic, strong, readonly) NSArray <SYPlayerFFTrack *> * audioTracks;

- (void)selectAudioTrackIndex:(int)audioTrackIndex;

@end

NS_ASSUME_NONNULL_END
