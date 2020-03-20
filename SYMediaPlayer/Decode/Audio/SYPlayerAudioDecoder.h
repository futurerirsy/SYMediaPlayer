//
//  SYPlayerAudioDecoder.h
//  SYMediaPlayer
//
//  Created by RYB_iMAC on 2020/3/17.
//  Copyright © 2020 RYB. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <libavformat/avformat.h>
#import "SYPlayerAudioFrame.h"

@class SYPlayerAudioDecoder;


NS_ASSUME_NONNULL_BEGIN

@protocol SYPlayerAudioDecoderDelegate <NSObject>

- (void)audioDecoder:(SYPlayerAudioDecoder *)audioDecoder samplingRate:(Float64 *)samplingRate;
- (void)audioDecoder:(SYPlayerAudioDecoder *)audioDecoder channelCount:(UInt32 *)channelCount;

@end


@interface SYPlayerAudioDecoder : NSObject

+ (instancetype)decoderWithCodecContext:(AVCodecContext *)codec_context
                               timebase:(NSTimeInterval)timebase
                               delegate:(id <SYPlayerAudioDecoderDelegate>)delegate;

@property (nonatomic, weak) id <SYPlayerAudioDecoderDelegate> delegate;

@property (nonatomic, assign) float rate;
@property (nonatomic, assign, readonly) int size;
@property (nonatomic, assign, readonly) BOOL empty;
@property (nonatomic, assign, readonly) NSTimeInterval duration;

- (SYPlayerAudioFrame *)getFrameSync;
- (int)putPacket:(AVPacket)packet;

- (void)flush;
- (void)destroy;

@end

NS_ASSUME_NONNULL_END
