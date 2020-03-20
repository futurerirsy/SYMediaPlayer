//
//  SYPlayerVideoFrame.h
//  SYMediaPlayer
//
//  Created by RYB_iMAC on 2020/3/17.
//  Copyright © 2020 RYB. All rights reserved.
//

#import "SYPlayerFrame.h"
#import <UIKit/UIKit.h>
#import <libavformat/avformat.h>
#import <AVFoundation/AVFoundation.h>

typedef NS_ENUM(int, SYPlayerYUVChannel) {
    SYPlayerYUVChannelLuma = 0,
    SYPlayerYUVChannelChromaB = 1,
    SYPlayerYUVChannelChromaR = 2,
    SYPlayerYUVChannelCount = 3,
};

typedef NS_ENUM(NSUInteger, SYPlayerVideoFrameRotateType) {
    SYPlayerVideoFrameRotateType0,
    SYPlayerVideoFrameRotateType90,
    SYPlayerVideoFrameRotateType180,
    SYPlayerVideoFrameRotateType270,
};


NS_ASSUME_NONNULL_BEGIN

@interface SYPlayerVideoFrame : SYPlayerFrame

@property (nonatomic, assign) SYPlayerVideoFrameRotateType rotateType;

@end


// FFmpeg AVFrame YUV frame
@interface SYPlayerAVYUVVideoFrame : SYPlayerVideoFrame
{
@public
    UInt8 * channel_pixels[SYPlayerYUVChannelCount];
}

@property (nonatomic, assign, readonly) int width;
@property (nonatomic, assign, readonly) int height;

+ (instancetype)videoFrame;

- (UIImage *)image;
- (void)setFrameData:(AVFrame *)frame width:(int)width height:(int)height;

@end


// CoreVideo YUV frame
@interface SYPlayerCVYUVVideoFrame : SYPlayerVideoFrame

@property (nonatomic, assign, readonly) CVPixelBufferRef pixelBuffer;

- (instancetype)initWithAVPixelBuffer:(CVPixelBufferRef)pixelBuffer;

@end

NS_ASSUME_NONNULL_END
