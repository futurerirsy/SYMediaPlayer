//
//  SYPlayerFFCodecContext.m
//  SYMediaPlayer
//
//  Created by RYB_iMAC on 2020/3/18.
//  Copyright © 2020 RYB. All rights reserved.
//

#import "SYPlayerFFCodecContext.h"
#import "SYPlayerFFTools.h"

static int ffmpeg_interrupt_callback(void *ctx)
{
    SYPlayerFFCodecContext * obj = (__bridge SYPlayerFFCodecContext *)ctx;
    return [obj.delegate formatContextNeedInterrupt:obj];
}


@interface SYPlayerFFCodecContext ()

@property (nonatomic, copy) NSError * error;
@property (nonatomic, copy) NSURL * contentURL;
@property (nonatomic, copy) NSDictionary * metadata;
@property (nonatomic, assign) BOOL videoEnable;
@property (nonatomic, assign) BOOL audioEnable;

@property (nonatomic, strong) SYPlayerFFTrack * videoTrack;
@property (nonatomic, strong) SYPlayerFFTrack * audioTrack;
@property (nonatomic, strong) NSArray <SYPlayerFFTrack *> * videoTracks;
@property (nonatomic, strong) NSArray <SYPlayerFFTrack *> * audioTracks;

@property (nonatomic, assign) NSTimeInterval audioTimebase;
@property (nonatomic, assign) NSTimeInterval videoTimebase;
@property (nonatomic, assign) NSTimeInterval videoFPS;
@property (nonatomic, assign) CGFloat videoAspect;
@property (nonatomic, assign) CGSize videoPresentationSize;

@end


@implementation SYPlayerFFCodecContext

+ (instancetype)formatContextWithContentURL:(NSURL *)contentURL
                                   delegate:(id<SYPlayerFFCodecContextDelegate>)delegate
{
    return [[self alloc] initWithContentURL:contentURL delegate:delegate];
}

- (instancetype)initWithContentURL:(NSURL *)contentURL
                          delegate:(id<SYPlayerFFCodecContextDelegate>)delegate
{
    if (self = [super init])
    {
        self.contentURL = contentURL;
        self.delegate = delegate;
    }
    return self;
}

- (void)setupSync
{
    self.error = [self openStream];
    if (self.error)
    {
        return;
    }
    
    [self openTracks];
    
    NSError * videoError = [self openVideoTrack];
    NSError * audioError = [self openAutioTrack];
    
    if (videoError && audioError)
    {
        if (videoError.code == SYPlayerDecoderErrorCodeStreamNotFound && audioError.code != SYPlayerDecoderErrorCodeStreamNotFound)
        {
            self.error = audioError;
        }
        else
        {
            self.error = videoError;
        }
        return;
    }
}

- (NSError *)openStream
{
    NSError * error = nil;
    
    self->_format_context = avformat_alloc_context();
    if (!_format_context)
    {
        error = [NSError errorWithDomain:@"SYPlayerDecoderErrorCodeFormatCreate error" code:SYPlayerDecoderErrorCodeFormatCreate userInfo:nil];
        return error;
    }
    
    _format_context->interrupt_callback.callback = ffmpeg_interrupt_callback;
    _format_context->interrupt_callback.opaque = (__bridge void *)self;
    
    AVDictionary * options = SYPlayerFFmpegBrigeOfNSDictionary(self.formatContextOptions);
    
    // options filter.
    NSString * URLString = [self contentURLString];
    NSString * lowercaseURLString = [URLString lowercaseString];
    if ([lowercaseURLString hasPrefix:@"rtmp"] || [lowercaseURLString hasPrefix:@"rtsp"]) {
        av_dict_set(&options, "timeout", NULL, 0);
    }
    
    int reslut = avformat_open_input(&_format_context, URLString.UTF8String, NULL, &options);
    if (options) {
        av_dict_free(&options);
    }
    
    error = SYPlayerCheckErrorCode(reslut, SYPlayerDecoderErrorCodeFormatOpenInput);
    if (error || !_format_context)
    {
        if (_format_context)
        {
            avformat_free_context(_format_context);
        }
        return error;
    }
    
    reslut = avformat_find_stream_info(_format_context, NULL);
    error = SYPlayerCheckErrorCode(reslut, SYPlayerDecoderErrorCodeFormatFindStreamInfo);
    if (error || !_format_context)
    {
        if (_format_context)
        {
            avformat_close_input(&_format_context);
        }
        return error;
    }
    
    self.metadata = SYPlayerFoundationBrigeOfAVDictionary(_format_context->metadata);
    
    return error;
}

- (void)openTracks
{
    NSMutableArray <SYPlayerFFTrack *> * videoTracks = [NSMutableArray array];
    NSMutableArray <SYPlayerFFTrack *> * audioTracks = [NSMutableArray array];
    
    for (int i = 0; i < _format_context->nb_streams; i++)
    {
        AVStream * stream = _format_context->streams[i];
        switch (stream->codecpar->codec_type)
        {
            case AVMEDIA_TYPE_VIDEO:
            {
                SYPlayerFFTrack * track = [[SYPlayerFFTrack alloc] init];
                track.type = SYPlayerFFTrackTypeVideo;
                track.index = i;
                track.metadata = [SYPlayerFFMetadata metadataWithAVDictionary:stream->metadata];
                [videoTracks addObject:track];
            }
                break;
            case AVMEDIA_TYPE_AUDIO:
            {
                SYPlayerFFTrack * track = [[SYPlayerFFTrack alloc] init];
                track.type = SYPlayerFFTrackTypeAudio;
                track.index = i;
                track.metadata = [SYPlayerFFMetadata metadataWithAVDictionary:stream->metadata];
                [audioTracks addObject:track];
            }
                break;
            default:
                break;
        }
    }
    
    if (videoTracks.count > 0)
    {
        self.videoTracks = videoTracks;
    }
    if (audioTracks.count > 0)
    {
        self.audioTracks = audioTracks;
    }
}

- (NSError *)openVideoTrack
{
    NSError * error = nil;
    
    if (self.videoTracks.count > 0)
    {
        for (SYPlayerFFTrack * obj in self.videoTracks)
        {
            int index = obj.index;
            if ((_format_context->streams[index]->disposition & AV_DISPOSITION_ATTACHED_PIC) == 0)
            {
                AVCodecContext * codec_context;
                error = [self openStreamWithTrackIndex:index codecContext:&codec_context domain:@"video"];
                if (!error)
                {
                    self.videoTrack = obj;
                    self.videoEnable = YES;
                    self.videoTimebase = SYPlayerStreamGetTimebase(_format_context->streams[index], 0.00004);
                    self.videoFPS = SYPlayerStreamGetFPS(_format_context->streams[index], self.videoTimebase);
                    self.videoPresentationSize = CGSizeMake(codec_context->width, codec_context->height);
                    self.videoAspect = (CGFloat)codec_context->width / (CGFloat)codec_context->height;
                    self->_video_codec_context = codec_context;
                    break;
                }
            }
        }
    }
    else
    {
        error = [NSError errorWithDomain:@"video stream not found" code:SYPlayerDecoderErrorCodeStreamNotFound userInfo:nil];
        return error;
    }
    
    return error;
}

- (NSError *)openAutioTrack
{
    NSError * error = nil;
    
    if (self.audioTracks.count > 0)
    {
        for (SYPlayerFFTrack * obj in self.audioTracks)
        {
            int index = obj.index;
            AVCodecContext * codec_context;
            error = [self openStreamWithTrackIndex:index codecContext:&codec_context domain:@"audio"];
            if (!error)
            {
                self.audioTrack = obj;
                self.audioEnable = YES;
                self.audioTimebase = SYPlayerStreamGetTimebase(_format_context->streams[index], 0.000025);
                self->_audio_codec_context = codec_context;
                break;
            }
        }
    }
    else
    {
        error = [NSError errorWithDomain:@"audio stream not found" code:SYPlayerDecoderErrorCodeStreamNotFound userInfo:nil];
        return error;
    }
    
    return error;
}

- (NSError *)openStreamWithTrackIndex:(int)trackIndex codecContext:(AVCodecContext **)codecContext domain:(NSString *)domain
{
    int result = 0;
    NSError * error = nil;
    
    AVStream * stream = _format_context->streams[trackIndex];
    AVCodec * codec = avcodec_find_decoder(stream->codecpar->codec_id);
    if (!codec) {
        error = [NSError errorWithDomain:[NSString stringWithFormat:@"%@ codec not found decoder", domain]
                                    code:SYPlayerDecoderErrorCodeCodecFindDecoder
                                userInfo:nil];
        return error;
    }
    
    AVCodecContext *codec_context = avcodec_alloc_context3(codec);
    if (!codec_context)
    {
        error = [NSError errorWithDomain:[NSString stringWithFormat:@"%@ codec context create error", domain]
                                    code:SYPlayerDecoderErrorCodeCodecContextCreate
                                userInfo:nil];
        return error;
    }
    
    result = avcodec_parameters_to_context(codec_context, stream->codecpar);
    error = SYPlayerCheckErrorCode(result, SYPlayerDecoderErrorCodeCodecContextSetParam);
    if (error)
    {
        avcodec_free_context(&codec_context);
        return error;
    }
    
    codec_context->pkt_timebase = stream->time_base;
    codec_context->codec_id = codec->id;
    
    AVDictionary * options = SYPlayerFFmpegBrigeOfNSDictionary(self.codecContextOptions);
    if (!av_dict_get(options, "threads", NULL, 0)) {
        av_dict_set(&options, "threads", "auto", 0);
    }
    if (codec_context->codec_type == AVMEDIA_TYPE_VIDEO || codec_context->codec_type == AVMEDIA_TYPE_AUDIO) {
        av_dict_set(&options, "refcounted_frames", "1", 0);
    }
    
    result = avcodec_open2(codec_context, codec, &options);
    error = SYPlayerCheckErrorCode(result, SYPlayerDecoderErrorCodeCodecOpen2);
    if (error)
    {
        avcodec_free_context(&codec_context);
        return error;
    }
    
    *codecContext = codec_context;
    return error;
}

- (void)seekFileWithFFTimebase:(NSTimeInterval)time
{
    int64_t ts = (int64_t)(time * AV_TIME_BASE);
    av_seek_frame(self->_format_context, -1, ts, AVSEEK_FLAG_BACKWARD);
}

- (void)seekFileWithVideo:(NSTimeInterval)time
{
    if (self.videoEnable)
    {
        int64_t ts = (int64_t)(time * 1000.0 / self.videoTimebase);
        av_seek_frame(self->_format_context, -1, ts, AVSEEK_FLAG_BACKWARD);
    }
    else
    {
        [self seekFileWithFFTimebase:time];
    }
}

- (void)seekFileWithAudio:(NSTimeInterval)time
{
    if (self.audioTimebase > 0.f)
    {
        int64_t ts = (int64_t)(time * 1000 / self.audioTimebase);
        av_seek_frame(self->_format_context, -1, ts, AVSEEK_FLAG_BACKWARD);
    }
    else
    {
        [self seekFileWithFFTimebase:time];
    }
}

- (int)readFrame:(AVPacket *)packet
{
    return av_read_frame(self->_format_context, packet);
}

- (BOOL)containAudioTrack:(int)audioTrackIndex
{
    for (SYPlayerFFTrack * obj in self.audioTracks) {
        if (obj.index == audioTrackIndex) {
            return YES;
        }
    }
    
    return NO;
}

- (NSError * )selectAudioTrackIndex:(int)audioTrackIndex
{
    if (audioTrackIndex == self.audioTrack.index)
        return nil;
    if (![self containAudioTrack:audioTrackIndex])
        return nil;
    
    AVCodecContext * codec_context;
    NSError * error = [self openStreamWithTrackIndex:audioTrackIndex codecContext:&codec_context domain:@"audio select"];
    if (!error)
    {
        if (_audio_codec_context)
        {
            avcodec_close(_audio_codec_context);
            _audio_codec_context = NULL;
        }
        for (SYPlayerFFTrack * obj in self.audioTracks)
        {
            if (obj.index == audioTrackIndex)
            {
                self.audioTrack = obj;
            }
        }
        self.audioEnable = YES;
        self.audioTimebase = SYPlayerStreamGetTimebase(_format_context->streams[audioTrackIndex], 0.000025);
        self->_audio_codec_context = codec_context;
    }
    else
    {
        NSLog(@"select audio track error : %@", error);
    }
    
    return error;
}

- (NSTimeInterval)duration
{
    if (!self->_format_context)
        return 0;
    
    int64_t duration = self->_format_context->duration;
    if (duration < 0) {
        return 0;
    }
    
    return (NSTimeInterval)duration / AV_TIME_BASE;
}

- (BOOL)seekEnable
{
    if (!self->_format_context)
        return NO;
    
    BOOL ioSeekAble = YES;
    if (self->_format_context->pb) {
        ioSeekAble = self->_format_context->pb->seekable;
    }
    if (ioSeekAble && self.duration > 0) {
        return YES;
    }
    
    return NO;
}

- (NSTimeInterval)bitrate
{
    if (!self->_format_context)
        return 0;
    
    return (self->_format_context->bit_rate / 1000.0f);
}

- (NSString *)contentURLString
{
    if ([self.contentURL isFileURL])
    {
        return [self.contentURL path];
    }
    else
    {
        return [self.contentURL absoluteString];
    }
}

- (SYPlayerVideoFrameRotateType)videoFrameRotateType
{
    int rotate = [[self.videoTrack.metadata.metadata objectForKey:@"rotate"] intValue];
    if (rotate == 90) {
        return SYPlayerVideoFrameRotateType90;
    }
    else if (rotate == 180) {
        return SYPlayerVideoFrameRotateType180;
    }
    else if (rotate == 270) {
        return SYPlayerVideoFrameRotateType270;
    }
    return SYPlayerVideoFrameRotateType0;
}

- (void)destroyAudioTrack
{
    self.audioEnable = NO;
    self.audioTrack = nil;
    self.audioTracks = nil;
    
    if (_audio_codec_context)
    {
        avcodec_close(_audio_codec_context);
        _audio_codec_context = NULL;
    }
}

- (void)destroyVideoTrack
{
    self.videoEnable = NO;
    self.videoTrack = nil;
    self.videoTracks = nil;
    
    if (_video_codec_context)
    {
        avcodec_close(_video_codec_context);
        _video_codec_context = NULL;
    }
}

- (void)destroy
{
    [self destroyVideoTrack];
    [self destroyAudioTrack];
    
    if (_format_context)
    {
        avformat_close_input(&_format_context);
        _format_context = NULL;
    }
}

- (void)dealloc
{
    [self destroy];
}

@end
