//
//  SYPlayerDecoder.m
//  SYMediaPlayer
//
//  Created by RYB_iMAC on 2020/3/17.
//  Copyright © 2020 RYB. All rights reserved.
//

#import "SYPlayerDecoder.h"


@interface SYPlayerDecoder ()

@property (nonatomic, strong) NSMutableDictionary * formatContextOptions;
@property (nonatomic, strong) NSMutableDictionary * codecContextOptions;

@end


@implementation SYPlayerDecoder

+ (instancetype)decoderByDefault
{
    SYPlayerDecoder * decoder = [[self alloc] init];
    decoder.decodeTypeForUnknown   = SYDecoderTypeFFmpeg;
    decoder.decodeTypeForMP3       = SYDecoderTypeAVPlayer;
    decoder.decodeTypeForMPEG4     = SYDecoderTypeAVPlayer;
    decoder.decodeTypeForMOV       = SYDecoderTypeAVPlayer;
    decoder.decodeTypeForFLV       = SYDecoderTypeFFmpeg;
    decoder.decodeTypeForM3U8      = SYDecoderTypeAVPlayer;
    decoder.decodeTypeForRTMP      = SYDecoderTypeFFmpeg;
    decoder.decodeTypeForRTSP      = SYDecoderTypeFFmpeg;
    return decoder;
}

+ (instancetype)decoderByAVPlayer
{
    SYPlayerDecoder * decoder = [[self alloc] init];
    decoder.decodeTypeForUnknown   = SYDecoderTypeAVPlayer;
    decoder.decodeTypeForMP3       = SYDecoderTypeAVPlayer;
    decoder.decodeTypeForMPEG4     = SYDecoderTypeAVPlayer;
    decoder.decodeTypeForMOV       = SYDecoderTypeAVPlayer;
    decoder.decodeTypeForFLV       = SYDecoderTypeAVPlayer;
    decoder.decodeTypeForM3U8      = SYDecoderTypeAVPlayer;
    decoder.decodeTypeForRTMP      = SYDecoderTypeAVPlayer;
    decoder.decodeTypeForRTSP      = SYDecoderTypeAVPlayer;
    return decoder;
}

+ (instancetype)decoderByFFmpeg
{
    SYPlayerDecoder * decoder = [[self alloc] init];
    decoder.decodeTypeForUnknown   = SYDecoderTypeFFmpeg;
    decoder.decodeTypeForMP3       = SYDecoderTypeFFmpeg;
    decoder.decodeTypeForMPEG4     = SYDecoderTypeFFmpeg;
    decoder.decodeTypeForMOV       = SYDecoderTypeFFmpeg;
    decoder.decodeTypeForFLV       = SYDecoderTypeFFmpeg;
    decoder.decodeTypeForM3U8      = SYDecoderTypeFFmpeg;
    decoder.decodeTypeForRTMP      = SYDecoderTypeFFmpeg;
    decoder.decodeTypeForRTSP      = SYDecoderTypeFFmpeg;
    return decoder;
}

- (instancetype)init
{
    if (self = [super init]) {
        self.hardwareAccelerateEnableForFFmpeg = YES;
        [self configFFmpegOptions];
    }
    return self;
}

- (SYMediaFormat)mediaFormatForContentURL:(NSURL *)contentURL
{
    if (!contentURL)
        return SYMediaFormatError;
    
    NSString * path;
    if (contentURL.isFileURL) {
        path = contentURL.path;
    }
    else {
        path = contentURL.absoluteString;
    }
    path = [path lowercaseString];
    
    //.
    if ([path hasPrefix:@"rtmp:"])
    {
        return SYMediaFormatRTMP;
    }
    else if ([path hasPrefix:@"rtsp:"])
    {
        return SYMediaFormatRTSP;
    }
    else if ([path containsString:@".flv"])
    {
        return SYMediaFormatFLV;
    }
    else if ([path containsString:@".mp4"])
    {
        return SYMediaFormatMPEG4;
    }
    else if ([path containsString:@".mp3"])
    {
        return SYMediaFormatMP3;
    }
    else if ([path containsString:@".m3u8"])
    {
        return SYMediaFormatM3U8;
    }
    else if ([path containsString:@".mov"])
    {
        return SYMediaFormatMOV;
    }
    
    return SYMediaFormatUnknown;
}

- (SYDecoderType)decoderTypeForContentURL:(NSURL *)contentURL
{
    SYMediaFormat mediaFormat = [self mediaFormatForContentURL:contentURL];
    switch (mediaFormat) {
        case SYMediaFormatError:
            return SYDecoderTypeError;
        case SYMediaFormatUnknown:
            return self.decodeTypeForUnknown;
        case SYMediaFormatMP3:
            return self.decodeTypeForMP3;
        case SYMediaFormatMPEG4:
            return self.decodeTypeForMPEG4;
        case SYMediaFormatMOV:
            return self.decodeTypeForMOV;
        case SYMediaFormatFLV:
            return self.decodeTypeForFLV;
        case SYMediaFormatM3U8:
            return self.decodeTypeForM3U8;
        case SYMediaFormatRTMP:
            return self.decodeTypeForRTMP;
        case SYMediaFormatRTSP:
            return self.decodeTypeForRTSP;
    }
}


#pragma mark - ffmpeg opstions

- (void)configFFmpegOptions
{
    self.formatContextOptions = [NSMutableDictionary dictionary];
    self.codecContextOptions = [NSMutableDictionary dictionary];
    
    [self setFFmpegFormatContextOptionStringValue:@"SGPlayer" forKey:@"user-agent"];
    [self setFFmpegFormatContextOptionIntValue:20 * 1000 * 1000 forKey:@"timeout"];
    [self setFFmpegFormatContextOptionIntValue:1 forKey:@"reconnect"];
}

- (NSDictionary *)FFmpegFormatContextOptions
{
    return [self.formatContextOptions copy];
}

- (void)setFFmpegFormatContextOptionIntValue:(int64_t)value forKey:(NSString *)key
{
    [self.formatContextOptions setValue:@(value) forKey:key];
}

- (void)setFFmpegFormatContextOptionStringValue:(NSString *)value forKey:(NSString *)key
{
    [self.formatContextOptions setValue:value forKey:key];
}

- (void)removeFFmpegFormatContextOptionForKey:(NSString *)key
{
    [self.formatContextOptions removeObjectForKey:key];
}

- (NSDictionary *)FFmpegCodecContextOptions
{
    return [self.codecContextOptions copy];
}

- (void)setFFmpegCodecContextOptionIntValue:(int64_t)value forKey:(NSString *)key
{
    [self.codecContextOptions setValue:@(value) forKey:key];
}

- (void)setFFmpegCodecContextOptionStringValue:(NSString *)value forKey:(NSString *)key
{
    [self.codecContextOptions setValue:value forKey:key];
}

- (void)removeFFmpegCodecContextOptionForKey:(NSString *)key
{
    [self.codecContextOptions removeObjectForKey:key];
}

@end
