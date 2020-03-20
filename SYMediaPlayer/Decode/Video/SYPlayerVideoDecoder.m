//
//  SYPlayerVideoDecoder.m
//  SYMediaPlayer
//
//  Created by RYB_iMAC on 2020/3/17.
//  Copyright © 2020 RYB. All rights reserved.
//

#import "SYPlayerVideoDecoder.h"
#import "SYPlayerFrameQueue.h"
#import "SYPlayerFramePool.h"
#import "SYPlayerVideoToolBox.h"
#import "SYPlayerVideoPacketQueue.h"
#import "SYPlayerFFTools.h"

static AVPacket flush_packet;


@interface SYPlayerVideoDecoder ()
{
    AVCodecContext * _codec_context;
    AVFrame * _temp_frame;
}

@property (nonatomic, assign) NSInteger preferredFramesPerSecond;
@property (nonatomic, assign) BOOL canceled;

@property (nonatomic, strong) SYPlayerVideoPacketQueue * packetQueue;
@property (nonatomic, strong) SYPlayerVideoToolBox * videoToolBox;
@property (nonatomic, strong) SYPlayerFrameQueue * frameQueue;
@property (nonatomic, strong) SYPlayerFramePool * framePool;

@end


@implementation SYPlayerVideoDecoder

+ (instancetype)decoderWithCodecContext:(AVCodecContext *)codec_context
                               timebase:(NSTimeInterval)timebase
                                    fps:(NSTimeInterval)fps
                      codecContextAsync:(BOOL)codecContextAsync
                     videoToolBoxEnable:(BOOL)videoToolBoxEnable
                             rotateType:(SYPlayerVideoFrameRotateType)rotateType
                               delegate:(id<SYPlayerVideoDecoderDlegate>)delegate
{
    return [[self alloc] initWithCodecContext:codec_context
                                     timebase:timebase
                                          fps:fps
                            codecContextAsync:codecContextAsync
                           videoToolBoxEnable:videoToolBoxEnable
                                   rotateType:rotateType
                                     delegate:delegate];
}

- (instancetype)initWithCodecContext:(AVCodecContext *)codec_context
                            timebase:(NSTimeInterval)timebase
                                 fps:(NSTimeInterval)fps
                   codecContextAsync:(BOOL)codecContextAsync
                  videoToolBoxEnable:(BOOL)videoToolBoxEnable
                          rotateType:(SYPlayerVideoFrameRotateType)rotateType
                            delegate:(id<SYPlayerVideoDecoderDlegate>)delegate
{
    if (self = [super init]) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            av_init_packet(&flush_packet);
            flush_packet.data = (uint8_t *)&flush_packet;
            flush_packet.duration = 0;
        });
        
        self.delegate = delegate;
        self->_codec_context = codec_context;
        self->_timebase = timebase;
        self->_rate = 1.f;
        self->_fps = fps;
        self->_codecContextAsync = codecContextAsync;
        self->_videoToolBoxEnable = videoToolBoxEnable;
        self->_rotateType = rotateType;
        
        [self setupCodecContext];
    }
    return self;
}

- (void)setupCodecContext
{
    self.preferredFramesPerSecond = 60;
    self->_temp_frame = av_frame_alloc();
    self.packetQueue = [SYPlayerVideoPacketQueue packetQueueWithTimebase:self.timebase];
    self.videoToolBoxMaxDecodeFrameCount = 20;
    self.codecContextMaxDecodeFrameCount = 3;
    
    if (self.videoToolBoxEnable && _codec_context->codec_id == AV_CODEC_ID_H264) {
        self.videoToolBox = [SYPlayerVideoToolBox videoToolBoxWithCodecContext:self->_codec_context];
        if ([self.videoToolBox trySetupVTSession]) {
            self->_videoToolBoxDidOpen = YES;
        }
        else {
            [self.videoToolBox flush];
            self.videoToolBox = nil;
        }
    }
    
    if (self.videoToolBoxDidOpen) {
        self.frameQueue = [SYPlayerFrameQueue frameQueue];
        self.frameQueue.minFrameCountForGet = 4;
        self->_decodeAsync = YES;
    }
    else if (self.codecContextAsync) {
        self.frameQueue = [SYPlayerFrameQueue frameQueue];
        self.framePool = [SYPlayerFramePool videoPool];
        self->_decodeAsync = YES;
    }
    else {
        self.framePool = [SYPlayerFramePool videoPool];
        self->_decodeSync = YES;
        self->_decodeOnMainThread = YES;
    }
}

- (SYPlayerVideoFrame *)getFrameAsync
{
    if (self.videoToolBoxDidOpen || self.codecContextAsync) {
        return [self.frameQueue getFrameAsync];
    }
    else {
        return [self codecContextDecodeSync];
    }
}

- (SYPlayerVideoFrame *)getFrameAsyncPosistion:(NSTimeInterval)position
{
    if (self.videoToolBoxDidOpen || self.codecContextAsync) {
        NSMutableArray <SYPlayerFrame *> * discardFrames = nil;
        SYPlayerVideoFrame * videoFrame = [self.frameQueue getFrameAsyncPosistion:position discardFrames:&discardFrames];
        for (SYPlayerVideoFrame * obj in discardFrames) {
            [obj cancel];
        }
        return videoFrame;
    }
    else {
        return [self codecContextDecodeSync];
    }
}

- (void)discardFrameBeforPosition:(NSTimeInterval)position
{
    if (self.videoToolBoxDidOpen || self.codecContextAsync) {
        NSMutableArray <SYPlayerFrame *> * discardFrames = [self.frameQueue discardFrameBeforPosition:position];
        for (SYPlayerVideoFrame * obj in discardFrames) {
            [obj cancel];
        }
    }
}

- (NSTimeInterval)getFirstFramePositionAsync
{
    return [self.frameQueue getFirstFramePositionAsync];
}

- (void)putPacket:(AVPacket)packet
{
    NSTimeInterval duration = 0;
    if (packet.duration <= 0 && packet.size > 0 && packet.data != flush_packet.data) {
        duration = 1.0 / self.fps;
    }
    [self.packetQueue putPacket:packet duration:duration];
}


#pragma mark - start decode thread

- (void)startDecodeThread
{
    if (self.videoToolBoxDidOpen) {
        [self videoToolBoxDecodeAsyncThread];
    }
    else if (self.codecContextAsync) {
        [self codecContextDecodeAsyncThread];
    }
}

- (NSError *)checkResultCode:(int)result errorCode:(NSUInteger)errorCode
{
    if (result < 0) {
        char * error_string_buffer = malloc(256);
        av_strerror(result, error_string_buffer, 256);
        NSString * error_string = [NSString stringWithFormat:@"ffmpeg code : %d, ffmpeg msg : %s", result, error_string_buffer];
        NSError * error = [NSError errorWithDomain:error_string code:errorCode userInfo:nil];
        return error;
    }
    return nil;
}


#pragma mark - FFmpeg

- (void)codecContextDecodeAsyncThread
{
    while (YES) {
        @autoreleasepool {
            if (!self.codecContextAsync) {
                break;
            }
            if (self.canceled || self.error) {
//                NSLog(@"decode video thread quit");
                break;
            }
            if (self.endOfFile && self.packetQueue.count <= 0) {
//                NSLog(@"decode video finished");
                break;
            }
            if (self.paused) {
//                NSLog(@"decode video thread pause sleep");
                [NSThread sleepForTimeInterval:0.03f];
                continue;
            }
            if (self.frameQueue.count >= self.codecContextMaxDecodeFrameCount) {
//                NSLog(@"decode video thread sleep");
                [NSThread sleepForTimeInterval:0.03f];
                continue;
            }
            
            AVPacket packet = [self.packetQueue getPacketSync];
            if (packet.data == flush_packet.data) {
//                NSLog(@"video codec flush");
                avcodec_flush_buffers(_codec_context);
                [self.frameQueue flush];
                continue;
            }
            if (packet.stream_index < 0 || packet.data == NULL)
                continue;
            
            SYPlayerVideoFrame * videoFrame = nil;
            int result = avcodec_send_packet(_codec_context, &packet);
            if (result < 0) {
                if (result != AVERROR(EAGAIN) && result != AVERROR_EOF) {
                    self->_error = SYPlayerCheckError(result);
                    [self delegateErrorCallback];
                }
            }
            else {
                while (result >= 0) {
                    result = avcodec_receive_frame(_codec_context, _temp_frame);
                    if (result < 0) {
                        if (result != AVERROR(EAGAIN) && result != AVERROR_EOF) {
                            self->_error = SYPlayerCheckError(result);
                            [self delegateErrorCallback];
                        }
                    }
                    else {
                        videoFrame = [self videoFrameFromTempFrame:packet.size];
                        if (videoFrame) {
                            [self.frameQueue putSortFrame:videoFrame];
                        }
                    }
                }
            }
            av_packet_unref(&packet);
        }
    }
}

- (SYPlayerVideoFrame *)codecContextDecodeSync
{
    if (self.canceled || self.error) {
        return nil;
    }
    if (self.paused) {
        return nil;
    }
    if (self.endOfFile && self.packetQueue.count <= 0) {
        return nil;
    }
    
    AVPacket packet = [self.packetQueue getPacketAsync];
    if (packet.data == flush_packet.data) {
        avcodec_flush_buffers(_codec_context);
        return nil;
    }
    if (packet.stream_index < 0 || packet.data == NULL) {
        return nil;
    }
    
    SYPlayerVideoFrame * videoFrame = nil;
    int result = avcodec_send_packet(_codec_context, &packet);
    if (result < 0) {
        if (result != AVERROR(EAGAIN) && result != AVERROR_EOF) {
            self->_error = SYPlayerCheckError(result);
            [self delegateErrorCallback];
        }
    }
    else {
        while (result >= 0) {
            @autoreleasepool {
                result = avcodec_receive_frame(_codec_context, _temp_frame);
                if (result < 0) {
                    if (result != AVERROR(EAGAIN) && result != AVERROR_EOF) {
                        self->_error = SYPlayerCheckError(result);
                        [self delegateErrorCallback];
                    }
                }
                else {
                    videoFrame = [self videoFrameFromTempFrame:packet.size];
                }
            }
        }
    }
    av_packet_unref(&packet);
    
    return videoFrame;
}

- (SYPlayerAVYUVVideoFrame *)videoFrameFromTempFrame:(int)packetSize
{
    if (!_temp_frame->data[0] || !_temp_frame->data[1] || !_temp_frame->data[2])
        return nil;
    
    SYPlayerAVYUVVideoFrame * videoFrame = [self.framePool getUnuseFrame];
    videoFrame.rotateType = self.rotateType;
    
    [videoFrame setFrameData:_temp_frame width:_codec_context->width height:_codec_context->height];
    videoFrame.position = _temp_frame->best_effort_timestamp * self.timebase;
    videoFrame.packetSize = packetSize;
    
    const int64_t frame_duration = _temp_frame->pkt_duration;
    if (frame_duration) {
        videoFrame.duration = frame_duration * self.timebase;
        videoFrame.duration += _temp_frame->repeat_pict * self.timebase * 0.5 * self.rate;
    }
    else {
        videoFrame.duration = self.rate * 1.0 / self.fps;
    }
    
    return videoFrame;
}


#pragma mark - VideoToolBox

- (void)videoToolBoxDecodeAsyncThread
{
    while (YES) {
        @autoreleasepool {
            if (!self.videoToolBoxDidOpen) {
                break;
            }
            if (self.canceled || self.error) {
//                NSLog(@"decode video thread quit");
                break;
            }
            if (self.endOfFile && self.packetQueue.count <= 0) {
//                NSLog(@"decode video finished");
                break;
            }
            if (self.paused) {
//                NSLog(@"decode video thread pause background sleep");
                [NSThread sleepForTimeInterval:0.01f];
                continue;
            }
            if (self.frameQueue.count >= self.videoToolBoxMaxDecodeFrameCount) {
//                NSLog(@"decode video thread sleep");
                [NSThread sleepForTimeInterval:0.03f];
                continue;
            }
            
            AVPacket packet = [self.packetQueue getPacketSync];
            if (packet.data == flush_packet.data) {
//                NSLog(@"video codec flush");
                [self.frameQueue flush];
                [self.videoToolBox flush];
                continue;
            }
            if (packet.stream_index < 0 || packet.data == NULL)
                continue;
            
            SYPlayerVideoFrame * videoFrame = nil;
            BOOL vtbEnable = [self.videoToolBox trySetupVTSession];
            if (vtbEnable) {
                BOOL needFlush = NO;
                BOOL result = [self.videoToolBox sendPacket:packet needFlush:&needFlush];
                if (result) {
                    videoFrame = [self videoFrameFromVideoToolBox:packet];
                }
                else if (needFlush) {
                    [self.videoToolBox flush];
                    BOOL result2 = [self.videoToolBox sendPacket:packet needFlush:&needFlush];
                    if (result2) {
                        videoFrame = [self videoFrameFromVideoToolBox:packet];
                    }
                }
            }
            if (videoFrame) {
                [self.frameQueue putSortFrame:videoFrame];
            }
            av_packet_unref(&packet);
        }
    }
    self.frameQueue.ignoreMinFrameCountForGetLimit = YES;
}

- (SYPlayerVideoFrame *)videoFrameFromVideoToolBox:(AVPacket)packet
{
    CVImageBufferRef imageBuffer = [self.videoToolBox imageBuffer];
    if (imageBuffer == NULL)
        return nil;
    
    SYPlayerCVYUVVideoFrame * videoFrame = [[SYPlayerCVYUVVideoFrame alloc] initWithAVPixelBuffer:imageBuffer];
    videoFrame.rotateType = self.rotateType;
    
    if (packet.pts != AV_NOPTS_VALUE) {
        videoFrame.position = packet.pts * self.timebase;
    }
    else {
        videoFrame.position = packet.dts;
    }
    videoFrame.packetSize = packet.size;
    
    const int64_t frame_duration = packet.duration;
    if (frame_duration) {
        videoFrame.duration = frame_duration * self.timebase * self.rate;
    }
    else {
        videoFrame.duration = self.rate * 1.0 / self.fps;
    }
    
    return videoFrame;
}

- (void)setPreferredFramesPerSecond:(NSInteger)preferredFramesPerSecond
{
    if (_preferredFramesPerSecond != preferredFramesPerSecond) {
        _preferredFramesPerSecond = preferredFramesPerSecond;
        [self.delegate videoDecoder:self didChangePreferredFramesPerSecond:_preferredFramesPerSecond];
    }
}

- (int)size
{
    if (self.videoToolBoxDidOpen || self.codecContextAsync) {
        return self.packetQueue.size + self.frameQueue.packetSize;
    }
    else {
        return self.packetQueue.size;
    }
}

- (BOOL)empty
{
    if (self.videoToolBoxDidOpen || self.codecContextAsync) {
        return self.packetQueue.count <= 0 && self.frameQueue.count <= 0;
    }
    else {
        return self.packetQueue.count <= 0;
    }
}

- (NSTimeInterval)duration
{
    if (self.videoToolBoxDidOpen || self.codecContextAsync) {
        return self.packetQueue.duration + self.frameQueue.duration;
    }
    else {
        return self.packetQueue.duration;
    }
}

- (void)delegateErrorCallback
{
    if (self.error) {
        [self.delegate videoDecoder:self didError:self.error];
    }
}

- (void)flush
{
    [self.packetQueue flush];
    [self.frameQueue flush];
    [self.framePool flush];
    [self putPacket:flush_packet];
}

- (void)destroy
{
    self.canceled = YES;
    
    [self.frameQueue destroy];
    [self.packetQueue destroy];
    [self.framePool flush];
}

- (void)dealloc
{
    if (_temp_frame) {
        av_free(_temp_frame);
        _temp_frame = NULL;
    }
    NSLog(@"Video decoder dealloc");
}

@end
