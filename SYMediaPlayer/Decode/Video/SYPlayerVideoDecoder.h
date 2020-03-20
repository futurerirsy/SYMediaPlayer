//
//  SYPlayerVideoDecoder.h
//  SYMediaPlayer
//
//  Created by RYB_iMAC on 2020/3/17.
//  Copyright © 2020 RYB. All rights reserved.
//

#import <libavformat/avformat.h>
#import <Foundation/Foundation.h>
#import "SYPlayerVideoFrame.h"

@class SYPlayerVideoDecoder;

NS_ASSUME_NONNULL_BEGIN

@protocol SYPlayerVideoDecoderDlegate <NSObject>

- (void)videoDecoder:(SYPlayerVideoDecoder *)videoDecoder didError:(NSError *)error;
- (void)videoDecoder:(SYPlayerVideoDecoder *)videoDecoder didChangePreferredFramesPerSecond:(NSInteger)preferredFramesPerSecond;

@end


@interface SYPlayerVideoDecoder : NSObject

+ (instancetype)decoderWithCodecContext:(AVCodecContext *)codec_context
                               timebase:(NSTimeInterval)timebase
                                    fps:(NSTimeInterval)fps
                      codecContextAsync:(BOOL)codecContextAsync
                     videoToolBoxEnable:(BOOL)videoToolBoxEnable
                             rotateType:(SYPlayerVideoFrameRotateType)rotateType
                               delegate:(id <SYPlayerVideoDecoderDlegate>)delegate;

@property (nonatomic, weak) id <SYPlayerVideoDecoderDlegate> delegate;
@property (nonatomic, assign, readonly) SYPlayerVideoFrameRotateType rotateType;

@property (nonatomic, strong, readonly) NSError * error;
@property (nonatomic, assign, readonly) NSTimeInterval fps;
@property (nonatomic, assign, readonly) NSTimeInterval timebase;

@property (nonatomic, assign, readonly) BOOL videoToolBoxEnable;
@property (nonatomic, assign, readonly) BOOL videoToolBoxDidOpen;
@property (nonatomic, assign) NSInteger videoToolBoxMaxDecodeFrameCount;    // default is 20.

@property (nonatomic, assign, readonly) BOOL codecContextAsync;
@property (nonatomic, assign) NSInteger codecContextMaxDecodeFrameCount;    // default is 3.

@property (nonatomic, assign, readonly) BOOL decodeSync;
@property (nonatomic, assign, readonly) BOOL decodeAsync;
@property (nonatomic, assign, readonly) BOOL decodeOnMainThread;

@property (nonatomic, assign, readonly) int size;
@property (nonatomic, assign, readonly) BOOL empty;
@property (nonatomic, assign, readonly) NSTimeInterval duration;

@property (nonatomic, assign) float rate;
@property (nonatomic, assign) BOOL paused;
@property (nonatomic, assign) BOOL endOfFile;

- (SYPlayerVideoFrame *)getFrameAsync;
- (SYPlayerVideoFrame *)getFrameAsyncPosistion:(NSTimeInterval)position;
- (void)discardFrameBeforPosition:(NSTimeInterval)position;
- (NSTimeInterval)getFirstFramePositionAsync;

- (void)putPacket:(AVPacket)packet;
- (void)destroy;
- (void)flush;

- (void)startDecodeThread;

@end

NS_ASSUME_NONNULL_END
