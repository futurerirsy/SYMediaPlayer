//
//  SYPlayerGLFrame.h
//  SYMediaPlayer
//
//  Created by RYB_iMAC on 2020/3/17.
//  Copyright © 2020 RYB. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "SYPlayerVideoFrame.h"

typedef NS_ENUM(NSUInteger, SYPlayerGLFrameType) {
    SYPlayerGLFrameTypeNV12,
    SYPlayerGLFrameTypeYUV420,
};


NS_ASSUME_NONNULL_BEGIN

@interface SYPlayerGLFrame : NSObject

+ (instancetype)frame;

@property (nonatomic, assign, readonly) SYPlayerGLFrameType type;

@property (nonatomic, assign, readonly) BOOL hasData;
@property (nonatomic, assign, readonly) BOOL hasUpate;
@property (nonatomic, assign, readonly) BOOL hasUpdateRotateType;

- (void)didDraw;
- (void)didUpdateRotateType;
- (void)flush;

- (void)updateWithCVPixelBuffer:(CVPixelBufferRef)pixelBuffer;
- (CVPixelBufferRef)pixelBufferForNV12;

//. FFmpeg_Enable
@property (nonatomic, assign) SYPlayerVideoFrameRotateType rotateType;
- (void)updateWithSYPlayerVideoFrame:(SYPlayerVideoFrame *)videoFrame;
- (SYPlayerAVYUVVideoFrame *)pixelBufferForYUV420;

//.
- (NSTimeInterval)currentPosition;
- (NSTimeInterval)currentDuration;

- (UIImage *)imageFromVideoFrame;

@end

NS_ASSUME_NONNULL_END
