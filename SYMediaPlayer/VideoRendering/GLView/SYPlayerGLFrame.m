//
//  SYPlayerGLFrame.m
//  SYMediaPlayer
//
//  Created by RYB_iMAC on 2020/3/17.
//  Copyright © 2020 RYB. All rights reserved.
//

#import "SYPlayerGLFrame.h"


@interface SYPlayerGLFrame ()

@property (nonatomic, assign) CVPixelBufferRef pixelBuffer;
@property (nonatomic, strong) SYPlayerVideoFrame * videoFrame;

@end


@implementation SYPlayerGLFrame

+ (instancetype)frame
{
    return [[self alloc] init];
}

- (void)updateWithCVPixelBuffer:(CVPixelBufferRef)pixelBuffer;
{
    [self flush];
    
    self->_type = SYPlayerGLFrameTypeNV12;
    self.pixelBuffer = pixelBuffer;
    
    self->_hasData = YES;
    self->_hasUpate = YES;
}

- (CVPixelBufferRef)pixelBufferForNV12
{
    if (self.pixelBuffer) {
        return self.pixelBuffer;
    }
    else {
        return [(SYPlayerCVYUVVideoFrame *)self.videoFrame pixelBuffer];
    }
    return nil;
}

- (void)updateWithSYPlayerVideoFrame:(SYPlayerVideoFrame *)videoFrame;
{
    [self flush];
    
    self.videoFrame = videoFrame;
    if ([videoFrame isKindOfClass:[SYPlayerCVYUVVideoFrame class]]) {
        self->_type = SYPlayerGLFrameTypeNV12;
    }
    else {
        self->_type = SYPlayerGLFrameTypeYUV420;
    }
    [self.videoFrame startPlaying];
    
    self->_hasData = YES;
    self->_hasUpate = YES;
}

- (SYPlayerAVYUVVideoFrame *)pixelBufferForYUV420
{
    return (SYPlayerAVYUVVideoFrame *)self.videoFrame;
}

- (void)setRotateType:(SYPlayerVideoFrameRotateType)rotateType
{
    if (_rotateType != rotateType) {
        _rotateType = rotateType;
        self->_hasUpdateRotateType = YES;
    }
}

- (NSTimeInterval)currentPosition
{
    if (self.videoFrame) {
        return self.videoFrame.position;
    }
    return -1;
}

- (NSTimeInterval)currentDuration
{
    if (self.videoFrame) {
        return self.videoFrame.duration;
    }
    return -1;
}

- (UIImage *)imageFromVideoFrame
{
    if ([self.videoFrame isKindOfClass:[SYPlayerAVYUVVideoFrame class]]) {
        SYPlayerAVYUVVideoFrame * frame = (SYPlayerAVYUVVideoFrame *)self.videoFrame;
        return frame.image;
    }
    else if ([self.videoFrame isKindOfClass:[SYPlayerCVYUVVideoFrame class]]) {
        SYPlayerCVYUVVideoFrame * frame = (SYPlayerCVYUVVideoFrame *)self.videoFrame;
        if (frame.pixelBuffer) {
            CIImage * ciImage = [CIImage imageWithCVPixelBuffer:frame.pixelBuffer];
            if (!ciImage)
                return nil;
            
            return [UIImage imageWithCIImage:ciImage];
        }
    }
    return nil;
}

- (void)didDraw
{
    self->_hasUpate = NO;
}

- (void)didUpdateRotateType
{
    self->_hasUpdateRotateType = NO;
}

- (void)flush
{
    self->_hasData = NO;
    self->_hasUpate = NO;
    self->_hasUpdateRotateType = NO;
    if (self.pixelBuffer) {
        CVPixelBufferRelease(self.pixelBuffer);
        self.pixelBuffer = NULL;
    }
    
    if (self.videoFrame) {
        [self.videoFrame stopPlaying];
        self.videoFrame = nil;
    }
}

- (void)dealloc
{
    [self flush];
}
@end
