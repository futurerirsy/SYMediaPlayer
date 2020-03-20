//
//  SYPlayerVideoFrame.m
//  SYMediaPlayer
//
//  Created by RYB_iMAC on 2020/3/17.
//  Copyright © 2020 RYB. All rights reserved.
//

#import "SYPlayerVideoFrame.h"
#import "SYPlayerYUVTool.h"


////////////////////////////
//. SYPlayerVideoFrame
////////////////////////////
@implementation SYPlayerVideoFrame

- (SYPlayerFrameType)type
{
    return SYPlayerFrameTypeVideo;
}

@end


////////////////////////////
//. SYPlayerAVYUVVideoFrame
////////////////////////////
@interface SYPlayerAVYUVVideoFrame ()
{
    enum AVPixelFormat pixelFormat;
    int channel_lenghts[SYPlayerYUVChannelCount];
    int channel_linesize[SYPlayerYUVChannelCount];
    size_t channel_pixels_buffer_size[SYPlayerYUVChannelCount];
}

@property (nonatomic, strong) NSLock * lock;

@end


@implementation SYPlayerAVYUVVideoFrame

- (SYPlayerFrameType)type
{
    return SYPlayerFrameTypeAVYUVVideo;
}

+ (instancetype)videoFrame
{
    return [[self alloc] init];
}

- (instancetype)init
{
    if (self = [super init]) {
        channel_lenghts[SYPlayerYUVChannelLuma] = 0;
        channel_lenghts[SYPlayerYUVChannelChromaB] = 0;
        channel_lenghts[SYPlayerYUVChannelChromaR] = 0;
        
        channel_pixels_buffer_size[SYPlayerYUVChannelLuma] = 0;
        channel_pixels_buffer_size[SYPlayerYUVChannelChromaB] = 0;
        channel_pixels_buffer_size[SYPlayerYUVChannelChromaR] = 0;
        
        channel_linesize[SYPlayerYUVChannelLuma] = 0;
        channel_linesize[SYPlayerYUVChannelChromaB] = 0;
        channel_linesize[SYPlayerYUVChannelChromaR] = 0;
        
        channel_pixels[SYPlayerYUVChannelLuma] = NULL;
        channel_pixels[SYPlayerYUVChannelChromaB] = NULL;
        channel_pixels[SYPlayerYUVChannelChromaR] = NULL;
        
        self.lock = [[NSLock alloc] init];
    }
    
    return self;
}

- (void)dealloc
{
    if (channel_pixels[SYPlayerYUVChannelLuma] != NULL && channel_pixels_buffer_size[SYPlayerYUVChannelLuma] > 0) {
        free(channel_pixels[SYPlayerYUVChannelLuma]);
    }
    
    if (channel_pixels[SYPlayerYUVChannelChromaB] != NULL && channel_pixels_buffer_size[SYPlayerYUVChannelChromaB] > 0) {
        free(channel_pixels[SYPlayerYUVChannelChromaB]);
    }
    
    if (channel_pixels[SYPlayerYUVChannelChromaR] != NULL && channel_pixels_buffer_size[SYPlayerYUVChannelChromaR] > 0) {
        free(channel_pixels[SYPlayerYUVChannelChromaR]);
    }
}


- (UIImage *)image
{
    [self.lock lock];
    UIImage * image = SYPlayerYUVConvertToImage(channel_pixels, channel_linesize, self.width, self.height, pixelFormat);
    [self.lock unlock];
    return image;
}

- (int)size
{
    return (int)(channel_lenghts[SYPlayerYUVChannelLuma]
                 + channel_lenghts[SYPlayerYUVChannelChromaB]
                 + channel_lenghts[SYPlayerYUVChannelChromaR]);
}

- (void)setFrameData:(AVFrame *)frame width:(int)width height:(int)height
{
    pixelFormat = frame->format;
    
    self->_width = width;
    self->_height = height;
    
    int linesize_y = frame->linesize[SYPlayerYUVChannelLuma];
    int linesize_u = frame->linesize[SYPlayerYUVChannelChromaB];
    int linesize_v = frame->linesize[SYPlayerYUVChannelChromaR];
    
    channel_linesize[SYPlayerYUVChannelLuma] = linesize_y;
    channel_linesize[SYPlayerYUVChannelChromaB] = linesize_u;
    channel_linesize[SYPlayerYUVChannelChromaR] = linesize_v;
    
    UInt8 * buffer_y = channel_pixels[SYPlayerYUVChannelLuma];
    UInt8 * buffer_u = channel_pixels[SYPlayerYUVChannelChromaB];
    UInt8 * buffer_v = channel_pixels[SYPlayerYUVChannelChromaR];
    
    size_t buffer_size_y = channel_pixels_buffer_size[SYPlayerYUVChannelLuma];
    size_t buffer_size_u = channel_pixels_buffer_size[SYPlayerYUVChannelChromaB];
    size_t buffer_size_v = channel_pixels_buffer_size[SYPlayerYUVChannelChromaR];
    
    int need_size_y = MIN(linesize_y, width) * height * 1;
    channel_lenghts[SYPlayerYUVChannelLuma] = need_size_y;
    if (buffer_size_y < need_size_y) {
        if (buffer_size_y > 0 && buffer_y != NULL) {
            free(buffer_y);
        }
        channel_pixels_buffer_size[SYPlayerYUVChannelLuma] = need_size_y;
        channel_pixels[SYPlayerYUVChannelLuma] = malloc(need_size_y);
    }
    
    int need_size_u = MIN(linesize_u, (width / 2)) * (height / 2) * 1;
    channel_lenghts[SYPlayerYUVChannelChromaB] = need_size_u;
    if (buffer_size_u < need_size_u) {
        if (buffer_size_u > 0 && buffer_u != NULL) {
            free(buffer_u);
        }
        channel_pixels_buffer_size[SYPlayerYUVChannelChromaB] = need_size_u;
        channel_pixels[SYPlayerYUVChannelChromaB] = malloc(need_size_u);
    }
    
    int need_size_v = MIN(linesize_v, (width / 2)) * (height / 2) * 1;
    channel_lenghts[SYPlayerYUVChannelChromaR] = need_size_v;
    if (buffer_size_v < need_size_v) {
        if (buffer_size_v > 0 && buffer_v != NULL) {
            free(buffer_v);
        }
        channel_pixels_buffer_size[SYPlayerYUVChannelChromaR] = need_size_v;
        channel_pixels[SYPlayerYUVChannelChromaR] = malloc(need_size_v);
    }
    
    SYPlayerYUVChannelFilter(frame->data[SYPlayerYUVChannelLuma],
                             linesize_y, width, height,
                             channel_pixels[SYPlayerYUVChannelLuma],
                             channel_pixels_buffer_size[SYPlayerYUVChannelLuma], 1);
    SYPlayerYUVChannelFilter(frame->data[SYPlayerYUVChannelChromaB],
                             linesize_u, width / 2, height / 2,
                             channel_pixels[SYPlayerYUVChannelChromaB],
                             channel_pixels_buffer_size[SYPlayerYUVChannelChromaB], 1);
    SYPlayerYUVChannelFilter(frame->data[SYPlayerYUVChannelChromaR],
                             linesize_v, width / 2, height / 2,
                             channel_pixels[SYPlayerYUVChannelChromaR],
                             channel_pixels_buffer_size[SYPlayerYUVChannelChromaR], 1);
}

- (void)flush
{
    self->_width = 0;
    self->_height = 0;
    
    channel_lenghts[SYPlayerYUVChannelLuma] = 0;
    channel_lenghts[SYPlayerYUVChannelChromaB] = 0;
    channel_lenghts[SYPlayerYUVChannelChromaR] = 0;
    channel_linesize[SYPlayerYUVChannelLuma] = 0;
    channel_linesize[SYPlayerYUVChannelChromaB] = 0;
    channel_linesize[SYPlayerYUVChannelChromaR] = 0;
    
    if (channel_pixels[SYPlayerYUVChannelLuma] != NULL && channel_pixels_buffer_size[SYPlayerYUVChannelLuma] > 0) {
        memset(channel_pixels[SYPlayerYUVChannelLuma], 0, channel_pixels_buffer_size[SYPlayerYUVChannelLuma]);
    }
    if (channel_pixels[SYPlayerYUVChannelChromaB] != NULL && channel_pixels_buffer_size[SYPlayerYUVChannelChromaB] > 0) {
        memset(channel_pixels[SYPlayerYUVChannelChromaB], 0, channel_pixels_buffer_size[SYPlayerYUVChannelChromaB]);
    }
    if (channel_pixels[SYPlayerYUVChannelChromaR] != NULL && channel_pixels_buffer_size[SYPlayerYUVChannelChromaR] > 0) {
        memset(channel_pixels[SYPlayerYUVChannelChromaR], 0, channel_pixels_buffer_size[SYPlayerYUVChannelChromaR]);
    }
}

- (void)stopPlaying
{
    [self.lock lock];
    [super stopPlaying];
    [self.lock unlock];
}

@end


////////////////////////////
//. SYPlayerAVYUVVideoFrame
////////////////////////////
@implementation SYPlayerCVYUVVideoFrame

- (SYPlayerFrameType)type
{
    return SYPlayerFrameTypeCVYUVVideo;
}

- (instancetype)initWithAVPixelBuffer:(CVPixelBufferRef)pixelBuffer
{
    if (self = [super init]) {
        self->_pixelBuffer = pixelBuffer;
    }
    return self;
}

- (void)dealloc
{
    if (self->_pixelBuffer) {
        CVPixelBufferRelease(self->_pixelBuffer);
        self->_pixelBuffer = NULL;
    }
}

@end
